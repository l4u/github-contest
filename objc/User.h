
#import <Foundation/Foundation.h>

@interface User : NSObject {
@private
    int userId;
	NSMutableSet *repos;
}

@property(readonly) int userId;
@property(readonly) NSMutableSet *repos;


-(id)initWithId:(int)aId;
-(void) addRepository:(NSNumber *)aRepoId;

@end
