#include <filesystem>
#include <cstdlib>
#include <stdexcept>
#include <random>
#include <vector>
#include <semaphore.h>
#include <stdio.h>
#include <thread>
#include "functions/json.hpp"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AppDelegate.h"
#import "functions/helper.h"
#import "Logger.h"

namespace fs = std::filesystem;
using json = nlohmann::json;

BOOL WasReseting = NO;

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

inline std::string ScriptNeededToRun = R"(
            tell application "Terminal"
                -- Get a list of all windows
                set terminalWindows to windows
                
                -- Loop through each window and execute `exit`
                repeat with aWindow in terminalWindows
                    tell aWindow
                        do script "exit" in (selected tab of aWindow)
                    end tell
                end repeat
                delay 2
                -- Quit the Terminal application
                do shell script "killall -QUIT Terminal"
            end tell
            )";

bool isFound = true;

inline std::string GetBashPath() {
    // Get the application's base path using NSBundle
    NSString *basePath = [[NSBundle mainBundle] bundlePath];
    
    // Convert NSString to C-style string
    const char *basePathCString = [basePath UTF8String];
    
    // Convert C-style string to std::string
    std::string basePathString(basePathCString);
    
    return basePathString + "/Contents/MacOS";
}

class Copy {
public:
    explicit Copy(const std::string& dir) : dir_(dir) {}

    // Returns the path to the renamed Roblox app
    std::string Path() const {
        return dir_;
    }

    // Removes the copied directory
    void Close() {
        fs::remove_all(dir_);
    }

    pid_t PID = 0;

private:
    std::string dir_;
};

void ChangeMultiInstance(std::string path, bool allow)
{
    NSString* nsPlistPath = [NSString stringWithUTF8String:path.c_str()];
    NSString* nsKey = @"LSMultipleInstancesProhibited";

    // Load the plist file
    NSMutableDictionary* plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:nsPlistPath];
    if (!plistDict) {
        return; // Failed to load plist file
    }

    // Update the value for the specified key
    [plistDict setObject:@(allow) forKey:nsKey];

    // Write the updated dictionary back to the plist file
    BOOL success = [plistDict writeToFile:nsPlistPath atomically:YES];
    if (success == YES)
    {
        NSLog(@"[INFO] Changed LSMultipleInstancesProhibited value to: %s", allow == true ? "true" : "false");
    }
    else
    {
        NSLog(@"[ERROR] Failed to write LSMultipleInstancesProhibited value to plist file. Path to plist file is %@", nsPlistPath);
    }
}

int destroy_semaphore()
{
    //https://github.com/Insadem/multi-roblox-macos/blob/main/internal/syncbreaker/syncbreaker_darwin.go
    const char *sem_name = "/RobloxPlayerUniq";
    if (sem_unlink(sem_name) == -1)  // Attempt to destroy the semaphore
    {
        NSLog(@"[INFO] Failed to unlink");
        return 1;  // failed to destroy semaphore
    }
    NSLog(@"[INFO] Successfully destroyed");
    return 0;
}

bool BreakSemaphore()
{
    return destroy_semaphore() == 0;
}

std::string SupportPath() {
    const char* homeDir = std::getenv("HOME");  // Get the user's home directory
    if (!homeDir) {
        throw std::runtime_error("Failed to get home directory");
    }
    return std::string(homeDir) + "/Library/Application Support/MacBlox_Data";
}
std::string GetPath() {
    try {
        std::string appSupportPath = SupportPath();
        
        // Create the directory and any necessary parent directories
        if (fs::create_directories(appSupportPath)) {
            //std::cout << "[INFO] Directory created successfully: " << appSupportPath << std::endl;
        } else {
            //std::cout << "[INFO] Directory already exists or failed to create: " << appSupportPath << std::endl;
        }
        return appSupportPath;
    } catch (const fs::filesystem_error& e) {
        std::cerr << "[ERORR] Filesystem error: " << e.what() << std::endl;
        return "";
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] " << e.what() << std::endl;
        return "";
    }
}

// Function to create a temporary directory
std::string copyDestDir() {
    fs::path tempDir = fs::temp_directory_path();

    return tempDir.string();
}

// Function to generate a random name for the app
std::string generateRandomName() {
    std::random_device rd;
    std::mt19937 generator(rd());
    std::uniform_int_distribution<int> distribution(1000, 9999);

    return "Roblox_" + std::to_string(distribution(generator)) + ".app";
}

// Function to create a new copy of Roblox and rename it with a random name
Copy NewCopy() {
    std::string sourcePath = fs::temp_directory_path().string() + "/Roblox.app";
    std::string destDir = copyDestDir();

    // Copy Roblox.app to the destination directory
    std::string command = "cp -a " + sourcePath + " " + destDir;
    int result = std::system(command.c_str());

    if (result != 0) {
        throw std::runtime_error("[ERROR] Failed to copy Roblox.app");
    }

    // Generate a random name and rename the copied Roblox.app
    std::string randomName = generateRandomName();
    fs::path oldPath = destDir + "/Roblox.app";
    fs::path newPath = destDir + "/" + randomName;
    
    try {
        fs::rename(oldPath, newPath);
    } catch (const std::exception& e) {
        throw std::runtime_error("[ERROR] Failed to rename Roblox.app: " + std::string(e.what()));
    }

    // Update dir_ to point to the renamed app
    return Copy(newPath.string());
}

