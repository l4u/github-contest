#import "Strategy.h"

@implementation Strategy



-(id)initWithModel:(Model *)aModel {
	self = [super init];	
	
	if(self) {		
		model = aModel;
		[aModel retain];		
		
		// random numbers: http://stackoverflow.com/questions/160890/generating-random-numbers-in-objective-c
		// srandom(time(NULL));
		srandom(99); // fixed seed for taste-testing results
	}
	
	return self;
}

-(void) dealloc {
	[topReposByWatch release];
	[topReposByFork release];
	[testGlobalWeights release];
	[model release];
	[testSet release];
	[classifier release];

	[super dealloc]; // always last
}


-(void)employStrategy {
	// test case
	// [self newReposFromLanguageTest];
	
	// normal case
	[self initialize];
	[self holisticPredictions];
	[self calculatePredictions];
}

//
// An experiment to see if there are any points for the 5 new repos defined in the language data
//
-(void)newReposFromLanguageTest {
	// collect the repos with no watches
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:5];
	
	for(Repository * repo in [model.repositoryMap allValues]) {
		if(!repo.watchCount){
			[array addObject:repo.repoId];
		}
	}
	
	// validation
	NSLog(@"Found a total of %i repos without watches", [array count]);
	
	// assign the same set to all users
	for(User *user in model.testUsers) {
		for(NSNumber *repoId in array) {
			[user addPrediction:repoId];
		}		
	}
	// validate
	[model validatePredictions];
	// output
	[model outputPredictions];
}

