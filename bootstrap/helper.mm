/*

    This is the code that makes this app crash

*/

#import "helper.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import <minizip/unzip.h>
#import <OSAKit/OSAKit.h>
#import <ScriptingBridge/ScriptingBridge.h>

namespace fs = std::filesystem;

BOOL isAdminUser;
static NSString * const sAppAdminInstallPath = @"/Applications";
static NSString * const sAppUserInstallPath  =@"~/Applications";

void TestCommand() {
    isAdminUser = [[NSFileManager defaultManager] isWritableFileAtPath:sAppAdminInstallPath];
    NSLog(@"Is admin user: %@", isAdminUser? @"Yes" : @"No");
}

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

bool ensureDirectoryExists(const std::string& path) {
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    
    // Check if the directory exists
    BOOL exists = [fileManager fileExistsAtPath:nsPath isDirectory:&isDirectory];
    if (exists && isDirectory) {
        return true; // Directory exists
    }
    
    // Attempt to create the directory
    NSError *error = nil;
    BOOL success = [fileManager createDirectoryAtPath:nsPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        NSLog(@"Failed to create directory: %@", [error localizedDescription]);
        return false;
    }
    
    return true;
}

std::string GetDownloadsFolderPath() {
    NSString *downloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    // Convert NSString to std::string
    const char *pathCString = [downloadsPath UTF8String];
    std::string pathString(pathCString);
    
    // Ensure the directory exists
    if (!ensureDirectoryExists(pathString)) {
        std::cerr << "Failed to ensure the Downloads folder exists." << std::endl;
        return "";
    }
    
    return pathString;
}


void fixInstall(std::string path) {
    // Convert the std::string to an NSString
    NSString *applicationPath = [NSString stringWithUTF8String:path.c_str()];

    // Create the command with the application path
    NSString *cmd = [NSString stringWithFormat:@"xattr -w com.apple.quarantine \"\" %@", applicationPath];

    // Execute the command
    system([cmd UTF8String]);
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

std::string ShowOpenFileDialog(const std::string& defaultDirectory) {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    
    // Set default directory
    if (!defaultDirectory.empty()) {
        NSString* nsDefaultDirectory = [NSString stringWithUTF8String:defaultDirectory.c_str()];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:nsDefaultDirectory]];
    }
    [openPanel setPrompt:@"Select folder (Select /Applications/Roblox/Contents/MacOS)"];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL* directoryURL = [[openPanel URLs] objectAtIndex:0];
        NSString* directoryPath = [directoryURL path];
        
        // Convert to std::string
        return std::string([directoryPath UTF8String]);
    }
    return "";
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


void CreateFolder(std::string path)
{
    // Convert std::string to NSString
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    
    // Create a file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the directory already exists
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:nsPath isDirectory:&isDirectory] && isDirectory) {
        NSLog(@"[INFO] Directory already exists at %@", nsPath);
        return;
    }
    
    // Create the directory
    NSError *error = nil;
    BOOL success = [fileManager createDirectoryAtPath:nsPath
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&error];
    
    if (success) {
        NSLog(@"[INFO] Directory created successfully at %@", nsPath);
    } else {
        NSLog(@"[ERROR] Failed to create directory: %@", [error localizedDescription]);
    }
}

bool FolderExists(const std::string& path) {
    NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:nsPath];
}

void copyFile(const std::string& oldPath, const std::string& newPath) {
    @autoreleasepool {
        // Convert std::string to NSString
        NSString *sourcePath = [NSString stringWithUTF8String:oldPath.c_str()];
        NSString *destinationPath = [NSString stringWithUTF8String:newPath.c_str()];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        
        // Check if source file exists
        if (![fileManager fileExistsAtPath:sourcePath]) {
            NSLog(@"[ERROR] Source file does not exist: %@", sourcePath);
            return;
        }

        // Create necessary directories for the destination path
        NSString *destinationDirectory = [destinationPath stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:destinationDirectory]) {
            if (![fileManager createDirectoryAtPath:destinationDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"[ERROR] Failed to create directory: %@", destinationDirectory);
                return;
            }
        }

        // Check if destination file already exists and remove it
        if ([fileManager fileExistsAtPath:destinationPath]) {
            if (![fileManager removeItemAtPath:destinationPath error:&error]) {
                NSLog(@"[ERROR] Failed to remove existing file at destination: %@", error.localizedDescription);
                return;
            }
        }

        // Copy the file from oldPath to newPath
        if (![fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error]) {
            NSLog(@"[ERROR] Failed to copy file: %@", error.localizedDescription);
        } else {
            NSLog(@"[INFO] File copied successfully from %@ to %@", sourcePath, destinationPath);
        }
    }
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

