#import "AppDelegate.h"
#import "helper.h"
#import <Foundation/Foundation.h>

std::string finalURLString = "";
std::string checkIfRobloxIsRunning = R"(
                    tell application "System Events"
                        set appList to name of every process
                    end tell

                    if "RobloxPlayer" is in appList then
                        return "true"
                    else
                        return "false"
                    end if
                            )";

bool isFound = true;

std::string getCurrentAppPath() {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appPath = [bundle bundlePath];
    return [appPath UTF8String];
}

bool isAppRunningTerminal() {
    std::string command = "pgrep -x \"Terminal\" > /dev/null 2>&1";
    return system(command.c_str()) == 0;
}

void quitTerminal() {
    std::string command = "osascript -e 'do shell script \"killall -QUIT Terminal\"'";
    system(command.c_str());
}

void runLoginInScript(const std::string& appName, const std::string& appPath) {
    std::string escapedAppPath;
    for (char c : appPath) {
        if (c == '"') {
            escapedAppPath += "\\\"";
        } else if (c == '\\') {
            escapedAppPath += "\\\\";
        } else {
            escapedAppPath += c;
        }
    }

    // Construct the AppleScript content
    std::string script =
        "property appName : \"" + appName + "\"\n"
        "property appPath : \"" + escapedAppPath + "\"\n"
        "\n"
        "on isLoginItem()\n"
        "    set loginItems to (do shell script \"osascript -e 'tell application \\\"System Events\\\" to get the name of every login item'\")\n"
        "    return loginItems contains appName\n"
        "end isLoginItem\n"
        "\n"
        "on addLoginItem()\n"
        "    do shell script \"osascript -e 'tell application \\\"System Events\\\" to make new login item at end with properties {name:\\\"" + appName + "\\\", path:\\\"" + escapedAppPath + "\\\", hidden:false}'\"\n"
        "end addLoginItem\n"
        "\n"
        "if not (isLoginItem()) then\n"
        "    display dialog \"Would you like to add \" & appName & \" to your login items to start automatically on login?\" buttons {\"Cancel\", \"Add\"} default button \"Add\"\n"
        "    if button returned of result is \"Add\" then\n"
        "        addLoginItem()\n"
        "    end if\n"
        "end if\n";

    // Write the AppleScript to a temporary file
    const char* tempScriptPath = "/tmp/checkLoginItems.applescript";
    std::ofstream tempScriptFile(tempScriptPath);
    if (!tempScriptFile) {
        std::cerr << "[ERROR] Unable to create temporary AppleScript file." << std::endl;
        return;
    }
    tempScriptFile << script;
    tempScriptFile.close();

    // Execute the AppleScript file
    std::string command = "osascript " + std::string(tempScriptPath);
    std::cout << "[INFO] Executing command: " << command << std::endl; // For debugging
    int result = system(command.c_str());
    if (result != 0) {
        std::cerr << "[ERROR] AppleScript execution failed." << std::endl;
    }

    // Clean up the temporary file
    std::remove(tempScriptPath);
}

// Function to check if Roblox is running and close it
void checkAndCloseRoblox() {
    terminateApplicationByName("Roblox");
}

std::string currentDateTime_() {
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

std::string getLogPath_() {
    std::string currentDate = currentDateTime_();
    std::string path = "/Users/" + std::string(getenv("USER")) + "/Library/Logs/Macblox";
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
    return path + "/" + currentDate + "_runner_ad_task_log.log";
}

std::string filePath_ = getLogPath_();

void CustomNSLog_(NSString *format, ...) {
    // Open the file in append mode
    FILE *logFile = fopen(filePath_.c_str(), "a");

    if (logFile != nullptr) {
        va_list args;
        va_start(args, format);

        // Create an NSString with the formatted message
        NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];

        // Get the current time with microseconds
        struct timeval tv;
        gettimeofday(&tv, NULL);

        // Format the time
        struct tm *timeinfo;
        char timeBuffer[80];
        timeinfo = localtime(&tv.tv_sec);
        strftime(timeBuffer, sizeof(timeBuffer), "%Y-%m-%d %H:%M:%S", timeinfo);

        // Calculate milliseconds
        int milliseconds = tv.tv_usec / 1000;

        // Get the current process ID and process name
        pid_t pid = [[NSProcessInfo processInfo] processIdentifier];
        NSString *processName = [[NSProcessInfo processInfo] processName];

        // Format the log message to match the NSLog style
        NSString *logEntry = [NSString stringWithFormat:@"%s.%03d %s[%d:%x] %s\n",
                              timeBuffer,
                              milliseconds,
                              [processName UTF8String],
                              pid,
                              (unsigned int)pthread_mach_thread_np(pthread_self()),
                              [formattedMessage UTF8String]];

        // Print to the console
        fprintf(stdout, "%s", [logEntry UTF8String]);

        // Print to the file
        fprintf(logFile, "%s", [logEntry UTF8String]);

        va_end(args);

        // Close the file
        fclose(logFile);
    } else {
        NSLog(@"[ERROR] Failed to open file for logging: %s", filePath_.c_str());
    }
}

