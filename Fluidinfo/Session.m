//
//  Session.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/20/11.
//

#import "Session.h"
#import "fluidinfo.h"

#define _DOMAIN @"com.fluidinfo.api.NSCocoaErrorDomain"
#define INSTANCE [NSURL URLWithString: [NSString stringWithFormat:@"%@://%@", scheme, instance]]
#define __DEBUG__ YES

@implementation Session
@synthesize instance, scheme;
- (id) init 
{
  self = [super init];
  if (self) {
  instance = @"sandbox.fluidinfo.com";
  scheme = @"http";
  }
  return self;
}

+ (id) initWithUsername:(NSString *)u andPassword:(NSString *)p
{
  Session * s = [[Session alloc] init];
  [s loginWithUsername:u andPassword:p];
  return s;
}

- (ServerResponse *) doRequest:(NSMutableURLRequest *)request
{
    NSError *err = [[NSError alloc] initWithDomain:_DOMAIN code:0 userInfo:NULL];    
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] init];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
    // the code should get reset with all errors, but it doesn't always happen so, so we have to check the status code ourselves.
    NSInteger code = [resp statusCode];
    if (err.code != 0 || code >= 400)
    { 

      // DEBUGGING:
      if (__DEBUG__) {
        NSLog(@"error %d with %@ request:\n \
              request with headers:%@\nandbody:%s \
              and url:%@\n \
              response with headers:%@\nandbody:%s",
              code,
              [request HTTPMethod],
              [request allHTTPHeaderFields],
              [[request HTTPBody] bytes],
              [[request URL] standardizedURL],
              [resp allHeaderFields],
              [data bytes]);
      }
        // this ensures that all the information sent back from the
        // server is preserved in the usual way.  It's great for
        // debugging.

        NSDictionary * rinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [resp allHeaderFields], @"headers",
                                             data, @"data",
                                             err, @"NSURLConnectionError",
                                             nil];
        NSError *error = [[NSError alloc] initWithDomain:_DOMAIN code:code userInfo:rinfo];
        return [[ServerResponse alloc] initwithError:error];
    }
    else
        return [[ServerResponse alloc] initwithData:(NSData *)data andResponse:(NSHTTPURLResponse *)resp];
}

- (void) loginWithUsername:(NSString *)u andPassword:(NSString *)p
{
    if (headers == NULL) [self initHeaders];
    
    NSString *temp = [NSString stringWithFormat:@"%@:%@", u, p];
    // NSStringAdditions accepts NSData objects, only, for this.
    NSData *data = [temp dataUsingEncoding:NSUTF8StringEncoding];
    NSString *auth = [NSString base64StringFromData:data length:[data length]];
    
    [headers setValue:[NSString stringWithFormat:@"Basic %@",auth]
               forKey:@"Authorization"];
    scheme = @"https";
}

- (void) initHeaders
{
    // we do not want to end up trying to assign values to a NULL object.
    headers = [NSMutableDictionary dictionaryWithObjectsAndKeys:
               @"*/*", @"Accept",
               @"Fluidinfo Obj-c client library",  @"User-Agent",
               nil];
}

- (id) get:(FluidObject *)fl
// get returns whatever JSON fluiddb gives back.  Use refresh to refresh an object's attributes.
{
    ServerResponse * response = [self getWithPath:[fl resavePath]];
    if (response.err != NULL)
    {
        [fl setErr:response.err];
	// have to return an NSObject..
        return [NSNumber numberWithBool:NO];
    }
    return [NSJSONSerialization JSONObjectWithData:response.data options:normal error:NULL];
}

- (id) get:(FluidObject *)fl withArgs:(NSArray *)args
// get returns whatever JSON fluiddb gives back.  Use refresh to refresh an object's attributes.
{
    ServerResponse * response = [self getWithPath:[fl resavePath] andArgs:args];
    if (response.err != NULL)
    {
                [fl setErr:response.err];
        return [NSNumber numberWithBool:NO];
    }
    return [NSJSONSerialization JSONObjectWithData:response.data options:normal error:NULL];
}

