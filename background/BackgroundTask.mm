#include "BackgroundTask.h"
#include "helper.h"
#include <thread>
#include <Foundation/Foundation.h>
#include <string>
#include <dispatch/dispatch.h>
#include <filesystem>

namespace fs = std::filesystem;

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

// Function to get the parent folder name
std::string getParentFolderOfApp() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    return std::string([parentPath UTF8String]);
}

std::string checkParentDirectory(const std::string& pathStr) {
    fs::path currentPath(pathStr);

    // Traverse up the directory tree
    while (currentPath.has_parent_path()) {
        fs::path parentPath = currentPath.parent_path();

        if (parentPath.filename() == "Macblox") {
            return parentPath.string();
        }

        currentPath = parentPath;
    }

    return "No parent directory named 'Macblox' was found.";
}

void runCppTask() {
    std::string folder_parent_path = checkParentDirectory(getParentFolderOfApp());
    std::cout << "[INFO] Path to parent folder is: " << folder_parent_path << "\n";

    while (true) {
        while (!isRobloxRunning()) {}

        if (isRunnerRunning()) {
            std::cout << "[INFO] Runner is already running!" << std::endl;
            continue;
        }

        std::cout << "[INFO] Roblox is running! Starting background task..." << std::endl;
        runApp(folder_parent_path + "/Play.app", true);
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}
