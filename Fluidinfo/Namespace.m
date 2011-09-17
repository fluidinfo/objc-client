//
//  Namespace.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/23/11.
//

#import "fluidinfo.h"

@implementation Namespace
@synthesize name;
@synthesize path;
@synthesize tagNames;
@synthesize namespaceNames;
@synthesize fullpath;

+ (id) initWithName:(NSString *)n andPath:(NSString *)p
{
    return [[Namespace alloc] initWithName:n andPath:p andDescription:@""];
}

- (id) initWithName:(NSString *)n andPath:(NSString *)p andDescription:(NSString *)d
{
    self = [super init];
    if (self)
    {
        name = [n copy];
        path = [p copy];
        description = [d copy];
        dirty = YES;
        fullpath = [NSString stringWithFormat:@"%@/%@", path, name];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Namespace *copy = [[Namespace allocWithZone: zone] 
                 initWithName:name andPath:path andDescription:description];
    [copy setErr:err];
    [copy setURI:URI];
    [copy setFluidinfoId:fluidinfoId];
    copy->dirty = dirty;
    return copy;                 
}

- (NSString *) fluidinfoDescription
{
  return description;
}

- (void) setDescription:(NSString *)d
{
    description = [d copy];
    dirty = YES;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Namespace \"%@\" at \"%@\" (\"%@\") \
            \nwith fluidinfo id:%@ and URI:%@", name, path, description, [super fluidinfoId], [super URI]];
}

- (NSString *) savePath
{
  return [NSString stringWithFormat:@"namespaces/%@", path];
}

- (NSString *) resavePath
{
    return [NSString stringWithFormat:@"namespaces/%@/%@", path, name];    
}

- (NSDictionary *) saveJSON
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         name, @"name",
                       description, @"description",
                       nil];
}

- (NSDictionary *) resaveJSON
{
    return [NSDictionary dictionaryWithObject:description forKey:@"description"];
}

@end
