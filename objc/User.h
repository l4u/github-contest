
#import <Foundation/Foundation.h>

#import "Repository.h"

@interface User : NSObject {
@private
    int userId;
	NSMutableSet *repos;
	BOOL test;
	NSMutableSet *predictions;
	NSMutableSet *neighbours;
	NSCountedSet *neighbourhoodRepos;
}

@property(readonly, nonatomic) int userId;
@property(readonly, nonatomic) NSMutableSet *repos;
@property(nonatomic) BOOL test;
@property(readonly, nonatomic) NSMutableSet *predictions;
@property(readonly, nonatomic) NSMutableSet *neighbours;
@property(readonly, nonatomic) NSCountedSet *neighbourhoodRepos;

-(id)initWithId:(int)aId;
-(void) addRepository:(NSNumber *)aRepoId;
-(void) addPrediction:(NSNumber *)aRepoId;
-(NSString *) getPredictionAsString;
-(void) addNeighbour:(User *)aUserId;
-(int)neighbourhoodOccurance:(NSNumber *)repoId;

-(double)probabilityUserWillWatchRepo:(Repository *)repo;
-(double)calculateUserDistance:(User*)other;

@end
