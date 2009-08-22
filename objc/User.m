#import "User.h"

@implementation User

@dynamic userId;
@dynamic repos;
@synthesize test;


-(id) initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		test = NO;
		userId = aId;
		repos = [[[NSMutableSet alloc] init] retain];
	}
	
	return self;
}

-(void) dealloc {
	[repos release];
	
	[super dealloc]; // always last
}

-(int)userId {
    return userId;
}

-(NSMutableSet *)repos {
    return repos;
}

-(void) addRepository:(NSNumber *)aRepoId {
	if([repos containsObject:aRepoId]) {
		[NSException raise:@"Invalid Repository Id" format:@"repository %@ already used by user %i", aRepoId, userId]; 
	}
	[repos addObject:aRepoId];
}



@end
