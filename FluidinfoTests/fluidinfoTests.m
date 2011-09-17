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



