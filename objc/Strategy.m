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
		if((i % 500)==0) {
			NSLog(@"Prediction status: [%i/%i]", i, [model.testUsers count]);
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];			
		}			
		// testing
		// if(i > 50) {
		// 	break;
		// }	
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
	
	//
	// build a big list of **REPO ID's**
	//
	NSMutableSet *candidateSet = [[[NSMutableSet alloc] init] autorelease];
	
	// top 20 by watch count
	[candidateSet addObjectsFromArray:top20ReposByWatch];
	// top 20 by fork count
	[candidateSet addObjectsFromArray:top20ReposByFork];
	// repos related to current repos
	for(NSNumber *repoId in user.repos) {
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// add list of parents
		if(repo.parentId) {
			[candidateSet addObjectsFromArray:[repo getParentTree]];
		}
		// add list of forks
		if(repo.forkCount) {
			[candidateSet addObjectsFromArray:[repo getChildTree]];
		}
		// add list of siblings
		// TODO
		// repos with the same name
		[candidateSet addObjectsFromArray:[model.ownerSet objectForKey:repo.name]];
		// repos with the same owner
		[candidateSet addObjectsFromArray:[model.ownerSet objectForKey:repo.owner]];
		// repos in same repo cluster
		// TODO
	}
	
		
	// repos of users in same user cluster (knn)
	if(user.numNeighbours) {
		// have to enumerate
		for(NSNumber *repoId in user.neighbourhoodRepos) {
			[candidateSet addObject:repoId];
		}		
	}
	
	return candidateSet;
}


// strip candidates that are already being watched
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user {	
	// nothing to strip
	if(![user.repos count]) {
		return;
	}	
	for(NSNumber *repoId in user.repos) {
		[candidates removeObject:repoId];
	}
}

// assign probabilities that predictions are correct
-(NSArray *)scoreCandidates:(NSSet *)candidates user:(User *)user {	
	// stats
	[user calculateStats:model.repositoryMap];
		
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


#define DEFAULT_WEIGHT 1.0

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	
	// testing
	if(true) {
		int totalRepos = [model.repositoryMap count];
		
		return ((double)repo.watchCount / (double)model.totalWatches);
		
		// forked repos		
		if(repo.forkCount > 0) {
			// prob of a user watching a forked repo
			return ((double)model.totalWatchedForked / (double)model.totalForked);
		} else {
			// prob of a user watching a non-forked repo
			return ((double)(model.totalWatches-model.totalWatchedForked) / (double)(totalRepos-model.totalForked));
		}
	}
	
	double score = 0.0;
	
	// calculate indicators
	NSDictionary *indicators = [self indicatorWeights:user repo:repo]; 	
	// get weights
	NSDictionary *weights = nil;//[user indicatorWeights]; 
	
	// process all indicators
	for(NSString *key in indicators.allKeys) {
		NSNumber *indicator = [indicators objectForKey:key];
		NSNumber *weight = [weights objectForKey:key];

		// linear weighted sum of independent probablistic predictors
		if(weight) {
			score += ([weight doubleValue] * [indicator doubleValue]);
		} else {
			score += (DEFAULT_WEIGHT * [indicator doubleValue]);
		}
		
	} 
	
	return score;
}

-(NSDictionary *)indicatorWeights:(User *)user repo:(Repository *)repo {
	NSMutableDictionary *indicators = [[[NSMutableDictionary alloc] init] autorelease];
	double tmp;
	
	//
	// global indicators
	// ------------------------------------------	
	{
		int totalRepos = [model.repositoryMap count];
				
		// prob of a user watching this repo (873  	18.23%)
		tmp = ((double)repo.watchCount / (double)model.totalWatches);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch"];
		
		// forked repos		
		if(repo.forkCount > 0) {
			// prob of a user watching a forked repo
			tmp = ((double)model.totalWatchedForked / (double)model.totalForked);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_forked"];
			// fork tree size (one or all levels)
			// TODO
		} else {
			// prob of a user watching a non-forked repo
			tmp = ((double)(model.totalWatches-model.totalWatchedForked) / (double)(totalRepos-model.totalForked));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_nonforked"];
		}
		// root repos
		if(repo.parentId == 0) {
			// prob of a user watching a root repo
			tmp = ((double)model.totalWatchedRoot / (double)model.totalRoot);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_root"];
		} else {
			// prob of a user watching a non-root repo
			tmp = ((double)(model.totalWatches-model.totalWatchedRoot) / (double)(totalRepos-model.totalRoot));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_nonroot"];
		}
		
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
	if(user.numNeighbours > 0) {
		
		// prob of a user in the group watching this repo
		tmp = ((double)[user neighbourhoodOccurance:repo.repoId] / (double)user.numNeighbourhoodWatched);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch"];		
		// prob of a user in the group watching a repo with this name
		tmp = ((double)[user neighbourhoodTotalWatchesForName:repo.name repositoryMap:model.repositoryMap] / (double)user.numNeighbourhoodWatched);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch_name"];
		// prob of a user in the group watching a repo with this owner
		tmp = ((double)[user neighbourhoodTotalWatchesForOwner:repo.owner repositoryMap:model.repositoryMap] / (double)user.numNeighbourhoodWatched);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch_language"];

		// prob of a user in the group watching a repo with thid dominant language
		// TODO
	}
	//
	// individual indicators
	// ------------------------------------------
	if([user.repos count] > 0) {
		// prob of this user watching a forked repo
		if(repo.forkCount > 0) {
			tmp = ((double)user.numForked / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_forked"];
		} else {
			tmp = ((double)(user.numWatched-user.numForked) / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_nonforked"];
		}
		// prob of this user watching a root repo
		if(repo.parentId == 0) {
			tmp = ((double)user.numRoot / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_root"];
		} else {
			tmp = ((double)(user.numWatched-user.numRoot) / (double)user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_nonroot"];
		}
		// prob of user watching with owner
		tmp = ((double) [user.ownerSet countForObject:repo.owner] / (double) [user.ownerSet count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_owner"];
		// prob of user watching with name
		tmp = ((double) [user.nameSet countForObject:repo.name] / (double) [user.nameSet count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_name"];
		// prob of user watching with dominant language
		if(repo.languageMap && user.numWithLanguage > 0) {
			tmp = ((double)[user.languageSet countForObject:repo.dominantLanguage] / (double) user.numWithLanguage);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_language"];
		}
		// prob of a user watching a repo with this size (order)
		// TODO
	}
		
	return indicators;
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