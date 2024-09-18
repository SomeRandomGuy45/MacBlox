#include <fstream>
#include <filesystem>
#include <vector>

#include "json.hpp"

namespace fs = std::filesystem;
using json = nlohmann::json;

std::string USER = getenv("USER");
std::string Path = "/Users/" + USER + "/Library/Application Support/Macblox_Data";

std::vector<std::string> type_s = {
    "isDebug",
    "allowDownload",
    "allowSystemCommand",
    "disableAllAPI",
};

std::map<std::string, bool> CreateAndReadJson()
{
    std::map<std::string, bool> bools = {
        {"isDebug", false},
        {"allowDownload", true},
        {"allowSystemCommand", false},
        {"disableAllAPI", false},
    };
    fs::create_directories(Path);
    if (!fs::exists(Path + "/lua_flags.json"))
    {
        std::ofstream outfile(Path + "/lua_flags.json");
        json j;
        for (size_t i = 0; i < bools.size(); i++)
        {
            //we match the thing
            j[type_s[i]] = bools[type_s[i]];
        }
        outfile << j.dump(4);
        outfile.close();
    }
    std::ifstream infile(Path + "/lua_flags.json");
    json file_data;
    infile >> file_data;
    infile.close();
    for (const auto& data : file_data.items())
    {
        std::string key = data.key();
        for (const auto& value : type_s)
        {
            if (key == value)
            {
                bools[key] = data.value().get<bool>(); // if we are not a bool we crash lol
                break;
            }
        }
    }
    return bools;
}