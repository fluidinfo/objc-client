//
//  FluidinfoTests.h
//  FluidinfoTests
//
//  Created by Barbara Shirtcliff on 7/12/11.
//
#define TESTING YES
#import <SenTestingKit/SenTestingKit.h>

@class FakeSession, Tag;

@interface fluidinfoTests : SenTestCase
{
  Session * session;
}
@property (readwrite, retain)  Session * session;
- (void) setUp;
- (void) tearDown;
- (void) testPutPrimitive;
- (void) testNamespaceCreation;
- (void) testNamespaceDelete;
- (void) testNamespaceUpdate;
- (void) testTagCreation;
- (void) testTagDelete;
- (void) testTagUpdate;
- (void) testObjectSaveWithTagValues;
// test permissions
// test objects
// test response handling: 
//    for object queries (refresh, get, head, save)
//    for the same, but with errors
//    for queries that return a list of Fluidinfo objects and possibly tag values
- (void) dataCheck:(NSMutableURLRequest *)request forValue:(id)val;
@end

