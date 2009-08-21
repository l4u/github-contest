#import "User.h"

@implementation User
@dynamic userId;


-(id) initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		userId = aId;
	}
	
	return self;
}

-(void) dealloc {
	
	[super dealloc]; // always last
}

-(int)userId {
    return userId;
}

@end
