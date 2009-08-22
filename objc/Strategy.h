
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"
#import "Counter.h"

#define MAX_REPOS 10

@interface Strategy : NSObject {

@private
	Model *model;
	NSMutableArray *top10;
}

@property(readonly, nonatomic) Model *model;

-(id)initWithModel:(Model *)aModel;

// prediction entry
-(void)calculatePredictions;
// high-level strategies
-(void)randomStrategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys;
-(void)top10Strategy:(User *)user;
-(void)top10NeighbourhoodStrategy:(User *)user;

// general utils
-(NSArray *)orderUserReposByWatchOccurance:(NSArray *)userIds;
-(NSArray *)getTop10Repos;
-(NSArray *)getTop10OrLess:(NSArray *)someArray;
-(NSArray *)calculateNeighbours:(User *)user;
-(NSArray *)reversedArray:(NSArray *)other;

@end
