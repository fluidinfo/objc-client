//
//  FluidinfoTests.m
//  FluidinfoTests
//
//  Created by Barbara Shirtcliff on 7/12/11.
//

#import "fluidinfo.h"
#import "fluidinfoTests.h"
#import "FakeServer.h"
#import "Sample.h"
#import "Utils.h"

#define DEBUG_ON TRUE

// error domain as recommended by "Error Objects, Domains, and Codes" in iOS 5 Documentation.
#define _DOMAIN @"com.fluidinfo.api.NSCocoaErrorDomain"

@implementation fluidinfoTests
@synthesize session;

- (void)setUp
{
    [super setUp];
    // the server seeds itself with a few default objects, tags, and tag-values for each test.
    [self setSession:[Session initWithUsername:@"test" andPassword:@"test"]];
}

- (void)tearDown
{
    [super tearDown];
}

/*
 
 Request Semantics
 
 */

- (void) testHead
{
    NSMutableURLRequest * request = [session headWithPath:@"/about/albuquerque/test/anamespace/inttag"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", @"Authorization", nil]
                                 required:NULL];
    STAssertTrue(okayheaders, @"correct headers", @"foo");
    STAssertTrue([@"HEAD" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/about/albuquerque/test/anamespace/inttag"], @"correct path.");
}


- (void) testPutPrimitive
{
    NSArray *types = [NSArray arrayWithObjects:@"float",@"set",@"int",@"string",@"bool",@"null",nil];
    for (NSString * ty in types) {
        id val = [Utils randomValuewithType:ty];
        NSMutableURLRequest * request = [session putWithPath:@"/about/albuquerque/test/foo/footag" 
                                                  andContent:val];
        BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
        STAssertTrue(okayheaders, @"correct headers", @"foo");
        BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/vnd.fluiddb.value+json"];
        STAssertTrue(okayContent, @"correct Content-Type.");
        STAssertTrue([@"PUT" isEqualToString:[request HTTPMethod]], @"correct method");
        STAssertTrue([[[request URL] path] isEqualToString:@"/about/albuquerque/test/foo/footag"], @"correct path.");
        [self dataCheck:request forValue:val];
    }
}



- (void) testNamespaceCreation
{
    Namespace * namespace = [FluidObject Namespace:@"foonamespace" withPath:@"test/public" andDescription:@"another testing namespace."];
    [session save:namespace];
    NSMutableURLRequest * request = [[[namespace err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
    STAssertTrue(okayheaders, @"correct headers", @"foo");
    BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/json"];
    STAssertTrue(okayContent, @"correct Content-Type.");
    STAssertTrue([@"POST" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/namespaces/test/public"], @"correct path.");
    // TODO: check actual JSON formation?  Doing so seems silly, since it means reproducing the workings of the JSON library precisely, and, many things about JSON are flexible.
}


- (void) testNamespaceDelete
{
    Namespace * namespace = [FluidObject Namespace:@"foonamespace" withPath:@"test/public" andDescription:@"another testing namespace."];
    [namespace markClean];
    [session delete:namespace];
    NSMutableURLRequest * request = [[[namespace err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", nil]];
    STAssertTrue(okayheaders, @"correct headers", @"foo");
    STAssertTrue([@"DELETE" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/namespaces/test/public/foonamespace"], @"correct path.");    
}


-(void) testNamespaceUpdate
{
    Namespace * namespace = [FluidObject Namespace:@"foonamespace" withPath:@"test/public" andDescription:@"another testing namespace."];
    // fake it so it looks like it has already been saved.
    [namespace markClean];
    namespace.URI = @"foesu";
    namespace.fluidinfoId = @",.schrl,c";
    // update the description
    [namespace setDescription:@"foo foo foo"];
    [session save:namespace];
    // look at request - should be a PUT, not a POST.
    NSMutableURLRequest * request = [[[namespace err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
    STAssertTrue(okayheaders, @"correct headers", @"foo");
    BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/json"];
    STAssertTrue(okayContent, @"correct Content-Type.");
    STAssertTrue([@"PUT" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/namespaces/test/public/foonamespace"], @"correct path.");
}

/*

- (void) testDeleteTagValues
{
  ;
}

- (void) testURLArgsWithGetRequest
{
    // this is unfortunately how one should use url arguments if one doesn't want to construct the url oneself.
    NSArray * args = [NSArray arrayWithObjects:@"returnDescription=True", @"returnNamespaces=True", @"returnTags=True", nil];
    NSMutableURLRequest *request = [session 
				     getWithPath:@"test/namespaces/%@/public"
                                        andArgs:args];
    // look at request
}


- (void) testGetQueryWithTags
{
    NSArray *tags = [NSArray arrayWithObjects:
                     @"test/anamespace/inttag",
                     @"test/anamespace/stringtag", nil];
    NSMutableURLRequest *request = [session 
                                    getWithQuery:@"has test/anamespace/inttag"
                                    forTags:tags];
    // look at request
}

- (void) testPutWithQuery
{ // does it really have to be structured like this???
  NSDictionary *query = [NSDictionary dictionaryWithObject:
                                        [NSDictionary dictionaryWithObject:@"foo" forKey:@"test/public/testing"]
                                                    forKey:@"has test/anamespace/inttag"];
  // look at request
}

- (void) testSampleObjects 
{
    Sample * example = [[Sample alloc] initWithAbout:@"http://example.com" 
                                              Rating:5 
                                             Comment:@"a useful site."
                                             andDate:@"12534"];
    [session save:example];
    // look at request    
}



// =========== here's where we were before the big refactoring of today. ==============

- (void) testPutWithMime
{
  NSString *page = @"<html>Test page with nothing in it!<p>    but it's html.</p></html>";
  NSData *temp = [page dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableURLRequest *request = [session putWithPath:[NSString stringWithFormat:@"about/albuquerque/%@/public/testtag", USERNAME] andMimeType:@"text/html" andContent:temp];
    ServerResponse * response = [session doRequest:request];
    STAssertEquals([response.response statusCode], 204, 
                   [NSString stringWithFormat:@"Problem with urlargs:\n%@\nor response body:\n%s.",
                             [[request URL] absoluteURL],
                             [response.data bytes]],
                   @"See if we can put get our mime-types handled.");
}

- (void) testTagCreation
{
  Tag * tag = [FluidObject Tag:@"footag1" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"another awesome testing tag."];
    BOOL passed = [tag save] || tag.err.code == 412;
    STAssertTrue(passed, [NSString stringWithFormat:@"tag didn't save properly:\n%@", [tag description]]);
    [tag delete];
}

- (void) testTagUpdateViaCreation
// effectively tests both means, as one calls the other after failing with a 412.
{
  Tag * tag = [FluidObject Tag:@"footag1" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"This test tag keeps getting cooler.  I just can't leave it alone."];
    [tag save];
    [tag setDescription:@"okay, I'm fed up with this tag."];
    STAssertTrue([tag save], [NSString stringWithFormat:@"tag didn't save properly:\n%@", [tag description]]);
}

- (void) testTagDeletion // this should fail if the tag does not exist.
{
  Tag * tag = [FluidObject Tag:@"footag1" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"another awesome testing tag."];
    [tag save]; // not getting its id set.  URI is set.
    [tag delete];
    STAssertFalse([tag refresh], @"Tag refresh succeeded after deletion.", @"Nonexistent tags can't be refreshed.");
}

- (void) testNamespaceCreationAndDeletion
{
  Namespace * namespace = [FluidObject Namespace:@"foonamespace" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"another testing namespace."];
    BOOL passed = [namespace save] || namespace.err.code == 412;
    STAssertTrue(passed, @"namespace could not be saved.", @"Able to create a namespace.");
    STAssertTrue([namespace delete], @"unable to delete namespace.", @"bummer, dude.");
}

- (void) testObjectCreation
{
    Object * obj = [FluidObject Object];
    STAssertTrue([obj save], @"unable to create anonymous object", @"ability to create an anonymous object.");
    STAssertNotNil([obj fluidinfoId], @"object created, but id not set.", @"fluidinfoId should be set when an object is saved.");
}

- (void) testObjectCreationWithAbout
{
    Object * obj = [FluidObject Object:@"Phoenix the dog."];
    STAssertTrue([obj save], @"unable to create object with about", @"ability to create an object with an about string.");
}

- (void) testObjectAddTag
{
    Object * obj = [[Object alloc] init];
    STAssertTrue([obj save], @"anonymous object not saved.");
    Tag * tag = [FluidObject Tag:@"objecttag" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"an object-testing tag."];
    [tag save];
    Value * val = [[Value alloc] initWithValue:[@"1" dataUsingEncoding:NSUTF8StringEncoding]];
    STAssertTrue([obj setTag:tag withValue:val], @"Could not set tag-value.", @"impossible.");
    STAssertEquals(val, [obj tagValue:tag], @"Tag not really set on object", @"this is serious!");
    STAssertTrue([obj saveTag:tag], @"Could not save tag-value.", @"returns true on 204.");
}

- (void) testObjectRemoveTag
{
    Object * obj = [[Object alloc] init];
    [obj save];
    Tag * tag = [FluidObject Tag:@"objecttag" withPath:[NSString stringWithFormat:@"%@/public", USERNAME] andDescription:@"an object-testing tag."];
    [tag save];
    Value * val = [[Value alloc] initWithValue:[@"1" dataUsingEncoding:NSUTF8StringEncoding]];
    [obj setTag:tag withValue:val];
    [obj saveTag:tag];
    STAssertTrue([obj removeTag:tag], @"Could not remove tag-value.", @"oh shit!");
}

- (void) testObjectMultipleTags
{
    Object * obj = [FluidObject Object];
    NSArray * tags = [NSArray arrayWithObjects:
                              [FluidObject Tag:@"objecttag1" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
                              [FluidObject Tag:@"objecttag2" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
                              [FluidObject Tag:@"objecttag3" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
                              [FluidObject Tag:@"objecttag4" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
                      nil];

    Value * val = [[Value alloc] initWithValue:[@"1" dataUsingEncoding:NSUTF8StringEncoding]];

    for (Tag * tag in tags)
      [obj setTag:tag withValue:val];
    
    STAssertTrue([obj save], @"could not create an anonymous object, a bunch of tags, and some tag values all in one step!", @"the ultimate object-save.");

    for (Tag * tag in tags)
        [tag delete];
}

- (void) testPrimitiveTagValues
{
    Object * obj = [FluidObject Object];
    [obj setTag:[FluidObject Tag:@"int" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]] withValue:[[Value alloc] initWithValue:[NSNumber numberWithInteger:13]]]; // error expected
    [obj setTag:[FluidObject Tag:@"float" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]] withValue:[[Value alloc] initWithValue:[NSNumber numberWithFloat:13.5]]];
    [obj setTag:[FluidObject Tag:@"bool" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]] withValue:[[Value alloc] initWithValue:[NSNumber numberWithBool:NO]]];
    [obj setTag:[FluidObject Tag:@"string" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]] withValue:[[Value alloc] initWithValue:@"foofoofoo!"]];
    [obj setTag:[FluidObject Tag:@"set" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]] withValue:[[Value alloc] initWithValue:[NSArray arrayWithObjects:@"foo",@"bore",@"baz",nil]]];
    STAssertTrue([obj save], @"could not save an object with several primitive tag-values.", @"these are like the apes of tags, so Fluidinfo helps us to keep better track of them.");
}


- (void) testTagsWithJsonValues
{
    
}

- (void) testTagsSetByTagPaths
{
    Object * obj = [FluidObject Object];
    NSArray * tags = [NSArray arrayWithObjects:
			      [FluidObject Tag:@"objecttag1" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
			      [FluidObject Tag:@"objecttag2" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
			      [FluidObject Tag:@"objecttag3" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
			      [FluidObject Tag:@"objecttag4" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]],
                      nil];
    Value *v = [[Value alloc] initWithValue:[NSNumber numberWithInteger:3500]];
    for (Tag * tag in tags)
    {
        [tag save];
        [obj setTagPath:[tag fullpath] withValue:v];
    }
    STAssertTrue([obj save], @"setting tags by path not working.", @"important functionality.");
    for (Tag * tag in tags)
        [tag delete];
}

- (void) testGetVariousPerms
{
  Tag * tag = [FluidObject Tag:@"permissions" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]];
    [tag save];
    NSArray * actions = [NSArray arrayWithObjects:@"update",@"delete",@"control", nil];
    for (NSString * act in actions)
        STAssertNotNil([tag getPermission:act], @"unable to get %@ permission information on a tag", @"...");
    actions = [NSArray arrayWithObjects:@"delete", @"read", @"control", nil];
    for (NSString * act in actions)
        STAssertNotNil([tag getValuePermission:act], @"unable to get %@ permission information on a tag", @"...");
    Namespace * namespace = [FluidObject Namespace:@"permissions" withPath:[NSString stringWithFormat:@"%@/public", USERNAME]];
    [namespace save];
    actions = [NSArray arrayWithObjects:@"create", @"update",@"delete", @"list", @"control", nil];
    for (NSString * act in actions)
        STAssertNotNil([namespace getPermission:act], @"unable to get %@ permission information on a namespace", @"...");
    
}
// TODO
- (void) testGetValuesWithTags
{

}

*/

// TODO: this test has uncovered a problem in the JSON library, which is that it decodes floats as decimals, rounding as necessary.  We have to override how JSONSerialization is doing this, or possibly report the issue to Apple.  Meanwhile, this test might as well just check to see if the decimal is reasonably close to its original value.
- (void) dataCheck:(NSMutableURLRequest *)request forValue:(id)val
{
    if ([val isKindOfClass:[NSNumber class]]) {
        ;
        //        NSNumber * encval = [NSJSONSerialization JSONObjectWithData:[request HTTPBody] options:NSJSONReadingAllowFragments error:NULL];
        //        STAssertTrue([[encval stringValue] isEqualToString:[val stringValue]], 
        //                     [NSString stringWithFormat:@"dataCheck error:\noriginal value: %@\nencoded value: %@\n"]);
    }
    else if ([val isKindOfClass:[NSString class]]) {
        ; // this is not easy.
    }
}
@end



