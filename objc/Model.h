
#import <Foundation/Foundation.h>

#import "Repository.h"
#import "User.h"



@interface Model : NSObject {
@private
    NSMutableDictionary *repositoryMap;
	NSMutableDictionary *userMap;
	NSMutableArray *testUsers;
}

@property(readonly) NSMutableDictionary *repositoryMap;
@property(readonly) NSMutableDictionary *userMap;
@property(readonly) NSMutableArray *testUsers;

-(void) printStats;

-(void) loadModel;
-(void) loadRepos;
-(void) loadRepoLanguages;
-(void) loadRepoUserRelationships;
-(void) loadTestUsers;

-(void) validatePredictions;
-(void) outputPredictions;

@end