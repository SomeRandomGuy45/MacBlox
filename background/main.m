#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#include <iostream>
#include <AppKit/AppKit.h>

std::string GetResourcesFolder()
{
    // Get the main bundle
    NSBundle *mainBundle = [NSBundle mainBundle];

    // Get the path to the resources folder
    NSString *resourcesFolderPath = [mainBundle resourcePath];

    // Convert NSString to std::string and return
    return std::string([resourcesFolderPath UTF8String]);
}

std::string Path = GetResourcesFolder();

void createStatusBar(const std::string &imagePath)
{
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem *statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];

    // Convert std::string to NSString
    NSString *path = [NSString stringWithUTF8String:imagePath.c_str()];

    // Create an NSImage from the file path
    NSImage *statusImage = [[NSImage alloc] initWithContentsOfFile:path];
    if (statusImage == nil) {
        NSLog(@"[ERROR] Failed to load image from path: %@", path);
        return;
    }

    [statusItem setImage:statusImage];
    
    // Access the button associated with the NSStatusItem
    NSButton *statusButton = [statusItem button];
    if (statusButton) {
        [statusButton setToolTip:@"Your tooltip text"];
    }

    // Create and set up a menu for the status item
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    [menu addItem:quitMenuItem];
    [statusItem setMenu:menu];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        createStatusBar(Path + "/test_icon.png");
        [app setDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}