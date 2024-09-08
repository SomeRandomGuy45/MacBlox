#import "AppDelegate.h"

NSString *convertToValidJSONString(NSString *inputString) {
    // Use a regular expression to add double quotes around keys
    NSRegularExpression *regexKeys = [NSRegularExpression regularExpressionWithPattern:@"(?<!\")\\b(\\w+)\\b(?!\")" options:0 error:nil];
    NSString *quotedKeysString = [regexKeys stringByReplacingMatchesInString:inputString options:0 range:NSMakeRange(0, inputString.length) withTemplate:@"\"$1\""];
    
    // Use a regular expression to add double quotes around string values that are not already quoted
    NSRegularExpression *regexValues = [NSRegularExpression regularExpressionWithPattern:@":\\s*([^\\d{,}][^\",\\}]+)(?=,|\\})" options:0 error:nil];
    NSString *quotedValuesString = [regexValues stringByReplacingMatchesInString:quotedKeysString options:0 range:NSMakeRange(0, quotedKeysString.length) withTemplate:@": \"$1\""];
    
    return quotedValuesString;
}

@implementation AppDelegate

@synthesize window;
@synthesize scrollView;
@synthesize contentView;
@synthesize processInfo;
@synthesize mainHelper;
@synthesize pid;

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)application {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)anotification {
    NSLog(@"[INFO] Exiting proccess with PID %@", self.pid);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    self.pid = [@([processInfo processIdentifier]) stringValue];
    self.mainHelper = [[Main_Helper alloc] init];
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    NSString *JSON_Data = @"";
    bool ShouldKill = NO;

    // Iterate over arguments, starting from index 1 to skip the app path
    for (NSUInteger i = 1; i < [arguments count]; i++) {
        NSString *argument = [arguments objectAtIndex:i];
        
        if ([argument isEqualTo:@"-updateJsonGameDataWithPathData"]) {
            if ([JSON_Data isEqualTo:@""]) {
                // Data is still nothing
                NSLog(@"[WARN] Data is still nothing exiting self!");
                [NSApp terminate:self];
            }
            
            // Correct JSON formatting
            NSString *correctedJsonData = [self correctJsonFormatting:JSON_Data];
            NSLog(@"[INFO] New json is %@",correctedJsonData);
            [self.mainHelper addToJson:correctedJsonData];
            NSLog(@"[INFO] Added to data!");
            ShouldKill = YES;
        }
        else if ([argument isEqualTo:@"-clearJsonGameData"]) {
            [self.mainHelper resetJson];
            ShouldKill = YES;
        }
        
        if ([argument hasPrefix:@"-"] && i + 1 < [arguments count]) {
            NSString *key = argument;
            NSString *value = [arguments objectAtIndex:i + 1];
            
            NSLog(@"[INFO] Argument: %@, Value: %@", key, value);
            
            if ([key isEqualTo:@"-JsonData"]) {
                JSON_Data = value;
            }
            
            // Skip the next argument as it's the value for the current key
            i++;
        }
    }
    
    if (ShouldKill)
    {
        [NSApp terminate:self];
    }

    self.scrollView = [[NSScrollView alloc] initWithFrame:self.window.contentView.frame];
    [self.scrollView setHasVerticalScroller:YES];
    self.scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    // Create a content view that will hold all framesx
    self.contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 600, 800)]; // Increase height for multiple items
    [self.scrollView setDocumentView:self.contentView];
        
    // Add the scroll view to the window's content view
    [self.window.contentView addSubview:self.scrollView];
    NSError *error = nil;
    NSString* path = [[self.mainHelper getApplicationSupportPath] stringByExpandingTildeInPath];
    path = [NSString stringWithFormat:@"%@%@", path, @"/game_watcher.json"];
    NSLog(@"[INFO] Looking in path %@", path);

    NSString *fileContents = [NSString stringWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];

    if (error) {
        NSLog(@"[ERROR] Could not read file: %@", error.localizedDescription);
        return; // Exit if there is an error reading the file
    }

    NSData *jsonData = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    NSDictionary *dataArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&jsonError];

    if (jsonError) {
        NSLog(@"[ERROR] Could not parse JSON: %@", jsonError.localizedDescription);
        return; // Exit if JSON parsing fails
    }

    NSLog(@"[INFO] Doing loop!");
    NSLog(@"[INFO] Data type: %@", [dataArray class]);
    BOOL Create2 = NO;
    for (NSString *key in dataArray) {
        if ([dataArray count] == 1)
        {
            Create2 = YES;
        }
        NSDictionary *item = dataArray[key];  // Get the dictionary associated with each key
        NSString *Game_Name = item[@"name"];
        NSString *Game_Img = item[@"img"];
        NSString *Game_Deeplink = item[@"deeplink"];
        NSString *StartTime = item[@"startTime"];
        NSString *EndTime = item[@"endTime"];
        NSLog(@"[INFO] Game data is: %@, %@, %@", Game_Name, Game_Img, Game_Deeplink);
        if (Create2)
        {
            [self.mainHelper addCustomFramesToContentView:self.contentView name:Game_Name imgUrl:Game_Img deepLink:Game_Deeplink startTime:StartTime endTime:EndTime shouldTimes2:YES];
        }
        else
        {
            [self.mainHelper addCustomFramesToContentView:self.contentView name:Game_Name imgUrl:Game_Img deepLink:Game_Deeplink startTime:StartTime endTime:EndTime shouldTimes2:NO];
        }
    }
        
    [self.window makeKeyAndOrderFront:nil];
}

- (NSString *)correctJsonFormatting:(NSString *)jsonString {
    // Replace single quotes with double quotes
    NSString *formattedString = [jsonString stringByReplacingOccurrencesOfString:@"'" withString:@"\""];

    // Ensure keys are quoted
    NSRegularExpression *keyRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<=^|,)([a-zA-Z0-9_]+):" options:0 error:nil];
    formattedString = [keyRegex stringByReplacingMatchesInString:formattedString
                                                         options:0
                                                           range:NSMakeRange(0, [formattedString length])
                                                    withTemplate:@"\"$1\":"];
    
    // Ensure values are quoted if they are not already quoted or numeric
    NSRegularExpression *valueRegex = [NSRegularExpression regularExpressionWithPattern:@":(?!\")([^\"\\r\\n]+)(?=[,}\\s])" options:0 error:nil];
    formattedString = [valueRegex stringByReplacingMatchesInString:formattedString
                                                           options:0
                                                             range:NSMakeRange(0, [formattedString length])
                                                      withTemplate:@":\"$1\""];
    
    // Ensure proper escaping for internal quotes
    formattedString = [formattedString stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""];
    
    // Remove any leading or trailing whitespace
    formattedString = [formattedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return formattedString;
}



@end
