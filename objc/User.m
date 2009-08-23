#import "User.h"

@implementation User

@dynamic userId;
@dynamic repos;
@synthesize test;
@dynamic predictions;
@dynamic neighbours;

-(id) initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		test = NO;
		userId = aId;
		repos = [[NSMutableSet alloc] init];
		predictions = [[NSMutableSet alloc] init];
		neighbours = [[NSMutableSet alloc] init];
		neighbourhoodRepos = [[NSCountedSet alloc] init];
	}
	
	return self;
}

-(void) dealloc {
	[repos release];
	[predictions release];
	[neighbours release];
	[neighbourhoodRepos release];
	
	[super dealloc]; // always last
}

-(int)userId {
    return userId;
}

-(NSMutableSet *)repos {
    return repos;
}

-(void) addRepository:(NSNumber *)aRepoId {
	// if([repos containsObject:aRepoId]) {
	// 	[NSException raise:@"Invalid Repository Id" format:@"repository %@ already used by user %i", aRepoId, userId]; 
	// }
	[repos addObject:aRepoId];
}

-(void) addPrediction:(NSNumber *)aRepoId {
	// cannot be used or predicted
	// if([repos containsObject:aRepoId]) {
	// 	[NSException raise:@"Invalid Predicted Repository Id" format:@"repository %@ cannot be predicted, already used by user %i", aRepoId, userId]; 
	// } else if([predictions containsObject:aRepoId]) {
	// 	[NSException raise:@"Invalid Predicted Repository Id" format:@"repository %@ already predicted for user %i", aRepoId, userId]; 
	// } else if([predictions count] > 10) {
	// 	[NSException raise:@"Invalid Predicted Repository Id" format:@"user %i already has %i predictions.", userId, [predictions count]]; 		
	// }
	
	[predictions addObject:aRepoId];
}

-(void) addNeighbour:(User *)other {	
	[neighbours addObject:[NSNumber numberWithInteger:other.userId]];
	// add neighbourhood repos
	for(NSNumber *repoId in user.repos) {
		[neighbourhoodRepos addObject:repoId];
	}
}

-(NSMutableSet *)predictions {
    return predictions;
}
-(NSMutableSet *)neighbours {
    return neighbours;
}

// userId:repoId,repoId,repoId,...
-(NSString *) getPredictionAsString {
	NSMutableString *buffer = [[[NSMutableString alloc] init] autorelease];
	[buffer appendString:[NSString stringWithFormat:@"%i:", userId]];
	
	int i = 0;
	for(NSNumber *num in predictions) {
		[buffer appendString:[NSString stringWithFormat:@"%@", num]];		
		if(i != [predictions count]-1) {
			[buffer appendString:@","];
		}
		i++;
	}
		
	return buffer;
}

// linear model for now
// ideally, this would be a pre-learned classifier for the cluster or even user
-(double)probabilityUserWillWatchRepo:(Repository *)repo {
	
	double score = 0.0;
	
	// preference for root repos
	if(repo.parentId == 0) {
		score += 1.0;	
	}

	// watch global popularity
	score += (repo.normalizedWatchRank * 1.0);
	// fork global popularity
	score += (repo.normalizedForkRank * 0.5);
	
	// exists in neighbourhood
	if([neighbourhoodRepos containsObject:[NSNumber numberWithInt:repo.repoId]]) {
		score += 1.0;
	}
	
	// neighbourhood popularity (occurance rank?)	
	
	// consider: candidate set popularity (rank from duplicate recommendations from sources)
	
	// watching other things with  by this author?
	
	// watch other things with this name?
	
	// 
	
	return score;
}

// bigger is better (maximizing)
-(double)calculateUserDistance:(User*)other {
	// never self
	if(other.userId == userId) {
		return 0.0;
	}
	// check for useless comparison
	if([other.repos count] <= 0) {
		return 0.0;
	}
	double dist = 0.0;
	
	// self against other
	for(Repository *repo_id in repos) {
		// count exact repo matches
		if([other.repos containsObject:repo_id]) {
			dist += 1.0;
		}
		// count soft repo matches
	
		// count vauge repo matches
		
	}	
	return dist;
}

-(NSNumber *)neighbourhoodOccurance(NSNumber *repoId) {
	return [neighbourhoodRepos countForObject:repoId];
}

@end
