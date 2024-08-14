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
    
    // Example: Run a shell command in the background
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", @"echo 'Hello, Background!' >> ~/Desktop/background.txt"]];
    [task launch];
    
    // Run C++ Task
    runCppTask();
}

@end