- (BOOL) refresh:(FluidObject *)fl
{
  id fresh;
  // handle namespaces.
  if ([fl isKindOfClass:[Namespace class]]) {
      Namespace * n = (Namespace *) fl;
    fresh = [self get:fl withArgs:[NSArray arrayWithObjects:
					   @"returnDescription=True",
					 @"Returnnamespaces=True",
					 @"returnTags=True",
					 nil]];
    if ([fresh isKindOfClass:[NSNumber class]])
        return NO; 
    [n setTagNames:[fresh valueForKey:@"tagNames"]];
    [n setNamespaceNames:[fresh valueForKey:@"namespaceNames"]];
    [n setDescription:[fresh valueForKey:@"description"]];
    [n setFluidinfoId:[fresh valueForKey:@"id"]];
      [n markClean];
      return YES;

  }
  // handle tags.
  else if ([fl isKindOfClass:[Tag class]]) {
    fresh = [self get:fl withArgs:[NSArray arrayWithObject:@"returnDescription=True"]];
    if ([fresh isKindOfClass:[NSNumber class]])
      return NO;
    [((Tag *) fl) setDescription:[fresh valueForKey:@"description"]];
  }
  [fl setFluidinfoId:[fresh valueForKey:@"id"]];
    [fl markClean];
  return YES;
}

- (BOOL) reset:(FluidObject *)fl
{
  if ([fl isKindOfClass:[Object class]])
    {
      // refresh all the tags that are on the object to null and get rid
      // of any tags that have been added with a value but never saved.
      // this does not change existing tagObjects or values that are not
      // marked "dirty."  It also does not delete tags in the tagObjects
      // dictionary, even if they are not actually attached to this
      // object.
      Object * obj = (Object *) fl;
      id  got = [self get:obj];
      if ([got isKindOfClass:[NSNumber class]])
	return NO;
      NSArray * tagpaths = [got valueForKey:@"tagPaths"];
      NSArray * oldtags = [[obj tags] allKeys];
      for (NSString * key in tagpaths)
	if ([oldtags containsObject:key])
	  {
	    if (![[obj tagPaths] containsObject:key]) // then remove it.  it isn't real.
	      [[obj tags] removeObjectForKey:key];
	    else
	      if ([[obj dirtytags] containsObject:key])
		{
		  [[obj tags] setValue:[NSNull null] forKey:key];
		  [[obj dirtytags] removeObject:key];
		}
	  }
	else // this is a new tag.
	  [[obj tags] setValue:[NSNull null] forKey:key];
      return YES;
    }
    else
        return NO;
}

- (BOOL) save:(FluidObject *)fl
{  
    if (![fl isdirty]) return YES;
    if ([fl URI] && [fl fluidinfoId]) return [self resave:fl];
    // then it's really a first-time save...
    // set the request
    ServerResponse * response;
    id j = [fl saveJSON];
    if (j) // Objects have no json to post.
        response = [self postWithPath:[fl savePath] andJson:j];
    else
        response = [self postWithPath:[fl savePath]];
    if (response.err != NULL)
        {
            [fl setErr:response.err];
            return NO;
        }
    NSDictionary * rdict = [NSJSONSerialization JSONObjectWithData:response.data options:normal error:NULL];
    [fl setURI: [rdict valueForKey:@"URI"]];
    [fl setFluidinfoId: [rdict valueForKey:@"id"]];
    if ([fl isKindOfClass:[Object class]]) 
      // if it's an object, we need to save any dirty tags that it might have.
      return [self resave:fl]; 
    [fl markClean];
    return YES;
}

