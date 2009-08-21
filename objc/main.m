
/*
Up and running: http://blog.lyxite.com/2008/01/compile-objective-c-programs-using-gcc.html
Compilation: http://www.cs.indiana.edu/classes/c304/ObjCompile.html
*/

#import <Foundation/Foundation.h>

#import "User.h"

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"Hello world\n");
	User *user = [[User alloc] initWithId:10];
	// TODO print user id

    [pool drain];
    return 0;
}



