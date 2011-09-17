//
//  Tag.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/23/11.
//

#import "fluidinfo.h"

@implementation Tag

@synthesize name;
@synthesize path;
@synthesize fullpath;
@synthesize tagperms;

+ (id) initWithName:(NSString *)n andPath:(NSString *)p
{
    return [[Tag alloc] initWithName:n andPath:p andDescription:@""];
}

+ (id) cleanTagWithName:(NSString *)n andPath:(NSString *)p;
{
    Tag *foo = [[Tag alloc] initWithName:n andPath:p andDescription:@""];
    foo->dirty = NO;
    return foo;
}

- (id) initWithName:(NSString *)n andPath:(NSString *)p andDescription:(NSString *)d
{
    self = [super init];
    if (self)
    {
        [self setTagperms:[NSMutableDictionary dictionaryWithCapacity:4]];
        name = [n copy];
        path = [p copy];
        description = [d copy];
        fullpath = [NSString stringWithFormat:@"%@/%@", path, name];
        dirty = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Tag *copy = [[Tag allocWithZone: zone] 
                 initWithName:name andPath:path andDescription:description];
    [copy setErr:err];
    [copy setURI:URI];
    [copy setFluidinfoId:fluidinfoId];
    copy->fullpath = [fullpath copy];
    copy->dirty = dirty;
    return copy;                 
}

- (void) setDescription:(NSString *)d
{
    description = [d copy];
    dirty = YES;
}
- (NSString *) fluidinfoDescription
{
    return description;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Tag \"%@\" at \"%@\" (\"%@\") \
            \nwith fluidinfo id:%@ and URI:%@", name, path, description, [super fluidinfoId], [super URI]];
}

- (NSString *) savePath
{
  return [NSString stringWithFormat:@"tags/%@", path];
}

- (NSString *) resavePath
{
    return [NSString stringWithFormat:@"tags/%@/%@", path, name];
}

- (NSDictionary *) saveJSON
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
                                           name, @"name",
                                         description, @"description",
                                             [NSNumber numberWithBool:YES], @"indexed", 
                                         nil];
}

- (NSDictionary *) resaveJSON
{
  return [NSDictionary dictionaryWithObject:description forKey:@"description"];
}

@end
