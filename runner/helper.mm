#import "helper.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import "minizip/unzip.h"
#import <OSAKit/OSAKit.h>
#import <ScriptingBridge/ScriptingBridge.h>

namespace fs = std::filesystem;
bool isDiscordFound_ = false;

@interface HelperClass : NSObject
- (void)toggleOption:(NSMenuItem *)sender;
@end

@implementation HelperClass

- (void)toggleOption:(NSMenuItem *)sender
{
    if (!doesAppExist("/Applications/Discord.app"))
    {
        NSLog(@"[INFO] Discord not found in /Applications/Discord.app");
        return;
    }
    if (!isAppRunning("Discord"))
    {
        NSLog(@"[INFO] Discord not running");
        return;
    }
    // Toggle the state
    if (isDiscordFound_ == false) {
        [sender setState:NSControlStateValueOn];
        // Handle the option being turned off
        NSLog(@"[INFO] Option is now ON");
        isDiscordFound_ = true;
    } else {
        [sender setState:NSControlStateValueOff];
        // Handle the option being turned on
        NSLog(@"[INFO] Option is now OFF");
        isDiscordFound_ = false;
    }
}

@end

bool isAppRunning(const std::string &appName) {
    @autoreleasepool {
        // Convert std::string to NSString
        NSString *searchAppName = [NSString stringWithUTF8String:appName.c_str()];
        
        // Get the list of running applications
        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        
        // Iterate through the list to find the application with the specified name
        for (NSRunningApplication *app in runningApps) {
            NSString *localizedName = [app localizedName];
            if ([localizedName isEqualToString:searchAppName]) {
                return true; // Application is running
            }
        }
    }
    return false; // Application is not running
}

std::string getTemp() {
    std::string tempDir = fs::temp_directory_path().string();
    NSLog(@"[INFO] temp path is %s", tempDir.c_str());
    return tempDir;
}

void terminateApplicationByName(const std::string& appName) {
    // Convert std::string to NSString
    NSString *nsAppName = [NSString stringWithUTF8String:appName.c_str()];
    
    // Get the list of running applications
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    // Iterate through the running applications
    for (NSRunningApplication *app in runningApps) {
        // Check if the application name matches
        if ([[app localizedName] isEqualToString:nsAppName]) {
            // Terminate the application
            [app terminate];
            NSLog(@"[INFO] Application %@ terminated.", nsAppName);
            return;
        }
    }
    
    NSLog(@"[INFO] Application %@ not found.", nsAppName);
} 

std::string GetResourcesFolderPath()
{
    // Get the main bundle
    NSBundle *mainBundle = [NSBundle mainBundle];

    // Get the path to the resources folder
    NSString *resourcesFolderPath = [mainBundle resourcePath];

    // Convert NSString to std::string and return
    return std::string([resourcesFolderPath UTF8String]);
}

void runApp(const std::string &launchPath, bool Check) {
   // Convert std::string to NSString
    NSString *launchAppPath = [NSString stringWithUTF8String:launchPath.c_str()];

    // Create an NSURL instance using the launchAppPath
    NSURL *url = [NSURL fileURLWithPath:launchAppPath isDirectory:YES];

    // Create an OpenConfiguration instance
    NSWorkspaceOpenConfiguration *configuration = [[NSWorkspaceOpenConfiguration alloc] init];

    if (Check)
    {
        NSString *scriptSource = [NSString stringWithFormat:@"tell application \"%@\" to activate", launchAppPath];
        NSDictionary *errorInfo = nil;
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource];
        NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&errorInfo];

        if (errorInfo) {
            NSLog(@"[ERROR] Something went wrong when requesting permission: %@", errorInfo);
            return;
        }
    }

    // Open the application with the specified configuration
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:url
                                         configuration:configuration
                                     completionHandler:nil];
}

