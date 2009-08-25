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
	//NSLog(@"Top 20 Watched:");
	NSArray *tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareWatchCount:)];
	top20ReposByWatch = [NSMutableArray arrayWithCapacity:max];
	int i = 0;
	//int total = [tmp count];
	for(NSNumber *repoId in tmp) {
		// set rank (decending)
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		//repo.normalizedWatchRank = ((double) (max-i) / (double)total);
		if(i<20) {
			[top20ReposByWatch addObject:repoId];
			// NSLog(@"...Top 20 Watched: name=%@, rank=%i normalized=%f", repo.fullname, i, repo.normalizedWatchRank);
		}
		i++;
	}	
	// top n by fork count
	tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareForkCount:)];
	top20ReposByFork = [NSMutableArray arrayWithCapacity:max];
	i = 0;
	//total = [tmp count];
	//NSLog(@"Top 20 Forked:");
	for(NSNumber *repoId in tmp) {
		// set rank (decending)
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		//repo.normalizedForkRank = ((double) (max-i) / (double)total);
		if(i<5) {
			[top20ReposByFork addObject:repoId];
			// NSLog(@"...Top 20 Forked: name=%@, rank=%i normalized=%f", repo.fullname, i, repo.normalizedForkRank);
		}
		i++;
	}	
}

-(void)calculatePredictions {
	NSLog(@"Calculating predictions...");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	
	for(User *user in model.testUsers) {
		//NSLog(@"Processing user %i...", user.userId);		
		// generate 
		NSMutableSet *candidateSet = [self generateCandidates:user];		
		// fiter
		[self filterCandidates:candidateSet user:user];
		// score
		NSArray *candidateList = [self scoreCandidates:candidateSet user:user];
		// assign
		[self assignRepos:user repoIds:candidateList];
		// clear mem sometimes
		i++;
		if((i % 5)==0) {
			NSLog(@"Prediction status: [%i/%i]", i, [model.testUsers count]);
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];			
		}			
		// testing
		if(i > 50) {
			break;
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
	
	// nothing to strip
	if([user.repos count] <= 0) {
		return;
	}
	
	for(NSNumber *repoId in user.repos) {
		[candidates removeObject:repoId];
	}
}

// assign probabilities that predictions are correct
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user {
	//NSLog(@"Scoring candidates for user %i...", user.userId);	
		
	NSMutableDictionary *candidateDict = [[NSMutableDictionary alloc] init];	
	for(NSNumber *repoId in candidates) {
		// get repo
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// ask user to score it
		repo.score = [self userScoreToWatchRepo:user repo:repo];		
		// add to dict
		[candidateDict setObject:repo forKey:repoId];
	}
	
	// order
	NSArray *candidateList = [candidateDict keysSortedByValueUsingSelector:@selector(compareScore:)];
	// free mem
	[candidateDict release];
	
	return candidateList;
}


#define GLOBAL_WEIGHT 	1.0
#define LOCAL_WEIGHT 	1.0
#define USER_WEIGHT 	1.0


// linear weighted sum of independent probablistic predictors
// TODO: calcluate optimum independent weights
-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	double score = 0.0;
	
	//
	// global indicators
	// ------------------------------------------
	if([user.neighbours count] <= 0)
	{
		int totalRepos = [model.repositoryMap count];
		
		// prob of a user watching this repo
		score += GLOBAL_WEIGHT * ((double)repo.watchCount / (double)model.totalWatches);
		// forked repos		
		if(repo.forkCount > 0) {
			// prob of a user watching a forked repo
			// score += GLOBAL_WEIGHT * ((double)model.totalWatchedForked / (double)model.totalForked);
			// fork tree size (one or all levels)
			// TODO
		} else {
			// prob of a user watching a non-forked repo
			// score += GLOBAL_WEIGHT * ((double)(model.totalWatches-model.totalWatchedForked) / (double)(totalRepos-model.totalForked));
		}
		// root repos
		if(repo.parentId == 0) {
			// prob of a user watching a root repo
			// score += GLOBAL_WEIGHT * ((double)model.totalWatchedRoot / (double)model.totalRoot);
		} else {
			// prob of a user watching a non-root repo
			// score += GLOBAL_WEIGHT * ((double)(model.totalWatches-model.totalWatchedRoot) / (double)(totalRepos-model.totalRoot));
		}
		// prob of a user watching a repo with this repo's owner's name
		// TODO
		// prob of a user watching a repo with this repo's dominant language
		if([repo.languageMap count] > 0) {
			// TODO
		}
		// prob of a user watching a repo of this size (order)
		// TODO
	}	
	//
	// group indicators
	// ------------------------------------------	
	if([user.neighbours count] > 0) {
		int totalNeighbourhoodWatches = [user neighbourhoodTotalWatches];
		
		// prob of a user in the group watching this repo
		score += LOCAL_WEIGHT * ((double)[user neighbourhoodOccurance:repo.repoId] / (double)totalNeighbourhoodWatches);
		// prob of a user in the group watching a repo with this name
		//score += LOCAL_WEIGHT * ((double)[user neighbourhoodTotalWatchesForName:repo.name repositoryMap:model.repositoryMap] / (double)totalNeighbourhoodWatches);
		// prob of a user in the group watching a repo with this owner
		//score += LOCAL_WEIGHT * ((double)[user neighbourhoodTotalWatchesForOwner:repo.owner repositoryMap:model.repositoryMap] / (double)totalNeighbourhoodWatches);
		// prob of a user in the group watching a repo with thid dominant language
		

	}
	//
	// individual indicators
	// ------------------------------------------
	if([user.repos count] > 0) {
		// prob of this user watching a forked repo
		// TODO
		// prob of this user watching a root repo
		// TODO
		// prob of user watching with owner name
		// TODO
		// prob of user watching with dominant language
		// TODO
	}
		
	return score;
}

#define MAX_REPOS 	10

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds {
	for(NSNumber *repoId in repoIds) {
		// add
		[user addPrediction:repoId];
		// check for finished
		if([user.predictions count] >= MAX_REPOS) {
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