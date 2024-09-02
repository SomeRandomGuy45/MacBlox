#import <Foundation/Foundation.h>
#import <minizip/unzip.h>
#import <AppKit/AppKit.h>
#import <OSAKit/OSAKit.h>
#import "Downloader.h"

#include <fstream>

std::string GetMacOSAppearance()
{
    std::string appearance = "Light";
    
    #ifdef __APPLE__
    @autoreleasepool {
        NSAppearance *appearanceSetting = [NSApp effectiveAppearance];
        NSString *name = [appearanceSetting name];
        
        if ([name isEqualToString:NSAppearanceNameDarkAqua]) {
            appearance = "Dark";
        } else if ([name isEqualToString:NSAppearanceNameAqua]) {
            appearance = "Light";
        }
    }
    #endif
    
    return appearance;
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

void downloadFile(const char* urlString, const char* destinationPath) {
    @autoreleasepool {
        NSString *urlStr = [NSString stringWithUTF8String:urlString];
        NSString *destPath = [NSString stringWithUTF8String:destinationPath];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLSession *session = [NSURLSession sharedSession];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                // Check if error is of type NSError
                if ([error isKindOfClass:[NSError class]]) {
                    NSLog(@"[ERROR] Download failed with error: %@", [error localizedDescription]);
                } else {
                    NSLog(@"[ERROR] Download failed with unknown error: %@", error);
                }
            } else {
                // Log the NSURLResponse details
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSLog(@"[INFO] Response status code: %ld", (long)[httpResponse statusCode]);
                    NSLog(@"[INFO] Response headers: %@", [httpResponse allHeaderFields]);
                } else {
                    NSLog(@"[INFO] Response: %@", response);
                }
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *fileError;
                
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
            
            // Signal the semaphore to continue
            dispatch_semaphore_signal(semaphore);
        }];
        
        [downloadTask resume];
        
        // Wait for the completion handler to finish
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

std::string GetResourcesFolderPath()
{
    // Get the main bundle
    NSBundle *mainBundle = [NSBundle mainBundle];

    // Get the path to the resources folder
    NSString *resourcesFolderPath = [mainBundle resourcePath];

    // Convert NSString to std::string and return
    return std::string([resourcesFolderPath UTF8String]);
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
                [app terminate];
                return true; // Application is running
            }
        }
    }
    return false; // Application is not running
}

std::string PromptUserForRobloxID() {
    // Create and configure the alert
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Enter Roblox User ID"];
    [alert setInformativeText:@"Please enter the Roblox User ID:"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    // Create a text field for user input
    NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [inputField setPlaceholderString:@"Roblox User ID"];
    
    // Set up the dialog's accessory view
    [alert setAccessoryView:inputField];
    
    // Run the alert and check the user's response
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
        // User pressed OK, get the text from the input field
        std::string userID = [[inputField stringValue] UTF8String];
        return userID;
    } else {
        // User pressed Cancel or closed the dialog
        return "";
    }
}

std::string downloadFile_WITHOUT_DESTINATION(const char* urlString) {
    @autoreleasepool {
        NSString *urlStr = [NSString stringWithUTF8String:urlString];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLSession *session = [NSURLSession sharedSession];

        __block std::string result;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"Download failed with error: %@", error.localizedDescription);
            } else {
                NSData *data = [NSData dataWithContentsOfURL:location];
                if (data) {
                    result = std::string((const char*)[data bytes], [data length]);
                } else {
                    NSLog(@"Failed to read downloaded data");
                }
            }
            dispatch_semaphore_signal(semaphore);
        }];

        [downloadTask resume];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return result;
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