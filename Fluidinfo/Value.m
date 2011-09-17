//
//  Value.m
//  fluidinfo
//
//  Created by Barbara Shirtcliff on 7/25/11.
//  Copyright 2011 UNM. All rights reserved.
//

#import "Value.h"

@implementation Value
@synthesize type;
@synthesize value;
@synthesize filepath;


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id) initWithValue:(id)v
{
    self = [super init];
    [self setValue:v];
    return self;
}

- (id) initWithValue:(id)v andType:(NSString *)t
{
    self = [super init];
    [self setValue:v];
    [self setType:t];
    return self;    
}

- (id) initWithFile:(NSURL *)f;
{
    self = [super init];
    [self setFilepath:f];
    return self;
}

- (id) initWithFile:(NSURL *)f andType:(NSString *)t;
{
    self = [super init];
    [self setFilepath:f];
    [self setType:t];
    return self;
}

@end