- (BOOL) resave:(FluidObject *)fl
{
    if (![fl isKindOfClass:[Object class]]) {
	ServerResponse * response = [self 
					   putWithPath:[fl resavePath] andJson:[fl resaveJSON]];
	if (response.err != NULL)
	    { 
		[fl setErr:response.err];
		return NO;
	    }
	[fl markClean];
	return YES;
    }
    Object * obj = (Object *) fl;
    if (![obj isdirty]) return YES;
    // this is a  one-liner with foldl, in Haskell.  :(
    BOOL sofarsogood = YES;
    // try to save all of the dirty tags, but returns YES only if they
    // all saved correctly.
    // save the assignments and put it into another dictionary before sending it.
    NSMutableDictionary * assignments = [[NSMutableDictionary alloc] init];
    id val;
    for (NSString * tag in [[obj dirtytags] copy]) {
	val = [[obj tagValues] objectForKey:tag];
        if ([self isPrimitive:val]) {
            [assignments setObject:[((Value *)val) value] forKey:tag];
            [[obj dirtytags] removeObject:tag]; 
        }
    }
    NSDictionary * final = [NSDictionary dictionaryWithObject:assignments forKey:
				  [NSString stringWithFormat:@"fluiddb/id = \"%@\"", [obj fluidinfoId]]];
    ServerResponse * resp = [self putWithQuery:final];
    // the only place to save a group error like this is on the object itself.
   if ([resp err]) {
       sofarsogood = NO;
       obj.err = resp.err;
    }
   BOOL success;
    for (NSString * tag in [[obj dirtytags] copy]) {      
	success = [self object:obj saveTag:[[obj tagValues] valueForKey:tag]];
	if (!success)
        // these errors can be saved per-tag.
	    [[[obj tags] objectForKey:tag] setErr:[resp err]];
        sofarsogood = success && sofarsogood;
    }
	return sofarsogood;
}


- (BOOL) isPrimitive:(id)thing
{
    return [thing isKindOfClass:[Value class]] && ![((Value *) thing) type];
}

- (BOOL) delete:(FluidObject *)fl
{
    ServerResponse * response = [self deleteWithPath:[fl resavePath]];
    if (response.err != NULL)
    { 
        [fl setErr:response.err];
        return NO;
    }
    return YES;
}

- (Permission *) getPermission:(NSString *)act for:(FluidObject *)fl;
{
  NSString * path;
  if ([fl isKindOfClass:[Namespace class]]) 
    path = [NSString stringWithFormat:@"/permissions/namespaces/%@", [((Namespace *) fl) fullpath]];    
  else if ([fl isKindOfClass:[Tag class]])
    path = [NSString stringWithFormat:@"/permissions/tags/%@", [((Tag *) fl) fullpath]];
  ServerResponse *resp = [self getWithPath:path andArgs:[NSArray arrayWithObject:[NSString stringWithFormat:@"action=%@", act]]];
  if (resp.err != NULL) return NULL;
  NSDictionary * rdict = [NSJSONSerialization JSONObjectWithData:resp.data options:normal error:NULL];
  enum policy pol = [rdict valueForKey:@"policy"] == @"open" ? (enum policy) OPEN : (enum policy) CLOSED;
  Permission * permission = [[Permission alloc] initWithPolicy:pol andExceptions:[rdict valueForKey:@"exceptions"]];
  return permission;
}

- (BOOL) setPermission:(NSString *)act for:(FluidObject *)fl to:(Permission *)p;
{
  NSString * path;
  if ([fl isKindOfClass:[Namespace class]]) 
    path = [NSString stringWithFormat:@"/permissions/namespaces/%@", [((Namespace *) fl) fullpath]];
  else if ([fl isKindOfClass:[Tag class]]) 
    path = [NSString stringWithFormat:@"/permissions/tags/%@", [((Tag *) fl) fullpath]];
  ServerResponse *resp = [self putWithPath:path andJson:
				     [NSDictionary 
				       dictionaryWithObjectsAndKeys:
					 p->_policy == 0 ? @"closed" : @"open", @"policy",
				       [p getExceptions], @"exceptions",
				       nil]];
  if (resp.err != NULL) 
    {
      [fl setErr:resp.err];
      return NO;
    }
  if ([fl isKindOfClass:[Namespace class]]) 
    [[((Namespace *) fl) perms] setValue:p forKey:act];
  else if ([fl isKindOfClass:[Tag class]]) 
    [[((Tag *) fl) perms] setValue:p forKey:act];
  return YES;
}

