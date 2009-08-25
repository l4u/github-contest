#import "User.h"

@implementation User

@synthesize userId;
@synthesize repos;
@synthesize test;
@synthesize predictions;
@synthesize neighbours;
@synthesize neighbourhoodRepos;

-(id) initWithId:(NSNumber *)aId {
	self = [super init];	
	
	if(self) {
		test = NO;
		userId = [aId retain];
		repos = [[NSMutableSet alloc] init];
		predictions = [[NSMutableSet alloc] init];
		neighbours = [[NSMutableSet alloc] init];
		neighbourhoodRepos = [[NSCountedSet alloc] init];
	}
	
	return self;
}

-(void) dealloc {
	[userId release];
	[repos release];
	[predictions release];
	[neighbours release];
	[neighbourhoodRepos release];
	
	[super dealloc]; // always last
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
	[neighbours addObject:other.userId];
	// add neighbourhood repos
	for(NSNumber *repoId in other.repos) {
		[neighbourhoodRepos addObject:repoId];
	}
}

// userId:repoId,repoId,repoId,...
-(NSString *) getPredictionAsString {
	NSMutableString *buffer = [[[NSMutableString alloc] init] autorelease];
	[buffer appendString:[NSString stringWithFormat:@"%@:", userId]];
	
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

// bigger is better (maximizing)
-(double)calculateUserDistance:(User*)other {
	// never self
	if([other.userId intValue] == [userId intValue]) {
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
		// count soft repo matches (ansestor, sibling, or child)
	
		// count vauge repo matches (project compsition)
		
	}	
	
	// consider user watched set size
		
	
	return dist;
}

-(int)neighbourhoodOccurance:(NSNumber *)repoId {
	return [neighbourhoodRepos countForObject:repoId];
}

-(int) neighbourhoodTotalWatches {
	int total = 0;
	for(NSNumber *repoId in neighbourhoodRepos) {
		total += [neighbourhoodRepos countForObject:repoId];
	}
	return total;
}

-(int) neighbourhoodTotalWatchesForOwner:(NSString *)owner repositoryMap:(NSMutableDictionary *)repositoryMap {
	int total = 0;
	for(NSNumber *repoId in neighbourhoodRepos) {
		if([((Repository *)[repositoryMap objectForKey:repoId]).owner isEqualToString:owner]==YES){
			total += [neighbourhoodRepos countForObject:repoId];
		}
	}
	return total;
}

-(int) neighbourhoodTotalWatchesForName:(NSString *)name repositoryMap:(NSMutableDictionary *)repositoryMap {
	int total = 0;
	for(NSNumber *repoId in neighbourhoodRepos) {
		if([((Repository *)[repositoryMap objectForKey:repoId]).name isEqualToString:name]==YES){
			total += [neighbourhoodRepos countForObject:repoId];
		}
	}
	return total;
}

@end
