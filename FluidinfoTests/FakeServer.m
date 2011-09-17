//
//  FakeServer.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 8/6/11.
//

#import "FakeServer.h"
#import "ServerResponse.h"

@implementation NSURLConnection (FakeServer)
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error {
    return NULL;
}
@end

@implementation Session (FakeSession)
- (ServerResponse *) doRequest:(NSMutableURLRequest *)req {
    NSDictionary * rinfo = [NSDictionary dictionaryWithObject:req forKey:@"request"];
    NSError *error = [[NSError alloc] initWithDomain:@"Fluidinfo.tests" code:0 userInfo:rinfo];
    return [[ServerResponse alloc] initwithError:error];
}

@end