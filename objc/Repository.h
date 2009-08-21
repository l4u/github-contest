
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
    int repoId;
	NSString *date;
	NSString *fullname;
	int parentId;
}

@property(readonly) int repoId;
@property(readonly) NSString * date;
@property(readonly) NSString * fullname;
@property(readonly) int parentId;

-(void)parse:(NSString*)repoDef;

@end