
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
		// execute
		[strategy calculatePredictions];
		// validate
		[model validatePredictions];
		// output
		[model outputPredictions];
	} 
	@catch(NSException *e) {
		NSLog(@">>Caught exception during run: %@", e);
	}
	
	[strategy release];
	[model release];
	NSLog(@"Finished!");
    [pool drain];

    return 0;
}



