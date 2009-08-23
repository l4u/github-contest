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
	[top20ReposByWatch release];
	[top20ReposByFork release];
	[model release];

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
	NSLog(@"Initializing...");
	
	int max = 20;
	
	// top n by watch count
	NSArray *tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareWatchCount:)];
	top20ReposByWatch = [NSMutableArray arrayWithCapacity:max];
	int i;
	for(i=0; i<max; i++) {
		NSNumber *repoId = [tmp objectAtIndex:i];
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// set rank (decending)
		repo.normalizedWatchRank = ((double) (max-i) / (double)max);
		// store
		[top20ReposByWatch addObject:repoId];
		NSLog(@"...Top 20 Watched: name=%@, rank=%i normalized=%f", repo.fullname, i, repo.normalizedWatchRank);
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
	NSLog(@"Calculating predictions...");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	
	for(User *user in model.testUsers) {
		//NSLog(@"Processing user %i...", user.userId);
						
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
		i++;
		if((i % 500)==0) {
			NSLog(@"Prediction status: [%i/%i]", i, [model.testUsers count]);
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
	//NSLog(@"Generating candidates for user %i...", user.userId);
	
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
	if([user.neighbourhoodRepos count] > 0) {
		for(Repository *repoId in user.neighbourhoodRepos){
			[candidateSet addObject:repoId];
		}
	}
	return candidateSet;
}

// strip candidates that are already being watched
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user {	
	//NSLog(@"Filtering candidates for user %i...", user.userId);
	
	for(NSNumber *repoId in user.repos) {
		[candidates removeObject:repoId];
	}
}

// assign probabilities that predictions are correct
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user {
	//NSLog(@"Scoring candidates for user %i...", user.userId);
	
	// do some pre-calculation on the neighbourhood set
	[self preScoreCalculations:candidates user:user];
	
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

-(void)preScoreCalculations:(NSSet *)candidates user:(User *)user {
		
	// find best neighbourhood score
	int max = 0;
	for(NSNumber *repoId in user.neighbourhoodRepos) {
		int score = [user neighbourhoodOccurance:repoId];
		if(score > max) {
			max = score;
		}
	}
	// calculate neighbourhood ranking
	for(NSNumber *repoId in user.neighbourhoodRepos) {
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// set rank (decending)
		repo.normalizedNeighborhoodWatchRank = ((double) [user neighbourhoodOccurance:repoId] / (double)max);
	}
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