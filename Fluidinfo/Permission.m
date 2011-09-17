//
//  Permission.m
//  FLUIDINFO
//
//  Created by Barbara Shirtcliff on 7/31/11.
//

#import "Permission.h"

@implementation Permission
@synthesize exceptions;

// TODO: make it also accept an immutable array.
- (id) initWithPolicy:(enum policy)policy andExceptions:(NSMutableArray *)_exceptions
{
    self = [super init];
    self->_policy = policy;
    [self setExceptions:_exceptions];
    return self;
}

- (NSMutableArray *) getExceptions
{
  return exceptions;
}

@end
