#include "BackgroundTask.h"
#include "helper.mm"

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

bool isRobloxRunning()
{
    std::string output = runAppleScriptAndGetOutput(script);
    return output == "true" ? true : false;
}

void runCppTask() {
    std::cout << "[INFO] Running C++ task!" << std::endl;
    start: //maybe find a different way...
    while (!isRobloxRunning()) {}
    std::cout << "[INFO] Roblox is running! Starting background task..." << std::endl
    
}