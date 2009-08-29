#import "Model.h"

@implementation Model

// properties
@synthesize repositoryMap;
@synthesize userMap;
@synthesize testUsers;
@synthesize ownerSet;
@synthesize nameSet;

@synthesize totalWatchedRepos;
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
		ownerSet = [[NSMutableDictionary dictionaryWithCapacity:41444] retain];
		nameSet = [[NSMutableDictionary dictionaryWithCapacity:71847] retain];
	}
	
	return self;
}

-(void) dealloc {
	[repositoryMap release];
	[userMap release];
	[testUsers release];
	[ownerSet release];
	[nameSet release];
	
	[super dealloc]; // always last
}

-(void) printStats {
	NSLog(@"");
	NSLog(@"Statistics: ");
	NSLog(@"Total Repositories:..........%i", [repositoryMap count]);
	NSLog(@"Total Repo Owners:...........%i", [ownerSet count]);
	NSLog(@"Total Repo Names:............%i", [nameSet count]);
	NSLog(@"Total Users:.................%i", [userMap count]);
	NSLog(@"Total Test Users:............%i", [testUsers count]);
	
	NSLog(@"Total Watched Repos:....%i", totalWatchedRepos);
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
	// [self prepareRepoNeighbours];
	
	[pool drain];
}

-(void) prepareUserNeighbours {
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *filename =@"../data/derived_user_neighbours.txt";
	
	if([fm fileExistsAtPath:filename] == YES) {
		// load user distance matrix
		NSLog(@"Loading user neighbours...");
		[self loadUserNeighbours];
	} else {
		[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];		
		NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:filename];

		NSLog(@"User neighbourhood's don't exist, creating...");
		NSMutableString *buffer = [[NSMutableString alloc] init];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// calculate neighbours
		int count = 0;
		for(User *user in testUsers) {			
			// calculate
			NSArray *neighbours = [self calculateUserNeighbours:user];
			if([neighbours count] > 0) {
				[buffer appendString:[NSString stringWithFormat:@"%@:", user.userId]]; 
				// store K
				int i;
				int max = ([neighbours count] > KNN_STORE) ? KNN_STORE : [neighbours count] ; 			
				for(i=0; i<max; i++) {
					NSNumber *neighbourId = [neighbours objectAtIndex:i];
					if(i < KNN_READ) {
						[user addNeighbour:[userMap objectForKey:neighbourId]];
					} 					
					[buffer appendString:[NSString stringWithFormat:@"%@", neighbourId]];
					if(i != max-1) {
						[buffer appendString:@","];
					}					
				}
				[buffer appendString:@"\n"];
			}
			count++;
			if((count%50) == 0) {
				// flush
				[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];
				[buffer release];
				[pool drain];
				NSLog(@" >  finished [%i of %i] user knn", count, [testUsers count]);
				// init
				pool = [[NSAutoreleasePool alloc] init];
				buffer = [[NSMutableString alloc] init];
			}			
		}		

		// done
		[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];		
		[file closeFile];
		[pool drain];
		[buffer release];
		
		NSLog(@"Wrote user neighbourhoods to %@", filename);		
	} 	
}

// calculates neighbouring users using user-defined distance metric
-(NSArray *) calculateUserNeighbours:(User *)user {	
	// build overlap set for all users
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(User *other in [userMap allValues]) {
		// calculate distance
		double distance = [user calculateUserDistance:other];
		// only add if useful
		if(distance > 0) {
			[dic setObject:[NSNumber numberWithDouble:distance] forKey:other.userId];
		}
	}
	// order by occurance count (ascending)
	NSArray *ordered = [dic keysSortedByValueUsingSelector:@selector(compare:)];
	// reverse (decending)
	ordered = [self reversedArray:ordered];
	// extract 
	return ordered;
}

//
// way toooo slow! also a bug in here that stops be from cleaning up mem every mod(n) cycles
//
-(void) prepareRepoNeighbours { 
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *filename =@"../data/derived_repo_neighbours.txt";
	
	if([fm fileExistsAtPath:filename] == YES) {
		NSLog(@"Loading repo neighbours...");
		[self loadRepoNeighbours];
	} else {
		[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];		
		NSFileHandle *file = [[NSFileHandle fileHandleForWritingAtPath:filename] retain];
		
		NSLog(@"Repo neighbourhood's don't exist, creating...(going to be a long time!)");
		NSMutableString *buffer = [[NSMutableString alloc] init];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		// calculate neighbours
		int count = 0;
		for(Repository *repo in [repositoryMap allValues]) {
			// calculate
			NSArray *neighbours = [self calculateRepoNeighbours:repo];
			if([neighbours count] > 0) {
				[buffer appendString:[NSString stringWithFormat:@"%@:", repo.repoId]]; 
				// store K
				int i;
				int max = ([neighbours count] > KNN_STORE) ? KNN_STORE : [neighbours count] ; 			
				for(i=0; i<max; i++) {
					NSNumber *neighbourId = [neighbours objectAtIndex:i];
					if(i < KNN_READ) {
						[repo addNeighbour:[repositoryMap objectForKey:neighbourId]];
					}
					[buffer appendString:[NSString stringWithFormat:@"%@", neighbourId]];
					if(i != max-1) {
						[buffer appendString:@","];
					}					
				}
				[buffer appendString:@"\n"];
			}
			count++;
			if((count%100) == 0) {				
				// flush
				if([buffer length]){ // safe as!
					[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];
					[buffer release];
					buffer = [[NSMutableString alloc] init];
				}				
				NSLog(@" >  finished [%i of %i] repo knn", count, [repositoryMap count]);
				// some bug stops me from doing this
				// [pool drain];	
				// pool = [[NSAutoreleasePool alloc] init];
			}
		}		
		
		// done
		[file writeData:[buffer dataUsingEncoding: NSASCIIStringEncoding]];		
		[file closeFile];
		[file release];
		[pool drain];
		[buffer release];
	}
}

