//
//  Utils.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 9/14/11.
//

#include <stdlib.h>
@class Tag;

@interface Utils : NSObject
+ (id) randomValuewithType:(NSString *)ty;
+ (NSString *) rstring;
+ (BOOL) headersOkay:(NSDictionary *)headers withAllowed:(NSArray *)allowed required:(NSArray *)required;
@end
