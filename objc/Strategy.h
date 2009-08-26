
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"


#define TOP_RANKED_REPOS 20
#define MAX_REPOS 	10
#define NUM_TRAINING_USERS 50


@interface Strategy : NSObject {

@private
	// cfg
	BOOL generateTrainingData;

	// internal
	Model *model;
	NSMutableArray *top20ReposByFork;
	NSMutableArray *top20ReposByWatch;
	NSMutableDictionary *testGlobalWeights;
	NSFileHandle *file;
	NSMutableSet *testSet;
}


@property(nonatomic) BOOL generateTrainingData;

-(id)initWithModel:(Model *)aModel;

// prediction entry
-(void)employStrategy;
-(void) initialize;
-(void)calculatePredictions;

// main prediction pipeline
-(NSMutableSet *)generateCandidates:(User *)user;
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user;
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user;

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo;
-(NSDictionary *)indicatorWeights:(User *)user repo:(Repository *)repo;
-(NSDictionary *)getTestWeights;

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds;

-(void) generateTestCasesForUser:(User*)user candidates:(NSMutableSet*)candidates;


@end
