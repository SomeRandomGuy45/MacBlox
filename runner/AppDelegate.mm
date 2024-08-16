#import "AppDelegate.h"

std::string currentUser = getenv("USER");

void executeAppleScript(NSString *scriptNSString) {
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptNSString];
    NSDictionary *errorDict = nil;
    [appleScript executeAndReturnError:&errorDict];
    if (errorDict) {
        NSLog(@"AppleScript Error: %@", errorDict);
    }
}

// Function to check if Roblox is running and close it
void checkAndCloseRoblox() {
    NSString *scriptNSString = 
    @"tell application \"System Events\"\n"
    @"    set robloxRunning to (exists (processes whose name is \"Roblox\"))\n"
    @"end tell\n"
    @"if robloxRunning then\n"
    @"    tell application \"Roblox\" to quit\n"
    @"end if";
    
    executeAppleScript(scriptNSString);
}

std::string time___() {
    time_t now = time(0);
    struct tm tstruct;
    char buf[80];
    if (localtime_r(&now, &tstruct) == nullptr) {
        return "[ERROR] Failed to get local time";
    }
    if (strftime(buf, sizeof(buf), "%Y-%m-%d-%H-%M-%S", &tstruct) == 0) {
        return "[ERROR] Failed to format time";
    }
    return buf;
}


std::string logPath() {
    std::string currentDate = time___();
    std::string path = "/Users/" + currentUser + "/Library/Logs/Macblox";
    if (std::filesystem::exists(path)) {
        NSLog(@"[INFO] Folder already exists.");
    } else {
        if (std::filesystem::create_directory(path)) {
            NSLog(@"[INFO] Folder created successfully.");
        } else {
            NSLog(@"[ERROR] Failed to create folder.");
            return "";
        }
    }
    return path + "/" + currentDate + "_runner_log.log";
}

std::string file_path = logPath();

void NSlog_funny(NSString *format, ...) {
    // Open the file in append mode
    FILE *logFile = fopen(file_path.c_str(), "a");

    if (logFile != nullptr) {
        va_list args;
        va_start(args, format);

        // Create an NSString with the formatted message
        NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];

        // Print to the console
        fprintf(stdout, "%s\n", [formattedMessage UTF8String]);

        // Print to the file
        fprintf(logFile, "%s\n", [formattedMessage UTF8String]);

        va_end(args);

        // Close the file
        fclose(logFile);
    } else {
        NSLog(@"Failed to open file for logging: %s", file_path.c_str());
    }
}

#define NSLog(format, ...) NSlog_funny(format, ##__VA_ARGS__)

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    main_loop();
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    std::cout << "[INFO] App is about to terminate\n";
    checkAndCloseRoblox();
}

@end
