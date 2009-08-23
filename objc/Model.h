
#import <Foundation/Foundation.h>

#import "Repository.h"
#import "User.h"



@interface Model : NSObject {
@private
    NSMutableDictionary *repositoryMap;
	NSMutableDictionary *userMap;
	NSMutableArray *testUsers;
}

@property(readonly) NSMutableDictionary *repositoryMap;
@property(readonly) NSMutableDictionary *userMap;
@property(readonly) NSMutableArray *testUsers;

-(void) printStats;

// loading
-(void) loadModel;
-(void) loadRepos;
-(void) loadRepoLanguages;
-(void) loadRepoUserRelationships;
-(void) loadTestUsers;
-(void) loadNeighbours;

// indicators
-(void) calculateForkCounts;
-(void) prepareUserNeighbours;
-(NSArray *) calculateNeighbours:(User *)user;
- (NSArray *)reversedArray:(NSArray *)other;

// output
-(void) validatePredictions;
-(void) outputPredictions;



@end