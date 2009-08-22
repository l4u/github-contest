
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"
#import "Counter.h"

#define MAX_REPOS 10

@interface Strategy : NSObject {

@private
	Model *model;
	NSMutableArray *reposByOccurance;
}

@property(readonly, nonatomic) Model *model;

-(id)initWithModel:(Model *)aModel;

// prediction entry
-(void)calculatePredictions;
// high-level strategies
-(void)randomStrategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys;
-(void)top10Strategy:(User *)user;
-(void)top10NeighbourhoodStrategy:(User *)user;

// array utils
-(NSArray *)getTopNOrLess:(NSArray *)someArray maximum:(int)maximum;
-(NSArray *)reversedArray:(NSArray *)other;
// general
-(NSArray *)orderUserReposByWatchOccurance:(NSArray *)userIds;
-(NSArray *)calculateNeighbours:(User *)user;
-(void)assignRepos:(User *)user repoIds:(NSArray*)repoIds;

@end
