#import "helper.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import <minizip/unzip.h>
#import <OSAKit/OSAKit.h>

namespace fs = std::filesystem;

bool isAppRunning(const std::string &appName) {
    NSString *nsAppName = [NSString stringWithUTF8String:appName.c_str()];
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    bool test = false;
    for (NSRunningApplication *app in runningApps) {
        if ([app.localizedName isEqualToString:nsAppName]) {
            test = true;
            break;
        }
    }
    return test;
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
    [openPanel setPrompt:@"Select at ~/Library/Logs/Roblox"];
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL* fileURL = [[openPanel URLs] objectAtIndex:0];
        NSString* filePath = [fileURL path];
        
        return std::string([filePath UTF8String]);
    }
    return "";
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
