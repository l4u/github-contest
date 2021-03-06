#import "Repository.h"

@implementation Repository

@synthesize repoId;
@synthesize date;
@synthesize fullname;
@synthesize parentId;
@synthesize languageMap;
@synthesize name;
@synthesize owner;

@synthesize forks;
@synthesize watches;
@synthesize parent;
@synthesize dominantLanguage;

@synthesize forkCount;
@synthesize watchCount;
@synthesize score;

@synthesize normalizedWatchRank;
@synthesize normalizedForkRank;
@synthesize normalizedNameRank;
@synthesize normalizedOwnerRank;

@synthesize normalizedGroupWatchRank;
@synthesize normalizedGroupForkRank;
@synthesize normalizedGroupNameRank;
@synthesize normalizedGroupOwnerRank;

@synthesize normalizedUserNameRank;
@synthesize normalizedUserOwnerRank;

@synthesize neighbours;

-(id) init {
	self = [super init];	
	
	if(self) {
		// nothing as of yet
		watches = [[NSMutableSet alloc] init];
	}
	
	return self;
}

-(id)initWithId:(NSNumber *)aId {
	self = [super init];	
	
	if(self) {		
		watches = [[NSMutableSet alloc] init];
		repoId = [aId retain];
	}
	
	return self;
}

-(void) dealloc {
	[repoId release];
	[parentId release];
	[fullname release];
	[date release];
	[languageMap release];
	[forks release];
	[parent release];
	[watches release];
	[dominantLanguage release];
	[neighbours release];
	
	[super dealloc]; // always last
}

// example: 123338:DylanFM/roro-faces,2009-05-31,13635
-(void)parse:(NSString*)repoDef {
	// main split
	NSArray *bigBits = [repoDef componentsSeparatedByString:@":"];
	// repo id
	repoId = [[NSNumber numberWithInteger:[[bigBits objectAtIndex:0] integerValue]] retain];
	// split remaining data
	NSArray *items = [[bigBits objectAtIndex:1] componentsSeparatedByString:@","];	
	fullname = [[items objectAtIndex:0] retain];
	date = [[[items objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];	
	// extract names
	NSArray *names = [fullname componentsSeparatedByString:@"/"];	
	owner = [[names objectAtIndex:0] retain];
	name = [[names objectAtIndex:1] retain];
	// parent
	if([items count] == 3) {
		parentId = [[NSNumber numberWithInteger:[[items objectAtIndex:2] integerValue]] retain];
	} 
}

// example: JavaScript;148,Ruby;16079
-(void)parseLanguage:(NSString*)langDef {
	if(languageMap && [languageMap count]) {
		[NSException raise:@"Invalid Repository Language" format:@"repository %@ already had language definition", repoId]; 
	} else {
		languageMap = [[NSMutableDictionary alloc] init];
	}
	
	NSArray *languages = [langDef componentsSeparatedByString:@","];
	
	int maxLines = -1;
	for(NSString *lang in languages) {
		NSArray *pieces = [lang componentsSeparatedByString:@";"];
		// extract
		NSString *langName = [pieces objectAtIndex:0];
		int lines = [[pieces objectAtIndex:1] integerValue];
		// store		
		NSNumber *numLines = [NSNumber numberWithInteger:lines];
		[languageMap setObject:numLines forKey:langName];
		
		if(lines > maxLines) {
			[dominantLanguage release];
			dominantLanguage = langName;
			[dominantLanguage retain];
			maxLines = lines;
		}
	}
	// NSLog(@"%@ is dominant with %i lines", dominantLanguage, maxLines);
}

-(void)addFork:(Repository *)repo {
	if(!forks) {
		forks = [[NSMutableArray alloc] init];
	}
	forkCount++;
	[forks addObject:repo];
}

-(void) addWatcher:(NSNumber *)userId {
	[watches addObject:userId];
	watchCount++;
}

-(NSComparisonResult)compareWatchCount: (id) other {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	// ensure decending
	if(watchCount > ((Repository*)other).watchCount) {
		return NSOrderedAscending;
	} else if(watchCount < ((Repository*)other).watchCount) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(NSComparisonResult)compareForkCount: (id) other {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	// ensure decending
	if(forkCount > ((Repository*)other).forkCount) {
		return NSOrderedAscending;
	} else if(forkCount < ((Repository*)other).forkCount) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(NSComparisonResult)compareScore: (id) other {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	// ensure decending
	if(score > ((Repository*)other).score) {
		return NSOrderedAscending;
	} else if(score < ((Repository*)other).score) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(NSArray *)getParentTree {
	if(!parentId) {
		return nil;
	}
	
	NSMutableArray *parentTree = [[[NSMutableArray alloc] init] autorelease];
	
	Repository *current = self;
	while(current.parent) {
		[parentTree addObject:current.parent.repoId];
		current = current.parent;
	}
	
	return parentTree;
}

-(NSArray *)getChildTree {
	if(!forkCount) {
		return nil;
	}
	
	NSMutableArray *forkTree = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *stack = [[NSMutableArray alloc] init];
	
	[stack addObject:self];
	
	while([stack count]) {
		// pop
		Repository *current = (Repository *) [stack objectAtIndex:0]; // depth first
		[stack removeObjectAtIndex:0];
		// process
		if(current.forkCount) {
			// forks of current to tree
			for(Repository *repo in current.forks) {
				[forkTree addObject:repo.repoId];		
			}			
			// we want to enumerate all forks
			[stack addObjectsFromArray:current.forks];
		}
	}
	
	[stack release];
	
	return forkTree;
}


-(void) addNeighbour:(Repository *)other {	
	// lazy create 
	if(!neighbours){
		neighbours = [[NSMutableSet alloc] init];		
	}
	
	[neighbours addObject:other.repoId];
}


// bigger is better (maximizing)
-(double)calculateRepoDistance:(Repository*)other {
	// never self
	if([other.repoId intValue] == [repoId intValue]) {
		return 0.0;
	}

	double dist = 0.0;
	
	for(NSNumber *userId in watches) {
		if([other.watches containsObject:userId]){
			dist += 1.0;
		}
	}
			
			
	return dist;
}

@end