- (Permission *) getTagValuePermission:(NSString *)act forTag:(Tag *)t
{
  NSString * path = [NSString stringWithFormat:@"/permissions/tag-values/%@", [t fullpath]];
  ServerResponse *resp = [self getWithPath:path andArgs:[NSArray arrayWithObject:[NSString stringWithFormat:@"action=%@", act]]];
  if (resp.err != NULL) return NULL;
  NSDictionary * rdict = [NSJSONSerialization JSONObjectWithData:resp.data options:normal error:NULL];
  enum policy pol = [rdict valueForKey:@"policy"] == @"open" ? (enum policy) OPEN : (enum policy) CLOSED;
  Permission * permission = [[Permission alloc] initWithPolicy:pol andExceptions:[rdict valueForKey:@"exceptions"]];
  if (resp.err != NULL) 
    {
      [t setErr:resp.err];
      return NULL;
    }
  [[t perms] setValue:permission forKey:act];
  return permission;
}

- (BOOL) setValuePermission:(NSString *)act to:(Permission *)p forTag:(Tag *)t
{

  NSString * path = [NSString stringWithFormat:@"/permissions/tag-values/%@", [t fullpath]];
  ServerResponse *resp = [self putWithPath:path andJson:
				     [NSDictionary 
				       dictionaryWithObjectsAndKeys:
					 p->_policy == 0 ? @"closed" : @"open", @"policy",
				       [p getExceptions], @"exceptions",
				       nil]];
  if (resp.err != NULL) 
    {
      [t setErr:resp.err];
      return NO;
    }
  [[t perms] setValue:p forKey:act];
  return YES;
}

- (BOOL) object:(Object *)o tagValue:(Tag *)t
{
// load a tag-value from Fluidinfo into the object's tags dictionary.
    NSString * path = [NSString stringWithFormat:@"%@/%@",
				[o savePath], [t path]];
    ServerResponse * resp = [self getWithPath:path];
    if ([resp.response statusCode] == 200)
	{   
	    // it should try to figure out what the value is and cast it.  this will do for now.
	  // TODO finish this!
	    Value * val = [[Value alloc] 
			      initWithValue:(NSData *)resp.data
				    andType:[[resp.response allHeaderFields] valueForKey:@"Content-Type"]];
	    [[o tags] setValue:val forKey:[t path]];
	    return YES;
	}
    else
      [o setErr:resp.err];
    return NO;
}

- (BOOL) object:(Object *)fl hasTag:(Tag *)t
{
    NSString * path = [fl pathForTag:t];
    ServerResponse * resp = [self headWithPath:path];
    NSInteger code = [resp.response statusCode];
    if (code == 200)
	return YES;
    [fl setErr:resp.err];
    return NO;
}

- (BOOL) object:(Object *)fl saveTagByString:(NSString *)t
{
  return [self object:fl saveTag:[[fl tags] valueForKey:t]];
}

