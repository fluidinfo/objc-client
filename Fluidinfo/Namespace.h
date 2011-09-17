//
//  FluidObject.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//

@class FluidObject;

@interface Namespace : FluidObject {
    NSArray * namespaceNames;
    NSArray * tagNames;
    NSString * name;
    NSString * path;
    NSString * fullpath;
@private
    NSString * description;
}
@property (readwrite, copy) NSString * name;
@property (readwrite, copy) NSString * path;
@property (readwrite, copy) NSArray * namespaceNames;
@property (readwrite, copy) NSArray * tagNames;
@property (readwrite, copy) NSString * fullpath;
+ (id) initWithName:(NSString *)n andPath:(NSString *)p;
- (id) initWithName:(NSString *)n andPath:(NSString *)p andDescription:(NSString *)d;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *) fluidinfoDescription;
- (void) setDescription:(NSString *)d; // the description used for namespaces and tags in fluidinfo.
- (NSString *) description; // the tostring of obj-c.
- (NSString *) savePath;
- (NSString *) resavePath;
- (NSDictionary *) saveJSON;
- (NSDictionary *) resaveJSON;
@end
