#import <Foundation/Foundation.h>
#import <minizip/unzip.h>
#import <AppKit/AppKit.h>
#import <OSAKit/OSAKit.h>
#import "Downloader.h"

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
                    NSLog(@"Download failed with error: %@", [error localizedDescription]);
                } else {
                    NSLog(@"Download failed with unknown error: %@", error);
                }
            } else {
                // Log the NSURLResponse details
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSLog(@"Response status code: %ld", (long)[httpResponse statusCode]);
                    NSLog(@"Response headers: %@", [httpResponse allHeaderFields]);
                } else {
                    NSLog(@"Response: %@", response);
                }
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *fileError;
                
                // Move the downloaded file to the destination path
                BOOL success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&fileError];
                
                if (!success) {
                    if ([fileError isKindOfClass:[NSError class]]) {
                        NSLog(@"File move failed with error: %@", [fileError localizedDescription]);
                    } else {
                        NSLog(@"File move failed with unknown error: %@", fileError);
                    }
                } else {
                    NSLog(@"File downloaded successfully to %@", destPath);
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
            NSLog(@"Error requesting permission: %@", errorInfo);
            return;
        }
    }

    // Open the application with the specified configuration
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:url
                                         configuration:configuration
                                     completionHandler:nil];
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