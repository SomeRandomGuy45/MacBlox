//
//  Main_Helper.m
//  GameWatcher
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Main_Helper.h"
#import "Logger.h"

@implementation Main_Helper

@synthesize numberOfItems;

- (void)addCustomFramesToContentView:(NSView *)contentView name:(NSString *) NameOfGame imgUrl:(NSString *) URLOfGame deepLink:(NSString *) DeeplinkOfGame startTime:(NSString *) startTime endTime:(NSString *) endTime shouldTimes2:(BOOL) shouldTimes2 {
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[startTime doubleValue]];
    NSDate *data_End = [NSDate dateWithTimeIntervalSince1970:[endTime doubleValue]];
    // Create and configure date formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"]; // Format for time of day
    NSString *timeString_Start = [formatter stringFromDate:date];
    NSString *timeString_End = [formatter stringFromDate:data_End];
    NSInteger integerValue = [self.numberOfItems integerValue];
    integerValue += 1;
    NSNumber *updatedNumberOfItems = [NSNumber numberWithInteger:integerValue];
    self.numberOfItems = updatedNumberOfItems;
    
    // Create a frame for each item
    NSView *itemView = [[NSView alloc] initWithFrame:NSMakeRect(0, [self.numberOfItems intValue] * 150, 600, 150)];
    
    // Create a label for the title
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 110, 1000, 40)];
    [label setStringValue:NameOfGame];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    NSLog(@"[INFO] Times are: %@ %@", timeString_Start, timeString_End);
    NSTextField *label_StartTime = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 90, 200, 40)];
    [label_StartTime setStringValue:[NSString stringWithFormat:@"%@ %@",@"Start Time: ",timeString_Start]];
    [label_StartTime setBezeled:NO];
    [label_StartTime setDrawsBackground:NO];
    [label_StartTime setEditable:NO];
    [label_StartTime setSelectable:NO];
    
    NSTextField *label_EndTime = [[NSTextField alloc] initWithFrame:NSMakeRect(200, 90, 200, 40)];
    [label_EndTime setStringValue:[NSString stringWithFormat:@"%@ %@",@"End Time: ",timeString_End]];;
    [label_EndTime setBezeled:NO];
    [label_EndTime setDrawsBackground:NO];
    [label_EndTime setEditable:NO];
    [label_EndTime setSelectable:NO];
    
    // Create a button
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(320, 110, 100, 40)];
    [button setTitle:@"Rejoin Game"];
    [button setTarget:self];
    [button setAction:@selector(buttonClicked:)];
    objc_setAssociatedObject(button, @"DeeplinkKey", DeeplinkOfGame, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Create an image view
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 20, 100, 80)];
    NSURL *imagePath = [NSURL URLWithString:URLOfGame];
    
    // Use NSURLSession to load the image asynchronously
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:imagePath completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] Failed to load image: %@", error.localizedDescription);
            return;
        }

        // Check if we received valid data
        if (data) {
            NSImage *image = [[NSImage alloc] initWithData:data];
            
            // Ensure UI updates happen on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [imageView setImage:image];
            });
        }
    }];

    // Start the download task
    [downloadTask resume];
    
    // Add label, button, and image to the item view
    [itemView addSubview:label];
    [itemView addSubview:label_StartTime];
    [itemView addSubview:label_EndTime];
    [itemView addSubview:button];
    [itemView addSubview:imageView];
    
    // Add the item view to the content view
    [contentView addSubview:itemView];
    
    // Update the content size of the scroll view based on the number of items
    if (shouldTimes2)
    {
        [contentView setFrame:NSMakeRect(0, 0, 600, ([self.numberOfItems intValue] + 1) * 150)];
    }
    else
    {
        [contentView setFrame:NSMakeRect(0, 0, 600, ([self.numberOfItems intValue]) * 150)];
    }
}

- (void)openApplicationWithDeeplink:(NSString *) deeplink {
    // Create a new NSTask instance
    NSTask *task = [[NSTask alloc] init];
    
    // Set the shell to use (in this case, /bin/zsh)
    [task setLaunchPath:@"/bin/zsh"];
    
    // Prepare the full command with arguments
    NSString *fullCommand = [NSString stringWithFormat:@"open \"%@\"", deeplink];
    
    // Set the arguments for zsh; -c tells zsh to run the command
    [task setArguments:@[@"-c", fullCommand]];
    
    // Launch the task
    [task launch];
}


- (void)buttonClicked:(id)sender {
    NSString *deeplink = objc_getAssociatedObject(sender, @"DeeplinkKey");
    NSLog(@"[INFO] Button was clicked! Deeplink: %@", deeplink);
    [self openApplicationWithDeeplink:deeplink];
}

