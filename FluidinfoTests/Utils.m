//
//  Utils.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 9/14/11.
//

#import "Utils.h"
#import "Tag.h"
#import "Value.h"

@implementation Utils
+ (id) randomValuewithType:(NSString *)ty
// create random values to return for all tag types.
// tests should check for the right type of value, unless tests have explicitely set a specific value.
{
    if (ty == @"int") 
        return [NSNumber numberWithInteger:arc4random() % 74];  
    else if (ty == @"string")
        return [self rstring];
    else if (ty == @"float")
        return [NSNumber numberWithFloat:(arc4random() % 74) / 59.2];
    else if (ty == @"set")
      return [NSArray arrayWithObjects:@"foo",@"bor", nil]; // temporary
    else if (ty == @"null")
        return NULL;
    else if (ty == @"bool") {
      BOOL a = (arc4random() % 2) == 0 ? YES : NO;
      return [NSNumber numberWithBool:a];
	}
    return NULL;
}

+ (NSString *) rstring
{
    NSArray * charsets = [NSArray arrayWithObjects:[[NSCharacterSet letterCharacterSet] bitmapRepresentation],
                          [[NSCharacterSet letterCharacterSet] bitmapRepresentation],
                          [[NSCharacterSet punctuationCharacterSet] bitmapRepresentation],
                          [[NSCharacterSet symbolCharacterSet] bitmapRepresentation],
                          [[NSCharacterSet whitespaceAndNewlineCharacterSet] bitmapRepresentation],
                          [[NSCharacterSet decimalDigitCharacterSet] bitmapRepresentation],
                          nil];
    
    NSInteger length = arc4random() % 74;
    NSMutableString *str = [[NSMutableString alloc] init];
    do {
        NSData *chrs = [charsets objectAtIndex:arc4random() % ([charsets count] - 1)];
        unichar tstr[1];
        NSInteger t = arc4random() % [chrs length];
        [chrs getBytes:tstr range:NSMakeRange(t, 1)];
        [str appendString:[NSString stringWithCharacters:tstr length:1]];
        length -= 1;
    } while (length > 0);
    return str;
}
    
+ (BOOL) headersOkay:(NSDictionary *)headers withAllowed:(NSArray *)allowed required:(NSArray *)required
{
    for (NSString * header in required)
        if (![headers valueForKey:header])
            return NO;
    // the following is one line, except for compiler optimizations that prevent easy equality tests (such as used in containsObject, alas).
    BOOL okay = YES;
    for (NSString * header in headers) 
        if (okay) {
            for (NSString * hh in allowed)
                if ([hh isEqualToString:header]) {
                    okay = YES;
                    break;
            }
            for (NSString * hh in required)
                if ([hh isEqualToString:header]) {
                    okay = YES;
                    break;
                }
        } else 
            return NO;
    return okay;
}

@end
