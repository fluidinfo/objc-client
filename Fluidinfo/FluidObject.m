//
//  FluidObject.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//

#import "fluidinfo.h"

@implementation FluidObject
@synthesize fluidinfoId;
@synthesize URI;
@synthesize err;
@synthesize perms;

+ (Namespace *) Namespace:(NSString *)n withPath:(NSString *)p
{
    return [Namespace initWithName:n andPath:p];
}

+ (Namespace *) Namespace:(NSString *)n withPath:(NSString *)p andDescription:(NSString *)d
{
    return [[Namespace alloc] initWithName:n andPath:p andDescription:d];
}

+ (Tag *) Tag:(NSString *)n withPath:(NSString *)p
{
  return [Tag initWithName:n andPath:p];
}

+ (Tag *) Tag:(NSString *)n withPath:(NSString *)p andTagDescription:(NSString *)d
{
  return [[Tag alloc] initWithName:n andPath:p andDescription:d];
}

+ (FObject *) Object
{
    return [[FObject alloc] init];
}

+ (FObject *) Object:(NSString *)about
{
    return [[FObject alloc] initWithAbout:about];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (BOOL) isdirty
{
    return dirty;
}

- (void) markDirty
{
    dirty = YES;
}

- (void) markClean
{
    dirty = NO;
}

// the following are designed to be overridden.
- (NSString *) description
{
    return NULL;
}

- (BOOL) refresh
{
    return NO;
}

- (NSString *) savePath
{
    return NULL;
}

- (NSString *) resavePath
{
    return NULL;
}

- (NSDictionary *) saveJSON
{
    return NULL;
}

- (NSDictionary *) resaveJSON
{
    return NULL;
}

@end