pid_t openAppAndGetPID(const std::string& appPath, const std::string& url) {
    NSString *openCommand = [NSString stringWithFormat:@"open -a \"%s\" \"%s\" -n --args", appPath.c_str(), url.c_str()];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", openCommand]];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];

    [task launch];
    [task waitUntilExit];

    // Extract the PID of the launched app
    pid_t pid = [task processIdentifier];

    // Log the PID
    NSLog(@"[INFO] Launched app with PID: %d", pid);

    return pid;
}

std::vector<Copy> copyPaths;

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
    return;
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

std::string convertToLowercase(const std::string& str) 
{ 
    std::string result = ""; 
  
    for (char ch : str) { 
        // Convert each character to lowercase using tolower 
        result += tolower(ch); 
    } 
  
    return result; 
} 

bool killAppByPID(pid_t pid) {
    int result = kill(pid, SIGTERM); // You can also use SIGKILL for a forceful kill
    if (result == 0) {
        NSLog(@"[INFO] Successfully terminated the app with PID: %d", pid);
        return true;
    } else {
        NSLog(@"[ERROR] Failed to terminate the app with PID: %d. Error: %s", pid, strerror(errno));
        return false;
    }
}

pid_t getAppPID(NSString *appName) {
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    for (NSRunningApplication *app in runningApps) {
        if ([[app localizedName] isEqualToString:appName]) {
            return [app processIdentifier];
        }
    }
    
    // If the app is not found, return -1 (indicating no PID was found)
    return -1;
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
            bool shouldAllow = false;
            std::string bootstrapData = FileChecker(GetPath() + "/bootstrap_data.json");
            NSLog(@"[INFO] Bootstrap data file: %s", bootstrapData.c_str());
            if (!bootstrapData.empty())
            {
                json JsonData = json::parse(bootstrapData);
                if (JsonData.contains("Allow Multiple Instance"))
                {
                    std::string AllowMultiple = convertToLowercase(JsonData["Allow Multiple Instance"].get<std::string>());
                    if (AllowMultiple.find("true") != std::string::npos)
                    {
                        shouldAllow = true;
                    }
                    else
                    {
                        shouldAllow = false;
                    }
                }
            }
            if (shouldAllow)
            {
                try {
                    Copy robloxCopy = NewCopy();
                    NSLog(@"[INFO] New Copy at roblox %s", robloxCopy.Path().c_str());
                    copyPaths.push_back(robloxCopy);
                    BreakSemaphore();
                    std::string OpenCommand = "open -a \"" + robloxCopy.Path() + "\" \"" + finalURLString + "\"";
                    NSLog(@"[INFO] Open command: %s", OpenCommand.c_str());
                    robloxCopy.PID = openAppAndGetPID(robloxCopy.Path(), finalURLString);
                    ChangeMultiInstance(robloxCopy.Path() + "/Contents/Info.plist", false); // wouldn't you have to like resign?
                    BreakSemaphore();
                    //robloxCopy.Close();
                } catch (const std::exception& e) {
                    std::cerr << "[ERROR] " << e.what() << std::endl;
                }
            }
            else
            {
                std::string run_to_open_lol = "open -a \"" + fs::temp_directory_path().string() + "/Roblox.app\" \"" + finalURLString + "\"";
                NSLog(@"[INFO] Ok got it running this command %s", run_to_open_lol.c_str());
                system(run_to_open_lol.c_str());
            }
        }
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //runLoginInScript("Background_Runner", getCurrentAppPath());
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    self.pid = [@([processInfo processIdentifier]) stringValue];
    NSLog(@"[INFO] App's PID: %@", self.pid);
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *termProgram = environment[@"TERM_PROGRAM"];
    
    if ([termProgram length] != 0 && ![termProgram isEqualTo:@"vscode"])
    {
        NSLog(@"[INFO] App environment: %@", termProgram);
        //WasReseting = YES;
        //[NSApp terminate:nil];
    }

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
    if (WasReseting)
    {
        //We are just reseting the app to launch outside of the terminal
        NSURL *urlToOpen = [NSURL URLWithString:@"roblox://"];
        if ([[NSWorkspace sharedWorkspace] openURL:urlToOpen])
        {
            NSLog(@"[OK] Relaunching application successfully!");
            return;
        }
        NSLog(@"[ERROR] Cannot open URL!");
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        return;
    }
    std::string filename = GetResourcesFolderPath() + "/kill.txt";

    std::ofstream outfile(filename);

    if (outfile.is_open()) {
        // Write to the file
        outfile << "if kill then kill_thing() end" << std::endl;
        outfile.close();
    }

    NSLog(@"[INFO] Did kill.txt file");

    try {
        if (std::filesystem::remove(filename)) {
            NSLog(@"[INFO] Successfully deleted kill.txt" );
        }
    } catch (const std::filesystem::filesystem_error& e) {
        std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
    }
    quitTerminal();
    checkAndCloseRoblox();
    for (auto &app_copy : copyPaths)
    {
        NSLog(@"[INFO] Closing multiple app at: %s", app_copy.Path().c_str());
        app_copy.Close();
        killAppByPID(app_copy.PID);
    }
    std::string Command = GetBashPath() + "/GameWatcher.app/Contents/MacOS/GameWatcher -clearJsonGameData";
    std::cout << "[INFO] Command is: " << Command << "\n";
    system(Command.c_str());
    NSLog(@"[INFO] App is about to terminate\n");
}

@end
