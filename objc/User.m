#import "User.h"

@implementation User

@dynamic userId;
@dynamic repos;
@synthesize test;
@dynamic predictions;

-(id) initWithId:(int)aId {
	self = [super init];	
	
	if(self) {
		test = NO;
		userId = aId;
		repos = [[NSMutableSet alloc] init];
		predictions = [[NSMutableSet alloc] init];
	}
	
	return self;
}

-(void) dealloc {
	[repos release];
	[predictions release];
	
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

-(void) addPrediction:(NSNumber *)aRepoId {
	// cannot be used or predicted
	if([repos containsObject:aRepoId]) {
		[NSException raise:@"Invalid Predicted Repository Id" format:@"repository %@ cannot be predicted, already used by user %i", aRepoId, userId]; 
	} else if([predictions containsObject:aRepoId]) {
		[NSException raise:@"Invalid Predicted Repository Id" format:@"repository %@ already predicted for user %i", aRepoId, userId]; 
	} else if([predictions count] > 10) {
		[NSException raise:@"Invalid Predicted Repository Id" format:@"user %i already has %i predictions.", userId, [predictions count]]; 		
	}
	
	[predictions addObject:aRepoId];
}

-(NSMutableSet *)predictions {
    return predictions;
}

-(NSString *) getPredictionAsString {
	NSMutableString *buffer = [[[NSMutableString alloc] init] autorelease];
	[buffer appendString:[NSString stringWithFormat:@"%i:", userId]];
	
	int i = 0;
	for(NSNumber *num in predictions) {
		[buffer appendString:[NSString stringWithFormat:@"%i", num]];		
		if(i != [predictions count]-1) {
			[buffer appendString:@","];
		}
		i++;
	}
		
	return buffer;
}

@end
