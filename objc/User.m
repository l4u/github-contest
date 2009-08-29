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
@synthesize deducedName;

@synthesize numNeighbours;
@synthesize numForked;
@synthesize numRoot;
@synthesize numWatched;
@synthesize numNeighbourhoodWatched;
@synthesize ownerSet;
@synthesize nameSet;
@synthesize languageSet;
@synthesize watchedParents;



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
	[deducedName release];
	[watchedParents release];
	
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

// minimizing is better
-(double)calculateUserDistance:(User*)other {
	double distance = 0.0;
	
	int numRepos = [repos count];
	int numOtherRepos = [other.repos count];
	
	// attempt to do the least work
	
	if(numRepos < numOtherRepos) {
		distance += (numOtherRepos - numRepos);
		
		for(Repository *repo_id in repos) {
			if(![other.repos containsObject:repo_id]) {
				distance += 1.0;
			}
		}
		
	} else if(numRepos > numOtherRepos){
		distance += (numRepos - numOtherRepos);
		
		for(Repository *repo_id in other.repos) {
			if(![repos containsObject:repo_id]) {
				distance += 1.0;
			}
		}
		
	} else{
		for(Repository *repo_id in repos) {
			if(![other.repos containsObject:repo_id]) {
				distance += 1.0;
			}
		}
	}
	
	return distance;
}

/*
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
		// TODO
		// count vauge repo matches (project compsition)
		// TODO
	}	
	
	// consider user watched set size
			
	return dist;
}
*/

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
	watchedParents = [[NSMutableSet alloc] init];
	
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
		} else {
			[watchedParents addObject:repo.parentId];
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
		NSArray *tmp = [userrepos sortedArrayUsingFunction:neighbourhoodNameSort context:nameSet];
		int i = 0;	
		int total = [tmp count];
		for(Repository *repo in tmp) {
			double rank = (double)(total-i) / (double)total;
			repo.normalizedUserNameRank = rank;
			i++;		
		}
		// user owner rank
		tmp = [userrepos sortedArrayUsingFunction:neighbourhoodOwnerSort context:ownerSet];
		i = 0;		
		total = [tmp count];
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(total-i) / (double)total;
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
		int total = [tmp count];
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(total-i) / (double)total;
			repo.normalizedGroupNameRank = rank;
			i++;		
		}
		// neighbourhood owner rank
		tmp = [neighbourhood sortedArrayUsingFunction:neighbourhoodOwnerSort context:neighbourhoodWatchOwner];
		i = 0;		
		total = [tmp count];
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(total-i) / (double)total;
			repo.normalizedGroupOwnerRank = rank;
			i++;		
		}
		// neighbourhood watch rank
		tmp = [neighbourhood sortedArrayUsingFunction:neighbourhoodWatchSort context:neighbourhoodRepos];
		i = 0;		
		total = [tmp count];
		for(Repository *repo in tmp) {
			// set rank (decending)
			double rank = (double)(total-i) / (double)total;
			repo.normalizedGroupWatchRank = rank;
			i++;
		}		
		
		[neighbourhood release];
	}	
	
}


-(void) deduceName:(NSDictionary *)repositoryMap {
	int match = 0;
	
	for(NSNumber *repoId in repos) {
		Repository *repo = [repositoryMap objectForKey:repoId];
		// no parent, no children, only one watcher
		if(!repo.parentId && !repo.forkCount, repo.watchCount==1) {
			if(match) {
				// an alternatve hypothesis is that other users are watching and not in this dataset
				if(![deducedName isEqualToString:repo.owner]) {
					//NSLog(@" > conflict on name resolution, id=%@, first=%@ new=%@", userId, deducedName, repo.owner);
					deducedName = nil;
					return;
				} else {
					match++;
				}
			} else {
				deducedName = repo.owner;
				match++;
			}			
		}
	}
	
	//only match if we multiple hits
	if(match < 2) {
		deducedName = nil;
	}
}
	

-(int)neighbourhoodOccurance:(NSNumber *)repoId {
	if(numNeighbours) {
		return [neighbourhoodRepos countForObject:repoId];
	}
	
	return 0;
}



@end
