
#import <Foundation/Foundation.h>

#import "Repository.h"
#import "Model.h"

#define REPOSITORY_FILENAME = "../data/repos.txt"

@interface Model : NSObject {
@private
    NSMutableDictionary *repositoryMap;
	NSMutableDictionary *userMap;
}

@property(readonly) NSMutableDictionary *repositoryMap;
@property(readonly) NSMutableDictionary *userMap;

-(void) printStats;
-(void) loadRepos;

@end