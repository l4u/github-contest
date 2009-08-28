
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import <JavaVM/JavaVM.h>

#import "Model.h"
#import "Classification.h"


#define TOP_RANKED_REPOS 100
#define MAX_REPOS 	10
#define NUM_TRAINING_USERS 100
#define USE_EXT_CLASSIFIER false
#define TASTE_TEST false
#define USE_RANK_INDICATORS false

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
-(void) holisticPredictions;

// main prediction pipeline
-(void)generateCandidates:(User *)user candidateSet:(NSMutableSet *)candidateSet;
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user;
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user;

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo;
-(NSDictionary *)indicatorWeights:(User *)user repo:(Repository *)repo;
-(NSDictionary *)indicatorWeights2:(User *)user repo:(Repository *)repo;
-(NSDictionary *)getTestWeights;
-(NSDictionary *)getTestWeights2;

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds;

-(void)buildClassificationLine:(NSMutableString *)buffer indicators:(NSDictionary *)indicators;
-(void)buildClassificationLine2:(NSMutableString *)buffer indicators:(NSDictionary *)indicators;

-(NSString *) generateTestCasesForUser:(User*)user candidates:(NSMutableSet*)candidates;

-(void)newReposFromLanguageTest;

// -(NSComparisonResult)nameSort:(id)o1 o2:(id)o2 context:(void*)context;
// -(NSComparisonResult)ownerSort:(id)o1 o2:(id)o2 context:(void*)context;

NSInteger nameSort(id o1, id o2, void *context);
NSInteger ownerSort(id o1, id o2, void *context);



@end