- (BOOL) object:(Object *)fl saveTag:(Tag *)t
{
    // don't save it if it isn't dirty.
    if (![[fl dirtytags] containsObject:[t fullpath]])
        return YES;
    // create vars.
    Value * v = [[fl tags] valueForKey:[t fullpath]];
    NSString *path = [fl pathForTag:t];
    // set the request content for NSData puts.
    ServerResponse * response;
    if ([[v value] isKindOfClass:[NSData class]])
	{
	    NSData *content = [v value];
	    if (content == NULL && v.filepath != NULL)
		content = [NSData dataWithContentsOfURL:v.filepath];
	    if (v.type == NULL)
            response = [self putWithPath:path andContent:content];
	    else
            response = [self putWithPath:path andMimeType:v.type andContent:content];
	}
    else
        if (v.type == @"application/json")
            // it is assumed to be either an NSArray, or an NSDictionary,
            // i.e. serializable for JSON and intended to be sent as JSON.
            response = [self putWithPath:path andJson:[v value]];
        else
            // then it must be a primitive value, which FluidRequests will wrap for us.
            response = [self putWithPath:path andContent:[v value]];
    // contact the server, store the error if any, and return a helpful boolean.
    if ([response.response statusCode] == 204) {
        [[fl dirtytags] removeObject:[t fullpath]];   
        return YES;
    }
    [fl setErr:response.err];
    return NO;
}

- (BOOL) object:(Object *)fl removeTagString:(NSString *)s
{
  return [self object:fl removeTag:[[fl tags] valueForKey:s]];
}

- (BOOL) object:(Object *)fl removeTag:(Tag *)t
{
    ServerResponse * resp = [self deleteWithPath:[fl pathForTag:t]];
    if (resp.err == NULL)
	return YES;
    [fl setErr: resp.err];
    return NO;
}

- (ServerResponse *)getWithPath:(NSString *)_path 
{
  return [self doRequest:[self subGetWithPath:_path]];
}

- (NSMutableURLRequest *)subGetWithPath:(NSString *)_path 
{
    if (headers == NULL) [self initHeaders];
    NSURL *u = [NSURL URLWithString:_path relativeToURL:INSTANCE];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u
						       cachePolicy:NSURLRequestReloadIgnoringCacheData
						   timeoutInterval:60];
    [req setAllHTTPHeaderFields:headers];
    return req;
}

- (ServerResponse *) getWithPath:(NSString *)s andArgs:(NSArray *)a
{
  NSString *args = [Session doArgs:a];
    NSString *url = [NSString stringWithFormat:@"%@?%@", s, args];
    return [self getWithPath:url];
}

- (ServerResponse *) getWithPath:(NSString *)s andQuery:(NSString *)q
{
  NSString * url = [NSString stringWithFormat:@"%@?query=%@", s,
                             [q stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  return [self getWithPath:url];
}

- (ServerResponse *) getWithQuery:(NSString *)q forTags:(NSArray *)t
{
  return [self getWithPath:[self pathWithQuery:q forTags:t]];
}

- (NSString *) pathWithQuery:(NSString *)q forTags:(NSArray *)arr
{
    return  [NSString stringWithFormat:@"/values?query=%@%@",
		      [q stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
			  [Session doTags:arr]];
}

- (ServerResponse *) headWithPath:(NSString *)s
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"HEAD"];
    return [self doRequest:req];
}

// this method is for sending primitive values in various states of undress.
- (ServerResponse *) putWithPath:(NSString *)s andContent:(id)c
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"PUT"];
    [req addValue:@"application/vnd.fluiddb.value+json" forHTTPHeaderField:@"Content-Type"];
    if ([c isKindOfClass:[NSData class]]) {
        [req setHTTPBody:c];   
        [req addValue:[NSString stringWithFormat:@"%d", [c length]] forHTTPHeaderField:@"Content-Length"];
    }
    else 
    {
        NSData * d = [[Session packPrimitive:c] dataUsingEncoding:NSUTF8StringEncoding];
        [req setHTTPBody:d];
        [req addValue:[NSString stringWithFormat:@"%d", [d length]] forHTTPHeaderField:@"Content-Length"];
    }
    return [self doRequest:req];
}
- (ServerResponse *) putWithPath:(NSString *)s andJson:(id)j
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"PUT"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (![NSJSONSerialization isValidJSONObject:j])
        return [NSError errorWithDomain:_DOMAIN code:1 userInfo:[NSDictionary dictionaryWithObject:@"cannot send unserializable JSON." forKey:@"reason"]];
    NSError * err = [NSError errorWithDomain:_DOMAIN code:0 userInfo:NULL];
    NSData *body = [NSJSONSerialization dataWithJSONObject:j options:normal error:&err];
    [req addValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:body];
    return [self doRequest:req];
}

