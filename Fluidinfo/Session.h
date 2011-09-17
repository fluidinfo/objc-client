//
//  Session.h
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/20/11.
//  Class for Fluidinfo session-dependent operations.
//

#import <Foundation/Foundation.h>
#import "NSStringAdditions.m"
@class ServerResponse;
@class FluidObject, Tag, Object, Permission;

@interface Session : NSObject
{
  NSString * instance;
  NSString * scheme;
@private
  NSDictionary * headers;
}
@property (readwrite, copy) NSString * instance;
@property (readwrite, copy) NSString * scheme;

- (id) init;
+ (id) initWithUsername:(NSString *)u andPassword:(NSString *)p;
- (ServerResponse *) doRequest:(NSMutableURLRequest *)req;
- (void)loginWithUsername:(NSString *)u andPassword:(NSString *)p;
- (void) initHeaders;

// FluidObject convenience methods.
- (id) get:(FluidObject *)fl;
- (id) get:(FluidObject *)fl withArgs:(NSArray *)args;
- (BOOL) refresh:(FluidObject *)fl;
- (BOOL) reset:(FluidObject *)fl;
- (BOOL) save:(FluidObject *)fl;
- (BOOL) resave:(FluidObject *)fl;
- (BOOL) delete:(FluidObject *)fl;

- (Permission *) getPermission:(NSString *)act for:(FluidObject *)fl;
- (BOOL) setPermission:(NSString *)act for:(FluidObject *)fl to:(Permission *)p;
- (Permission *) getTagValuePermission:(NSString *)act forTag:(Tag *)t;
- (BOOL) setValuePermission:(NSString *)act to:(Permission *)p forTag:(Tag *)t;

- (BOOL) object:(Object *)o tagValue:(Tag *)t;
- (BOOL) object:(Object *)fl hasTag:(Tag *)t;
- (BOOL) object:(Object *)fl saveTagByString:(NSString *)t;
- (BOOL) object:(Object *)fl saveTag:(Tag *)t;
- (BOOL) object:(Object *)fl removeTag:(Tag *)t;
- (BOOL) object:(Object *)fl removeTagString:(NSString *)t;

// lower-level methods.
- (id) getWithPath:(NSString *)s;
- (id) getWithPath:(NSString *)s andArgs:(NSArray *)a;
- (id) getWithPath:(NSString *)s andQuery:(NSString *)q;
- (id) getWithQuery:(NSString *)q forTags:(NSArray *)t;
- (id) pathWithQuery:(NSString *)q forTags:(NSArray *)arr;
- (id) headWithPath:(NSString *)s;
- (id) putWithPath:(NSString *)s andContent:(id)c;
- (id) putWithPath:(NSString *)s andJson:(id)j;
- (id) putWithPath:(NSString *)s andQuery:(NSDictionary *)dic;
- (id) putWithPath:(NSString *)s andMimeType:(NSString *)t andContent:(NSData *)c;
- (id) postWithPath:(NSString *)s;
- (id) postWithPath:(NSString *)s andContent:(NSData *)c;
- (id) postWithPath:(NSString *)s andJson:(id)j;
- (id) deleteWithPath:(NSString *)s;

+ (NSString *) packPrimitive:(id)c;
+ (NSString *) doArgs:(NSArray *)d;
+ (NSString *) doTags:(NSArray *)arr;
@end
