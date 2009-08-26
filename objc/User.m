#import "User.h"

@implementation User

@synthesize userId;
@synthesize repos;
@synthesize test;
@synthesize predictions;
@synthesize neighbours;
@synthesize neighbourhoodRepos;
@synthesize numWithLanguage;
@synthesize neighbourhoodWatchName;
@synthesize neighbourhoodWatchOwner;

@synthesize numNeighbours;
@synthesize numForked;
@synthesize numRoot;
@synthesize numWatched;
@synthesize numNeighbourhoodWatched;
@synthesize ownerSet;
@synthesize nameSet;
@synthesize languageSet;

-(id) initWithId:(NSNumber *)aId {
	self = [super init];	
	
	if(self) {
		userId = [aId retain];
	}
	
	return self;
}

-(void) dealloc {
	[userId release];
	[repos release];
	[predictions release];
	[neighbours release];
	[neighbourhoodRepos release];
	[languageSet release];
	[neighbourhoodWatchOwner release];
	[neighbourhoodWatchName release];
	
	[super dealloc]; // always last
}

-(void) addRepository:(NSNumber *)aRepoId {
	// lazy create
	if(!repos) {
		repos = [[NSMutableSet alloc] init];
	}
	[repos addObject:aRepoId];
}

-(void) addPrediction:(NSNumber *)aRepoId {
	// lazy create
	if(!predictions) {
		predictions = [[NSMutableSet alloc] init];
	}
	[predictions addObject:aRepoId];
}

-(void) addNeighbour:(User *)other {	
	// lazy create 
	if(!neighbours){
		neighbours = [[NSMutableSet alloc] init];		
		neighbourhoodRepos = [[NSCountedSet alloc] init];
	}
	
	[neighbours addObject:other.userId];
	numNeighbours++;
	
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


-(void) calculateStats:(NSDictionary *)repositoryMap {
	numWatched = [repos count];
	ownerSet = [[NSCountedSet alloc] init];
	nameSet = [[NSCountedSet alloc] init];	
	languageSet = [[NSCountedSet alloc] init];
	
	// process repos
	for(NSNumber *repoId in repos) {
		Repository *repo = [repositoryMap objectForKey:repoId];
		// forked
		if(repo.forks > 0) {
			numForked++;			
		}
		// root
		if(!repo.parentId) {
			numRoot++;
		}
		// language
		if(repo.languageMap != nil) {
			numWithLanguage++;
			[languageSet addObject:repo.dominantLanguage];
		}
		[ownerSet addObject:repo.owner];
		[nameSet addObject:repo.name];
	}
	
	// process neighbour repos
	if(numNeighbours){
		
		numNeighbourhoodWatched = 0;
		neighbourhoodWatchName = [[NSCountedSet alloc] init];
		neighbourhoodWatchOwner = [[NSCountedSet alloc] init];

		for(NSNumber *repoId in neighbourhoodRepos) {	
			Repository *repo = [repositoryMap objectForKey:repoId];		
			// model of name watches
			[neighbourhoodWatchName addObject:repo.name];			
			// model of owner watches
			[neighbourhoodWatchOwner addObject:repo.owner];
			// total neighbourhood watches
			numNeighbourhoodWatched += [neighbourhoodRepos countForObject:repoId];
		}
	}	
}

-(int)neighbourhoodOccurance:(NSNumber *)repoId {
	if(numNeighbours) {
		return [neighbourhoodRepos countForObject:repoId];
	}
	
	return 0;
}



@end
