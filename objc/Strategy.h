
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import <JavaVM/JavaVM.h>

#import "Model.h"
#import "Classification.h"


#define TOP_RANKED_REPOS 20
#define MAX_REPOS 	10
#define NUM_TRAINING_USERS 500
#define USE_EXT_CLASSIFIER true
#define TASTE_TEST true

@interface Strategy : NSObject {

@private
	// cfg
	BOOL generateTrainingData;

	// internal
	Model *model;
	NSMutableArray *topReposByFork;
	NSMutableArray *topReposByWatch;
	NSMutableDictionary *testGlobalWeights;
	NSMutableSet *testSet;
	
	Classification * classifier;
}


@property(nonatomic) BOOL generateTrainingData;

-(id)initWithModel:(Model *)aModel;

// prediction entry
-(void)employStrategy;
-(void) initialize;
-(void)calculatePredictions;

// main prediction pipeline
-(void)generateCandidates:(User *)user candidateSet:(NSMutableSet *)candidateSet;
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user;
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user;

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo;
-(NSDictionary *)indicatorWeights:(User *)user repo:(Repository *)repo;
-(NSDictionary *)getTestWeights;

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds;
-(void)buildClassificationLine:(NSMutableString *)buffer indicators:(NSDictionary *)indicators;

-(NSString *) generateTestCasesForUser:(User*)user candidates:(NSMutableSet*)candidates;

-(void)newReposFromLanguageTest;

@end
