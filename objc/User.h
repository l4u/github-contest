
#import <Foundation/Foundation.h>

#import "Repository.h"


@interface User : NSObject {
@private
    NSNumber *userId;
	NSMutableSet *repos;
	BOOL test;
	NSMutableSet *predictions;
	NSMutableSet *neighbours;
	NSCountedSet *neighbourhoodRepos;
}

@property(readonly, nonatomic) NSNumber * userId;
@property(readonly, nonatomic) NSMutableSet *repos;
@property(nonatomic) BOOL test;
@property(readonly, nonatomic) NSMutableSet *predictions;
@property(readonly, nonatomic) NSMutableSet *neighbours;
@property(readonly, nonatomic) NSCountedSet *neighbourhoodRepos;

-(id)initWithId:(NSNumber *)aId;
-(void) addRepository:(NSNumber *)aRepoId;
-(void) addPrediction:(NSNumber *)aRepoId;
-(NSString *) getPredictionAsString;
-(void) addNeighbour:(User *)aUserId;

-(int)neighbourhoodOccurance:(NSNumber *)repoId;
-(int)neighbourhoodTotalWatches;
-(int)neighbourhoodTotalWatchesForName:(NSString *)name repositoryMap:(NSMutableDictionary *)repositoryMap;
-(int)neighbourhoodTotalWatchesForOwner:(NSString *)owner repositoryMap:(NSMutableDictionary *)repositoryMap;

-(double)calculateUserDistance:(User*)other;


@end
