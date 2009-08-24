#import "Model.h"

@implementation Model

// properties
@dynamic repositoryMap;
@dynamic userMap;
@dynamic testUsers;

@synthesize totalWatches;
@synthesize totalForked;
@synthesize totalWatchedForked;
@synthesize totalRoot;
@synthesize totalWatchedRoot;

-(id) init {
	self = [super init];	
	
	if(self) {
		// we know exactly how many we have - provided data is finite
		repositoryMap = [[NSMutableDictionary dictionaryWithCapacity:120872] retain];
		userMap = [[NSMutableDictionary dictionaryWithCapacity:56521] retain];
		testUsers = [[NSMutableArray arrayWithCapacity:4788] retain];
	}
	
	return self;
}

-(void) dealloc {
	[repositoryMap release];
	[userMap release];
	[testUsers release];
	
	[super dealloc]; // always last
}

-(void) printStats {
	NSLog(@"");
	NSLog(@"Statistics: ");
	NSLog(@"Total Repositories:.....%i", [repositoryMap count]);
	NSLog(@"Total Users:............%i", [userMap count]);
	NSLog(@"Total Test Users:.......%i", [testUsers count]);
	NSLog(@"Total Watches:..........%i", totalWatches);
	NSLog(@"Total Forked:...........%i", totalForked);
	NSLog(@"Total Watched Forked:...%i", totalWatchedForked);
	NSLog(@"Total Root:.............%i", totalRoot);
	NSLog(@"Total Watched Root:.....%i", totalWatchedRoot);
	
	NSLog(@"");
}

-(void) loadModel {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// first order data
	[self loadRepos];
	[self loadRepoLanguages];
	[self loadRepoUserRelationships];
	[self loadTestUsers];
	
	// second order pre-calculations
	[self calculateForkCounts];
	[self prepareUserNeighbours];
	
	
	[pool drain];
}

-(void) prepareUserNeighbours {
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *filename =@"../data/derived_user_neighbours.txt";
	
	if([fm fileExistsAtPath:filename] == YES) {
		// load user distance matrix
		NSLog(@"Loading user neighbours...");
		[self loadNeighbours];
	} else {
		NSLog(@"User neighbourhood's don't exist, creating...");
		NSMutableString *buffer = [[NSMutableString alloc] init];
		// calculate neighbours
		for(User *user in [userMap allValues]) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			// calculate
			NSArray *neighbours = [self calculateNeighbours:user];
			if([neighbours count] > 0) {
				[buffer appendString:[NSString stringWithFormat:@"%i:", user.userId]]; 
				// store K
				int i;
				int K = 10;
				int max = ([neighbours count] > K) ? K : [neighbours count] ; 			
				for(i=0; i<max; i++) {
					NSNumber *neighbourId = [neighbours objectAtIndex:i];
					[user addNeighbour:[userMap objectForKey:neighbourId]];
					[buffer appendString:[NSString stringWithFormat:@"%@", neighbourId]];
					if(i != max-1) {
						[buffer appendString:@","];
					}					
				}
				[buffer appendString:@"\n"];
			}
			[pool drain];
		}		
		// save		
		if([buffer writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:NULL] == NO) {
			[NSException raise:@"File Write Error" format:@"Unable to write user neighbourhoods to filename: %@", filename];
		} else {
			NSLog(@"Wrote user neighbourhoods to %@", filename);
		}
				
		[buffer release];
	} 	
}

// calculates neighbouring users using user-defined distance metric
-(NSArray *) calculateNeighbours:(User *)user {	
	// build overlap set for all users
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(User *other in [userMap allValues]) {
		// calculate distance
		double distance = [user calculateUserDistance:other];
		// only add if useful
		if(distance > 0) {
			[dic setObject:[NSNumber numberWithInt:distance] forKey:[NSNumber numberWithInt:other.userId]];
		}
	}
	// order by occurance count (ascending)
	NSArray *ordered = [dic keysSortedByValueUsingSelector:@selector(compare:)];
	// reverse (decending)
	ordered = [self reversedArray:ordered];
	// extract 
	return ordered;
}