// -(NSComparisonResult)nameSort:(id)o1 o2:(id)o2 context:(void*)context {
NSInteger nameSort(id o1, id o2, void *context) {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	Model *model = (Model *) context;
	
	int v1 = [[model.nameSet objectForKey:((Repository*)o1).name] count];
	int v2 = [[model.nameSet objectForKey:((Repository*)o2).name] count];
	
	// ensure decending
	if(v1 > v2) {
		return NSOrderedAscending;
	} else if(v2 < v2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

// -(NSComparisonResult)ownerSort:(id)o1 o2:(id)o2 context:(void*)context {
NSInteger ownerSort(id o1, id o2, void *context) {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	Model *model = (Model *) context;
	
	int v1 = [[model.ownerSet objectForKey:((Repository*)o1).owner] count];
	int v2 = [[model.ownerSet objectForKey:((Repository*)o2).owner] count];
	
	// ensure decending
	if(v1 > v2) {
		return NSOrderedAscending;
	} else if(v2 < v2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(void) initialize {
	NSLog(@"Initializing...");
	
	NSArray *tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareWatchCount:)];
	topReposByWatch = [[NSMutableArray arrayWithCapacity:TOP_RANKED_REPOS] retain];
	int i = 0;
	int total = [tmp count];
	NSLog(@"Watch Rank:");
	for(NSNumber *repoId in tmp) {		
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		if(i<TOP_RANKED_REPOS) {
			[topReposByWatch addObject:repoId];
		}
		// set rank (decending)
		double rank = (double)(total-i) / (double)total;
		repo.normalizedWatchRank = rank;
		if(i<TOP_RANKED_REPOS_PRINT) {
			NSLog(@" > name=%@, rank=%i, nrank=%f", repo.name, i, rank);
		}
		i++;
	}	
	// top n by fork count
	tmp = [model.repositoryMap keysSortedByValueUsingSelector:@selector(compareForkCount:)];
	topReposByFork = [[NSMutableArray arrayWithCapacity:TOP_RANKED_REPOS] retain];
	i = 0;
	NSLog(@"Fork Rank:");
	for(NSNumber *repoId in tmp) {
		// set rank (decending)
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		if(i<TOP_RANKED_REPOS) {
			[topReposByFork addObject:repoId];
		}		
		// set rank (decending)
		double rank = (double)(total-i) / (double)total;
		repo.normalizedForkRank = rank;
		if(i<TOP_RANKED_REPOS_PRINT) {
			NSLog(@" > name=%@, rank=%i, nrank=%f", repo.name, i, rank);
		}
		i++;
	}	
	// calculate name rank
	tmp = [[model.repositoryMap allValues] sortedArrayUsingFunction:nameSort context:model];
	i = 0;
	NSLog(@"Name Rank:");
	for(Repository *repo in tmp) {
		// set rank (decending)
		double rank = (double)(total-i) / (double)total;
		repo.normalizedNameRank = rank;
		if(i<TOP_RANKED_REPOS_PRINT) {
			NSLog(@" > name=%@, rank=%i, nrank=%f", repo.name, i, rank);
		}
		i++;		
	}
	// calculate owner rank
	tmp = [[model.repositoryMap allValues] sortedArrayUsingFunction:ownerSort context:model];
	i = 0;
	NSLog(@"Owner Rank:");
	for(Repository *repo in tmp) {
		// set rank (decending)
		double rank = (double)(total-i) / (double)total;
		repo.normalizedOwnerRank = rank;
		if(i<TOP_RANKED_REPOS_PRINT) {
			NSLog(@" > name=%@, rank=%i, nrank=%f", repo.name, i, rank);
		}
		i++;
	}
	
	if(USE_EXT_CLASSIFIER && !GENERATE_TRAINING_DATA) {
		NSLog(@" > Booting the Java VM...");
		// http://www.macosxhints.com/article.php?story=20040321163154226
		// http://cocoadevcentral.com/articles/000024.php
		
		// boot the vm
		[[NSJavaVirtualMachine alloc] initWithClassPath:[[NSJavaVirtualMachine defaultClassPath] stringByAppendingString:@":./weka.jar:./"]];
	
   		// load the classifier
		classifier = (Classification*) NSJavaObjectNamedInPath(@"Classification", nil);
	}
	
}


-(void) holisticPredictions {
	NSLog(@"Holistic predictions...");
	
	int count = 0;
	int assignment = 0;
	
	//
	// note to self: 
	//   - 204 of 229 assigned are correct with a cutoff of 2 name matches (4.260% boost)
	//   - 146 of 166 are correct wit a cutoff of 3 matches (3.049% boost)
	// 20 assured errors
	
	// deduce name
	for(User *user in model.testUsers) {
		[user deduceName:model.repositoryMap];
		if(user.deducedName) {
			count++;
			// repo assignment
			NSArray *ownerSet = [model.ownerSet objectForKey:user.deducedName];
			for(NSNumber *repoId in ownerSet) {
				if(![user.repos containsObject:repoId]) {
					[user addPrediction:repoId];
					assignment++;
				}
			}
		}
	}
	NSLog(@" > Successfully deduced %i user names, and assigned %i repos", count, assignment);	
}

-(void)calculatePredictions {
	NSLog(@"Calculating predictions...");

	
	NSFileHandle *file = nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	
	if(GENERATE_TRAINING_DATA) {
		NSString *filename = @"../data/training_data.txt";
		[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];		
		file = [[NSFileHandle fileHandleForWritingAtPath:filename] retain];	
	}
	
	if(TASTE_TEST || GENERATE_TRAINING_DATA) {
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
		
		if(TASTE_TEST || GENERATE_TRAINING_DATA) {
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
		if(GENERATE_TRAINING_DATA) {
			// build string
			NSString *buffer = [self generateTestCasesForUser:user candidates:candidateSet];
			// write to disk
			[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];
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
		
		// testing
		// if(TASTE_TEST && i>=100) {
		// 	break;
		// }
	}
	
	if(GENERATE_TRAINING_DATA) {
		// close		
		[file closeFile];
		[file release];
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
	
	// build a big list of **REPO ID's**
		
	// top repos by watch count
	[candidateSet addObjectsFromArray:topReposByWatch];
	// top repos by fork count
	[candidateSet addObjectsFromArray:topReposByFork];	
	
	
	// users watched parent hierarchy
	//[candidateSet addObjectsFromArray:user.watchedParentHierarchy];
	// if(user.numWatched) {
	// 	for(NSNumber *repoId in user.watchedParentHierarchy) {
	// 		[candidateSet addObject:repoId];
	// 	}
	// }
	
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
		// repos with the same deduced user name
		if(user.deducedName) {
			[candidateSet addObjectsFromArray:[model.ownerSet objectForKey:user.deducedName]];
		}
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
// the smaller we can make this - the faster!
//
-(void)filterCandidates:(NSMutableSet *)candidates user:(User *)user {	
	// nothing to strip
	if(![user.repos count]) {
		return;
	}	
	if(GENERATE_TRAINING_DATA) {
		// add repos
		for(NSNumber *repoId in user.repos) {
			[candidates addObject:repoId];
		}
	} else {
		// remove repos
		for(NSNumber *repoId in user.repos) {
			[candidates removeObject:repoId];
		}		
		// remove all current predictions
		for(NSNumber *repoId in user.predictions) {
			[candidates removeObject:repoId];
		}
		
		//
		// intelligent trimming (no effect in taste test)
		// seems to reduce total score by 0.13
/*
		NSMutableSet *trimList = [[NSMutableSet alloc] init]; 
		// try and trim garbage
		for(NSNumber *repoId in candidates) {
			Repository *repo = [model.repositoryMap objectForKey:repoId];
			if([[repo.name lowercaseString] isEqualToString:@"test"] == YES ||
				[[repo.name lowercaseString] isEqualToString:@"dotfiles"] == YES) {
				[trimList addObject:repoId];
			}
		}
		// remove
		[candidates minusSet:trimList];
		// NSLog(@" >trimmed %i repos for user %@ [from %i repos to %i]", [trimList count], user.userId, ([candidates count]+[trimList count]), [candidates count]);
		
		[trimList release];
*/		
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
		// score
		repo.score = [self userScoreToWatchRepo:user repo:repo];
		//repo.score = [self cooccurrencesScoreToWatchRepo:user repo:repo];
		// add to dict
		[candidateDict setObject:repo forKey:repoId];
	}
	
	// order
	NSArray *candidateList = [candidateDict keysSortedByValueUsingSelector:@selector(compareScore:)];
	// free mem
	[candidateDict release];
	
	return candidateList;
}

//
// far far too slow - need to pre-calculate things
//
-(double)cooccurrencesScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	
	// return best for now
	double best = 0.0;
	
	// probability of watching this repo
	double probWatch = ((double)repo.watchCount / (double)model.totalWatches);
	
	
	// process all user repos and calculate the co-occurance for this repo with each
	for(NSNumber *repoId in user.repos) {
		//Repository *userRepo = [model.repositoryMap objectForKey:repoId];
		
		int count = 0;
		// process all watches of the active repo and count occurance of the other repo
		for(NSNumber *userId in repo.watches) {
			if(userId == user.userId) {
				continue; // impossible right?
			}
			// get the user 
			User *other = [model.userMap objectForKey:userId];
			// check for user repo in other (the co-occurrence)
			if([other.repos containsObject:repoId]) {
				count++;
			}
		}
		
		// probability actual co-occurrences out if possible co-occurrences
		double probCoOcc = ((double)count /(double) repo.watchCount);
		
		
		// what about mediating by actual occurances out of all possible occurances
		// a multiplication factor perhaps?
		double score = (probCoOcc * probWatch);
		
		if(score > best) {
			best = score;
		}
	}
	
	return best;
}

-(NSString *) generateTestCasesForUser:(User*)user candidates:(NSMutableSet*)candidates {
	// stats
	[user calculateStats:model.repositoryMap];
	NSMutableString *buffer = [[[NSMutableString alloc] init] autorelease];
		
	NSMutableDictionary *candidateDict = [[NSMutableDictionary alloc] init];	
	for(NSNumber *repoId in candidates) {		
		// get repo
		Repository *repo = [model.repositoryMap objectForKey:repoId];
		
		NSDictionary *indicators = nil;
		
		if(USE_RANK_INDICATORS) {
			indicators = [self indicatorWeights2:user repo:repo]; 
			[self buildClassificationLine2:buffer indicators:indicators];			
		} else {
			// get indicators
			indicators = [self indicatorWeights:user repo:repo]; 
			// get line
			[self buildClassificationLine:buffer indicators:indicators];
		}
		
		// class
		[buffer appendString:(([user.repos containsObject:repoId]) ? @"1.0" : @"0.0")];				
		[buffer appendString:@"\n"];
	}
	
	return buffer;
}

-(void)buildClassificationLine:(NSMutableString *)buffer indicators:(NSDictionary *)indicators {
	// fixed known format (15 indicators)
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
}


//
// score is maximizing
//
-(double)userScoreToWatchRepo:(User *)user repo:(Repository *)repo {
	double score = 0.0;
	
							
	
	if(true){
		// brass tacks time
		
		score += ((double)repo.watchCount / (double)model.totalWatches);
			
		if(user.numNeighbours) { 
			// group popularity
			//score += ((double)[user neighbourhoodOccurance:repo.repoId] / (double)user.numNeighbourhoodWatched);
			
			//score += ((double)[[user neighbourhoodWatchName] countForObject:repo.name] / (double) user.numNeighbourhoodWatched);
			//score += ((double)[[user neighbourhoodWatchOwner] countForObject:repo.owner] / (double) user.numNeighbourhoodWatched);
			
			double occurance = 0;
			// try weighted neighbourhood
			for(NSNumber *userId in user.neighbours) {
				User *other = [model.userMap objectForKey:userId];
				// check for watch
				if([other.repos containsObject:repo.repoId]){
					double dist = [user calculateUserDistance2:other];
					double distRatio = (dist/(double)[user.repos count]);
					occurance += (1 * distRatio);
				}
			}
			score += (occurance /(double)user.numNeighbours);
			
		} else {
			
		}	
		 
		// bias toward root repos
		if(!repo.parentId) {
			score += 0.2;
		}	
		
		if([user.repos count]) {		
			// if(!user.numNeighbours) { 	
			// 	score += ((double) [user.ownerSet countForObject:repo.owner] / (double) [user.ownerSet count]);
			// 	score += ((double) [user.nameSet countForObject:repo.name] / (double) [user.nameSet count]);
			// }

			// score += ((double) [user.ownerSet countForObject:repo.owner] / (double) [user.ownerSet count]);
			// score += ((double) [user.nameSet countForObject:repo.name] / (double) [user.nameSet count]);

			// bug fix
			score += ((double) [user.ownerSet countForObject:repo.owner] / (double) [user.repos count]);
			score += ((double) [user.nameSet countForObject:repo.name] / (double) [user.repos count]);

			
			
			//reward direct parents
			if([user.watchedParents containsObject:repo.repoId]){
				score += 0.5;
			// reward parent hiearchy
			} else if([user.watchedParentHierarchy containsObject:repo.repoId]){
				score += 0.6;
			}	
			
/*			
			// hack give repos that match langs a boost
			if(repo.languageMap) {
				int match = 0;
				// look for at least one match
				for(NSString *langName in [repo.languageMap allKeys]) {
					if([user.languageSet countForObject:langName]) {
						match += 1;
					}
				}
				
				if(match) {
					score += 0.1;
				}
			}
*/			

/*
			//
			// try to personalize (looking for bump)
			//
			if([user.watchedParents containsObject:repo.repoId]){
				score += user.probWatchParentOfWatched;
			// reward parent hiearchy
			} else if([user.watchedParentHierarchy containsObject:repo.repoId]){
				score += user.probWatchParentHiearchyOfWatched;
			}
*/					
		}
		
		return score;
	}
	
	// calculate indicators
	NSDictionary *indicators = nil;
	if(USE_RANK_INDICATORS) {
		indicators = [self indicatorWeights2:user repo:repo];
	}else {
		indicators = [self indicatorWeights:user repo:repo];
	}

	// use external classifier
	if(USE_EXT_CLASSIFIER && [user.repos count]) {
		// prepare indicator string
		NSMutableString *buffer = [[NSMutableString alloc] init];
		// build the line
		if(USE_RANK_INDICATORS) {
			[self buildClassificationLine2:buffer indicators:indicators];
		} else {
			[self buildClassificationLine:buffer indicators:indicators];	
		}

		//
		// This is really slow, but I'm a lazy programmer that wants to use Weka and not re-write this in java
		//
		
		// note: could not get array of doubles across
		score = [classifier classify:buffer];

		// release
		[buffer release];
	} else {
	
		//
		// use internal classifier - good for testing, or hand-annealing the weights.
		//
		
		// get weights
		NSDictionary *weights = nil;
		if(USE_RANK_INDICATORS) {
			weights = [self getTestWeights2]; 
		}else{
			weights = [self getTestWeights]; 
		}
	
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
	
	}

	return score;
}

//indicators
// 
 
// TODO optimize weights (graident decent)
// TODO: get pre-learned weights from user/neighbourhood
-(NSDictionary *)getTestWeights {
	if(testGlobalWeights){
		return testGlobalWeights;
	}
	
	// some human annealing
	double w[11] = {1, 0, 0,    1, 0, 0,   0, 0, 1, 1, 0};
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
		if(!repo.parentId) {
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



//
// an attempt at generating general indicators
//
-(NSDictionary *)indicatorWeights2:(User *)user repo:(Repository *)repo {
	NSMutableDictionary *indicators = [[[NSMutableDictionary alloc] init] autorelease];
	double tmp;
	
	//
	// global
	//
		
	// normalized watch rank
	[indicators setObject:[NSNumber numberWithDouble:repo.normalizedWatchRank] forKey:@"normalized_watch_rank"];
	// normalized fork rank
	[indicators setObject:[NSNumber numberWithDouble:repo.normalizedForkRank] forKey:@"normalized_fork_rank"];
	// is root
	if(repo.parentId) {
		[indicators setObject:[NSNumber numberWithDouble:1.0] forKey:@"is_root"];
	} else {
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"is_root"];
	}	
	// name rank
	[indicators setObject:[NSNumber numberWithDouble:repo.normalizedNameRank] forKey:@"normalized_name_rank"];
	// owner rank
	[indicators setObject:[NSNumber numberWithDouble:repo.normalizedOwnerRank] forKey:@"normalized_owner_rank"];


	//
	// group
	//
	if(user.numNeighbours) {
		// neighbourhood watch rank
		if([user neighbourhoodOccurance:repo.repoId]) {
			[indicators setObject:[NSNumber numberWithDouble:repo.normalizedGroupWatchRank] forKey:@"normalized_group_watch_rank"];	
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_watch_rank"];	
		}	
		// neighbourhood name rank
		if([user.neighbourhoodWatchName countForObject:repo.name]){
			[indicators setObject:[NSNumber numberWithDouble:repo.normalizedGroupNameRank] forKey:@"normalized_group_name_rank"];	
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_name_rank"];
		}
		// neighbourhood owner rank
		if([user.neighbourhoodWatchOwner countForObject:repo.owner]){
			[indicators setObject:[NSNumber numberWithDouble:repo.normalizedGroupOwnerRank] forKey:@"normalized_group_owner_rank"];
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_owner_rank"];
		}
	}else{
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_watch_rank"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_name_rank"];	
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_group_owner_rank"];
	}

	//
	// user
	//
	if(user.numWatched) {	
		// user watch name rank
		if([user.nameSet countForObject:repo.name]){
			[indicators setObject:[NSNumber numberWithDouble:repo.normalizedUserNameRank] forKey:@"normalized_user_name_rank"];
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_user_name_rank"];
		}
		// user watch owner rank
		if([user.ownerSet countForObject:repo.owner]){
			[indicators setObject:[NSNumber numberWithDouble:repo.normalizedUserOwnerRank] forKey:@"normalized_user_owner_rank"];
		} else {
			[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_user_owner_rank"];
		}
	}else{
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_user_name_rank"];
		[indicators setObject:[NSNumber numberWithDouble:0.0] forKey:@"normalized_user_owner_rank"];
	}		
	return indicators;
}


-(NSDictionary *)getTestWeights2 {
	if(testGlobalWeights){
		return testGlobalWeights;
	}

	testGlobalWeights = [[NSMutableDictionary alloc] init];
	int i = 0;
	double w[10] = {1, 0, 0, 0, 0,    1, 0, 0,   1, 1};

	// global
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_watch_rank"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_fork_rank"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"is_root"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_name_rank"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_owner_rank"];
	i++;
	
	// neighbourhood
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_group_watch_rank"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_group_name_rank"];
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_group_owner_rank"];
	i++;
	
	// user
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_user_name_rank"];	
	i++;
	[testGlobalWeights setObject:[NSNumber numberWithDouble:w[i]] forKey:@"normalized_user_owner_rank"];
	
	return testGlobalWeights;
}

-(void)buildClassificationLine2:(NSMutableString *)buffer indicators:(NSDictionary *)indicators {
	// fixed known format (10 indicators)
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_watch_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_fork_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"is_root"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_name_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_owner_rank"]]];
	
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_group_watch_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_group_name_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_group_owner_rank"]]];
	
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_user_name_rank"]]];
	[buffer appendString:[NSString stringWithFormat:@"%@,", [indicators objectForKey:@"normalized_user_owner_rank"]]];
}

-(void)assignRepos:(User *)user repoIds:(NSArray *)repoIds {
	int i = 0;
	for(NSNumber *repoId in repoIds) {
		// make sure we are not already predicting it
		if([user.predictions containsObject:repoId]) {
			continue;
		}
		// check for finished
		if([user.predictions count] >= MAX_REPOS) {
			break;
		}
		// add
		[user addPrediction:repoId];
		i++;
	}
}

@end