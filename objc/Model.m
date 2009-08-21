#import "Model.h"

@implementation Model

// properties
@dynamic repositoryMap;
@dynamic userMap;

-(id) init {
	self = [super init];	
	
	if(self) {
		repositoryMap = [[NSMutableDictionary dictionaryWithCapacity:121000] retain];
		userMap = [[NSMutableDictionary dictionaryWithCapacity:20000] retain];
	}
	
	return self;
}

-(void) dealloc {
	[repositoryMap dealloc];
	[userMap dealloc];
	
	[super dealloc]; // always last
}

-(void) printStats {
	NSLog(@"Total Repositories:...%i", [repositoryMap count]);
}

-(void) loadRepos {	
	// reads file into memory as an NSString
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/repos.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		Repository *repo = [[Repository alloc] init];
		[repo parse:line];
		
		NSNumber *key = [NSNumber numberWithInteger:repo.repoId];
		if([repositoryMap objectForKey:key]) {
			NSLog(@">Duplicate repository with key: %@", key);
			continue;
		}
		[repositoryMap setObject:repo forKey:key];		
	}
	
	NSLog(@"Finished loading %i repositories in %i seconds", [repositoryMap count], 1);
}


-(NSMutableDictionary*)repositoryMap {
    return repositoryMap;
}
-(NSMutableDictionary*)userMap {
    return userMap;
}

@end
