#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>
#import <CoreServices/CoreServices.h>
#include <string>
#include <iostream>

std::string getParentFolderOfApp() {
    // Get the bundle path
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    // Get the parent directory of the bundle
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    // Convert NSString to std::string
    return std::string([parentPath UTF8String]);
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    std::string command__ = "open " + getParentFolderOfApp() + "/Play.app --args --supercoolhackthing";
    std::cout << "[INFO] Command is: " << command__ << "\n";
    system(command__.c_str());
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    std::cout << "[INFO] App is about to terminate\n";
}

- (BOOL)applicationSupportsSecureRestorableState:(NSNotification *)aNotification {
    return YES;
}

@end