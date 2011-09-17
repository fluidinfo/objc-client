//
//  ServerResponse.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/21/11.
//  Reponse object for encapsulating the two essential parts of a response in one object, for easier handling.
//

#import <Foundation/Foundation.h>


@interface ServerResponse : NSObject
{
    NSData * data;
    NSHTTPURLResponse * response;
    NSError * err;
}
@property (retain, readwrite) NSData * data;
@property (retain, readwrite) NSHTTPURLResponse * response;
@property (retain, readwrite) NSError * err;
- (id) initwithData:(NSData *)d andResponse:(NSHTTPURLResponse *)r;
- (id) initwithError:(NSError *)error;
@end