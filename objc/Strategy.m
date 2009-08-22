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
	
	NSArray *allKeys = [model.repositoryMap allKeys];
	
	for(User *user in model.testUsers) {
		// random strategy 
		//[self randomStrategy:user allRepoKeys:allKeys];
		// top 10 strategy
		[self top10Strategy:user allRepoKeys:allKeys];
	}
}

// assign each user the top 10 most popular repos
-(void)top10Strategy:(User *)user allRepoKeys:(NSArray *)allRepoKeys {
	if(!top10) {
		top10 = [[self getTop10Repos] retain]; 
	}
	// assign
	[user.predictions addObjectsFromArray:top10];
}

-(NSArray *)getTop10Repos {
	// order all repos by occurance
	NSArray *all = [self orderUserReposByWatchOccurance:[model.userMap allValues]];
	// snip off the top 10 most watched
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	int i = 0;
	for(i=0; i<10; i++) {
		[array addObject:[all objectAtIndex:i]];
	}
	return array;
}

-(NSArray *)orderUserReposByWatchOccurance:(NSArray *)userList {
	// build an occurance count for all watched repos
	NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
	// process all users
	for(User *user in userList) {
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