
/*
Up and running: http://blog.lyxite.com/2008/01/compile-objective-c-programs-using-gcc.html
Compilation: http://www.cs.indiana.edu/classes/c304/ObjCompile.html
*/

#import <Foundation/Foundation.h>

#import "User.h"
#import "Repository.h"
#import "Model.h"

void runTest() {
	
	Model *model = [[Model alloc] init];
	[model loadModel];
	[model printStats];
	
	NSLog(@"Done.");
}

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// do work
	runTest();

    [pool drain];
    return 0;
}



