
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
    int repoId, parentId;
	NSString *date, *fullname;
}

@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, nonatomic) NSString *date, *fullname;

-(id)initWithId:(int)aId;
-(void)parse:(NSString*)repoDef;

@end