
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
	// data
	int repoId;
	int parentId;
	NSString *date;
	NSString *fullname;
	NSMutableDictionary *languageMap;	
	
	
	
	// indicators
	int watchCount;
	// double normalizedWatchRank;
	int forkCount;
	// double normalizedForkRank;	
	// double normalizedNeighborhoodWatchRank;
	
	double score;
	
	// calculated
	NSMutableSet *watches;
	NSMutableArray *forks;
	Repository *parent;
}

// data
@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, nonatomic) NSString *date, *fullname;
@property(readonly, nonatomic) NSMutableDictionary *languageMap;
@property(readonly, nonatomic) NSSet *watches;
// indicators
@property(readwrite, nonatomic) int watchCount;
@property(readwrite, nonatomic) int forkCount;
@property(readwrite, nonatomic) double score;
// calculated
@property(readonly, nonatomic) NSMutableArray *forks;
@property(retain, readwrite, nonatomic) Repository *parent;


-(id)initWithId:(int)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

-(void)addFork:(Repository *)repoId;
-(void) addWatcher:(NSNumber *)userId;

// compare indicators
-(NSComparisonResult)compareForkCount: (id) other;
-(NSComparisonResult)compareWatchCount: (id) other;
-(NSComparisonResult)compareScore: (id) other;

@end