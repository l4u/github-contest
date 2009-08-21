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

-(void) dealloc {
	[fullname release];
	[date release];
	
	[super dealloc]; // always last
}


// example: 123338:DylanFM/roro-faces,2009-05-31,13635
-(void)parse:(NSString*)repoDef {
	
	// must be a better way to process strings?

	// no error checking, we know the data is good right?	
	NSArray *bigBits = [repoDef componentsSeparatedByString:@":"];
	repoId = [[bigBits objectAtIndex:0] integerValue];
	
	NSArray *items = [[bigBits objectAtIndex:1] componentsSeparatedByString:@","];
	NSLog([items objectAtIndex:0]);
	fullname = [[NSString alloc] initWithString:[items objectAtIndex:0]];
	date = [NSString stringWithString:[items objectAtIndex:1]];

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