- (NSArray *)reversedArray:(NSArray *)other {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[other count]];
    NSEnumerator *enumerator = [other reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

// evolved into building fork hierarchy
-(void) calculateForkCounts {
	// build hierarchy
	for(NSNumber *repoId in repositoryMap.allKeys) {
		Repository *repo = [repositoryMap objectForKey:repoId];
		if(repo.parentId) {
			// get parent
			NSNumber *parentId = [NSNumber numberWithInteger:repo.parentId];
			Repository *parent = [repositoryMap objectForKey:parentId];
			// set parent
			repo.parent = parent;
			// set forks in parent
			[parent addFork:parent];
		}
	}
	
	// count forked
	for(NSNumber *repoId in repositoryMap.allKeys) { 
		Repository *repo = [repositoryMap objectForKey:repoId];
		if(repo.forkCount > 0) {
			totalForked++; // all
			// check watched
			if(repo.watchCount > 0) {
				totalWatchedForked++;
			}
		}
		if(repo.parentId==0) {
			totalRoot++;
			if(repo.watchCount > 0) {
				totalWatchedRoot++;
			}
		}
	}
	
}

-(void) outputPredictions {
	NSLog(@"Writing predictions to file...");
	
	// build prediction file in mem
	NSMutableString *buffer = [[NSMutableString alloc] init];	
	// enumerate test users
	for(User *user in testUsers) {
		// get prediction string
		[buffer appendString:[user getPredictionAsString]];
		// new line
		[buffer appendString:@"\n"];
	}

	// output to backup
	NSString *filename = [NSString stringWithFormat:@"../backup/results-%i.txt", (int)[NSDate timeIntervalSinceReferenceDate]];
	if([buffer writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:NULL] == NO) {
		[NSException raise:@"File Write Error" format:@"Unable to write predictions to filename: %@", filename];
	} else {
		NSLog(@"Wrote prediction results to %@", filename);
	}
	// output to results.txt
	filename = @"../results.txt";
	if([buffer writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:NULL] == NO) {
		[NSException raise:@"File Write Error" format:@"Unable to write predictions to filename: %@", filename];
	} else {
		NSLog(@"Wrote prediction results to %@", filename);
	}
	
	[buffer release];
}

-(void) loadRepos {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/repos.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		Repository *repo = [[[Repository alloc] init] autorelease];
		[repo parse:line];
		
		NSNumber *key = [NSNumber numberWithInteger:repo.repoId];
		if([repositoryMap objectForKey:key]) {
			NSLog(@" > Duplicate repository with key: %@", key);
			continue;
		}
		[repositoryMap setObject:repo forKey:key];		
	}
	
	NSLog(@"Finished loading %i repositories", [repositoryMap count]);
}



-(void) loadRepoLanguages {
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/lang.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		// get repo
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *repoKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];
		Repository *repo = [repositoryMap objectForKey:repoKey];
		if(repo == nil) {
			NSLog(@" > Repository %@ has language definition, but was not previously defined", repoKey);
			repo = [[[Repository alloc] initWithId:[repoKey intValue]] autorelease];
			[repositoryMap setObject:repo forKey:repoKey];
		}
		// process language data
		[repo parseLanguage:[pieces objectAtIndex:1]];
	}
	
	NSLog(@"Finished loading %i repository language definitions", [lines count]);
}

-(void) loadRepoUserRelationships {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/data.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		// <user_id>:<repo_id>
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *userKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];
		NSNumber *repoKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:1] integerValue]];		
		// get repo
		Repository *repo = [repositoryMap objectForKey:repoKey];
		if(repo == nil) {
			NSLog(@" > Repository %@ specified in relationship did not exist", repoKey);
			repo = [[[Repository alloc] initWithId:[repoKey intValue]] autorelease];
			[repositoryMap setObject:repo forKey:repoKey];
		}
		// get user
		User *user = [userMap objectForKey:userKey];
		if(!user) {
			user = [[[User alloc] initWithId:[userKey intValue]] autorelease];
			[userMap setObject:user forKey:userKey];			
		}
		// repo
		[repo addWatcher:userKey];
		// add repo to user
		[user addRepository:repoKey];
		// count 
		totalWatches++;
	}
	
	NSLog(@"Finished loading %i user-repositories relationships", [lines count]);
}

-(void) loadTestUsers {
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/test.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		NSNumber *userKey = [NSNumber numberWithInteger:[line integerValue]];
		// get user
		User *user = [userMap objectForKey:userKey];
		if(!user) {
			user = [[[User alloc] initWithId:[userKey intValue]] autorelease];
			[userMap setObject:user forKey:userKey];			
			NSLog(@" > Users %@ is test but was not previously defined", userKey);
		}
		// user is test
		user.test = YES;
		[testUsers addObject:user];
	}
	
	NSLog(@"Finished loading %i test users", [lines count]);
}

-(NSMutableDictionary*)repositoryMap {
    return repositoryMap;
}
-(NSMutableDictionary*)userMap {
    return userMap;
}
-(NSMutableArray*)testUsers {
    return testUsers;
}

-(void) validatePredictions {
	NSLog(@"Validating prediction model...");
	for(User *user in testUsers) {
		// correct size
		if([user.predictions count] > 10) {
			[NSException raise:@"Invalid Prediction Model" format:@"user %@ contains too many predictions: %i", user.userId, [user.predictions count]];
		}		
		// check all predictions
		for(NSNumber *repoId in user.predictions) {
			// valid repo
			if(![repositoryMap objectForKey:repoId]) {
				[NSException raise:@"Invalid Prediction Model" format:@"user %@ contains unknown or invalid repo id %@", user.userId, repoId];
			}
			// not being watched
			if([user.repos containsObject:repoId]) {
				[NSException raise:@"Invalid Prediction Model" format:@"user %@ has prediction of a watched repo id %@", user.userId, repoId];
			}
		}
	}
	
	NSLog(@"..Prediction model appears valid");
}

-(void) loadNeighbours {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/derived_user_neighbours.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *userId = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];	
		// get user
		User *user = [userMap objectForKey:userId];
		if(!user) {
			[NSException raise:@"Invalid User" format:@"user %@ has neribours but was not previously known %@", userId];
		}
		// only process test users for now
		if(user.test == NO) {
			continue;
		}
		
		// process neighbours
		NSArray *neighbours = [[pieces objectAtIndex:1] componentsSeparatedByString:@","];
		for(NSString *neighbourId in neighbours) {			
			[user addNeighbour:[userMap objectForKey:[NSNumber numberWithInteger:[neighbourId integerValue]]]];
		}
	}
	
	NSLog(@"Finished loading %i derived_user_neighbours", [lines count]);
}


@end
