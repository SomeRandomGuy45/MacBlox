#include "BackgroundTask.h"
#include "helper.h"
#include <thread>
#include <Foundation/Foundation.h>

std::string script = R"(
        tell application "System Events"
            set appList to name of every process
        end tell

        if "RobloxPlayer" is in appList then
            return "true"
        else
            return "false"
        end if
    )";

std::string script_player = R"(
        tell application "System Events"
            set appList to name of every process
        end tell

        if "play" is in appList then
            return "true"
        else
            return "false"
        end if
    )";

bool isRobloxRunning()
{
    std::string output = runAppleScriptAndGetOutput(script);
    return output == "true" ? true : false;
}


bool isRunnerRunning()
{
    std::string output = runAppleScriptAndGetOutput(script_player);
    return output == "true" ? true : false;
}

std::string getParentFolderOfApp() {
    // Get the bundle path
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    // Get the parent directory of the bundle
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    // Convert NSString to std::string
    return std::string([parentPath UTF8String]);
}

void runCppTask() {
    std::string folder_parent_path = getParentFolderOfApp();
    std::cout << "[INFO] Path to parent folder is: " << folder_parent_path << "\n";

    while (true) {
        while (!isRobloxRunning()) {}

        if (isRunnerRunning()) {
            std::cout << "[INFO] Runner is already running!" << std::endl;
            continue;
        }

        std::cout << "[INFO] Roblox is running! Starting background task..." << std::endl;
        runApp(folder_parent_path + "/Play.app", true);
    }
}