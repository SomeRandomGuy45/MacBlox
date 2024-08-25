#import "AppDelegate.h"
#import "helper.h"
#import <Foundation/Foundation.h>

std::string getCurrentAppPath() {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appPath = [bundle bundlePath];
    return [appPath UTF8String];
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    runLoginInScript("Background_Runner", getCurrentAppPath());
    main_loop();
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    checkAndCloseRoblox();
    std::cout << "[INFO] App is about to terminate\n";
}

@end
