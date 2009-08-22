
#import <Foundation/Foundation.h>

@interface User : NSObject {
@private
    int userId;
	NSMutableSet *repos;
	BOOL test;
}

@property(readonly, nonatomic) int userId;
@property(readonly, nonatomic) NSMutableSet *repos;
@property(nonatomic) BOOL test;

-(id)initWithId:(int)aId;
-(void) addRepository:(NSNumber *)aRepoId;

@end
