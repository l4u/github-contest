
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
	// data
    int repoId, parentId;
	NSString *date, *fullname;
	NSMutableDictionary *languageMap;	
	// indicators
	int watchCount;
	double normalizedWatchRank;
	int forkCount;
	double normalizedForkRank;
	
	double normalizedNeighborhoodWatchRank;
	
	double score;
	
	// calculated
	NSMutableArray *forks;
	Repository *parent;
}

// data
@property(readonly, nonatomic) int repoId, parentId;
@property(readonly, nonatomic) NSString *date, *fullname;
@property(readonly, nonatomic) NSMutableDictionary *languageMap;
// indicators
@property(readwrite, nonatomic) int watchCount;
@property(readwrite, nonatomic) int forkCount;
@property(readwrite, nonatomic) double score;
@property(readwrite, nonatomic) double normalizedWatchRank;
@property(readwrite, nonatomic) double normalizedForkRank;
@property(readwrite, nonatomic) double normalizedNeighborhoodWatchRank;

// calculated
@property(readonly, nonatomic) NSMutableArray *forks;
@property(retain, readwrite, nonatomic) Repository *parent;


-(id)initWithId:(int)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

-(void)addFork:(Repository *)repoId;
-(void) clearIndicators;

// compare indicators
-(NSComparisonResult)compareForkCount: (id) other;
-(NSComparisonResult)compareWatchCount: (id) other;
-(NSComparisonResult)compareScore: (id) other;

@end