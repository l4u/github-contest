
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
// prediction types
-(void)randomStrategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys;
-(void)top10Strategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys;


-(NSArray *)orderUserReposByWatchOccurance:(NSArray *)userList;
-(NSArray *)getTop10Repos;

@end
