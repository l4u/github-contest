#import "Strategy.h"

// random numbers: http://stackoverflow.com/questions/160890/generating-random-numbers-in-objective-c

@implementation Strategy

@synthesize generateTrainingData;



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
	[testSet release];
	[classifier release];

	[super dealloc]; // always last
}


-(void)employStrategy {
	[self initialize];
	[self calculatePredictions];
}


-(void) initialize {
	NSLog(@"Initializing...");
	
	NSArray *tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareWatchCount:)];
	top20ReposByWatch = [[NSMutableArray arrayWithCapacity:TOP_RANKED_REPOS] retain];
	int i = 0;
	for(NSNumber *repoId in tmp) {
		// set rank (decending)
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		if(i<TOP_RANKED_REPOS) {
			[top20ReposByWatch addObject:repoId];
		}
		i++;
	}	
	// top n by fork count
	tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareForkCount:)];
	top20ReposByFork = [[NSMutableArray arrayWithCapacity:TOP_RANKED_REPOS] retain];
	i = 0;
	for(NSNumber *repoId in tmp) {
		// set rank (decending)
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		if(i<TOP_RANKED_REPOS) {
			[top20ReposByFork addObject:repoId];
		}
		i++;
	}	
	
	if(generateTrainingData == NO) {
		NSLog(@" > Booting the Java VM...");
		// http://www.macosxhints.com/article.php?story=20040321163154226
		// http://cocoadevcentral.com/articles/000024.php
		
		// boot the vm
		[[NSJavaVirtualMachine alloc] initWithClassPath:[[NSJavaVirtualMachine defaultClassPath] stringByAppendingString:@":./weka.jar:./"]];
	
   		// load the classifier
		classifier = (Classification*) NSJavaObjectNamedInPath(@"Classification", nil);
	}
	
}




-(void)calculatePredictions {
	NSLog(@"Calculating predictions...");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	
	if(generateTrainingData == YES) {
		NSString *filename = @"../data/training_data.txt";
		[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];		
		file = [[NSFileHandle fileHandleForWritingAtPath:filename] retain];	
		testSet = [[NSMutableSet alloc] init];	
		// select test set
		while([testSet count] < NUM_TRAINING_USERS) {
			int selection = random() % [model.testUsers count];
			User *user = [model.testUsers objectAtIndex:selection];
			if(![testSet containsObject:user.userId]){
				[testSet addObject:user.userId];
			}
		}
	}
	
	for(User *user in model.testUsers) {
		
		if(generateTrainingData == YES) {
			// only concerned with a subset
			if(![testSet containsObject:user.userId]){
				continue;
			}
		}
		
		
		NSMutableSet *candidateSet = [[NSMutableSet alloc] init];
		// generate 
		[self generateCandidates:user candidateSet:candidateSet];		
		// fiter
		[self filterCandidates:candidateSet user:user];
		if(generateTrainingData == YES) {
			[self generateTestCasesForUser:user candidates:candidateSet];
		} else {
			// score
			NSArray *candidateList = [self scoreCandidates:candidateSet user:user];
			// assign
			[self assignRepos:user repoIds:candidateList];			
		}
		
		// explicit release
		[candidateSet release];

		// clear mem sometimes
		i++;
		if((i % 50)==0) {
			NSLog(@"Prediction status: [%i/%i]", i, [model.testUsers count]);
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	
	if(generateTrainingData == YES) {
		// close		
		[file closeFile];
		[file release];
		file = nil;
	}else{
		// validate
		[model validatePredictions];
		// output
		[model outputPredictions];
	}
	
	[pool drain];
}


 
// generate a set of candidates a user may want to watch
// somewhat inspired by: http://github.com/jeremybarnes/github_contest/tree/master
-(void)generateCandidates:(User *)user candidateSet:(NSMutableSet *)candidateSet {
	
	//
	// build a big list of **REPO ID's**
	//
	
	
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
}


// strip candidates that are already being watched
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user {	
	// nothing to strip
	if(![user.repos count]) {
		return;
	}	
	if(generateTrainingData == YES) {
		// add repos
		for(NSNumber *repoId in user.repos) {
			[candidates addObject:repoId];
		}
	} else {
		// remove repos
		for(NSNumber *repoId in user.repos) {
			[candidates removeObject:repoId];
		}		
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


-(void) generateTestCasesForUser:(User*)user candidates:(NSMutableSet*)candidates {
	// stats
	[user calculateStats:model.repositoryMap];
	NSMutableString *buffer = [[NSMutableString alloc] init];
		
	NSMutableDictionary *candidateDict = [[NSMutableDictionary alloc] init];	
	for(NSNumber *repoId in candidates) {		
		// get repo
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		// get indicators
		NSDictionary *indicators = [self indicatorWeights:user repo:repo]; 
		// fixed known format
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"global_prob_watch"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"global_prob_watch_forked"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"global_prob_watch_nonforked"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"global_prob_watch_root"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"global_prob_watch_nonroot"]]];
		
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"local_prob_watch"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"local_prob_watch_name"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"local_prob_watch_owner"]]];
		
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_forked"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_nonforked"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_root"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_nonroot"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_owner"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_name"]]];
		[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"user_prob_watch_language"]]];
		
		// class
		[buffer appendString:(([user.repos containsObject:repoId]) ? @"1.0" : @"0.0")];				
		[buffer appendString:@"\n"];
	}
	
	// flush buffer
	[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];
	[buffer release];
}

