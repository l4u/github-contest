#import "Strategy.h"

@implementation Strategy

@dynamic model;

-(id)initWithModel:(Model *)aModel {
	self = [super init];	
	
	if(self) {
		model = aModel;
		[aModel retain];
	}
	
	return self;
}

-(void) dealloc {
	[model release];
	
	[super dealloc]; // always last
}

-(Model *)model {
	return model;
}

-(void)calculatePredictions {
	NSLog(@"calculating predictions...");
	
	
}



@end