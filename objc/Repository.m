#import "Repository.h"

@implementation Repository

@dynamic repoId;
@dynamic date;
@dynamic fullname;
@dynamic parentId;


-(id) init {
	self = [super init];	
	
	if(self) {
		
	}
	
	return self;
}

-(id)initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		repoId = aId;
	}
	
	return self;
}

-(void) dealloc {
	[fullname release];
	[date release];
	
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

@end
