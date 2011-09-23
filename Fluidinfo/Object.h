//
//  Object.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//

@class ServerResponse;

@class Value;
#import "FluidObject.h"

@interface Object : FluidObject
{
// the tags dictionary contains everything about the object, using
// tagPaths as keys.  it must be used with discretion for now.  Later,
// memory-control measures must be added, to comply with Apple's
// memory requirements.  we don't want things crashing.
    NSMutableDictionary * tagValues;
// the tagObjects dictionary also has tagpaths as keys, but tag
// objects as values.  this makes saving / using tags with tag-values
// easy.  this is referenced, not copied, so you can use the same tag
// in multiple objects and have it actually really be the same tag.
@private
    NSMutableDictionary * tags;
    NSString * about;
    NSMutableArray * dirtytags;
}
@property (readwrite, copy) NSString * about;
@property (readonly, retain) NSMutableDictionary * tagValues;
@property (retain, readwrite) NSMutableDictionary * tags;
@property (readwrite, retain) NSMutableArray * dirtytags;
- (id) init;
- (id) initWithAbout:(NSString *)a;
- (id)copyWithZone:(NSZone *)zone;
- (NSArray *) tagPaths;
- (Value *) tagValue:(Tag *)t;
- (BOOL) setTag:(Tag *)t withValue:(Value *)v;
- (BOOL) setTagPath:(NSString *)t withValue:(Value *)v;
- (NSString *) pathForTag:(Tag *)t;
- (NSString *) description;
// the following are not really used:
- (NSString *) savePath; 
- (NSString *) resavePath;
- (NSDictionary *) saveJSON;
@end
