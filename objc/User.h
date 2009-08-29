
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
	NSCountedSet *neighbourhoodWatchName;
	NSCountedSet *neighbourhoodWatchOwner;
	NSMutableSet *watchedParents;
	
	// stats
	int numNeighbours;
	int numForked;
	int numRoot;
	int numWatched;
	int numNeighbourhoodWatched;
	int numWithLanguage;
	
	NSCountedSet *ownerSet;
	NSCountedSet *nameSet;
	NSCountedSet *languageSet;
	
	NSString *deducedName;

}

// data
@property(readonly, nonatomic) NSNumber *userId;
@property(readonly, nonatomic) NSMutableSet *repos;
@property(readonly, nonatomic) NSMutableSet *predictions;
@property(readonly, nonatomic) NSMutableSet *watchedParents;
@property(nonatomic) BOOL test;

// derived
@property(readonly, nonatomic) NSMutableSet *neighbours;
@property(readonly, nonatomic) NSCountedSet *neighbourhoodRepos;
@property(readonly, nonatomic) NSCountedSet *ownerSet;
@property(readonly, nonatomic) NSCountedSet *nameSet;
@property(readonly, nonatomic) NSCountedSet *languageSet;
@property(readonly, nonatomic) NSCountedSet *neighbourhoodWatchName;
@property(readonly, nonatomic) NSCountedSet *neighbourhoodWatchOwner;
@property(readonly, nonatomic) NSString *deducedName;

// stats
@property(nonatomic) int numNeighbours;
@property(nonatomic) int numWatched;
@property(nonatomic) int numForked;
@property(nonatomic) int numRoot;
@property(nonatomic) int numNeighbourhoodWatched;
@property(nonatomic) int numWithLanguage;


-(id)initWithId:(NSNumber *)aId;
-(void) addRepository:(NSNumber *)aRepoId;
-(void) addPrediction:(NSNumber *)aRepoId;
-(NSString *) getPredictionAsString;
-(void) addNeighbour:(User *)aUserId;

-(int)neighbourhoodOccurance:(NSNumber *)repoId;


-(double)calculateUserDistance:(User*)other;
-(void) calculateStats:(NSDictionary *)repositoryMap;

NSInteger neighbourhoodWatchSort(id o1, id o2, void *context);
NSInteger neighbourhoodNameSort(id o1, id o2, void *context);
NSInteger neighbourhoodOwnerSort(id o1, id o2, void *context);

-(void) deduceName:(NSDictionary *)repositoryMap;

@end