#define NSLog(format, ...) CustomNSLog_(format, ##__VA_ARGS__)

@implementation AppDelegate

- (instancetype)initWithArguments:(NSArray *)arguments {
    self = [super init];
    if (self) {
        _arguments = arguments;
    }
    return self;
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        NSLog(@"[INFO] App opened with URL: %@", url);
        
        // Get the URL as a string
        NSString *urlString = [url absoluteString];
        
        // Replace "placeid/=" with "placeId="
        if ([urlString containsString:@"placeid/="]) {
            urlString = [urlString stringByReplacingOccurrencesOfString:@"placeid/=" withString:@"placeId="];
            NSLog(@"[INFO] Updated URL after replacement: %@", urlString);
        }

        // Decode the URL string
        NSString *decodedURLString = [urlString stringByRemovingPercentEncoding];
        NSLog(@"[INFO] Decoded URL: %@", decodedURLString);
        NSLog(@"[INFO] URL scheme: %@", [url scheme]);

        // Check if the scheme is "roblox-player"
        if ([[url scheme] isEqualToString:@"roblox-player"] || [urlString containsString:@"roblox-player://"]) {
            // Manually parse the query items
            NSString *queryString = [[decodedURLString componentsSeparatedByString:@"?"] lastObject];
            NSArray<NSString *> *queryItems = [queryString componentsSeparatedByString:@"&"];
            
            NSString *newScheme = @"roblox";
            NSString *newPath = @"//experiences/start";
            NSString *placeIdValue = nil;
            NSString *accessCodeValue = nil;
            
            for (NSString *queryItem in queryItems) {
                NSArray<NSString *> *pair = [queryItem componentsSeparatedByString:@"="];
                if ([pair count] == 2) {
                    NSString *key = pair[0];
                    NSString *value = pair[1];
                    NSLog(@"[INFO] Found item: %@ = %@", key, value);

                    if ([key isEqualToString:@"placeId"] || [key isEqualToString:@"roblox-player://placeId"]) {
                        placeIdValue = value;
                    } else if ([key isEqualToString:@"gameId"]) {
                        accessCodeValue = value;
                    }
                }
            }
            
            if (placeIdValue) {
                // Construct the new URL
                NSMutableString *newURLString = [NSMutableString stringWithFormat:@"%@:%@?placeId=%@", newScheme, newPath, placeIdValue];
                
                // Add accessCode as gameInstanceId if it exists
                if (accessCodeValue) {
                    [newURLString appendFormat:@"&gameInstanceId=%@", accessCodeValue];
                }
                
                finalURLString = std::string([newURLString UTF8String]);
                if (runAppleScriptAndGetOutput(checkIfRobloxIsRunning) == "true")
                {
                    std::string run_to_open_lol = "open \"" + finalURLString + "\"";
                    NSLog(@"[INFO] Ok got it running this command %s", run_to_open_lol.c_str());
                    system(run_to_open_lol.c_str());
                }

                // Log the final URL
                NSLog(@"[INFO] Modified URL: %s", finalURLString.c_str());
            } else {
                NSLog(@"[WARN] placeId not found in the URL");
            }
        }
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //runLoginInScript("Background_Runner", getCurrentAppPath());
    if (!doesAppExist("/Applications/Discord.app"))
    {
        NSLog(@"[INFO] Discord not found in /Applications/Discord.app");
        isFound = false;
    }
    if (!isAppRunning("Discord"))
    {
        NSLog(@"[INFO] Discord not running");
        isFound = false;
    }
    main_loop(_arguments, finalURLString, isFound);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (isAppRunning("Terminal")) {
        quitTerminal();
    }
    checkAndCloseRoblox();
    NSLog(@"[INFO] App is about to terminate\n");
}

@end
