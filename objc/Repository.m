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

@synthesize forkCount;
@synthesize watchCount;
@synthesize score;


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
	
	for(NSString *lang in languages) {
		NSArray *pieces = [lang componentsSeparatedByString:@";"];
		// store
		NSNumber *numLines = [NSNumber numberWithInteger:[[pieces objectAtIndex:1] integerValue]];
		[languageMap setObject:numLines forKey:[pieces objectAtIndex:0]];
	}
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

@end
