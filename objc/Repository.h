
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
    int repoId, parentId;
	NSString *date, *fullname;
}

@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, copy, nonatomic) NSString *date, *fullname;

-(void)parse:(NSString*)repoDef;

@end