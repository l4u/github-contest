
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
}

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
@property(readwrite, nonatomic) int watchCount;
@property(readwrite, nonatomic) int forkCount;
@property(readwrite, nonatomic) double score;
// calculated
@property(readonly, nonatomic) NSMutableArray *forks;
@property(retain, readwrite, nonatomic) Repository *parent;
@property(readonly, nonatomic) NSString *dominantLanguage;

-(id)initWithId:(NSNumber *)aId;
-(void)parse:(NSString*)repoDef;
-(void)parseLanguage:(NSString*)langDef;

-(void)addFork:(Repository *)repoId;
-(void)addWatcher:(NSNumber *)userId;

// compare indicators
-(NSComparisonResult)compareForkCount: (id) other;
-(NSComparisonResult)compareWatchCount: (id) other;
-(NSComparisonResult)compareScore: (id) other;

@end