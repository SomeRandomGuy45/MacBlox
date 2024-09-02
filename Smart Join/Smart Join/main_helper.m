//
//  main_helper.m
//  Smart Join
//

#import <Foundation/Foundation.h>
#import "main_helper.h"

NSString *checkIfRobloxIsRunning = @"tell application \"System Events\"\n"
                                    "    set appList to name of every process\n"
                                    "end tell\n\n"
                                    "if \"RobloxPlayer\" is in appList then\n"
                                    "    return \"true\"\n"
                                    "else\n"
                                    "    return \"false\"\n"
                                    "end if";


@implementation Main_Helper

- (NSString*)runAppleScript:(NSString *)scriptString {
    // Prepare the command
    NSString *command = @"/usr/bin/osascript";
    
    // Use a temporary file to store the script
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempScript.scpt"];
    [scriptString writeToFile:tempFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // Set up NSTask
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:command];
    [task setArguments:@[tempFilePath]];
    
    // Create a pipe to capture the standard output and standard error
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    // Launch the task
    [task launch];
    [task waitUntilExit];
    
    // Read and print the output
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[INFO] Output: %@", output);
    // Clean up the temporary file
    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    return output;
}

-(NSString*)extractGameIDFromURL:(NSString * )urlString {
    // Define the regular expression pattern for extracting the game ID
    NSString *pattern = @"/games/(\\d+)/";
    
    // Create a regular expression object
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    
    if (error) {
        NSLog(@"[ERROR] Couldn't creating regular expression: %@", error.localizedDescription);
        return nil;
    }
    
    // Search for matches in the URL string
    NSRange searchRange = NSMakeRange(0, [urlString length]);
    NSTextCheckingResult *match = [regex firstMatchInString:urlString options:0 range:searchRange];
    
    if (match) {
        // Extract the game ID from the match
        NSRange gameIDRange = [match rangeAtIndex:1]; // Capture group 1
        NSString *gameID = [urlString substringWithRange:gameIDRange];
        return gameID;
    } else {
        NSLog(@"[ERROR] No game ID match found.");
    }
    
    // If no game ID is found, attempt to extract placeId from the URL query parameters
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url) {
        NSLog(@"[ERROR] Invalid URL.");
        return nil;
    }
    
    // Create NSURLComponents from NSURL
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    if (!components) {
        NSLog(@"[ERROR] Unable to create NSURLComponents.");
        return nil;
    }
    
    // Extract the query items
    NSArray *queryItems = components.queryItems;
    
    // Iterate through query items to find placeId
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"placeId"]) {
            return item.value;
        }
    }
    
    NSLog(@"[ERROR] placeId not found in URL.");
    return nil;
}

-(NSString *)downloadFileWithoutDestination:(NSString * )urlString {
    __block NSString *result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] Download failed with error: %@", error.localizedDescription);
        } else {
            NSData *data = [NSData dataWithContentsOfURL:location];
            if (data) {
                result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            } else {
                NSLog(@"[ERROR] Failed to read downloaded data");
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    [downloadTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;
}

-(NSDictionary*)decodeJSONString:(NSString * ) jsonString {
    // Convert NSString to NSData
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!jsonData) {
        NSLog(@"Failed to convert NSString to NSData.");
        return nil;
    }
    
    NSError *error = nil;
    // Use NSJSONSerialization to deserialize the JSON data
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"Failed to deserialize JSON: %@", error.localizedDescription);
        return nil;
    }
    
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Expected NSDictionary but got %@", [jsonObject class]);
        return nil;
    }
    
    return (NSDictionary *)jsonObject;
}

-(void)RunScript:(NSString *)commandString {
    // Initialize NSTask
    NSTask *task = [[NSTask alloc] init];
    
    // Set the launch path to zsh
    NSString *zshPath = @"/bin/zsh";
    [task setLaunchPath:zshPath];
    
    // Prepare the command as an argument to zsh
    // Use -c option to pass the command to be executed by zsh
    [task setArguments:@[@"-c", commandString]];
    
    // Create a pipe to capture the standard output and standard error
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    
    // Launch the task
    [task launch];
}

-(BOOL) CheckIfRobloxIsRunning
{
    NSString *output = [self runAppleScript:checkIfRobloxIsRunning];
    return [output containsString:@"true"];
}

-(BOOL) canConvertToLong:(NSString * ) stringValue {
    // Convert the string to a long long
    long long longValue = [stringValue longLongValue];
    
    // Check if the conversion was successful
    return [stringValue isEqualToString:[NSString stringWithFormat:@"%lld", longValue]];
}

-(BOOL) doesFileExistAtPath:(NSString * ) path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL fileExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    return fileExists;
}

@end
