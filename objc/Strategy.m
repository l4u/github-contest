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
	[model release];
	
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
		[self randomStraetgy:user allRepoKeys:allKeys];
	}
}

// random strategy (for process testing)
// select random repos not in the users 'watch' set or in the users predicted set
-(void)randomStraetgy:(User *)user allRepoKeys:(NSArray *)allRepoKeys {	
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