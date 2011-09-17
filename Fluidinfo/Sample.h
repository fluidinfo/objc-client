//
//  Sample.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 9/11/11.
//

#import "Object.h"
@class Tag;

@interface Sample : Object {
    Tag * rating;
    Tag * comment;
    Tag * dateRead;
}
@property (readwrite, copy) Tag * rating;
@property (readwrite, copy) Tag * comment;
@property (readwrite, copy) Tag * dateRead;
- (id) initWithAbout:(NSString *)a Rating:(NSInteger)r Comment:(NSString *)c andDate:(NSString *)d;
@end
