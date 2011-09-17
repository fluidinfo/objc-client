//
//  FakeServer.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 8/6/11.  

//  This just intercepts requests and returns null.  This will happen
//  with things like [session save].  To check whether the request is
//  correct, have a look at the request itself, which should be in the
//  error.
//

#import "Session.h"

@interface NSURLConnection (FakeServer)
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;
@end
