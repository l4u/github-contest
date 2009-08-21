
/*
Up and running: http://blog.lyxite.com/2008/01/compile-objective-c-programs-using-gcc.html
Compilation: http://www.cs.indiana.edu/classes/c304/ObjCompile.html
*/

#import <Foundation/Foundation.h>

#import "User.h"
#import "Repository.h"
#import "Model.h"

void runTest() {
	NSLog(@"Hello world\n");

	// user test
	User *user = [[User alloc] initWithId:10];
	NSLog(@"User id=%i\n", [user userId]);
	// [user release];

	// repo test
	Repository *repo = [[Repository alloc] init];
	[repo parse:@"123338:DylanFM/roro-faces,2009-05-31,13635"];
	NSLog(@"Repo id=%i, name=%s, date=%s, parent=%i\n", [repo repoId], [repo fullname], [repo date], [repo parentId]);
	// [repo release];
}

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// do work
	runTest();

    [pool drain];
    return 0;
}



