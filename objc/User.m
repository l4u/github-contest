#import "User.h"

@implementation User
@dynamic userId;

-(id)initWithId:(int)initUserId {
    userId = initUserId;
    return self;
}

-(int)userId {
    return userId;
}
@end