-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	
	if(false) {
		// Classification *test=[[NSClassFromString(@"Classification") alloc] init];
		Classification * test = (Classification*) NSJavaObjectNamedInPath(@"Classification", nil);
		
		// could not get array of doubles across
		double rs = [test classify:@"blah blah blah"];
		NSLog(@" got something from the classifier: %f", rs);
	}
	
	
	
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
	double w[11] = {1, 0, 0,    1, 0, 0,   0, 0, 1, 1, 0}; // K=5 (1857  	38.78%)
	//double w[11] = {0.3, 0.05, 0.05,    0.8, 0.1, 0.1,   0.05, 0.05, 0.8, 0.8, 0.05}; // K=5 (1854  	38.72%)
	// double w[11] = {0.8, 0.05, 0.05,    0.9, 0.1, 0.1,   0.05, 0.05, 1, 1, 0.05}; // K=5 (1852  	38.68%)
	
	int i = 0;
	
	testGlobalWeights = [[NSMutableDictionary alloc] init];
	
	//
	// NOTE: putting i++ inside the w[] does not result in expected behaviour. broken gcc?
	//
		
	// global
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_forked"];
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_nonforked"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_root"];
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"global_prob_watch_nonroot"];
	i++;
	// neighbourhood
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch_name"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"local_prob_watch_owner"];
	i++;
	// user
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_forked"];
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_nonforked"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_root"];	
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_nonroot"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_owner"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"user_prob_watch_name"];
	i++;
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
	if(true) {
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
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"global_prob_watch_nonforked"];
		} else {
			// prob of a user watching a non-forked repo
			tmp = ((double)(model.totalWatches-model.totalWatchedForked) / (double)(totalRepos-model.totalForked));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_nonforked"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"global_prob_watch_forked"];
		}
		// root repos 
		// TEST: K=5  (359  	7.497%)
		if(repo.parentId == 0) {
			// prob of a user watching a root repo
			tmp = ((double)model.totalWatchedRoot / (double)model.totalRoot);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_root"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"global_prob_watch_nonroot"];
		} else {
			// prob of a user watching a non-root repo
			tmp = ((double)(model.totalWatches-model.totalWatchedRoot) / (double)(totalRepos-model.totalRoot));
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"global_prob_watch_nonroot"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"global_prob_watch_root"];
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
	} else {
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"local_prob_watch"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"local_prob_watch_name"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"local_prob_watch_owner"];
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
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_nonforked"];
		} else {
			tmp = ((double)(user.numWatched-user.numForked) / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_nonforked"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_forked"];
		}
		// prob of this user watching a root repo
		// TEST: K=5  (349  	7.289%)
		if(!repo.parentId) {
			tmp = ((double)user.numRoot / (double) user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_root"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_nonroot"];
		} else {
			tmp = ((double)(user.numWatched-user.numRoot) / (double)user.numWatched);
			[indicators setObject:[NSNumber numberWithDouble:tmp] forKey:@"user_prob_watch_nonroot"];
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_root"];
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
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_language"];
		}
		// prob of a user watching a repo with this size (order)
		// TODO
	} else {
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_forked"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_nonforked"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_root"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_nonroot"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_owner"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_name"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"user_prob_watch_language"];
	}
		
	return indicators;
}



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