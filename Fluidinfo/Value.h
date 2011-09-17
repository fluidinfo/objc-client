//
//  Value.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/25/11.
//


@interface Value : NSObject
{
    id value;
    NSString * type;
    NSURL * filepath;
}
@property (retain) id value;
@property (copy) NSString * type;
@property (copy) NSURL * filepath;
- (id) initWithValue:(id)v;
- (id) initWithValue:(id)v andType:(NSString *)t;
- (id) initWithFile:(NSURL *)f;
- (id) initWithFile:(NSURL *)f andType:(NSString *)t;
@end