std::string runAppleScriptAndGetOutput(const std::string &script) {
    @autoreleasepool {
        // Convert std::string to NSString
        NSString *scriptNSString = [NSString stringWithUTF8String:script.c_str()];

        // Create an NSAppleScript object with the script
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptNSString];

        // Execute the script
        NSDictionary *errorDict = nil;
        NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&errorDict];

        if (errorDict) {
            // Print error details
            NSLog(@"[ERROR] AppleScript error: %@", errorDict);
            if ([errorDict objectForKey:NSAppleScriptErrorMessage]) {
                NSLog(@"[ERROR] Error message: %@", [errorDict objectForKey:NSAppleScriptErrorMessage]);
            }

            // Handle specific error for permissions issues
            NSNumber *errorNumber = [errorDict objectForKey:NSAppleScriptErrorNumber];
            if ([errorNumber integerValue] == -600) {
                // Show an alert to the user
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Permission Required"];
                [alert setInformativeText:@"Your application needs permission to control other applications. Please grant access in System Preferences."];
                [alert addButtonWithTitle:@"Open System Preferences"];
                [alert addButtonWithTitle:@"Cancel"];

                // Show the alert and handle user response
                NSModalResponse response = [alert runModal];
                if (response == NSAlertFirstButtonReturn) {
                    // Open the System Preferences pane
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"]];
                }

                return "";
            }

            return "";
        }

        // Extract the string result from NSAppleEventDescriptor
        NSString *resultString = [result stringValue];
        if (resultString) {
            return std::string([resultString UTF8String]);
        }

        return "";
    }
}

bool foundDiscord()
{
    return isDiscordFound_;
}

std::string ShowOpenFileDialog(const std::string& defaultDirectory) {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];

    // Set default directory
    if (!defaultDirectory.empty()) {
        NSString* nsDefaultDirectory = [NSString stringWithUTF8String:defaultDirectory.c_str()];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:nsDefaultDirectory]];
    }
    [openPanel setPrompt:@"Select folder (do ~/Library/Logs/Roblox)"];
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL* fileURL = [[openPanel URLs] objectAtIndex:0];
        NSString* filePath = [fileURL path];
        
        return std::string([filePath UTF8String]);
    }
    return "";
}

std::string FileChecker(const std::string path) {
    // Convert std::string to NSString
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    
    // Create an NSFileManager instance
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the file exists
    if ([fileManager fileExistsAtPath:nsPath]) {
        std::ifstream file(path);
        
        if (file.is_open()) {
            std::string line;
            std::string fileContent;
            
            // Read file contents
            while (std::getline(file, line)) {
                fileContent += line + "\n";
            }
            file.close();
            
            // Log the content for demonstration
            NSLog(@"[INFO] File contents:\n%@", [NSString stringWithUTF8String:fileContent.c_str()]);
            
            return fileContent;
        } else {
            NSLog(@"[ERROR] Failed to open file: %@", nsPath);
            return "";
        }
    } else {
        NSLog(@"[ERROR] File does not exist: %@", nsPath);
        return "";
    }
}

bool doesAppExist(const std::string& path) {
    // Convert std::string to NSString
    NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];

    // Create an NSURL from the NSString path
    NSURL* url = [NSURL fileURLWithPath:nsPath];

    // Use NSFileManager to check if the file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:[url path] isDirectory:&isDirectory];
    
    // Check if the file exists and if it is a directory (i.e., .app bundle)
    return exists && isDirectory;
}


std::string ShowOpenFileDialog_WithCustomText(const std::string& defaultDirectory, const std::string& customText) {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    NSString* text = [NSString stringWithUTF8String:customText.c_str()];
    // Set default directory
    if (!defaultDirectory.empty()) {
        NSString* nsDefaultDirectory = [NSString stringWithUTF8String:defaultDirectory.c_str()];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:nsDefaultDirectory]];
    }
    [openPanel setPrompt:text];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL* directoryURL = [[openPanel URLs] objectAtIndex:0];
        NSString* directoryPath = [directoryURL path];
        
        // Convert to std::string
        return std::string([directoryPath UTF8String]);
    }
    return "";
}

bool canAccessFile(const std::string& path) {
    // Convert std::string to NSString
    NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
    
    // Create an NSFileManager instance
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // Check if the file exists at the specified path
    BOOL isDirectory;
    BOOL fileExists = [fileManager fileExistsAtPath:nsPath isDirectory:&isDirectory];
    
    return fileExists;
}

