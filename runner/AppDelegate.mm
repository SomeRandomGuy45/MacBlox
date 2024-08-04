#import <Cocoa/Cocoa.h>
#import <iostream>
#import "AppDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@end

@implementation AppDelegate

void InitializeApp() {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [app setDelegate:delegate];
    [app run];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    // Your code to handle app termination
    std::cout << "[INFO] Application is terminating\n";
    // Perform any cleanup or finalization here
}

@end
