
#import <Foundation/Foundation.h>

@interface User : NSObject {
@private
    int userId;
	NSMutableSet *repos;
	BOOL test;
	NSMutableSet *predictions;
}

@property(readonly, nonatomic) int userId;
@property(readonly, nonatomic) NSMutableSet *repos;
@property(nonatomic) BOOL test;
@property(readonly, nonatomic) NSMutableSet *predictions;

-(id)initWithId:(int)aId;
-(void) addRepository:(NSNumber *)aRepoId;
-(NSString *) getPredictionAsString;

@end