- (ServerResponse *) putWithPath:(NSString *)s andMimeType:(NSString *)t andContent:(NSData *)c
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"PUT"];
    [req addValue:t forHTTPHeaderField:@"Content-Type"];
    [req addValue:[NSString stringWithFormat:@"%d", [c length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:c];
    return [self doRequest:req];
}

// alternative, ensure's correct encoding, since we're having problems with newlines.
// this is temporary, surely.
- (ServerResponse *) putWithQuery:(NSDictionary *)q
{
  NSMutableURLRequest *req = [self subGetWithPath:@"values"];
    [req setHTTPMethod: @"PUT"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableArray * queries = [[NSMutableArray alloc] initWithCapacity:([q count] + 1)];
    for (NSString * query in [q allKeys]) {
      NSMutableArray * arr = [NSMutableArray arrayWithObject:query];
      NSDictionary * xxx = [q objectForKey:query];
        for (NSString * tag in [xxx allKeys]) 
            [arr addObject:[NSDictionary dictionaryWithObject:
					    [NSDictionary dictionaryWithObject:
                         [xxx objectForKey:tag] forKey:@"value"]
							forKey:tag]];
        [queries addObject:arr];
    }
    return [self putWithPath:@"/values" andJson:[NSDictionary dictionaryWithObject:queries forKey:@"queries"]];
}
			       

/*
{
  "queries" : [
    [ "mike/rating > 5",
      {
        "ntoll/rating" : {
          "value" : 6
        },
        "ntoll/seen" : {
          "value" : true
        }
      }
    ],
    [ "fluiddb/about matches \"great\"",
      {
        "ntoll/rating" : {
          "value" : 10
        }
      }
    ],
    [ "fluiddb/id = \"6ed3e622-a6a6-4a7e-bb18-9d3440678851\"",
      {
        "mike/seen" : {
          "value" : true
      }
    ]
  ]
}

#define PUTVALQUERYSTART @"{\"queries\":["
#define PUTVALQUERYEND @"]}"

// this is a special dictionary.  its values must each be a dictionary of assignments to make to objects matching the query, which is the key.
- (ServerResponse *) putWithQuery:(NSDictionary *)q
{

  NSMutableURLRequest *req = [self subGetWithPath:@"values"];
    [req setHTTPMethod: @"PUT"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *body = [NSMutableString stringWithString:PUTVALQUERYSTART];
    BOOL firstQuery = YES;
    for (NSString * query in q)
    {
        [body appendFormat:@"%s[\"%@\",{" ,
          firstQuery ? "" : ",", 
              query];
        firstQuery = NO;
        NSDictionary * assignments = [q valueForKey:query];
        BOOL firstAssignment = YES;
        for (NSString * key in assignments)
        {
            [body appendFormat:@"%s\"%@\":{\"value\":%@}", 
                  firstAssignment ? "" : ",", 
                  key, 
             [Session packPrimitive:[assignments valueForKey:key]]];
            firstAssignment = NO;
        }
        [body appendString:@"}]"];
    }
    [body appendString:PUTVALQUERYEND];
    NSData * d = [body dataUsingEncoding:NSUTF8StringEncoding];
    [req setHTTPBody:d];
    [req addValue:[NSString stringWithFormat:@"%d", [d length]] forHTTPHeaderField:@"Content-Length"];
    return [self doRequest:req];
}
*/
- (ServerResponse *) postWithPath:(NSString *)s
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"POST"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return [self doRequest:req];
}

// this method is for primitive content.
- (ServerResponse *) postWithPath:(NSString *)s andContent:(NSData *)c
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"POST"];
    [req addValue:@"application/vnd.fluiddb.value+json" forHTTPHeaderField:@"Content-Type"];
    [req addValue:[NSString stringWithFormat:@"%d", [c length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:c];
    return [self doRequest:req];
}

- (ServerResponse *) postWithPath:(NSString *)s andJson:(id)j
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"POST"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // make sure it's valid json.
    if (![NSJSONSerialization isValidJSONObject:j])
        return [NSError errorWithDomain:_DOMAIN code:1 userInfo:[NSDictionary dictionaryWithObject:@"cannot send unserializable JSON as such." forKey:@"reason"]];
    NSError * err = [NSError errorWithDomain:_DOMAIN code:0 userInfo:NULL];
    NSData *body = [NSJSONSerialization dataWithJSONObject:j options:normal error:&err];
    [req addValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:body];
    return [self doRequest:req];
}

