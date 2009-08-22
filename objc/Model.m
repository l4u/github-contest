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
	// first order data
	[self loadRepos];
	[self loadRepoLanguages];
	[self loadRepoUserRelationships];
	[self loadTestUsers];
	// second order pre-calculations
	// ...
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
		NSArray *pieces = [line componentsSeparatedByString:@":"];
		NSNumber *repoKey = [NSNumber numberWithInteger:[[pieces objectAtIndex:0] integerValue]];
		Repository *repo = [repositoryMap objectForKey:repoKey];
		if(repo == nil) {
			NSLog(@">Repository %@ has language definition, but was not previously defined", repoKey);
			repo = [[Repository alloc] initWithId:[repoKey intValue]];
			[repositoryMap setObject:repo forKey:repoKey];
		}
		// process language data
		[repo parseLanguage:[pieces objectAtIndex:1]];
	}
	
	NSLog(@"Finished loading %i repository language definitions", [lines count]);
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

-(void) loadTestUsers {
	// load file 
	NSString *fileString = [NSString stringWithContentsOfFile:@"../data/test.txt" encoding:NSASCIIStringEncoding error:NULL]; 
	// each line, adjust character for line endings
	NSArray *lines = [fileString componentsSeparatedByString:@"\n"]; 

	// process all lines
	for(NSString *line in lines) {
		if([line length]<= 0) {
			continue;
		}
		NSNumber *userKey = [NSNumber numberWithInteger:[line integerValue]];
		// get user
		User *user = [userMap objectForKey:userKey];
		if(!user) {
			user = [[User alloc] initWithId:[userKey intValue]];
			[userMap setObject:user forKey:userKey];			
			NSLog(@">Users %@ is test but was not previously defined", userKey);
		}
		// user is test
		user.test = YES;
	}
	
	NSLog(@"Finished loading %i test users", [lines count]);
}

-(NSMutableDictionary*)repositoryMap {
    return repositoryMap;
}
-(NSMutableDictionary*)userMap {
    return userMap;
}

@end
