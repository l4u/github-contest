#import "Strategy.h"


// random numbers: http://stackoverflow.com/questions/160890/generating-random-numbers-in-objective-c

@implementation Strategy

@dynamic model;

-(id)initWithModel:(Model *)aModel {
	self = [super init];	
	
	if(self) {		
		model = aModel;
		[aModel retain];
		// random numbers
		srandom(time(NULL));
		
		top20ReposByWatch = nil;		
		top20ReposByFork = nil;
	}
	
	return self;
}

-(void) dealloc {
	[model release];
	[top20ReposByWatch release];
	[top20ReposByFork release];
	
	[super dealloc]; // always last
}

-(Model *)model {
	return model;
}

-(void)employStrategy {
	[self initialize];
	[self calculatePredictions];
}

-(void) initialize {
	int max = 20;
	
	// top n by watch count
	NSArray *tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareWatchCount:)];
	top20ReposByWatch = [NSMutableArray arrayWithCapacity:max];
	int i;
	for(i=0; i<max; i++) {
		NSNumber *repoId = [tmp objectAtIndex:i];
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// set rank (decending)
		repo.normalizedWatchRank = (double) (max-i) / (double)max;
		// store
		[top20ReposByWatch addObject:repoId];
	}	
	// top n by fork count
	tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareForkCount:)];
	top20ReposByFork = [NSMutableArray arrayWithCapacity:max];
	for(i=0; i<max; i++) {
		NSNumber *repoId = [tmp objectAtIndex:i];
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// set rank (decending)
		repo.normalizedForkRank = (double) (max-i) / (double)max;
		// store
		[top20ReposByFork addObject:repoId];
	}	
}

-(void)calculatePredictions {
	NSLog(@"calculating predictions...");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	
	for(User *user in model.testUsers) {				
		if([user.repos count]<=0) {
			[self assignRepos:user repoIds:top20ReposByWatch];
		} else {
			// generate 
			NSMutableSet *candidateSet = [self generateCandidates:user];		
			// fiter
			[self filterCandidates:candidateSet user:user];
			// score
			NSArray *candidateList = [self scoreCandidates:candidateSet user:user];
			// assign
			[self assignRepos:user repoIds:candidateList];
		}		
		 		
		// clear mem sometimes
		if((i % 10)==0) {
			NSLog(@"[%i/%i]: Finished prediction for user %i with %i repos", (++i), [model.testUsers count], user.userId, [user.predictions count]);
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];			
		}		
	}
	
	// validate
	[model validatePredictions];
	// output
	[model outputPredictions];
	
	[pool drain];
}



// generate a set of candidates a user may want to watch
// somewhat inspired by: http://github.com/jeremybarnes/github_contest/tree/master
-(NSMutableSet *)generateCandidates:(User *)user {
	NSMutableSet *candidateSet = [[[NSMutableSet alloc] init] autorelease];
	// top 20 by watch count
	for(NSNumber *repoId in top20ReposByWatch) {
		[candidateSet addObject:repoId];
	}
	// top 20 by fork count
	for(NSNumber *repoId in top20ReposByFork) {
		[candidateSet addObject:repoId];
	}
	// tree of parent repos

	// tree of children repos

	// repos with same name and different author

	// repos of authors of watched repos

	// repos in same repo cluster
	
	// repos of users in same user cluster (knn)
	for(User *other in user.neighbours) {
		for(Repository *repoId in other.repos){
			[candidateSet addObject:repoId];
		}
	}
	
	return candidateSet;
}

// strip candidates that are already being watched
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user {	
	for(NSNumber *repoId in user.repos) {
		[candidates removeObject:repoId];
	}
}

// assign probabilities that predictions are correct
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user {
	NSMutableDictionary *candidateDict = [[NSMutableDictionary alloc] init];
	
	for(NSNumber *repoId in candidates) {
		// get repo
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// ask user to score it
		repo.score = [user probabilityUserWillWatchRepo:repo];		
		// add to dict
		[candidateDict setObject:repo forKey:repoId];
	}
	
	// order
	NSArray *candidateList = [candidateDict keysSortedByValueUsingSelector:@selector(compareScore:)];
	// free mem
	[candidateDict release];
	
	return candidateList;
}

// -(void) preScoreCalculations:(NSSet *)candidates user:(User *)user {
// 	int maxCount;
// 	
// 	for(NSNumber *repoId in candidates) {
// 		// get repo
// 		Repository *repo = [model.repositoryMap objectForKey:repoId];
// 		// neighbourhood occurance
// 		NSNumber *occuranceCount = [user neighbourhoodOccurance];
// 		if()
// 	}
// }



//
// assign each user the most popular repos in their neighbourhood
//
/*
-(void)top10NeighbourhoodStrategy:(User *)user {
	// user must have repos
	if([user.repos count] <= 0) {
		[self top10Strategy:user]; // assign them the 10 most popular		
	} else {
		// calculate neighbours
		NSArray *neighbourIds = [self calculateNeighbours:user];
		if([neighbourIds count] <= 0) {
			[self top10Strategy:user]; // assign them the 10 most popular
		} else {
			// snip neighbours to K=10
			neighbourIds = [self getTopNOrLess:neighbourIds maximum:10];
			// order all neighbour repos by occurance
			NSArray *repos = [self orderUserReposByWatchOccurance:neighbourIds];
			// assign
			[self assignRepos:user repoIds:repos];
		}
	}
}
*/

// calculates neighbouring users using a watched profile distance metric
-(NSArray *) calculateNeighbours:(User *)user {	
	// build overlap set for all users
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(User *other in [model.userMap allValues]) {
		// never check against self
		if(other.userId == user.userId) {
			continue;
		}
		// other must have repos
		if([other.repos count] <= 0) {
			continue;
		}		
		// calculate intersection count
		int count = 0;
		for(Repository *repo_id in user.repos) {
			// count exact hits
			if([other.repos containsObject:repo_id]) {
				count++;
			}
			// TODO count fork matches
			
			// TODO count language matches >50% same langs
		}
		if(count > 0) {
			[dic setObject:[NSNumber numberWithInt:count] forKey:[NSNumber numberWithInt:other.userId]];
		}
	}
	// order by occurance count (ascending)
	NSArray *ordered = [dic keysSortedByValueUsingSelector:@selector(compare:)];
	// reverse (decending)
	ordered = [self reversedArray:ordered];
	// extract 
	return ordered;
}

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds {
	for(NSNumber *repoId in repoIds) {
		// add
		[user addPrediction:repoId];
		// check for finished
		if([user.predictions count] >= 10) {
			break;
		}
	}
}

- (NSArray *)reversedArray:(NSArray *)other {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[other count]];
    NSEnumerator *enumerator = [other reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

-(NSArray *)getTopNOrLess:(NSArray *)someArray maximum:(int)maximum {
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	int i = 0;
	for(i=0; i<maximum && i<[someArray count]; i++) {
		[array addObject:[someArray objectAtIndex:i]];
	}
	return array;
}

@end