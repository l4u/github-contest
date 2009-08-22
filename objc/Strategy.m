#import "Strategy.h"


// random numbers: http://stackoverflow.com/questions/160890/generating-random-numbers-in-objective-c

@implementation Strategy

@dynamic model;

-(id)initWithModel:(Model *)aModel {
	self = [super init];	
	
	if(self) {		
		model = aModel;
		top10 = nil;
		[aModel retain];
		// random numbers
		srandom(time(NULL));
	}
	
	return self;
}

-(void) dealloc {
	[model release];
	[top10 release];
	
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
		//[self randomStrategy:user allRepoKeys:allKeys];
		
		// top 10 strategy
		//[self top10Strategy:user];
		
		// top 10 repos in user's neighbourhood
		[self top10NeighbourhoodStrategy:user];
	}
}


-(void)top10NeighbourhoodStrategy:(User *)user {
	// user must have repos
	if([user.repos count] <= 0) {
		return;
	}	
	// calculate neighbours
	NSArray *neighbourIds = [self calculateNeighbours:user];
	// snip neighbours to K=10
	neighbourIds = [self getTop10OrLess:neighbourIds];
	// order all neighbour repos by occurance
	NSArray *repos = [self orderUserReposByWatchOccurance:neighbourIds];
	// snip off the top 10 most watched
	repos = [self getTop10OrLess:repos];
	// assign
	[user.predictions addObjectsFromArray:repos];
}

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

- (NSArray *)reversedArray:(NSArray *)other {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[other count]];
    NSEnumerator *enumerator = [other reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

// assign each user the top 10 most popular repos
-(void)top10Strategy:(User *)user {
	if(!top10) {
		top10 = [[self getTop10Repos] retain]; 
	}
	// assign
	[user.predictions addObjectsFromArray:top10];
}

-(NSArray *)getTop10OrLess:(NSArray *)someArray {
	// snip off the top 10 most watched
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	int i = 0;
	for(i=0; i<10 && i<[someArray count]; i++) {
		[array addObject:[someArray objectAtIndex:i]];
	}
	return array;
}

-(NSArray *)getTop10Repos {
	// order all repos by occurance
	NSArray *all = [self orderUserReposByWatchOccurance:[model.userMap allKeys]];
	// snip off the top 10 most watched
	return [self getTop10OrLess:all];
}

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



// random strategy (for process testing)
// select random repos not in the users 'watch' set or in the users predicted set
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

@end