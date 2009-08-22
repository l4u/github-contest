#import "Counter.h"

@implementation Counter

@synthesize value;

-(id) initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		value = 0;
	}
	
	return self;
}


-(NSComparisonResult)compareCounters: (id) other {
	// The comparator method should return NSOrderedAscending 
	// if the receiver is smaller than the argument, NSOrderedDescending 
	// if the receiver is larger than the argument, and NSOrderedSame if they are equal.
	
	// ensure decending
	if(value > ((Counter*)other).value) {
		return NSOrderedAscending;
	} else if(value < ((Counter*)other).value) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end