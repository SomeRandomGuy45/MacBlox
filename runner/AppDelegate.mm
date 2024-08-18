#import "AppDelegate.h"
#import "helper.h"
#import <Foundation/Foundation.h>

// Function to check if Roblox is running and close it
void checkAndCloseRoblox() {
    terminateApplicationByName("Roblox");
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    main_loop();
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    checkAndCloseRoblox();
    std::cout << "[INFO] App is about to terminate\n";
}

@end
