
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"
#import "Counter.h"

#define MAX_REPOS 10

@interface Strategy : NSObject {

@private
	Model *model;
	NSMutableArray *top20ReposByFork;
	NSMutableArray *top20ReposByWatch;
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

-(void)preScoreCalculations:(NSSet *)candidates user:(User *)user;
-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds;

// array utils
-(NSArray *)getTopNOrLess:(NSArray *)someArray maximum:(int)maximum;
-(NSArray *)reversedArray:(NSArray *)other;



@end
