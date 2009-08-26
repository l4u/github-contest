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
	[testGlobalWeights release];
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
		if((i % 100)==0) {
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

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	double score = 0.0;
	
	// calculate indicators
	NSDictionary *indicators = [self indicatorWeights:user repo:repo]; 	
	// get weights
	NSDictionary *weights = [self getTestWeights]; 
	
	// process all indicators
	for(NSString *key in indicators.allKeys) {
		NSNumber *indicator = [indicators objectForKey:key];
		NSNumber *weight = [weights objectForKey:key];

		// safety
		if(!weight) {
			[NSException raise:@"Invalid Indicator Key" format:@"we do not have a weight defined for indicator: %@", key];
		}
				
		// linear weighted sum of independent probablistic predictors		
		score += (([weight doubleValue] * [indicator doubleValue]));		
	} 
	
	return score;
}

// TODO optimize weights (graident decent)
// TODO: get pre-learned weights from user/neighbourhood
-(NSDictionary *)getTestWeights {
	if(testGlobalWeights){
		return testGlobalWeights;
	}
	
	// some human annealing
	//double w[11] = {1, 0, 0,    1, 0, 0,   0, 0, 1, 1, 0}; // K=5 (1857  	38.78%)
	//double w[11] = {0.3, 0.05, 0.05,    0.8, 0.1, 0.1,   0.05, 0.05, 0.8, 0.8, 0.05}; // K=5 (1854  	38.72%)
	double w[11] = {0.8, 0.05, 0.05,    0.9, 0.1, 0.1,   0.05, 0.05, 1, 1, 0.05}; // K=5 
	
	int i = 0;
	
	testGlobalWeights = [[NSMutableDictionary alloc] init];
		
	// global
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_forked"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_root"];i++;
	// neighbourhood
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch_name"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch_owner"];i++;
	// user
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_forked"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_root"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_owner"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_name"];i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_language"];
	
	return testGlobalWeights;
}

-(NSDictionary *)indicatorWeights:(User *)user repo:(Repository *)repo {
	NSMutableDictionary *indicators = [[[NSMutableDictionary alloc] init] autorelease];
	double tmp;
	
	// TEST: K=5, global_prob_watch, local_prob_watch, user_prob_watch_owner, user_prob_watch_name: (1857  	38.78%)
	// TEST: K=10, global_prob_watch, local_prob_watch, user_prob_watch_owner, user_prob_watch_name: (1867  38.99%)
	// TEST: K=3, global_prob_watch, local_prob_watch, user_prob_watch_owner, user_prob_watch_name: (1830  	38.22%)
	
	//
	// global indicators
	// ------------------------------------------	
	if(!user.numNeighbours) {
		int totalRepos = [model.repositoryMap count];
				
		// prob of a user watching this repo 
		// TEST: K=5 (873  	18.23%)
		tmp = ((double)repo.watchCount / (double)model.totalWatches);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch"];
		
		// forked repos	
		// TEST: K=5  (487  	10.17%)
		if(repo.forkCount > 0) {
			// prob of a user watching a forked repo
			tmp = ((double)model.totalWatchedForked / (double)model.totalForked);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_forked"];
		} else {
			// prob of a user watching a non-forked repo
			tmp = ((double)(model.totalWatches-model.totalWatchedForked) / (double)(totalRepos-model.totalForked));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_forked"];
		}
		// root repos 
		// TEST: K=5  (359  	7.497%)
		if(repo.parentId == 0) {
			// prob of a user watching a root repo
			tmp = ((double)model.totalWatchedRoot / (double)model.totalRoot);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_root"];
		} else {
			// prob of a user watching a non-root repo
			tmp = ((double)(model.totalWatches-model.totalWatchedRoot) / (double)(totalRepos-model.totalRoot));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_root"];
		}
		
		// prob of a user watching a repo with this repo's dominant language
		// TODO
		// prob of a user watching a repo of this size (order)
		// TODO
	}
		

		
	//
	// group indicators
	// ------------------------------------------	
	
	// TEST K=5, local_prob_watch, local_prob_watch_name, local_prob_watch_language (615  	12.84%)

	if(user.numNeighbours) {
		
		// prob of a user in the group watching this repo
		// TEST: K=5  (996  	20.80%)
		tmp = ((double)[user neighbourhoodOccurance:repo.repoId] / (double)user.numNeighbourhoodWatched);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch"];
		// prob of a user in the group watching a repo with this name
		// TEST: K=5  (1093  	22.82%)
		tmp = ((double)[[user neighbourhoodWatchName] countForObject:repo.name] / (double) [[user neighbourhoodWatchName] count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch_name"];
		// prob of a user in the group watching a repo with this owner
		// TEST: K=5  (1038  	21.67%)
		tmp = ((double)[[user neighbourhoodWatchOwner] countForObject:repo.owner] / (double) [[user neighbourhoodWatchOwner] count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"local_prob_watch_owner"];
		// prob of a user in the group watching a repo with this dominant language
		// TODO
	}
	
	//
	// individual indicators
	// ------------------------------------------

	// TEST: K=5, user_prob_watch_owner, user_prob_watch_name (1673  	34.94%)
	// TEST K=5, user_prob_watch_forked, user_prob_watch_root, user_prob_watch_owner, user_prob_watch_name, user_prob_watch_language (1623  	33.89%)

	if([user.repos count]) {
		// prob of this user watching a forked repo
		// TEST: K=5  (461  	9.628%)
		if(repo.forkCount) {
			tmp = ((double)user.numForked / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_forked"];
		} else {
			tmp = ((double)(user.numWatched-user.numForked) / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_forked"];
		}
		// prob of this user watching a root repo
		// TEST: K=5  (349  	7.289%)
		if(!repo.parentId) {
			tmp = ((double)user.numRoot / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_root"];
		} else {
			tmp = ((double)(user.numWatched-user.numRoot) / (double)user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_root"];
		}		
		// prob of user watching with owner 
		// TEST: K=5  (1061  	22.15%)
		tmp = ((double) [user.ownerSet countForObject:repo.owner] / (double) [user.ownerSet count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_owner"];
		// prob of user watching with name
		// TEST: K=5  (1030  	21.51%)
		tmp = ((double) [user.nameSet countForObject:repo.name] / (double) [user.nameSet count]);
		[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_name"];

		// prob of user watching with dominant language
		// TEST: K=5  (614  	12.82%)
		if(repo.languageMap && user.numWithLanguage) {
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
	int i = 0;
	for(NSNumber *repoId in repoIds) {
		// check for finished
		if(i >= MAX_REPOS) {
			break;
		}

		// add
		[user addPrediction:repoId];
		i++;
	}
}

@end