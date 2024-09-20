#include <string>
#include <fstream>
#include <filesystem>

#import "autoUpdater.h"

#include "json.hpp"

namespace fs = std::filesystem;

using json = nlohmann::json;

std::string localuser = getenv("USER");

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
    self.popUpWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 100)
                                            styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskClosable)
                                            backing:NSBackingStoreBuffered
                                            defer:NO];
    [self.popUpWindow setLevel:NSModalPanelWindowLevel];
    [self.popUpWindow setMovableByWindowBackground:YES];

    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(85, 40, 32, 32)];
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
        [NSThread sleepForTimeInterval:3.0]; //TODO

        // Close the popup on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndicator stopAnimation:nil];
            [self.popUpWindow close];
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