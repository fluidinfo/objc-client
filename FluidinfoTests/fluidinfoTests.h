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
/*
- (void) testDeleteTagViaAbout;
- (void) testURLArgsWithGetRequest;
- (void) testGetQuery;
- (void) testGetQueryWithArgs;
- (void) testPutWithQuery;
- (void) testSampleObjects;
- (void) testPutWithMime;
- (void) testTagDeletion;
- (void) testNamespaceCreationAndDeletion;
- (void) testObjectCreation;
- (void) testObjectCreationWithAbout;
- (void) testObjectAddTag;
- (void) testObjectRemoveTag;
- (void) testObjectMultipleTags;
- (void) testPrimitiveTagValues;
- (void) testTagsWithJsonValues;//TODO
- (void) testTagsSetByTagPaths;
- (void) testGetVariousPerms;
- (void) testGetValuesWithTags;
 */
- (void) dataCheck:(NSMutableURLRequest *)request forValue:(id)val;
@end

