
#import <Foundation/Foundation.h>

@interface User : NSObject {
@private
    int userId;
}

@property(readonly) int userId;
-(id)initWithId:(int)initUserId;

@end
