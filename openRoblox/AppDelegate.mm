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

bool isAppInDock() {
    NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
    NSURL *appURL = [NSURL fileURLWithPath:appBundlePath];
    
    // Load the Dock's preferences
    NSString *dockPlistPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.apple.dock.plist"];
    NSDictionary *dockPrefs = [NSDictionary dictionaryWithContentsOfFile:dockPlistPath];
    
    NSArray *persistentApps = dockPrefs[@"persistent-apps"];
    
    for (NSDictionary *appDict in persistentApps) {
        NSDictionary *tileData = appDict[@"tile-data"];
        NSDictionary *fileData = tileData[@"file-data"];
        NSString *bundleID = fileData[@"_CFURLString"];
        
        if ([bundleID containsString:appURL.absoluteString]) {
            return true;
        }
    }
    return false;
}

void addAppToDock() {
    if (!isAppInDock()) {
        NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
        NSURL *appURL = [NSURL fileURLWithPath:appBundlePath];
        
        // Construct the dictionary representing the app to be added
        NSDictionary *appEntry = @{
            @"tile-data": @{
                @"file-data": @{
                    @"_CFURLString": appURL.absoluteString,
                    @"_CFURLStringType": @15
                }
            },
            @"tile-type": @"file-tile"
        };
        
        // Load the Dock's preferences
        NSString *dockPlistPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.apple.dock.plist"];
        NSMutableDictionary *dockPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:dockPlistPath];
        
        NSMutableArray *persistentApps = [dockPrefs[@"persistent-apps"] mutableCopy];
        if (!persistentApps) {
            persistentApps = [NSMutableArray array];
        }
        
        // Add the app to the persistent-apps list
        [persistentApps addObject:appEntry];
        
        // Update the dock preferences
        dockPrefs[@"persistent-apps"] = persistentApps;
        
        // Write the updated preferences back to the plist file
        [dockPrefs writeToFile:dockPlistPath atomically:YES];
        
        // Restart the Dock to apply changes
        system("killall Dock");
    }
}


@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    addAppToDock();
    std::string command__ = "open " + getParentFolderOfApp() + "/Play.app --args --supercoolhackthing";
    std::cout << "[INFO] Command is: " << command__ << "\n";
    system(command__.c_str());
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    std::cout << "[INFO] App is about to terminate\n";
}

@end