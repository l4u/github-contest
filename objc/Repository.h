
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
    int repoId, parentId;
	NSString *date, *fullname;
	NSMutableDictionary *languageMap;
}

@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, nonatomic) NSString *date, *fullname;
@property(readonly, nonatomic) NSMutableDictionary *languageMap;

-(id)initWithId:(int)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

@end