
#import <Foundation/Foundation.h>

#import "Repository.h"
#import "User.h"



@interface Model : NSObject {
@private
    NSMutableDictionary *repositoryMap;
	NSMutableDictionary *userMap;
}

@property(readonly) NSMutableDictionary *repositoryMap;
@property(readonly) NSMutableDictionary *userMap;

-(void) printStats;

-(void) loadModel;
-(void) loadRepos;
-(void) loadRepoLanguages;
-(void) loadRepoUserRelationships;
-(void) loadTestUsers;


@end