-(NSArray *) calculateRepoNeighbours:(Repository *)repo {	
	// build overlap set for all users
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(Repository *other in [repositoryMap allValues]) {
		// calculate distance
		double distance = [repo calculateRepoDistance:other];
		// only add if useful
		if(distance > 0) {
			[dic setObject:[NSNumber numberWithDouble:distance] forKey:other.repoId];
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
			Repository *parent = [repositoryMap objectForKey:repo.parentId];
			// set parent
			repo.parent = parent;
			// set forks of parent
			[parent addFork:repo];
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
		// while we are here, check watched repos
		if(repo.watchCount > 0) {
			totalWatchedRepos++;
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
		// create
		Repository *repo = [[[Repository alloc] init] autorelease];
		// parse
		[repo parse:line];
		
		// owners
		NSMutableArray *list = [ownerSet objectForKey:repo.owner];
		if(list) {
			[list addObject:repo.repoId]; // add repoId
		} else {
			list = [[[NSMutableArray alloc] init] autorelease]; // create
			[list addObject:repo.repoId]; // add repoId
			[ownerSet setObject:list forKey:repo.owner]; // store
		}
		// name
		list = [nameSet objectForKey:repo.name];
		if(list) {
			[list addObject:repo.repoId]; // add repoId
		} else {
			list = [[[NSMutableArray alloc] init] autorelease]; // create
			[list addObject:repo.repoId]; // add repoId
			[nameSet setObject:list forKey:repo.name]; // store
		}
		
		// test
		if([repositoryMap objectForKey:repo.repoId]) {
			NSLog(@" > Duplicate repository with key: %@", repo.repoId);
			continue;
		}
		// store
		[repositoryMap setObject:repo forKey:repo.repoId];		
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
		if(!repo) {
			// NOTE: we do not want these - they are not scored
			NSLog(@" > Repository %@ has language definition, but was not previously defined. Skipping!", repoKey);
			// repo = [[[Repository alloc] initWithId:repoKey] autorelease];
			// [repositoryMap setObject:repo forKey:repoKey];
		} else {
			// process language data
			[repo parseLanguage:[pieces objectAtIndex:1]];
		}
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
			repo = [[[Repository alloc] initWithId:repoKey] autorelease];
			[repositoryMap setObject:repo forKey:repoKey];
		}
		// get user
		User *user = [userMap objectForKey:userKey];
		if(!user) {
			user = [[[User alloc] initWithId:userKey] autorelease];
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
			user = [[[User alloc] initWithId:userKey] autorelease];
			[userMap setObject:user forKey:userKey];			
			NSLog(@" > Users %@ is test but was not previously defined", userKey);
		}
		// user is test
		user.test = YES;
		[testUsers addObject:user];
	}
	
	NSLog(@"Finished loading %i test users", [lines count]);
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

-(void) loadUserNeighbours {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/derived_user_neighbours.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	int numLoaded = 0;

	// process all lines
	for(NSString *line in lines) {
		if(![line length]) {
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
		int i=0;
		for(NSString *neighbourId in neighbours) {			
			// we can bound on load, get the K best neighbours
			if(i >= KNN_READ) {
				break;
			}
			[user addNeighbour:[userMap objectForKey:[NSNumber numberWithInteger:[neighbourId integerValue]]]];
			i++;
		}
		numLoaded++;
	}
	
	NSLog(@"Finished loading neighbours for %i of %i test users", numLoaded, [testUsers count]);
}


-(void) loadRepoNeighbours {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/derived_repo_neighbours.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *repoId = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];	
		// get repo
		Repository *repo = [repositoryMap objectForKey:repoId];
		if(!repo) {
			[NSException raise:@"Invalid Repo" format:@"Repo %@ has neighbours but was not previously known %@", repoId];
		}
		
		// process neighbours
		NSArray *neighbours = [[pieces objectAtIndex:1] componentsSeparatedByString:@","];
		int i=0;
		for(NSString *neighbourId in neighbours) {			
			// we can bound on load, get the K best neighbours
			if(i >= KNN_READ) {
				break;
			}
			[repo addNeighbour:[repositoryMap objectForKey:[NSNumber numberWithInteger:[neighbourId integerValue]]]];
			i++;
		}
	}
	
	NSLog(@"Finished loading %i derived_repo_neighbours", [lines count]);
}


@end
