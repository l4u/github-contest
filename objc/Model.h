
#import <Foundation/Foundation.h>

#import "Repository.h"
#import "User.h"



#define KNN_STORE 	10
#define KNN_READ 	5


@interface Model : NSObject {
@private
    NSMutableDictionary *repositoryMap;
	NSMutableDictionary *userMap;
	NSMutableArray *testUsers;
	NSMutableDictionary *ownerSet;
	NSMutableDictionary *nameSet;
	
	int totalWatches;
	int totalForked;
	int totalWatchedForked;
	int totalRoot;
	int totalWatchedRoot;
	int totalWatchedRepos;
}

@property(readonly, nonatomic) NSMutableDictionary *repositoryMap;
@property(readonly, nonatomic) NSMutableDictionary *userMap;
@property(readonly, nonatomic) NSMutableArray *testUsers;
@property(readonly, nonatomic) NSMutableDictionary *ownerSet;
@property(readonly, nonatomic) NSMutableDictionary *nameSet;

@property(readonly, nonatomic) int totalWatchedRepos;
@property(readonly, nonatomic) int totalWatches;
@property(readonly, nonatomic) int totalForked;
@property(readonly, nonatomic) int totalWatchedForked;
@property(readonly, nonatomic) int totalRoot;
@property(readonly, nonatomic) int totalWatchedRoot;

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