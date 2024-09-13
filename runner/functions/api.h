#include <iostream>
#include <unordered_map>
#include <memory>
#include <functional>
#include <string>
#include <cstdlib>
#include <cstdio>
#include "function_wrapper.h"
#include "helper.h"
#include "main_helper.h"

std::unordered_map<std::string, std::unique_ptr<FunctionWrapper>> functionList;

std::string runCommand(const std::string& command) {
    std::string result;
    char buffer[128];
    FILE* pipe = popen(command.c_str(), "r");
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
    }
    pclose(pipe);
    return result;
}


namespace API
{
    void test_api()
    {
        std::cout << "[INFO-LUA] test_api!" << std::endl;
    }

    bool isDiscordRunning()
    {
        std::string command = "ps aux | grep '[d]iscord'"; // Avoid matching the grep command itself
        std::string output = runCommand(command);
        //std::cout << output << "\n";
        return !output.empty();
    }

    void UpdateDiscord(std::string details, 
        std::string state, 
        int64_t startTimestamp, 
        int64_t endTimestamp,
        long AssetIDLarge, 
        long AssetIDSmall, 
        std::string largeImgText, 
        std::string smallImageText, 
        std::string button1Text, 
        std::string button2Text, 
        std::string button1url, 
        std::string button2url)
    {
        UpdDiscordActivity(details, state, startTimestamp, AssetIDLarge, AssetIDSmall, largeImgText, smallImageText, button1Text, button2Text, button1url, button2url, endTimestamp);
    }
}
