
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"


#define MAX_REPOS 10

@interface Strategy : NSObject {

@private
	Model *model;
	NSMutableArray *top20ReposByFork;
	NSMutableArray *top20ReposByWatch;
	NSMutableDictionary *testGlobalWeights;
}

@property(readonly, nonatomic) Model *model;

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



@end
