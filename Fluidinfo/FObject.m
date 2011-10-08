//
//  Object.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/24/11.
//

#import "fluidinfo.h"

@implementation FObject
@synthesize about;
@synthesize tagValues;
@synthesize tags;
@synthesize dirtytags;

- (id)init
{
    return [self initWithAbout:NULL];
}

- (id) initWithAbout:(NSString *)a
{
    self = [super init];
    self->tagValues = [NSMutableDictionary dictionary];
    self->tags = [NSMutableDictionary dictionary];
    self->dirtytags = [NSMutableArray array];    
    [self setAbout:a];
    dirty = YES;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    FObject *copy = [[FObject allocWithZone: zone] 
                    initWithAbout:about];
    [copy setErr:err];
    [copy setURI:URI];
    [copy setFluidinfoId:fluidinfoId];
    copy->dirty = dirty;
    [copy setTags:[tags copyWithZone:zone]];
    [copy setDirtytags:[dirtytags copyWithZone:zone]];
    copy->tagValues = [tagValues copyWithZone:zone];
    return copy;                 
}


- (NSArray *) tagPaths
{
    if (tagValues == NULL)
	{
	    [self refresh];
	}
    return [tagValues allKeys];
}

- (Value *) tagValue:(Tag *)t
{
    if (tagValues == NULL)
	[self refresh];
    Value * v = [tagValues valueForKey:[t fullpath]];
    if (v == NULL)
	{
	    [self tagValue:t];
	    v = [tagValues valueForKey:[t fullpath]];        
	}
    return v;   // which could actually be NULL.
                // TODO: handle that case so that we don't have to keep asking just because it's a null-valued tag.
}

// creates new tags as necessary, based on whether or not the referenced Tag is "dirty."
- (BOOL) setTag:(Tag *)t withValue:(Value *)v
{
    NSString *tagPath = [NSString stringWithFormat:@"%@/%@", [t path], [t name]]; // path + name
    [tagValues setValue:v forKey:tagPath];
    [tags setValue:t forKey:tagPath];
    [dirtytags addObject:tagPath];
    return YES;
}

// this method does create a Tag object, but it is assumed to be an existent tag, so it creates a "clean" tag.  Do not use this method to create new tags.
- (BOOL) setTagPath:(NSString *)t withValue:(Value *)v
{
    Tag * tag = [Tag cleanTagWithName:[t lastPathComponent] andPath:[t stringByDeletingLastPathComponent]];
    [tagValues setValue:v forKey:t];
    [tags setValue:tag forKey:t];
    [dirtytags addObject:t];    
    return YES;
}

- (NSString *) pathForTag:(Tag *)t
{
    return [NSString stringWithFormat:@"%@/%@", [self resavePath], [t fullpath]];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Object with about:%@, id:%@, and URI:%@",
		     about,
		     [super fluidinfoId],
		     URI];
}

- (NSString *) savePath
{
    return about == NULL ? @"/objects" : 
	[NSString stringWithFormat:@"/about/%@", [about
						     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *) resavePath
{
    return [NSString stringWithFormat:@"/objects/%@", [super fluidinfoId]];    
}

- (NSDictionary *) saveJSON
{
    return NULL;
}
@end