bool CanAccessFolder(const std::string& path) {
    // Convert std::string to NSString
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    
    // Create a file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the path exists and is a directory
    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:nsPath isDirectory:&isDirectory];
    
    if (!exists || !isDirectory) {
        return false; // The folder doesn't exist or is not a directory
    }
    
    // Try to access the folder
    NSError *error = nil;
    BOOL isAccessible = [fileManager isReadableFileAtPath:nsPath] && [fileManager isWritableFileAtPath:nsPath];
    
    if (!isAccessible) {
        NSLog(@"[ERROR] Cannot access folder at %@: %@", nsPath, [error localizedDescription]);
    }
    
    return isAccessible;
}

void createStatusBarIcon(const std::string &imagePath)
{
    if (!doesAppExist("/Applications/Discord.app"))
    {
        NSLog(@"[INFO] Discord not found in /Applications/Discord.app");
        isDiscordFound_ = false;
    }
    if (!isAppRunning("Discord"))
    {
        NSLog(@"[INFO] Discord not running");
        isDiscordFound_ = false;
    }
    else
    {
        isDiscordFound_ = true;
    }
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
        [statusButton setToolTip:@"tooltip lol"];
    }

    // Create and set up a menu for the status item
    NSMenu *menu = [[NSMenu alloc] init];

    // Create an instance of HelperClass
    HelperClass *helper = [[HelperClass alloc] init];

    // Create a custom view for the menu item with a checkbox
    NSView *menuItemView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 22)];

    NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 22)];
    [checkbox setButtonType:NSSwitchButton]; // Set the button type to a checkbox
    [checkbox setTitle:@"Toggle Discord RPC"];
    if (isDiscordFound_) {
        [checkbox setState:NSControlStateValueOn]; // Initial state is off
    }
    else {
        [checkbox setState:NSControlStateValueOff]; // Initial state is off
    }
    [checkbox setTarget:helper];
    [checkbox setAction:@selector(toggleOption:)];

    [menuItemView addSubview:checkbox];

    // Create the menu item with the custom view
    NSMenuItem *boolMenuItem = [[NSMenuItem alloc] init];
    [boolMenuItem setView:menuItemView];

    [menu addItem:boolMenuItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Add the Quit menu item
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" 
                                                          action:@selector(terminate:) 
                                                   keyEquivalent:@""];
    [menu addItem:quitMenuItem];
    
    [statusItem setMenu:menu];
}

std::string getLogFile(const std::string& logDir) {
    NSString *nsLogDir = [NSString stringWithUTF8String:logDir.c_str()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the directory exists
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:nsLogDir isDirectory:&isDirectory] || !isDirectory) { 
        std::cerr << "[ERROR] Directory does not exist: " << logDir << std::endl;
        return "";
    }
    
    NSError *error = nil;
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:nsLogDir error:&error];
    
    if (error) {
        std::cerr << "[ERROR] accessing directory: " << [error localizedDescription].UTF8String << std::endl;
        std::cerr << "[ERROR] DIR IS: " << logDir << std::endl;
        return "";
    }
    
    std::vector<std::string> logFiles;
    
    for (NSString *fileName in files) {
        NSString *filePath = [nsLogDir stringByAppendingPathComponent:fileName];
        NSString *fileExtension = [filePath pathExtension];
        
        if ([fileExtension isEqualToString:@"log"] && [fileName containsString:@"Player"]) {
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
            
            if (error) {
                std::cerr << "[ERROR] getting file attributes: " << [error localizedDescription].UTF8String << std::endl;
                return "";
            }
            
            NSDate *modificationDate = [attributes fileModificationDate];
            logFiles.push_back(std::string([fileURL.path UTF8String]));
        }
    }
    
    if (logFiles.empty()) return "";
    
    auto latestLogFile = *std::max_element(logFiles.begin(), logFiles.end(), [&fileManager](const std::string& a, const std::string& b) {
        NSURL *urlA = [NSURL fileURLWithPath:[NSString stringWithUTF8String:a.c_str()]];
        NSURL *urlB = [NSURL fileURLWithPath:[NSString stringWithUTF8String:b.c_str()]];
        NSDictionary *attributesA = [fileManager attributesOfItemAtPath:[urlA path] error:nil];
        NSDictionary *attributesB = [fileManager attributesOfItemAtPath:[urlB path] error:nil];
        NSDate *dateA = [attributesA fileModificationDate];
        NSDate *dateB = [attributesB fileModificationDate];
        return [dateA compare:dateB] == NSOrderedAscending;
    });
    
    return latestLogFile;
}
