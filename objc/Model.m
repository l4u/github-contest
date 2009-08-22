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
	NSLog(@"Total Users:...%i", [userMap count]);
}

-(void) loadModel {
	[self loadRepos];
	[self loadRepoLanguages];
	[self loadRepoUserRelationships];
}

-(void) loadRepos {	
	// load file 
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
	
	NSLog(@"Finished loading %i repositories", [repositoryMap count]);
}

-(void) loadRepoLanguages {
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/lang.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		// get repo
		
		// process language data
	}
	
	NSLog(@"Finished loading %i repository langauge definitions", [lines count]);
}

-(void) loadRepoUserRelationships {	
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/data.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		// <user_id>:<repo_id>
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *userKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];
		NSNumber *repoKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:1] integerValue]];		
		// get repo
		Repository *repo = [repositoryMap objectForKey:repoKey];
		if(repo == nil) {
			NSLog(@">Repository %@ specified in relationship did not exist", repoKey);
			repo = [[Repository alloc] initWithId:[repoKey intValue]];
			[repositoryMap setObject:repo forKey:repoKey];
		}
		// get user
		User *user = [userMap objectForKey:userKey];
		if(!user) {
			user = [[User alloc] initWithId:[userKey intValue]];
			[userMap setObject:user forKey:userKey];			
		}
		// add user to repo
			// do we need this?
		
		// add repo to user
		[user addRepository:repoKey];
	}
	
	NSLog(@"Finished loading %i user-repositories relationships", [lines count]);
}


-(NSMutableDictionary*)repositoryMap {
    return repositoryMap;
}
-(NSMutableDictionary*)userMap {
    return userMap;
}

@end
