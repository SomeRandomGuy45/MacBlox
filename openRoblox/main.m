#import "AppDelegate.h"
#import <Foundation/Foundation.h>

int main(int argc, char* argv[]) { //I don't care about the args you pass
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}