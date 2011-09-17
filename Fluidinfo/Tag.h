//
//  FluidObject.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//

#import "FluidObject.h"
@class Permission;

@interface Tag : FluidObject {
@private
    NSString * name;
    NSString * path;
    NSString * fullpath;
    NSMutableDictionary * tagperms;
@private
    NSString * description;
}

@property (readonly, retain) NSString * name;
@property (readonly, retain) NSString * path;
@property (readonly, retain) NSString * fullpath;
@property (readwrite, copy) NSMutableDictionary * tagperms; // TODO: rename this to valueperms.

+ (id) initWithName:(NSString *)n andPath:(NSString *)p;
+ (id) cleanTagWithName:(NSString *)n andPath:(NSString *)p;
- (id) initWithName:(NSString *)n andPath:(NSString *)p andDescription:(NSString *)d;
- (void) setDescription:(NSString *)d;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *) fluidinfoDescription;
- (NSString *) description;
- (NSString *) savePath;
- (NSString *) resavePath;
- (NSDictionary *) saveJSON;
- (NSDictionary *) resaveJSON;
@end
