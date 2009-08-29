
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import <JavaVM/JavaVM.h>

#import "Model.h"
#import "Classification.h"
#import "cfg.h"



@interface Strategy : NSObject {

@private
	// internal
	Model *model;
	NSMutableArray *topReposByFork;
	NSMutableArray *topReposByWatch;
	NSMutableDictionary *testGlobalWeights;
	NSMutableSet *testSet;
	
	Classification * classifier;
}

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


-(double)cooccurrencesScoreToWatchRepo:(User *)user repo:(Repository *)repo;
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
