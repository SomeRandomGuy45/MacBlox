//
//  AppDelegate.m
//  Smart Join
//

#import "AppDelegate.h"


@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize main_helper;
@synthesize gameId;
@synthesize customInstallPath;
@synthesize useLowPing;
@synthesize serverArrayFPS;
@synthesize serverArrayPING;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.serverArrayFPS = [NSMutableArray array];
    self.serverArrayPING = [NSMutableArray array];
    self.useLowPing = YES;
    self.main_helper = [Main_Helper alloc];
    if ([self.main_helper CheckIfRobloxIsRunning] == YES)
    {
        [self.closeButton setTitle:@"Join Server"];
    }
    else
    {
        NSLog(@"[INFO] Found roblox running");
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)lowping:(id)sender {
    NSLog(@"[INFO] Using Low Ping");
    self.useLowPing = YES;
}

- (IBAction)highfps:(id)sender {
    NSLog(@"[INFO] Using High FPS");
    self.useLowPing = NO;
}

- (IBAction)installPath:(id)sender {
    NSString *inputText = [self.installPathText stringValue];
    NSLog(@"[INFO] Install Path Text Info is %@", inputText);
    self.customInstallPath = inputText;
}

- (IBAction)Close:(id)sender {
    NSLog(@"[INFO] Button got pressed");
    /*
    *   Since i want this to work outside of macblox
    *   We will check if /Applications/Roblox.app exists
    *   If not we will check if /tmp/Roblox.app exists as well
    */
    BOOL FoundRobloxApp = NO;
    if ([self.main_helper doesFileExistAtPath:@"/Applications/Roblox.app"])
    {
        self.customInstallPath = @"/Applications/Roblox.app";
        FoundRobloxApp = YES;
    }
    if ([self.main_helper doesFileExistAtPath:@"/tmp/Roblox.app"])
    {
        self.customInstallPath = @"/tmp/Roblox.app";
        FoundRobloxApp = YES;
    }
    if ([self.customInstallPath length] != 0 && [self.main_helper doesFileExistAtPath:self.customInstallPath])
    {
        FoundRobloxApp = YES;
    }
    NSString *url = @"https://games.roblox.com/v1/games/";
    NSString *Server = @"/servers/0?sortOrder=2&excludeFullGames=true&limit=25";
    NSString *full_url = [NSString stringWithFormat:@"%@%@%@", url, self.gameId, Server];
    NSLog(@"[INFO] Full URL is %@", full_url);
    NSString* downloadData = [self.main_helper downloadFileWithoutDestination:full_url];
    NSLog(@"[INFO] Downloaded data is: %@", downloadData);
    NSDictionary *jsonDict = [self.main_helper decodeJSONString:downloadData];
    NSArray *dataArray = jsonDict[@"data"];
    if ([dataArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in dataArray) {
            //printDictionary(item);
            NSString* ID = item[@"id"];
            NSString* PING = item[@"ping"];
            NSString* FPS = item[@"fps"];
            NSDictionary* FPS_ITEM = @{@"name": ID, @"value" : FPS};
            NSDictionary* PING_ITEM = @{@"name": ID, @"value" : PING};
            [serverArrayFPS addObject:FPS_ITEM];
            [serverArrayPING addObject:PING_ITEM];
            NSLog(@"[INFO] ID is %@", ID);
            NSLog(@"[INFO] PING is %@", PING);
            NSLog(@"[INFO] FPS is %@", FPS);
        }
    } else {
        NSLog(@"Expected NSArray for 'data' but got %@", [dataArray class]);
    }
    NSString* serverId;
    if (self.useLowPing)
    {
        NSLog(@"[INFO] Using Low ping");
        int lowestPing = 0;
        for (NSDictionary *item in serverArrayPING) {
            NSString *name = item[@"name"];
            NSNumber *value = item[@"value"];
            NSLog(@"jobID: %@, PING: %@", name, value);
            int ping = [value intValue];
            if (lowestPing == 0)
            {
                lowestPing = ping;
                serverId = name;
            }
            else if (ping < lowestPing)
            {
                NSLog(@"[INFO] Found lower ping! with %@", value);
                lowestPing = ping;
                serverId = name;
                NSLog(@"[INFO] New Server ID is: %@", serverId);
            }
        }
    }
    else
    {
        NSLog(@"[INFO] Using High FPS");
        int highestPing = 0;
        for (NSDictionary *item in serverArrayPING) {
            NSString *name = item[@"name"];
            NSNumber *value = item[@"value"];
            NSLog(@"jobID: %@, FPS: %@", name, value);
            int FPS = [value intValue];
            if (highestPing == 0)
            {
                highestPing = FPS;
                serverId = name;
            }
            else if (FPS > highestPing)
            {
                NSLog(@"[INFO] Found highest fps! with %@", value);
                highestPing = FPS;
                serverId = name;
                NSLog(@"[INFO] New Server ID is: %@", serverId);
            }
        }
    }
    NSString *openCommand = @"open ";
    NSString *robloxOpen = @"\"roblox://experiences/start?placeId=";
    NSString *robloxEndCommand = @"&gameInstanceId=";
    NSString *FullOpenURL = [NSString stringWithFormat:@"%@%@%@%@%@\"", openCommand, robloxOpen, self.gameId, robloxEndCommand, serverId];
    NSLog(@"[INFO] Command going to run is: %@", FullOpenURL);
    [self.main_helper RunScript:FullOpenURL];
    //[NSApp terminate:self];
}
- (IBAction)gameId:(id)sender {
    /*
    * It does what u think it does
    * It gets the game id of a game
    */
    NSString *inputText = [self.gameIdText stringValue];
    NSLog(@"[INFO] Text Field Input: %@", inputText);
    if ([self.main_helper canConvertToLong:inputText])
    {
        self.gameId = inputText;
        NSLog(@"[INFO] Can be converted to a long");
    }
    else
    {
        self.gameId = [self.main_helper extractGameIDFromURL:inputText];
        NSLog(@"[INFO] Cannot be converted to a long. But game id is: %@", self.gameId);
    }
}

@end
