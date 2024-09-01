#import "AppDelegate.h"
#import "helper.h"
#import "Logger.h"
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

        finalURLString = std::string([decodedURLString UTF8String]);
        if (runAppleScriptAndGetOutput(checkIfRobloxIsRunning) == "true")
        {
            std::string run_to_open_lol = "open -a /tmp/Roblox.app \"" + finalURLString + "\"";
            NSLog(@"[INFO] Ok got it running this command %s", run_to_open_lol.c_str());
            system(run_to_open_lol.c_str());
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
