#import "Repository.h"

@implementation Repository

@dynamic repoId;
@dynamic date;
@dynamic fullname;
@dynamic parentId;
@dynamic languageMap;

-(id) init {
	self = [super init];	
	
	if(self) {
		repoId = 0;
		date = nil;
		fullname = nil;
		parentId = 0;
		languageMap = nil;
	}
	
	return self;
}

-(id)initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		date = nil;
		fullname = nil;
		parentId = 0;
		languageMap = nil;
		repoId = aId;
	}
	
	return self;
}

-(void) dealloc {
	[fullname release];
	[date release];
	[languageMap release];
	
	[super dealloc]; // always last
}


// example: 123338:DylanFM/roro-faces,2009-05-31,13635
-(void)parse:(NSString*)repoDef {
	
	// must be a better way to process strings?

	NSArray *bigBits = [repoDef componentsSeparatedByString:@":"];
	repoId = [[bigBits objectAtIndex:0] integerValue];
	
	NSArray *items = [[bigBits objectAtIndex:1] componentsSeparatedByString:@","];	
	fullname = [[[NSString stringWithString:[items objectAtIndex:0]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
	date = [[[NSString stringWithString:[items objectAtIndex:1]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
	
	if([items count] == 3) {
		parentId = [[items objectAtIndex:2] integerValue];
	} 
}

// example: JavaScript;148,Ruby;16079
-(void)parseLanguage:(NSString*)langDef {
	if(languageMap && [languageMap count]) {
		[NSException raise:@"Invalid Repository Language" format:@"repository %@ already had language definition", repoId]; 
	} else {
		languageMap = [[[NSMutableDictionary alloc] init] retain];
	}
	
	NSArray *languages = [langDef componentsSeparatedByString:@","];
	
	for(NSString *lang in languages) {
		NSArray *pieces = [lang componentsSeparatedByString:@";"];
		// store
		NSNumber *numLines = [NSNumber numberWithInteger:[[pieces objectAtIndex:1] integerValue]];
		[languageMap setObject:numLines forKey:[pieces objectAtIndex:0]];
	}
}

-(int)repoId {
    return repoId;
}

-(NSString*)date {
    return date;
}

-(NSString*)fullname {
    return fullname;
}

-(int)parentId {
    return parentId;
}

-(NSMutableDictionary *)languageMap {
	return languageMap;
}

@end
