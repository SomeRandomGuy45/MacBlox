#include <string>
#include <fstream>
#include <filesystem>
#include <map>
#include <cstdlib>

#import "helper.h"
#import "autoUpdater.h"

#include "json.hpp"

namespace fs = std::filesystem;

using json = nlohmann::json;

std::string localuser = getenv("USER");

std::string download_branch = "main";

std::map<std::string, std::string> DownloadURLS = {
    {"main", "https://github.com/SomeRandomGuy45/CreateMacbloxInstaller/raw/dc8ad65d3d274aeb89b6c2f358178633a62f7bcc/Install.sh"},
    {"testing", "https://github.com/SomeRandomGuy45/CreateMacbloxInstaller/raw/dc8ad65d3d274aeb89b6c2f358178633a62f7bcc/Install_Testing.sh"},
};

@implementation autoUpdater : NSObject

- (BOOL)updateToData
{
    __block std::string latestVersion;

    // Proceed with the rest of the method
    BOOL result = YES;
    NSLog(@"[INFO] Checking for updates");
    if (!std::filesystem::exists(fs::path("/Users/" + localuser + "/Library/Application Support/Macblox_Installer_Data/config.json")))
    {
        NSLog(@"[ERROR] Config file not found");
        return NO;
    }
    
    json file_data;
    std::ifstream path("/Users/" + localuser + "/Library/Application Support/Macblox_Installer_Data/config.json");
    path >> file_data;
    path.close();
    if (!file_data.contains("branch") || !file_data.contains("version"))
    {
        return NO;
    }
    std::string branch = file_data["branch"];
    std::string version = file_data["version"];
    if (branch == "super_secret_test_branch_which_skips_version_check_lol")
    {
        return YES;
    }
    if (branch == "main")
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); // Create a semaphore to wait for the completion

        [self fetchLatestVersionWithCompletion:^(NSString *downloadLatestVersion, NSError *error) {
            if (error) {
                NSLog(@"[ERROR] Couldn't fetch latest version: %@", error.localizedDescription);
            } else {
                latestVersion = std::string([downloadLatestVersion UTF8String]);
                NSLog(@"[INFO] Latest version: %@", downloadLatestVersion);
            }
            dispatch_semaphore_signal(semaphore); // Signal that the async operation is done
        }];

        // Wait for the async operation to complete
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    else
    {
        download_branch = "testing";
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); // Create a semaphore to wait for the completion

        [self fetchLatestTagWithCompletion:^(NSString *downloadLatestVersion, NSError *error) {
            if (error) {
                NSLog(@"[ERROR] Couldn't fetch latest version: %@", error.localizedDescription);
            } else {
                latestVersion = std::string([downloadLatestVersion UTF8String]);
                NSLog(@"[INFO] Latest version: %@", downloadLatestVersion);
            }
            dispatch_semaphore_signal(semaphore); // Signal that the async operation is done
        }];

        // Wait for the async operation to complete
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    if (latestVersion != version)
    {
        result = NO;
    }
    return result;
}

- (void)fetchLatestTagWithCompletion:(void (^)(NSString *downloadLatestVersion, NSError *error))completion
{
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/repos/SomeRandomGuy45/MacBlox/commits/main"];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError) {
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        
        NSString *latestCommit = json[@"sha"];
        
        if (completion) {
            completion(latestCommit, nil);
        }
    }] resume];
}

- (void)fetchLatestVersionWithCompletion:(void (^)(NSString *downloadLatestVersion, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/repos/SomeRandomGuy45/MacBlox/releases/latest"];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        
        NSString *latestVersion = json[@"tag_name"];
        if (completion) {
            completion(latestVersion, nil);
        }
        
    }] resume];
}

- (void)doUpdate
{
    NSLog(@"[INFO] Doing updates");
    self.popUpWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                                            styleMask:(NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView)
                                            backing:NSBackingStoreBuffered
                                            defer:NO];
    self.popUpWindow.titlebarAppearsTransparent = YES;
    self.popUpWindow.titleVisibility = NSWindowTitleHidden;
    self.popUpWindow.styleMask &= ~NSWindowStyleMaskTitled;
    self.popUpWindow.movableByWindowBackground = YES;
    [self.popUpWindow setHasShadow:NO];
    NSVisualEffectView *visualEffect = [[NSVisualEffectView alloc] init];
    visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    visualEffect.state = NSVisualEffectStateActive;
    visualEffect.material = NSVisualEffectMaterialDark;
    self.popUpWindow.contentView = visualEffect;
    
    // Show the window
    [self.popUpWindow setLevel:NSFloatingWindowLevel];
    [self.popUpWindow makeKeyAndOrderFront:nil];

    /*
    NSRect textViewFrame = NSMakeRect(20, 50, 360, 200);
    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 300, 200)];
    [self.textView setMinSize:NSMakeSize(0.0, 200.0)];
    [self.textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [self.textView setVerticallyResizable:YES];
    [self.textView setHorizontallyResizable:NO];
    [self.textView setAutoresizingMask:NSViewWidthSizable];
    
    [self.popUpWindow.contentView addSubview:self.textView];

    // Set text attributes and initial content
    [self.textView setString:@"Hello, NSTextView!"];
    [self.textView setEditable:NO];
    */

    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(80, 80, 42, 42)];
    [self.progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    
    // Add the progress indicator to the window's content view
    [self.popUpWindow.contentView addSubview:self.progressIndicator];
    
    // Start the animation
    [self.progressIndicator startAnimation:nil];
    
    // Center the window and show it
    [self.popUpWindow center];
    [self.popUpWindow makeKeyAndOrderFront:nil];

    // Execute the update asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Simulate the update process
        std::string installerPath = GetResourcesFolderPath() + "/installer.sh";
        [NSThread sleepForTimeInterval:3.0]; //TODO
        downloadFile(DownloadURLS[download_branch].c_str(), installerPath.c_str());
        std::string chmodCommand = "chmod +x " + installerPath;
        system(chmodCommand.c_str());

        // Run the installer script
        int result = system(installerPath.c_str());
        if (result != 0) {
            // Handle error
            std::cerr << "[ERROR] Failed to run installer.sh: " << result << std::endl;
        }
        // Close the popup on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndicator stopAnimation:nil];
            [self.popUpWindow close];
            fs::remove(GetResourcesFolderPath() + "/installer.sh");
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Alert";
            alert.informativeText = @"Updated Application! When you relaunch the app it will be updated.";
            [alert addButtonWithTitle:@"Confirm"];
            [alert addButtonWithTitle:@"Cancel"];

            alert.icon = [NSImage imageNamed:NSImageNameCaution]; // Use the warning icon

            [alert runModal];
            // Notify the app that the update is complete
        });
    });
}

- (void)forceQuit
{
    [NSApp stopModal];
    [self.popUpWindow close];
}

@end