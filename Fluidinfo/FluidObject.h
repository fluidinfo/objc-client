//
//  FluidObject.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//  this is a convenience class, really.
//

@class ServerResponse, Permission;
@class Tag, Namespace, Object, TagValue, Permission;

@interface FluidObject : NSObject
{
    NSString * fluidinfoId;
    NSString * URI;
    BOOL dirty;
    NSError * err;
    NSMutableDictionary * perms;
}
@property (copy, readwrite) NSString * URI;
@property (copy, readwrite) NSString * fluidinfoId;
@property (copy, readwrite) NSError *err;
@property (copy, readwrite) NSMutableDictionary * perms;

+ (Namespace *) Namespace:(NSString *)n withPath:(NSString *)p;
+ (Namespace *) Namespace:(NSString *)n withPath:(NSString *)p andDescription:(NSString *)d;
+ (Tag *) Tag:(NSString *)n withPath:(NSString *)p;
+ (Tag *) Tag:(NSString *)n withPath:(NSString *)p andTagDescription:(NSString *)d;
+ (Object *) Object;
+ (Object *) Object:(NSString *)about;
- (BOOL) isdirty;
- (void) markDirty;
- (void) markClean;
// subclasses must either implement the following or override lots of stuff.
- (NSString *) description;
- (BOOL) refresh;
- (NSString *) savePath;
- (NSString *) resavePath;
- (NSDictionary *) saveJSON;
- (NSDictionary *) resaveJSON;
@end