void downloadFile(const char* urlString, const char* destinationPath) {
    @autoreleasepool {
        NSString *urlStr = [NSString stringWithUTF8String:urlString];
        NSString *destPath = [NSString stringWithUTF8String:destinationPath];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLSession *session = [NSURLSession sharedSession];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                if ([error isKindOfClass:[NSError class]]) {
                    NSLog(@"[ERROR] Download failed with error: %@", [error localizedDescription]);
                } else {
                    NSLog(@"[ERROR] Download failed with unknown error: %@", error);
                }
            } else {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSLog(@"[INFO] Response status code: %ld", (long)[httpResponse statusCode]);
                    NSLog(@"[INFO] Response headers: %@", [httpResponse allHeaderFields]);
                } else {
                    NSLog(@"[INFO] Response: %@", response);
                }
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *fileError;
                
                // Check if the file already exists at the destination path
                if ([fileManager fileExistsAtPath:destPath]) {
                    // Remove the existing file
                    BOOL removeSuccess = [fileManager removeItemAtPath:destPath error:&fileError];
                    if (!removeSuccess) {
                        if ([fileError isKindOfClass:[NSError class]]) {
                            NSLog(@"[ERROR] Failed to remove existing file: %@", [fileError localizedDescription]);
                        } else {
                            NSLog(@"[ERROR] Failed to remove existing file with unknown error: %@", fileError);
                        }
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                }
                
                // Move the downloaded file to the destination path
                BOOL success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&fileError];
                
                if (!success) {
                    if ([fileError isKindOfClass:[NSError class]]) {
                        NSLog(@"[ERROR] File move failed with error: %@", [fileError localizedDescription]);
                    } else {
                        NSLog(@"[ERROR] File move failed with unknown error: %@", fileError);
                    }
                } else {
                    NSLog(@"[INFO] File downloaded successfully to %@", destPath);
                }
            }
            
            dispatch_semaphore_signal(semaphore);
        }];
        
        [downloadTask resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
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

void RenameFile(const char* oldPathCStr, const char* newPathCStr)
{
    // Convert C strings to NSString
    NSString *oldPath = [NSString stringWithUTF8String:oldPathCStr];
    NSString *newPath = [NSString stringWithUTF8String:newPathCStr];
    
    // Initialize an error object
    NSError *error = nil;
    
    // Check if the file at the new path already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
        // Remove the existing file
        if (![[NSFileManager defaultManager] removeItemAtPath:newPath error:&error]) {
            NSLog(@"[INFO] Error removing existing file: %@", [error localizedDescription]);
            return; // Exit if the removal failed
        }
    }
    
    // Attempt to rename (move) the file
    if (![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
        NSLog(@"[INFO] Error renaming file: %@", [error localizedDescription]);
    } else {
        NSLog(@"[INFO] File renamed successfully.");
    }
}

bool unzipFile(const char* zipFilePath, const char* destinationPath) {
    @autoreleasepool {
        NSString *zipPath = [NSString stringWithUTF8String:zipFilePath];
        NSString *destPath = [NSString stringWithUTF8String:destinationPath];
        
        unzFile zipFile = unzOpen([zipPath fileSystemRepresentation]);
        if (!zipFile) {
            NSLog(@"[ERROR] Failed to open zip file: %s", zipFilePath);
            return false;
        }
        
        int ret = unzGoToFirstFile(zipFile);
        if (ret != UNZ_OK) {
            NSLog(@"[ERROR] Failed to go to first file in zip archive");
            unzClose(zipFile);
            return false;
        }

        do {
            char filename[256];
            unz_file_info fileInfo;
            ret = unzGetCurrentFileInfo(zipFile, &fileInfo, filename, sizeof(filename), NULL, 0, NULL, 0);
            if (ret != UNZ_OK) {
                NSLog(@"[ERROR] Failed to get file info");
                unzClose(zipFile);
                return false;
            }

            NSString *filePath = [destPath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
            if (filename[strlen(filename) - 1] == '/') {
                [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            } else {
                ret = unzOpenCurrentFile(zipFile);
                if (ret != UNZ_OK) {
                    NSLog(@"[ERROR] Failed to open file in zip archive");
                    unzClose(zipFile);
                    return false;
                }

                FILE *outFile = fopen([filePath fileSystemRepresentation], "wb");
                if (!outFile) {
                    NSLog(@"[ERROR] Failed to open output file");
                    unzCloseCurrentFile(zipFile);
                    unzClose(zipFile);
                    return false;
                }

                char buffer[8192];
                int bytesRead;
                while ((bytesRead = unzReadCurrentFile(zipFile, buffer, sizeof(buffer))) > 0) {
                    fwrite(buffer, 1, bytesRead, outFile);
                }

                fclose(outFile);
                unzCloseCurrentFile(zipFile);
            }
        } while (unzGoToNextFile(zipFile) == UNZ_OK);

        unzClose(zipFile);
        return true;
    }
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