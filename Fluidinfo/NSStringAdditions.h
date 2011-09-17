//
//  NSStringAdditions.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/19/11.
//

#import <Foundation/Foundation.h>

@interface NSString (NSStringAdditions)

+ (NSString *) base64StringFromData:(NSData *)data length:(int)length;

@end