-(void)ensureFileExists:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
        
    // Expand the path if it contains the ~ (home directory)
    NSString *expandedPath = [filePath stringByExpandingTildeInPath];
        
    // Extract the directory path
    NSString *directoryPath = [expandedPath stringByDeletingLastPathComponent];
    BOOL isDir;
    BOOL directoryExists = [fileManager fileExistsAtPath:directoryPath isDirectory:&isDir];
    if (!directoryExists || !isDir) {
        NSError *dirError = nil;
        BOOL dirCreated = [fileManager createDirectoryAtPath:directoryPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&dirError];
        if (!dirCreated) {
            NSLog(@"[ERROR] Failed to create directory: %@", dirError.localizedDescription);
            return;
        }
    }
        
    // Check if the file exists
    BOOL fileExists = [fileManager fileExistsAtPath:expandedPath];
    if (!fileExists) {
        NSLog(@"[INFO] Couldn't find file!");
        
        // Create an empty NSData object
        NSData *emptyData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
        
        // Create the file with empty data
        BOOL success = [fileManager createFileAtPath:expandedPath contents:emptyData attributes:nil];
        if (success) {
            NSLog(@"[INFO] File created successfully.");
        } else {
            NSLog(@"[ERROR] Failed to create the file.");
        }
    } else {
        NSLog(@"[INFO] File already exists.");
    }
}

- (void)addToJson:(NSString *)addedData {
    NSString *folderPath = [self getApplicationSupportPath];
    folderPath = [folderPath stringByExpandingTildeInPath];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", folderPath, @"/game_watcher.json"];
    
    // Load the existing JSON data
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    
    // Check if the file is empty or doesn't exist
    NSDictionary *jsonDict = nil;
    if (jsonData) {
        jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (error) {
            NSLog(@"[ERROR] Failed parsing JSON: %@", error.localizedDescription);
            return;
        }
    }
    
    // Ensure jsonDict is mutable
    NSMutableDictionary *mutableDict = [jsonDict mutableCopy];
    if (mutableDict == nil) {
        NSLog(@"[DEBUG] Initialized new mutable dictionary");
        mutableDict = [NSMutableDictionary dictionary];
    }
    
    // Convert addedData from NSString to NSDictionary
    NSData *addedDataJsonData = [addedData dataUsingEncoding:NSUTF8StringEncoding];
    
    // Logging the raw addedData string to check for errors
    NSLog(@"[DEBUG] Added data JSON string: %@", addedData);
    
    NSDictionary *addedDataDict = [NSJSONSerialization JSONObjectWithData:addedDataJsonData options:kNilOptions error:&error];

    if (error) {
        NSLog(@"[ERROR] Failed parsing added data JSON: %@", error.localizedDescription);
        return;
    }
    
    // Determine the next key
    NSInteger highestKey = 0;
    for (NSString *key in mutableDict) {
        NSLog(@"[DEBUG] Info key data is %@", key);
        NSRange range = [key rangeOfString:@"gameData-"];
        if (range.location != NSNotFound) {
            NSString *substring = [[key substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSLog(@"[INFO] SUB %@", substring);
            NSInteger keyNumber = [substring integerValue];
            if (keyNumber > highestKey) {
                highestKey = keyNumber;
            }
        }
    }
    
    // Increment the highestKey as a string
    NSInteger nextKeyNumber = highestKey + 1;
    NSString *newKey = [NSString stringWithFormat:@"gameData-%ld", (long)nextKeyNumber];
    NSLog(@"[INFO] New key is %@", newKey);
    
    // Add the new data with the new key
    mutableDict[newKey] = addedDataDict;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:filePath];
    
    if (!exists) {
        NSLog(@"[INFO] Couldn't find file!");
        [self ensureFileExists:filePath];
    }
    
    // Convert the dictionary back to JSON data
    NSData *updatedJsonData = [NSJSONSerialization dataWithJSONObject:mutableDict options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"[ERROR] Couldn't convert dictionary to JSON: %@", error.localizedDescription);
        return;
    }
    
    // Write the updated JSON data back to the file
    BOOL success = [updatedJsonData writeToFile:filePath atomically:YES];
    if (!success) {
        NSLog(@"[ERROR] Failed to write updated JSON to file.");
    } else {
        NSLog(@"[INFO] Saved with path: %@", filePath);
    }
}




- (void)resetJson
{
    NSString *folderPath = [self getApplicationSupportPath];
    folderPath = [folderPath stringByExpandingTildeInPath];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", folderPath, @"/game_watcher.json"];
    NSData *emptyData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    [emptyData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if ([error isNotEqualTo:nil])
    {
        //oh no we got a error when resetting
        NSLog(@"[ERROR] Unable to reset data data. Reason: %@", error.localizedDescription);
    }
}

- (NSString *)getApplicationSupportPath
{
    NSString *userName = [NSProcessInfo processInfo].userName;
    NSString *user = @"/User/";
    NSString *folderPath = @"/Library/Application Support/MacBlox_Data";
    folderPath = [NSString stringWithFormat:@"%@%@%@", user, userName, folderPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
        
    if (!exists || !isDir) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    folderPath = [NSString stringWithFormat:@"%@%@", @"~", @"/Library/Application Support/MacBlox_Data"];
    return folderPath;
}

- (NSDictionary *)decodeJSONFromFilePath:(NSString *)jsonString {
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

@end

