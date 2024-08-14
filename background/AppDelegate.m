#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>

// C++ Function Declaration
#ifdef __cplusplus
extern "C" {
    void runCppTask();
}
#endif

@implementation AppDelegate

- (void)addToLoginItems {
    NSString *helperBundleIdentifier = @"com.someguy.macbackground";
    BOOL success = SMLoginItemSetEnabled((__bridge CFStringRef)helperBundleIdentifier, YES);
    
    if (!success) {
        NSLog(@"Failed to add login item.");
    } else {
        NSLog(@"Login item added successfully.");
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self addToLoginItems];
    // Run C++ Task
    runCppTask();
}

@end