- (ServerResponse *) deleteWithPath:(NSString *)s
{
    NSMutableURLRequest *req = [self subGetWithPath:s];
    [req setHTTPMethod: @"DELETE"];
    return [self doRequest:req];
}

+ (NSMutableString *) doTags:(NSArray *)arr
{
    NSMutableString *args = [[NSMutableString alloc] init];
    for (NSString * tag in arr) 
	[args appendFormat:@"&tag=%@", tag];
    return args;
}

+ (NSString *) doArgs:(NSArray *) a
{
  NSMutableString *args = [[NSMutableString alloc] init];
    BOOL first = YES;
    for (NSString * arg in a) {
        [args appendFormat:@"%@%@", first ? @"" : @"&", arg];
        if (first) first = NO;
    }
    return args;
}



// convert a primitive value, such as an integer (which must be
// already packed into an NSValue in order to be passed to this
// function), into suitable NSData for sending over the wire.
+ (NSString *) packPrimitive:(id)content
{
    // the content might be in a Value, for whatever reason.
    id c;
    if ([content isKindOfClass:[Value class]])
         c = [((Value *) content) value];
    else
         c = content;
    if (c == NULL) return @"null";
    if ([c isKindOfClass:[NSString class]])
        return [NSString stringWithFormat:@"\"%@\"",c];
    
    // sets of strings
    if ([c isKindOfClass:[NSArray class]])
    {
        // see if it's compatible with the definition of primitives sets
        // in the Fluidinfo documentation.
        BOOL cando = YES;
        for (NSString * item in c)
            if (![item isKindOfClass:[NSString class]]) {
                cando = NO;
                break;
            }
        if (!cando) return [NSError errorWithDomain:_DOMAIN code:2 userInfo:
                            [NSDictionary dictionaryWithObject:
                             @"cannot send arrays with non-string members as fluidinfo primitives." forKey:@"reason"]];
        NSMutableString * temp = [[NSMutableString alloc] initWithString:@"["];
        for (NSString * item in c) {
            [temp appendFormat:@"%s\"%@\"", cando ? "" : ",", item]; // variable recycling.
            cando = NO;
        }
        [temp appendString:@"]"];
        return temp;
    }
    
    if (![c isKindOfClass:[NSNumber class]])
        return [NSError errorWithDomain:_DOMAIN code:3 userInfo:
                [NSDictionary dictionaryWithObject:
                 @"attempted to send a non-fluidinfo-primitive value as a primitive." forKey:@"reason"]];
    
    // bools, ints, and floats.
    const char * type = [c objCType];
    NSString * val;
    if (*type == 'c')
        val = [c boolValue] == YES ? @"true" : @"false";
    if (*type == 'i')
        val = [NSString stringWithFormat:@"%i", [c integerValue]];
    if (*type == 'f')
        val = [NSString stringWithFormat:@"%f", [c floatValue]];
    return val;
}


@end
