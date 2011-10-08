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
@class FluidObject, Tag, FObject, Permission;

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
- (BOOL) isPrimitive:(id)thing; // wrong spot!  move soon.
- (BOOL) delete:(FluidObject *)fl;

- (Permission *) getPermission:(NSString *)act for:(FluidObject *)fl;
- (BOOL) setPermission:(NSString *)act for:(FluidObject *)fl to:(Permission *)p;
- (Permission *) getTagValuePermission:(NSString *)act forTag:(Tag *)t;
- (BOOL) setValuePermission:(NSString *)act to:(Permission *)p forTag:(Tag *)t;

- (BOOL) object:(FObject *)o tagValue:(Tag *)t;
- (BOOL) object:(FObject *)fl hasTag:(Tag *)t;
- (BOOL) object:(FObject *)fl saveTagByString:(NSString *)t;
- (BOOL) object:(FObject *)fl saveTag:(Tag *)t;
- (BOOL) object:(FObject *)fl removeTag:(Tag *)t;
- (BOOL) object:(FObject *)fl removeTagString:(NSString *)t;

// lower-level methods.
- (ServerResponse *) getWithPath:(NSString *)s;
- (NSMutableURLRequest *) subGetWithPath:(NSString *)s;
- (ServerResponse *) getWithPath:(NSString *)s andArgs:(NSArray *)a;
- (ServerResponse *) getWithPath:(NSString *)s andQuery:(NSString *)q;
- (ServerResponse *) getWithQuery:(NSString *)q forTags:(NSArray *)t;
- (NSString *) pathWithQuery:(NSString *)q forTags:(NSArray *)arr;
- (ServerResponse *) headWithPath:(NSString *)s;
- (ServerResponse *) putWithPath:(NSString *)s andContent:(id)c;
- (ServerResponse *) putWithPath:(NSString *)s andJson:(id)j;
- (ServerResponse *) putWithQuery:(NSDictionary *)dic;
- (ServerResponse *) putWithPath:(NSString *)s andMimeType:(NSString *)t andContent:(NSData *)c;
- (ServerResponse *) postWithPath:(NSString *)s;
- (ServerResponse *) postWithPath:(NSString *)s andContent:(NSData *)c;
- (ServerResponse *) postWithPath:(NSString *)s andJson:(id)j;
- (ServerResponse *) deleteWithPath:(NSString *)s;

+ (NSData *) packPrimitive:(id)c;
+ (NSString *) doArgs:(NSArray *)d;
+ (NSString *) doTags:(NSArray *)arr;
@end
