#import "AppDelegate.h"
#import "BackgroundTask.h"
#import "StartAtLoginController.h"
#import <ServiceManagement/ServiceManagement.h>
#include <stdlib.h>
#include <fstream>

std::string getCurrentAppPath() {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appPath = [bundle bundlePath];
    return [appPath UTF8String];
}

void runAppleScript(const std::string& appName, const std::string& appPath) {
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

std::string current_user = getenv("USER")

std::string getLogPath() {
    std::string currentDate = currentDateTime();
    std::string path = "/Users/" + current_user + "/Library/Logs/Macblox";
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
    return path + "/" + currentDate + "_background_log.log";
}

std::string filePath = getLogPath();

void CustomNSLog(NSString *format, ...) {
    // Open the file in append mode
    FILE *logFile = fopen(filePath.c_str(), "a");

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
        NSLog(@"Failed to open file for logging: %s", filePath.c_str());
    }
}

#define NSLog(format, ...) CustomNSLog(format, ##__VA_ARGS__)


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self addToLoginItems];
    // Run C++ Task
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[INFO] Running C++ Task.");
        });
        runCppTask();
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Clean up if needed
}

// Add the app to login items
- (void)addToLoginItems {
    runAppleScript("BackgroundApp", getCurrentAppPath());
}

@end