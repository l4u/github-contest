
#import <Foundation/Foundation.h>

@interface Repository : NSObject {
@private
	// data
	NSNumber *repoId;
	NSNumber *parentId;
	NSString *date;
	NSString *fullname;
	NSString *name;
	NSString *owner;
	NSMutableDictionary *languageMap;	

	// indicators
	int watchCount;
	int forkCount;
	
	double score;
	
	// calculated
	NSMutableSet *watches;
	NSMutableArray *forks;
	Repository *parent;
	NSString *dominantLanguage;
	
	double normalizedWatchRank;
	double normalizedForkRank;
	double normalizedNameRank;
	double normalizedOwnerRank;
	
	double normalizedGroupWatchRank;
	double normalizedGroupForkRank;
	double normalizedGroupNameRank;
	double normalizedGroupOwnerRank;
	
	double normalizedUserNameRank;
	double normalizedUserOwnerRank;
}


@property(nonatomic) double normalizedWatchRank;
@property(nonatomic) double normalizedForkRank;
@property(nonatomic) double normalizedNameRank;
@property(nonatomic) double normalizedOwnerRank;

@property(nonatomic) double normalizedUserNameRank;
@property(nonatomic) double normalizedUserOwnerRank;

@property(nonatomic) double normalizedGroupWatchRank;
@property(nonatomic) double normalizedGroupForkRank;
@property(nonatomic) double normalizedGroupNameRank;
@property(nonatomic) double normalizedGroupOwnerRank;


// data
@property(readonly, nonatomic) NSNumber *repoId;
@property(readonly, nonatomic) NSNumber *parentId;
@property(readonly, nonatomic) NSString *date;
@property(readonly, nonatomic) NSString *fullname;
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *owner;
@property(readonly, nonatomic) NSMutableDictionary *languageMap;
@property(readonly, nonatomic) NSSet *watches;
// indicators
@property(nonatomic) int watchCount;
@property(nonatomic) int forkCount;
@property(nonatomic) double score;
// calculated
@property(readonly, nonatomic) NSMutableArray *forks;
@property(readonly, nonatomic) NSString *dominantLanguage;
@property(retain, readwrite, nonatomic) Repository *parent;





-(id)initWithId:(NSNumber *)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

-(void)addFork:(Repository *)repoId;
-(void)addWatcher:(NSNumber *)userId;

// compare indicators
-(NSComparisonResult)compareForkCount: (id) other;
-(NSComparisonResult)compareWatchCount: (id) other;
-(NSComparisonResult)compareScore: (id) other;


-(NSArray *)getChildTree;
-(NSArray *)getParentTree;

@end