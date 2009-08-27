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

NSInteger neighbourhoodNameSort(id o1, id o2, void *context) {
	NSCountedSet *model = (NSCountedSet *) context;
	
	int v1 = [model countForObject:((Repository*)o1).name];
	int v2 = [model countForObject:((Repository*)o2).name];
	
	// ensure decending
	if(v1 > v2) {
		return NSOrderedAscending;
	} else if(v2 < v2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

NSInteger neighbourhoodOwnerSort(id o1, id o2, void *context) {
	NSCountedSet *model = (NSCountedSet *) context;
	
	int v1 = [model countForObject:((Repository*)o1).owner];
	int v2 = [model countForObject:((Repository*)o2).owner];
	
	// ensure decending
	if(v1 > v2) {
		return NSOrderedAscending;
	} else if(v2 < v2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

NSInteger neighbourhoodWatchSort(id o1, id o2, void *context) {
	NSCountedSet *model = (NSCountedSet *) context;
	
	int v1 = [model countForObject:((Repository*)o1).repoId];
	int v2 = [model countForObject:((Repository*)o2).repoId];
	
	// ensure decending
	if(v1 > v2) {
		return NSOrderedAscending;
	} else if(v2 < v2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(void) calculateStats:(NSDictionary *)repositoryMap {
	numWatched = [repos count];
	ownerSet = [[NSCountedSet alloc] init];
	nameSet = [[NSCountedSet alloc] init];	
	languageSet = [[NSCountedSet alloc] init];
	
	NSMutableArray *userrepos = [[NSMutableArray alloc] init];
	
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
		
		[userrepos addObject:repo];
	}
	
	// scope var hacking
	{
		// user name rank
		NSArray * tmp = [userrepos sortedArrayUsingFunction:neighbourhoodNameSort context:nameSet];
		int i = 0;		
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(numWatched-i) / (double)numWatched;
			repo.normalizedUserNameRank = rank;
			i++;		
		}
		// user owner rank
		tmp = [userrepos sortedArrayUsingFunction:neighbourhoodOwnerSort context:ownerSet];
		i = 0;		
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(numWatched-i) / (double)numWatched;
			repo.normalizedUserOwnerRank = rank;
			i++;
		}
	}
	[userrepos release];
	
	
	
	
	// process neighbour repos
	if(numNeighbours){
		NSMutableArray *neighbourhood = [[NSMutableArray alloc] init];
		
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
			
			[neighbourhood addObject:repo];
		}
		
		// neighbourhood name rank
		NSArray * tmp = [neighbourhood sortedArrayUsingFunction:neighbourhoodNameSort context:neighbourhoodWatchName];
		int i = 0;		
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(numNeighbours-i) / (double)numNeighbours;
			repo.normalizedGroupNameRank = rank;
			i++;		
		}
		// neighbourhood owner rank
		tmp = [neighbourhood sortedArrayUsingFunction:neighbourhoodOwnerSort context:neighbourhoodWatchOwner];
		i = 0;		
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(numNeighbours-i) / (double)numNeighbours;
			repo.normalizedGroupOwnerRank = rank;
			i++;		
		}
		// neighbourhood watch rank
		tmp = [neighbourhood sortedArrayUsingFunction:neighbourhoodWatchSort context:neighbourhoodRepos];
		i = 0;		
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(numNeighbours-i) / (double)numNeighbours;
			repo.normalizedGroupWatchRank = rank;
			i++;
		}		
		
		[neighbourhood release];
	}	
	
	
	
	
	

}




-(int)neighbourhoodOccurance:(NSNumber *)repoId {
	if(numNeighbours) {
		return [neighbourhoodRepos countForObject:repoId];
	}
	
	return 0;
}



@end
