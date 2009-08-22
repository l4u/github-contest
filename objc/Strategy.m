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
		[self calculateTop10Repos];
	}
	// assign
	[user.predictions addObjectsFromArray:top10];
}

-(void)calculateTop10Repos {
	// build an occurance count for all watched repos
	NSMutableDictionary *dic = [[NSMutableDictionary dictionaryWithCapacity:120872] retain];
	// process all users
	for(User *user in [model.userMap allValues]) {
		// process all repos
		for(NSNumber *repoId in user.repos) {
			Counter *c = [dic objectForKey:repoId];
			if(!c) {
				c = [[Counter alloc] init];
				[dic setObject:c forKey:repoId];
			}
			c.value++;			
		}
	}
	// order by occurance count
	NSArray *ordered = [dic keysSortedByValueUsingSelector:@selector(compareCounters:)];
	
	// prep top 10
	top10 = [[NSMutableArray arrayWithCapacity:10] retain];
	int i = 0;
	for(i=0; i<10; i++) {
		[top10 addObject:[ordered objectAtIndex:i]];
		NSLog(@" rank is %i with occurance %i", i, ((Counter *)[dic objectForKey:[ordered objectAtIndex:i]]).value);
	}
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