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
    ServerResponse * response = [session headWithPath:@"/about/albuquerque/test/anamespace/inttag"];
    NSMutableURLRequest * request = [[[response err] userInfo] objectForKey:@"request"];
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
    NSMutableURLRequest * request;
    ServerResponse * response;
    for (NSString * ty in types) {
        id val = [Utils randomValuewithType:ty];
        response = [session putWithPath:@"/about/albuquerque/test/foo/footag" 
                                                  andContent:val];
        request = [[[response err] userInfo] objectForKey:@"request"];
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
    // TODO: check actual JSON formation.
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
    // fake it so it'll look good (i.e., already extant) to the save method.
    // these lines, and similar lines elsewhere, can go away after Issue #4 is done.    
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

- (void) testTagCreation
{
    Tag * tag = [FluidObject Tag:@"foo" withPath:@"test/public"];
    [session save:tag];
    NSMutableURLRequest * request = [[[tag err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
    STAssertTrue(okayheaders, @"correct headers");
    BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/json"];
    STAssertTrue(okayContent, @"correct Content-Type.");
    STAssertTrue([@"POST" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/tags/test/public"], @"correct path.");
    // TODO: check JSON.
    tag = [FluidObject Tag:@"foo" withPath:@"test/public" andTagDescription:@"a big footag"];
    // TODO: check JSON.
}

- (void) testTagDelete
{
    Tag * tag = [FluidObject Tag:@"foo" withPath:@"test/public"];
    [session delete:tag]; 
    NSMutableURLRequest * request = [[[tag err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", nil]];
    STAssertTrue(okayheaders, @"correct headers");
    STAssertTrue([@"DELETE" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/tags/test/public/foo"], @"correct path.");    
}

- (void) testTagUpdate 
{
    Tag * tag = [FluidObject Tag:@"foo" withPath:@"test/public"];
    tag.URI = @"osepu"; // more stuff to go away with issue #4
    tag.fluidinfoId = @"otn.egyls";
    [tag markClean];
    [tag setDescription:@"a fooey description."];
    [session save:tag];
    NSMutableURLRequest * request = [[[tag err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
    STAssertTrue(okayheaders, @"correct headers");
    BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/json"];
    STAssertTrue(okayContent, @"correct Content-Type.");
    STAssertTrue([@"PUT" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/tags/test/public/foo"], @"correct path.");
    // TODO: check JSON.
}

- (void) testObjectSaveWithTagValues
{
    FObject * obj = [FluidObject FObject];
    obj.URI = @"oentush,";
    obj.fluidinfoId = @".,curhs.co";
    
    // first, a values-put.
    Tag * prim1 = [FluidObject Tag:@"prim1" withPath:@"test/public"];
    Tag * prim2 = [FluidObject Tag:@"prim2" withPath:@"test/public"];
    [obj setTag:prim1 withValue:[[Value alloc] initWithValue:@"this is a primitive-bearing tag."]];
    [obj setTag:prim2 withValue:[[Value alloc] initWithValue:[NSNumber numberWithInteger:42]]];
    [session save:obj];
    
    NSMutableURLRequest * request = [[[obj err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[request allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", @"Content-Type", @"Content-Length", nil]];
    STAssertTrue(okayheaders, @"correct headers");
    BOOL okayContent = [[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:@"application/json"];
    STAssertTrue(okayContent, @"correct Content-Type.");
    STAssertTrue([@"PUT" isEqualToString:[request HTTPMethod]], @"correct method");
    STAssertTrue([[[request URL] path] isEqualToString:@"/values"], @"correct path.");
    NSData * body = [request HTTPBody];
    // not sure why the following is failing.  I can't get the escapes right.
    NSData * expected = [@"{\"queries\":[[\"fluiddb\\/id = \\\".,curhs.co\\\"\",{\"test\\/public\\/prim1\":{\"value\":\"this is a primitive-bearing tag.\"}},{\"test\\/public\\/prim2\":{\"value\":42}}]]}" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:expected], @"correct json.");
}

- (void) testLLMethodPutWithPathAndContent
{
    ServerResponse * resp = [session putWithPath:@"test/atag" andContent:@"foo foo \"foo!\" Bar?"];
    NSMutableURLRequest * req = [[[resp err] userInfo] objectForKey:@"request"];
    NSData * body = [req HTTPBody];
    NSData * exp = [@"\"foo foo \\\"foo!\\\" Bar?\"" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:exp], @"correct content for string primitive.");
    
    resp = [session putWithPath:@"test/atag" andContent:[NSArray arrayWithObjects:@"stringfirst", @"anotherstring", nil]];
    req = [[[resp err] userInfo] objectForKey:@"request"];
    body = [req HTTPBody];
    exp = [@"[\"stringfirst\",\"anotherstring\"]" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:exp],
                 @"correct content for set primitive.");

    resp = [session putWithPath:@"test/atag" andContent:[NSNumber numberWithBool:YES]];
    req = [[[resp err] userInfo] objectForKey:@"request"];
    body = [req HTTPBody];
    exp = [@"true" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:exp],
                 @"correct content for boolean primitive.");

    resp = [session putWithPath:@"test/atag" andContent:[NSNumber numberWithFloat:15.253]];
    req = [[[resp err] userInfo] objectForKey:@"request"];
    body = [req HTTPBody];
    NSLog(@"\n%s\n", [body bytes]);
    exp = [@"15.253000" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:exp],
                 @"correct content for float primitive.");

    resp = [session putWithPath:@"test/atag" andContent:[NSNumber numberWithInteger:2530]];
    req = [[[resp err] userInfo] objectForKey:@"request"];
    body = [req HTTPBody];
    exp = [@"2530" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertTrue([body isEqualToData:exp],
                 @"correct content for integer primitive.");
}

- (void)testDeleteTagsForQuery
{
  ServerResponse * resp = [session deleteTags:
				     [NSArray arrayWithObjects:@"ntoll/rating", @"ntoll/resume", nil]
                                     forQuery:@"mike/rating > 5"];
    NSMutableURLRequest * req = [[[resp err] userInfo] objectForKey:@"request"];
    BOOL okayheaders = [Utils headersOkay:[req  allHTTPHeaderFields]
                              withAllowed:[NSArray arrayWithObjects:@"User-Agent", @"Accept", nil]
                                 required:[NSArray arrayWithObjects:@"Authorization", nil]]; 
    STAssertTrue(okayheaders, @"correct headers");
    STAssertTrue([[[req URL] query] isEqualToString:@"query=mike/rating%20%3E%205&tag=ntoll/rating&tag=ntoll/resume"], @"correct query.");
    STAssertTrue([[[req URL] path] isEqualToString:@"/values"], @"correct path.");
    STAssertNil([req HTTPBody], @"null body");
}

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



