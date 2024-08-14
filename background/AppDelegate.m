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
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSURL *appURL = [NSURL fileURLWithPath:appPath];
    CFURLRef appURLRef = (__bridge CFURLRef)appURL;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, appURLRef, NULL, NULL);
        if (item) CFRelease(item);
        CFRelease(loginItems);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self addToLoginItems];
    // Run C++ Task
    runCppTask();
}

@end