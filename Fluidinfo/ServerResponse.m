//
//  ServerResponse.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/21/11.
//

#import "ServerResponse.h"

@implementation ServerResponse
@synthesize data;
@synthesize response;
@synthesize err;

- (id) init
{
    return [super init];
}

- (id) initwithData:(NSData *)d andResponse:(NSHTTPURLResponse *)r
{
    [self setData: d];
    [self setResponse: r];
    return self;
}

- (id) initwithError:(NSError *)error
{
    [self setErr: error];
    return self;
}

@end