
/*
Up and running: http://blog.lyxite.com/2008/01/compile-objective-c-programs-using-gcc.html
Compilation: http://www.cs.indiana.edu/classes/c304/ObjCompile.html
*/

#import <Foundation/Foundation.h>

#import "User.h"
#import "Repository.h"
#import "Model.h"
#import "Strategy.h"

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	Model *model = nil;
	Strategy *strategy = nil;
	@try {
		// model
		model = [[Model alloc] init];
		[model loadModel];
		[model printStats];
		// strategy
		strategy = [[Strategy alloc] initWithModel:model];		
		// prep training data
		strategy.generateTrainingData = NO;		
		// execute
		[strategy employStrategy];
	} 
	@catch(NSException *e) {
		NSLog(@">>Caught exception during run: %@", e);
	}
	NSLog(@"Finished!");
	
	[strategy release];
	[model release];

    [pool drain];

    return 0;
}



