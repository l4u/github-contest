#import "Strategy.h"


// random numbers: http://stackoverflow.com/questions/160890/generating-random-numbers-in-objective-c

@implementation Strategy

@dynamic model;

-(id)initWithModel:(Model *)aModel {
	self = [super init];	
	
	if(self) {		
		model = aModel;
		reposByOccurance = nil;
		[aModel retain];
		// random numbers
		srandom(time(NULL));
	}
	
	return self;
}

-(void) dealloc {
	[model release];
	[reposByOccurance release];
	
	[super dealloc]; // always last
}

-(Model *)model {
	return model;
}

-(void)calculatePredictions {
	NSLog(@"calculating predictions...");
		
	for(User *user in model.testUsers) {
		// random strategy 
		// NSArray *allKeys = [model.repositoryMap allKeys];
		// [self randomStrategy:user allRepoKeys:allKeys];
		
		// top 10 strategy
		[self top10Strategy:user];
		
		// top 10 repos in user's neighbourhood
		// [self top10NeighbourhoodStrategy:user];
	}
}

//
// random strategy (for process testing)
//
-(void)randomStrategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys {	
	while([user.predictions count] < MAX_REPOS) {
		// select a random repo
		int selection = random() % [allRepoKeys count];
		NSNumber * repoId = [allRepoKeys objectAtIndex:selection];
		// test for watch list
		if([user.repos containsObject:repoId]) {
			continue;
		}
		// test for prediction list
		if([user.predictions containsObject:repoId]) {
			continue;
		}
		// add
		[user addPrediction:repoId];
	}
}

//
// assign each user the top 10 non-conflicting most popular repos
//
-(void)top10Strategy:(User *)user {
	if(!reposByOccurance) {
		reposByOccurance = [self orderUserReposByWatchOccurance:[model.userMap allKeys]];
	}
	// assign
	[self assignRepos:user :reposByOccurance];
}


//
// assign each user the most popular repos in their neighbourhood
//
-(void)top10NeighbourhoodStrategy:(User *)user {
	// user must have repos
	if([user.repos count] <= 0) {
		return;
	}	
	// calculate neighbours
	NSArray *neighbourIds = [self calculateNeighbours:user];
	// snip neighbours to K=10
	neighbourIds = [self getTopNOrLess:neighbourIds maximum:10];
	// order all neighbour repos by occurance
	NSArray *repos = [self orderUserReposByWatchOccurance:neighbourIds];
	// assign
	[self assignRepos:user :repos];
}


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

-(void)assignRepos:(User *)user repoIds:(NSArray*)repoIds {
	for(NSNumber *repoId in repoIds) {
		// test for watch list
		if([user.repos containsObject:repoId]) {
			continue;
		}
		// test for prediction list
		if([user.predictions containsObject:repoId]) {
			continue;
		}
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

// builds an occurance count (histogram) of all repos watched by users in userIds
// returns repoId set ordered by occurance count
-(NSArray *)orderUserReposByWatchOccurance:(NSArray *)userIds {
	// build an occurance count for all watched repos
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(NSNumber *userId in userIds) {
		User *user = [model.userMap objectForKey:userId];
		// process all repos
		for(NSNumber *repoId in user.repos) {
			Counter *c = [dic objectForKey:repoId];
			if(!c) {
				c = [[[Counter alloc] init] autorelease];
				[dic setObject:c forKey:repoId];
			}
			c.value++;			
		}
	}
	// order by occurance count
	NSArray *ordered = [dic keysSortedByValueUsingSelector:@selector(compareCounters:)];
	// extract 
	return ordered;
}

@end