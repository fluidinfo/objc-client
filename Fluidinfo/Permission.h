//
//  Permission.h
//  FLUIDINFO
//
//  Created by Barbara Shirtcliff on 7/31/11.
//


enum policy {
    OPEN = 1,
    CLOSED = 0
    };

@interface Permission : NSObject
{
    NSMutableArray * exceptions;
    @public 
        enum policy _policy;
}
@property (readwrite, copy) NSMutableArray * exceptions;
- (id) initWithPolicy:(enum policy)_policy andExceptions:(NSArray *)_exceptions;
- (NSMutableArray *) getExceptions;
@end
