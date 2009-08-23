
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
	// data
    int repoId, parentId;
	NSString *date, *fullname;
	NSMutableDictionary *languageMap;	
	// indicators
	int watchCount;
	int forkCount;
}

// data
@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, nonatomic) NSString *date, *fullname;
@property(readonly, nonatomic) NSMutableDictionary *languageMap;
// indicators
@property(readwrite, nonatomic) int watchCount;
@property(readwrite, nonatomic) int forkCount;


-(id)initWithId:(int)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

// compare indicators
-(NSComparisonResult)compareForkCount: (id) other;
-(NSComparisonResult)compareWatchCount: (id) other;

@end