
#import <Foundation/Foundation.h>
#import <stdlib.h>
#import <time.h>

#import "Model.h"

#define MAX_REPOS 10

@interface Strategy : NSObject {

@private
	Model *model;
}

@property(readonly, nonatomic) Model *model;

-(id)initWithModel:(Model *)aModel;

-(void)calculatePredictions;
-(void)randomStraetgy:(User *)user allRepoKeys:(NSArray *)allRepoKeys;


@end
