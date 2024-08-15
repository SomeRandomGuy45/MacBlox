//Some of this c++ code is from https://github.com/pizzaboxer/bloxstrap/blob/main/Bloxstrap/Integrations/ActivityWatcher.cs
//it is in c# but i was able to translate it to c++

/*

    TODO:
        Refactor and optimize the code into header files and other stuff could be like a v2

*/

#include <iostream>
#include <vector>
#include <libproc.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <cstring>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string>
#include <fstream>
#include <filesystem>
#include <regex>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <map>
#include <cstdlib>
#include <functional>
#include <sys/stat.h>   
//#include "discord-game-sdk/discord.h"
#include <curl/curl.h> //for downloading files
#include "curlpp/cURLpp.hpp" //requests with out creating files
#include "curlpp/Options.hpp"
#include <libgen.h>
#include <signal.h>  // For kill function
#include <errno.h>   // For errno
#include <thread>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <chrono>
#include <algorithm>
#include <CoreFoundation/CoreFoundation.h>
#include <DiskArbitration/DiskArbitration.h>
#include <sstream>
#include <condition_variable>
#include <mutex>
#include <stdexcept>
#include <future>
#include <ctime> 
#include <spawn.h>
#include <sys/wait.h>
#include <wx/notifmsg.h>
#include <wx/msgdlg.h> 
#include <unordered_set>
#include <utility>
#include "json.hpp"
#include "helper.h"

/*
struct DiscordState {
	std::unique_ptr<discord::Core> core;
};

namespace {
	volatile bool interrupted{ false };
}
*/

#ifdef __APPLE__
    bool canRun = true;
#else
    bool canRun = false;
#endif
bool isDebug = false;

std::string tempDirStr = getTemp();
std::string user = getenv("USER"); //gets the current user name
std::string logfile = "~/Library/Logs/Roblox/"; //gets the log directory path
bool isRblxRunning = false;
long placeId = 0;
std::string jobId = "";
std::string GameIMG = "";
std::string ActivityMachineAddress = "";
bool ActivityMachineUDMUX = false;
bool ActivityIsTeleport = false;
bool _teleportMarker = false;
bool _reservedTeleportMarker = false;
bool ActivityInGame;
std::time_t lastRPCTime = std::time(nullptr);
std::unordered_set<std::string> processedLogs;
std::thread discordThread; //CHANGE ME LATER WHEN DISCORD RPC C++ IS FIX LOL
std::mutex mtx;
std::condition_variable cv;
bool scriptFinished = true;
pid_t currentScriptPID = -1;
extern char **environ;
std::string basePythonScript = "python3 " + GetResourcesFolderPath() + "/discord.py";
bool isDiscordFound = true;
std::string temp_dir;
std::mutex temp_dir_mutex;
int64_t TimeStartedUniverse = 0;

namespace fs = std::filesystem;
using json = nlohmann::json;

enum CurrentTypes {
    Home,
    Public,
    Reserved,
    Private,
};

CurrentTypes Current = Home;

using ArgHandler = std::function<void(const std::string&)>;
std::map<std::string, ArgHandler> argTable;
std::unordered_map<std::string, std::string> GeolocationCache;

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    size_t written = fwrite(ptr, size, nmemb, stream);
    return written;
}

std::string GetDataFromURL(std::string URL)
{
    try {
        std::ostringstream os;
        os << curlpp::options::Url(URL);
        return os.str();
    } 
    catch (curlpp::LogicError &e)
    {
        std::cerr << "[ERROR] curlpp::LogicError: " << e.what() << std::endl;
        return e.what();
    }
    catch (curlpp::RuntimeError &e)
    {
        std::cerr << "[ERROR] curlpp::RuntimeError: " << e.what() << std::endl;
        return e.what();
    }
}

// Helper function to get the default temporary directory
std::string get_default_temp_dir() {
    #ifdef _WIN32
        char temp_path[MAX_PATH];
        if (GetTempPathA(MAX_PATH, temp_path)) {
            return std::string(temp_path);
        }
        return "";
    #else
        return fs::temp_directory_path().string();
    #endif
}

// Function to get the temporary directory as a string
std::string get_temp_dir() {
    std::lock_guard<std::mutex> lock(temp_dir_mutex);
    if (temp_dir.empty()) {
        temp_dir = get_default_temp_dir();
    }
    return temp_dir;
}

// Function to get the temporary directory as a byte vector
std::vector<uint8_t> get_temp_dir_bytes() {
    std::string temp_dir_str = get_temp_dir();
    return std::vector<uint8_t>(temp_dir_str.begin(), temp_dir_str.end());
}

void CreateNotification(const wxString &title, const wxString &message, int Timeout)
{
    if (Timeout != 0 && Timeout != -1)
    {
        Timeout = -1;
    }
    wxNotificationMessage notification(title, message);
    if (!notification.Show(Timeout))
    {
        std::cerr << "[ERROR] Failed to show notification" << std::endl;
    }
    else
    {
        std::cout << "[INFO] Notification shown successfully" << std::endl;
    }
}

std::future<std::string> GetServerLocation(const std::string& ActivityMachineAddress, bool ActivityInGame_) {
    if (GeolocationCache.find(ActivityMachineAddress) != GeolocationCache.end()) {
        // If the address is cached, return the cached location
        return std::async(std::launch::deferred, [ActivityMachineAddress]() {
            return GeolocationCache[ActivityMachineAddress];
        });
    }

    // If the address is not cached, perform a real HTTP request
    return std::async(std::launch::async, [ActivityMachineAddress, ActivityInGame_]() {
        try {
            std::string location;
            // Fetch JSON data from URL
            std::string getData = GetDataFromURL("https://ipinfo.io/" + ActivityMachineAddress + "/json");
            json ipInfo = json::parse(getData);
            if (isDebug)
            {
                std::cout << "[INFO] Location: " << ipInfo << std::endl;
            }
            if (ipInfo.is_null()) {
                return std::string("? (Lookup Failed)");
            }

            if (ipInfo.contains("country") && !ipInfo["country"].get<std::string>().empty()) {
                if (ipInfo.contains("city") && ipInfo.contains("region")) {
                    if (ipInfo["city"].get<std::string>() == ipInfo["region"].get<std::string>()) {
                        location = ipInfo["region"].get<std::string>() + ", " + ipInfo["country"].get<std::string>();
                    } else {
                        location = ipInfo["city"].get<std::string>() + ", " + ipInfo["region"].get<std::string>() + ", " + ipInfo["country"].get<std::string>();
                    }
                } else {
                    location = "?";
                }
            } else {
                location = "?";
            }

            if (!ActivityInGame_) {
                return std::string("? (Left Game)");
            }

            GeolocationCache[ActivityMachineAddress] = location;
            return location;
        }
        catch (const std::exception& ex) {
            std::cerr << "[ERROR] Failed to get server location for " << ActivityMachineAddress << ": " << ex.what() << "\n";
            return std::string("? (Lookup Failed)");
        }
    });
}

void InitTable()
{
    argTable["-d"] = [](const std::string&) {isDebug = true; };
    argTable["--debug"] = [](const std::string&) {isDebug = true; };
}

std::string fixPath(const std::string& path) {
    // Find the position of "private" in the path
    std::string delimiter = "private";
    size_t pos = path.find(delimiter);

    // If "private" is found, extract the substring starting from "private"
    if (pos != std::string::npos) {
        std::string fixedPath = path.substr(pos);
        // Replace all colons with slashes
        for (char& ch : fixedPath) {
            if (ch == ':') {
                ch = '/';
            }
        }
        return fixedPath;
    }
    
    // If "private" is not found, return an empty string or handle accordingly
    return "";
}

void executeScript(const std::string& script) {
    std::string path = GetResourcesFolderPath() + "/helper.sh";
    std::string chmodCommand = "chmod +x " + path;
    system(chmodCommand.c_str());
    scriptFinished = false;

    std::string appleScript = R"(osascript -e '
            tell application "System Events"
                set isTerminalRunning to (exists (processes whose name is "Terminal"))
            end tell

            if isTerminalRunning then
                do shell script "killall -QUIT Terminal"
            end if
            -- Wait a bit to ensure windows are closed
            delay 0.25
            -- Open a new Terminal window and run the script
            tell application "Terminal"
                do script ")" + path + R"("
            end tell')";

    std::cout << "[INFO] Running AppleScript command: " << appleScript << "\n";

    // Run the AppleScript command
    int result = system(appleScript.c_str());

    if (result != 0) {
        std::cerr << "[ERROR] Failed to execute the AppleScript." << std::endl;
        return;
    }
}

//Maybe make this a struct
static void UpdDiscordActivity(
    const std::string& details, 
    const std::string& state, 
    int64_t startTimestamp, 
    long AssetIDLarge, 
    long AssetIDSmall, 
    const std::string& largeImgText, 
    const std::string& smallImageText, 
    const std::string& button1Text, 
    const std::string& button2Text, 
    const std::string& button1url, 
    const std::string& button2url,
    int64_t endTimestamp
    )
{
    if (!isDiscordFound) {
        return;
    }

    // Set default timestamps if not provided
    startTimestamp = startTimestamp != 0 ? startTimestamp : time(0);

    // Set default asset IDs if not provided
    AssetIDLarge = AssetIDLarge != 0 ? AssetIDLarge : 0;
    AssetIDSmall = AssetIDSmall != 0 ? AssetIDSmall : 0;

    // Generate asset URLs
    std::string key_large = AssetIDLarge != 0 
        ? "https://assetdelivery.roblox.com/v1/asset/?id=" + std::to_string(AssetIDLarge) 
        : GameIMG;

    std::string key_small = "https://assetdelivery.roblox.com/v1/asset/?id=" + std::to_string(AssetIDSmall);
    if (AssetIDSmall == -1) {
        key_small = "roblox";
    }

    std::string new_script = basePythonScript + " \"" + details + "\" \"" + state + "\" " +
                         std::to_string(startTimestamp) + " " +
                         "\"" + key_large + "\" \"" + key_small + "\" \"" + largeImgText + "\" \"" + smallImageText + "\" " +
                         "\"" + button1Text + "\" \"" + button2Text + "\" \"" + button1url + "\" \"" + button2url + "\" " +
                         "\"/" + tempDirStr + "/discord-ipc-0\"" + " " + std::to_string(endTimestamp);

    std::cout << "[INFO] Running script: " << new_script << "\n";
    std::cout << canAccessFile("/" + (tempDirStr) + "discord-ipc-0") << "\n";
    std::ofstream scriptFile(GetResourcesFolderPath() + "/helper.sh");
    if (!scriptFile.is_open()) {
        return;
    }
    scriptFile << new_script;
    scriptFile.close();
    pid_t pidToTerminate = -1;
    {
        pidToTerminate = currentScriptPID;
        std::cout << "[INFO] PID is " << pidToTerminate << "\n";
    }
    
    if (pidToTerminate != -1) {
        std::cout << "[INFO] Terminating previous script with PID: " << pidToTerminate << "\n";
        kill(pidToTerminate, SIGINT);
        currentScriptPID = -1; // Reset PID after waiting
    }

    std::string ScriptNeededToRun = R"(
            tell application "System Events"
                set isTerminalRunning to (exists (processes whose name is "Terminal"))
            end tell
            if isTerminalRunning then
                do shell script "killall -QUIT Terminal"
            end if)";
    runAppleScriptAndGetOutput(ScriptNeededToRun);

    // Run the custom function in a separate thread
    discordThread = std::thread([new_script]() {
        executeScript(new_script);
    });

    discordThread.detach();

    std::cout << "[INFO] Updated activity" << "\n";
}


std::string getApplicationSupportPath() {
    const char* homeDir = std::getenv("HOME");  // Get the user's home directory
    if (!homeDir) {
        throw std::runtime_error("Failed to get home directory");
    }
    return std::string(homeDir);
}
std::string GetBasePath() {
    try {
        std::string appSupportPath = getApplicationSupportPath();
        
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

std::string getLatestLogFile(bool need) {
    std::vector<std::string> logFiles;

    // Iterate through the directory to find log files with "Player" in their name
    for (const auto& entry : fs::directory_iterator(logfile)) {
        if (entry.path().extension() == ".log" && entry.path().filename().string().find("Player") != std::string::npos) {
            logFiles.push_back(entry.path().string());
        }
    }

    if (logFiles.empty()) return "";

    // Find the latest log file by last modification time
    auto latestLogFile = *std::max_element(logFiles.begin(), logFiles.end(), [](const std::string& a, const std::string& b) {
        return fs::last_write_time(a) < fs::last_write_time(b);
    });
    
    return latestLogFile;
}

bool isRobloxRunning()
{
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
    std::string output = runAppleScriptAndGetOutput(script);
    return output == "true" ? true : false;
}

std::string ReadFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "[ERROR] Failed to open file: " << filename << std::endl;
        return "";
    }
    return std::string((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
}

std::string GetGameURL(long customID) {
    return "roblox://experiences/start?placeId="+ std::to_string(customID) +"&gameInstanceId=" + jobId;
}

json GetGameData(long customID) {
    // Download the JSON file
    std::string url_getunid = "https://apis.roblox.com/universes/v1/places/" + std::to_string(customID) + "/universe";
    std::string downloadedFilePath = GetDataFromURL(url_getunid);
    //std::cout << "[INFO] Got data " << downloadedFilePath << std::endl;
    json data;
    try {
        data = json::parse(downloadedFilePath);
    } catch (const json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    }

    // Extract the universe ID
    std::string universeID;
    try {
        // Check if 'universeId' is a number and convert it to string if needed
        if (data.contains("universeId")) {
            if (data["universeId"].is_number()) {
                universeID = std::to_string(data["universeId"].get<long>());
            } else if (data["universeId"].is_string()) {
                universeID = data["universeId"].get<std::string>();
            } else {
                std::cerr << "[ERROR] Unexpected type for 'universeId'" << std::endl;
            }
        } else {
            std::cerr << "[ERROR] 'universeId' not found in JSON" << std::endl;
        }
    } catch (const json::type_error& e) {
        std::cerr << "[ERROR] JSON type error: " << e.what() << std::endl;
    }
    std::cout << "[INFO] universeId: " << universeID << std::endl;
    if (!universeID.empty() && std::stol(universeID) <= 0) {
        universeID = std::to_string(std::stol(universeID) * -1);
    }
    std::cout << "[INFO] new universeId: " << universeID << std::endl;
    std::string URL = "https://games.roblox.com/v1/games?universeIds=" + universeID;
    std::cout << "[INFO] Downloading URL: " << URL << "\n";
    std::string downloadData = GetDataFromURL(URL);
    json data_game_data;
    try {
        data_game_data = json::parse(downloadData);
    } catch (const json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    }
    return data_game_data;
}

std::string GetGameThumb(long customID) {
    // Download the JSON file
    std::string url_getunid = "https://apis.roblox.com/universes/v1/places/" + std::to_string(customID) + "/universe";
    std::string downloadedFilePath = GetDataFromURL(url_getunid);
    //std::cout << "[INFO] Got data " << downloadedFilePath << std::endl;
    json data;
    try {
        data = json::parse(downloadedFilePath);
    } catch (const json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
        return "";
    }

    // Extract the universe ID
    std::string universeID;
    try {
        // Check if 'universeId' is a number and convert it to string if needed
        if (data.contains("universeId")) {
            if (data["universeId"].is_number()) {
                universeID = std::to_string(data["universeId"].get<long>());
            } else if (data["universeId"].is_string()) {
                universeID = data["universeId"].get<std::string>();
            } else {
                std::cerr << "[ERROR] Unexpected type for 'universeId'" << std::endl;
                return "";
            }
        } else {
            std::cerr << "[ERROR] 'universeId' not found in JSON" << std::endl;
            return "";
        }
    } catch (const json::type_error& e) {
        std::cerr << "[ERROR] JSON type error: " << e.what() << std::endl;
        return "";
    }
    std::cout << "[INFO] universeId: " << universeID << std::endl;
    if (!universeID.empty() && std::stol(universeID) <= 0) {
        universeID = std::to_string(std::stol(universeID) * -1);
    }
    std::cout << "[INFO] new universeId: " << universeID << std::endl;

    // Download the game thumbnail JSON file
    std::string gameThumbURL = "https://thumbnails.roblox.com/v1/games/icons?universeIds=" + universeID + "&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false";
    //std::string universeThumbnailResponsePath = DownloadFile(gameThumbURL, "getunid.json");
    // Read and parse the thumbnail JSON file
    std::string thumbnailFileContent = GetDataFromURL(gameThumbURL);
    json thumbnailData;
    try {
        thumbnailData = json::parse(thumbnailFileContent);
    } catch (const json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
        return "";
    }
    std::cout << thumbnailData["data"] << std::endl;
    std::string thumbnailUrl = "";
    for (const auto& item : thumbnailData["data"])
    {
        thumbnailUrl = item["imageUrl"].get<std::string>();
    }

    // Output the thumbnail URL
    std::cout << "[INFO] Game Thumbnail: " << thumbnailUrl << std::endl;

    return thumbnailUrl;
}

template <typename T>
std::string to_string(const T& value) {
    std::ostringstream oss;
    oss << value;
    return oss.str();
}


int64_t getCurrentTimeMillis() {
    // Get the current time point
    auto now = std::chrono::system_clock::now();
    
    // Convert time point to milliseconds since epoch
    auto duration = now.time_since_epoch();
    auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
    
    return millis;
}


void doFunc(const std::string& logtxt) {
    //std::cout << logtxt << std::endl;
    if (processedLogs.find(logtxt) != processedLogs.end()) {
        return; // Skip processing if the log entry has already been handled
    }
    processedLogs.insert(logtxt);
    if (logtxt.find("[FLog::SingleSurfaceApp] initiateTeleport") != std::string::npos) 
    {
        _teleportMarker = true;
        std::cout << "[INFO] Attempting to teleport into new server\n";
    }
    else if (_teleportMarker && logtxt.find("[FLog::GameJoinUtil] GameJoinUtil::initiateTeleportToReservedServer") != std::string::npos) 
    {
        _reservedTeleportMarker = true;
        std::cout << "[INFO] Attempting to join reserved server\n";
    } 
    else if (logtxt.find("[FLog::GameJoinUtil] GameJoinUtil::joinGamePostPrivateServer") != std::string::npos) 
    {
        Current = Private;
        std::cout << "[INFO] Attempting to join private server\n";
    } 
    else if (logtxt.find("[FLog::Output] ! Joining game") != std::string::npos && !ActivityInGame && placeId == 0 && (Current == Home)) 
    {
        std::regex pattern(R"(! Joining game '([0-9a-f\-]{36})' place ([0-9]+) at ([0-9\.]+))");
        std::smatch match;
        std::cout << logtxt << std::endl;
        if (std::regex_search(logtxt, match, pattern) && match.size() == 4) {
            ActivityInGame = false;
            placeId = std::stol(match[2].str());
            std::cout << "[INFO] Place id: " << placeId << std::endl;
            if (placeId <= 0)
            {
                placeId = placeId * -1; //this fixes a bug making the placeid negative
            }
            jobId = match[1].str();
            ActivityMachineAddress = match[3].str();

            if (_teleportMarker) {
                ActivityIsTeleport = true;
                _teleportMarker = false;
            }

            if (_reservedTeleportMarker) {
                Current = Reserved;
                _reservedTeleportMarker = false;
            }
            else
            {
                Current = Public;
            }

            std::cout << "[INFO] Joining Game (" << placeId << "/" << jobId << "/" << ActivityMachineAddress << ")" << std::endl;
        }
    }
    else if (logtxt.find("[FLog::Network] serverId:") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::regex pattern(R"(serverId: ([0-9\.]+)\|[0-9]+)");
        std::smatch match;

        if (std::regex_search(logtxt, match, pattern) && match.size() == 2 && match[1].str() == ActivityMachineAddress) {
            std::cout << "[INFO] Joined Game (" << placeId << "/" << jobId << "/" << ActivityMachineAddress << ")" << std::endl;
            ActivityInGame = true;
            std::future<std::string> test_ig = GetServerLocation(ActivityMachineAddress, ActivityInGame);
            std::string serverLocationStr = test_ig.get();
            std::cout << "[INFO] Server location: " << serverLocationStr << std::endl;
            wxString Title_Text = "";
            wxString ServerLocationText(serverLocationStr.c_str(), wxConvUTF8);
            wxString Msg_Text = "Located at " + ServerLocationText;
            if (Current != CurrentTypes::Home) {
                if (Current == CurrentTypes::Private) {
                    Title_Text = "Conntected to private server";
                }
                else if (Current == CurrentTypes::Reserved) {
                    Title_Text = "Conntected to reserved server";
                }
                else
                {
                    Title_Text = "Connected to public server";
                }
            }
            CreateNotification(Title_Text, Msg_Text, wxNotificationMessage::Timeout_Auto);
            //https://github.com/pizzaboxer/bloxstrap/blob/7e95fb4d8fc4d132ee4633ba38b68a384ff897da/Bloxstrap/Integrations/DiscordRichPresence.cs
            GameIMG = GetGameThumb(placeId);
            std::vector<std::pair<std::string, std::string>> buttonPairs;
            if (Current != CurrentTypes::Reserved && Current != CurrentTypes::Private)
            {
                std::string URL = GetGameURL(placeId);
                buttonPairs.emplace_back("Join Server", URL);
            }
            else
            {
                std::string URL = "https://www.roblox.com/home";
                buttonPairs.emplace_back("Roblox", URL);
            }
            std::string page = "https://www.roblox.com/games/" + std::to_string(placeId);
            buttonPairs.emplace_back("See game page",page);
            json GameDetails = GetGameData(placeId);
            std::string status = "";
            if (Current == CurrentTypes::Private)
            {
                status = "In a private server";
            }
            else if (Current == CurrentTypes::Reserved)
            {
                status = "In a reserved server";
            }
            else
            {
                status = "by " + to_string(GameDetails["data"][0]["creator"]["name"]);
                status.erase(std::remove(status.begin(), status.end(), '"'), status.end());
                if (GameDetails["data"][0]["creator"]["hasVerifiedBadge"])
                {
                    status += " ☑️";
                }
            }
            TimeStartedUniverse = getCurrentTimeMillis();
                        std::string gameName = to_string(GameDetails["data"][0]["name"]);
            if (!gameName.empty() && gameName.front() == '"' && gameName.back() == '"') {
                gameName = gameName.substr(1, gameName.size() - 2);
            }
            auto it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                [](const std::pair<std::string, std::string>& pair) {
                    return pair.first == "Join Server";
                });
            auto it2 = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                [](const std::pair<std::string, std::string>& pair) {
                    return pair.first == "See game page";
                });
            if (it != buttonPairs.end())
            {
                UpdDiscordActivity("Playing " + gameName, status, TimeStartedUniverse, 0, -1, gameName, "Roblox", it->first, it2->first, it->second, it2->second, 0);
            }
            else
            {
                it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                    [](const std::pair<std::string, std::string>& pair) {
                        return pair.first == "Roblox";
                    });
                UpdDiscordActivity("Playing " + gameName, status, TimeStartedUniverse, 0, -1, gameName, "Roblox", it->first, it2->first, it->second, it2->second, 0);
            }
        }
    } 
    else if (logtxt.find("[FLog::Network] Time to disconnect replication data:") != std::string::npos || logtxt.find("[FLog::SingleSurfaceApp] leaveUGCGameInternal") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::cout << "[INFO] User disconnected\n";
        jobId = "";
        placeId = 0;
        ActivityInGame = false;
        ActivityMachineAddress = "";
        ActivityMachineUDMUX = false;
        ActivityIsTeleport = false;
        Current = Home;
        GameIMG = "";
        TimeStartedUniverse = 0;
        std::string ScriptNeededToRun = R"(
            tell application "System Events"
                set isTerminalRunning to (exists (processes whose name is "Terminal"))
            end tell
            if isTerminalRunning then
                do shell script "killall -QUIT Terminal"
            end if)";
        runAppleScriptAndGetOutput(ScriptNeededToRun);
    }
    else if (logtxt.find("[FLog::Network] UDMUX Address = ") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::regex pattern(R"(UDMUX Address = ([0-9\.]+), Port = [0-9]+ \| RCC Server Address = ([0-9\.]+), Port = [0-9]+)");
        std::smatch match;
        if (isDebug)
        {
            std::cout << "[INFO] match data: " << match.str() << "\n";
        }
        if (std::regex_search(logtxt, match, pattern) && match.size() == 3 && match[2].str() == ActivityMachineAddress) {
            ActivityMachineAddress = match[1].str();
            ActivityMachineUDMUX = true;
            std::cout << "[INFO] Server is UDMUX protected (" << placeId << "/" << jobId << "/" << ActivityMachineAddress << ")" << std::endl;
        }
        else
        {
            std::cerr << "[ERROR] Something happened data" << logtxt << "\n";
        }
    }
    else if (logtxt.find("[FLog::Output] [BloxstrapRPC]") != std::string::npos && Current != Home)
    {
        std::cout << "[INFO] Last time since last RPC " << std::to_string(std::time(nullptr) - lastRPCTime) << "\n";
        if (std::time(nullptr) - lastRPCTime <= 1)
        {
            std::cout << "[WARN] Dropping message (rate limit exceeded)\n";
            return;
        }
        std::regex pattern("\\[BloxstrapRPC\\] (.*)");
        std::smatch match;
        if (std::regex_search(logtxt, match, pattern) && match.size() == 2)
        {
            std::string data = match[1].str();
            std::cout << "[INFO] BloxstrapRPC: " << data << "\n";
            json _data = json::parse(data);
            lastRPCTime = std::time(nullptr);
            std::cout << "[INFO] BloxstrapRPC dumped: " << _data.dump(4) << "\n";

            if (_data["command"] == "SetRichPresence")
            {
                GameIMG = GetGameThumb(placeId);
                std::vector<std::pair<std::string, std::string>> buttonPairs;

                if (Current != CurrentTypes::Reserved && Current != CurrentTypes::Private)
                {
                    std::string URL = GetGameURL(placeId);
                    buttonPairs.emplace_back("Join Server", URL);
                }
                else
                {
                    std::string URL = "https://www.roblox.com/home";
                    buttonPairs.emplace_back("Roblox", URL);
                }

                std::string page = "https://www.roblox.com/games/" + std::to_string(placeId);
                buttonPairs.emplace_back("See game page", page);

                json GameDetails = GetGameData(placeId);
                std::string status = "";

                if (Current == CurrentTypes::Private)
                {
                    status = "In a private server";
                }
                else if (Current == CurrentTypes::Reserved)
                {
                    status = "In a reserved server";
                }
                else
                {
                    status = "by " + to_string(GameDetails["data"][0]["creator"]["name"]);
                    status.erase(std::remove(status.begin(), status.end(), '"'), status.end());
                    if (GameDetails["data"][0]["creator"]["hasVerifiedBadge"])
                    {
                        status += " ☑️";
                    }
                }

                TimeStartedUniverse = getCurrentTimeMillis();

                std::string gameName = to_string(GameDetails["data"][0]["name"]);
                if (!gameName.empty() && gameName.front() == '"' && gameName.back() == '"')
                {
                    gameName = gameName.substr(1, gameName.size() - 2);
                }

                auto it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                    [](const std::pair<std::string, std::string>& pair) {
                        return pair.first == "Join Server";
                    });

                auto it2 = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                    [](const std::pair<std::string, std::string>& pair) {
                        return pair.first == "See game page";
                    });

                // Check for null values before attempting to get string values
                if (!_data["data"]["state"].is_null())
                    status = !_data["data"]["state"].get<std::string>().empty() ? _data["data"]["state"].get<std::string>() : status;

                std::string details = (!_data["data"]["details"].is_null() && !_data["data"]["details"].get<std::string>().empty()) 
                    ? _data["data"]["details"].get<std::string>() 
                    : "Playing " + gameName;

                std::string largeImageHover = (!_data["data"]["largeImage"]["hoverText"].is_null() && !_data["data"]["largeImage"]["hoverText"].get<std::string>().empty()) 
                    ? _data["data"]["largeImage"]["hoverText"].get<std::string>() 
                    : gameName;

                std::string smallImageHover = (!_data["data"]["smallImage"]["hoverText"].is_null() && !_data["data"]["smallImage"]["hoverText"].get<std::string>().empty()) 
                    ? _data["data"]["smallImage"]["hoverText"].get<std::string>() 
                    : "Roblox";

                long id_long = (!_data["data"]["largeImage"]["assetId"].is_null() && _data["data"]["largeImage"]["assetId"].get<long>() != 0) 
                    ? _data["data"]["largeImage"]["assetId"].get<long>() 
                    : 0;

                long id_small = (!_data["data"]["smallImage"]["assetId"].is_null() && _data["data"]["smallImage"]["assetId"].get<long>() != 0) 
                    ? _data["data"]["smallImage"]["assetId"].get<long>() 
                    : -1;

                int64_t timeEnd = (!_data["data"]["timeEnd"].is_null() && _data["data"]["timeEnd"].get<int64_t>() != 0) 
                    ? _data["data"]["timeEnd"].get<int64_t>() 
                    : 0;

                int64_t timeStart = (!_data["data"]["timeStart"].is_null() && _data["data"]["timeStart"].get<int64_t>() != 0) 
                    ? _data["data"]["timeStart"].get<int64_t>() 
                    : 0;

                if (it != buttonPairs.end())
                {
                    UpdDiscordActivity(details, status, timeStart, id_long, id_small, largeImageHover, smallImageHover, it->first, it2->first, it->second, it2->second, timeEnd);
                }
                else
                {
                    it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                        [](const std::pair<std::string, std::string>& pair) {
                            return pair.first == "Roblox";
                        });
                    UpdDiscordActivity(details, status, timeStart, id_long, id_small, largeImageHover, smallImageHover, it->first, it2->first, it->second, it2->second, timeEnd);
                }
            }
        }
    }
}

std::string GetCoolFile(const std::string& logDirectory) {
    std::vector<fs::directory_entry> files;
    
    for (const auto& entry : fs::directory_iterator(logDirectory)) {
        if (fs::is_regular_file(entry)) {
            files.push_back(entry);
        }
    }

    if (files.empty()) {
        return "";
    }

    auto latestFile = std::max_element(files.begin(), files.end(), [](const fs::directory_entry& a, const fs::directory_entry& b) {
        return fs::last_write_time(a) < fs::last_write_time(b);
    });

    return latestFile->path().string();
}

/*
void Update(DiscordState& state_)
{
   state_.core->RunCallbacks();
}
*/

std::string GetBashPath() {
    char buffer[PATH_MAX];
    uint32_t size = sizeof(buffer);
    
    if (_NSGetExecutablePath(buffer, &size) != 0) {
        return ""; // Return empty string on failure
    }
    
    // Ensure buffer is null-terminated
    buffer[PATH_MAX - 1] = '\0';
    
    // Get the directory of the executable
    char* dir = dirname(buffer);
    
    return std::string(dir);
}

int main(int argc, char* argv[]) {
    //discord::Core* core = nullptr;
    //DiscordState state;
    if (doesAppExist("/Applications/Discord.app"))
    {
        std::cout << "[INFO] Temp Directory: " << tempDirStr << std::endl;
        if (canAccessFile("/" + (tempDirStr) + "discord-ipc-0"))
        {
            std::cout << "[INFO] Discord IPC found\n";
        }
    }
    else
    {
        isDiscordFound = false;
    }
    std::cout << "[INFO] Base python command " << basePythonScript << "\n";
    //UpdDiscordActivity("Test", "Playing", 0, 154835815, 154835815, "Test", "Test", "Test 1", "Test 2", "https://www.roblox.com/home", "https://www.roblox.com");
    if (!canRun)
    {
        std::cerr << "[ERROR] This program can only be run on macOS\n";
        return 1;
    }
    
    InitTable();
    std::string defaultPath = "/Users/" + user + "/Library/Logs/Roblox";
    if (!CanAccessFolder(defaultPath))
    {
        std::cout << "[INFO] Defualt log directory url is: " << "file://localhost"+defaultPath << "\n";
        logfile = ShowOpenFileDialog("file://localhost"+defaultPath);
        if (logfile != "/Users/" + user + "/Library/Logs/Roblox")
        {
            std::string path = "The location of the Roblox log file isn't correct. The location of is /Users/" + user + "/Library/Logs/Roblox";
            wxString toWxString(path.c_str(), wxConvUTF8);
            int answer = wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);
            return -1;
        }
    }
    else
    {
        std::cout << "[INFO] We have access\n";
        logfile = defaultPath;
    }
    //GetGameThumb(18419624945);
    if (argc >= 2)
    {
        for (int i = 1; i < argc; ++i) 
        {
            std::string arg = argv[i];
            if (argTable.find(arg) != argTable.end()) {
                // Handle argument without additional value
                argTable[arg]("");
            }
        }
    }
    //CreateNotification("Hello world!", "Test lol", wxNotificationMessage::Timeout_Auto);
    std::cout << "[INFO] Username: " << user << ", path to log file is: " << logfile << "\n";
    //std::cout << "[INFO] start time " << time(0) << ", add time " << time(0) + 5 * 60 << "\n";
    if (!isRobloxRunning())
    {
        runApp("/Applications/Roblox.app", false);
    }
    else
    {
        terminateApplicationByName("Roblox");
        runApp("/Applications/Roblox.app", false);
    }
    do {} while (!isRobloxRunning());
    isRblxRunning = isRobloxRunning();
    std::this_thread::sleep_for(std::chrono::seconds(5));
    std::cout << "[INFO] Roblox player is running\n";
    std::string latestLogFile = getLatestLogFile(false);
    do {latestLogFile = getLatestLogFile(false);} while (latestLogFile.empty());
    std::cout << "[INFO] Reading log file now!\n";
    if (latestLogFile.empty()) {
        throw std::runtime_error("[ERROR] Roblox log file not found!");
    } else {
        std::filesystem::directory_entry logFileInfo;
        bool logUpdated = false;
        std::string logFilePath;
        while (true) {
            logFilePath = GetCoolFile(logfile);

            if (!logFilePath.empty()) {
                auto fileTime = fs::last_write_time(logFilePath);

                // vscode giving weird errors
                auto fileTimePoint = std::chrono::system_clock::time_point(
                    std::chrono::duration_cast<std::chrono::system_clock::duration>(
                        fileTime.time_since_epoch() - std::chrono::file_clock::now().time_since_epoch()
                    ) + std::chrono::system_clock::now().time_since_epoch()
                );

                auto now = std::chrono::system_clock::now();
                auto fifteenSecondsAgo = now - std::chrono::seconds(15);

                if (fileTimePoint > fifteenSecondsAgo) {
                    break;
                }
            }

            std::cout << "[INFO] Could not find recent enough log file, waiting... (newest is " << fs::path(logFilePath).filename().string() << ")\n";
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
        std::cout << "[INFO] Path is " << logFilePath << "\n";
        std::cout << "[INFO] Log updated: " << getLatestLogFile(true) << "\n";
        if (fs::path(getLatestLogFile(true)).filename().string() != fs::path(logFilePath).filename().string())
        {
            logFilePath = getLatestLogFile(true);
        }
        std::condition_variable logUpdatedEvent;
        std::mutex mtx;
        std::ifstream logFile(logFilePath);
        std::thread logThread([&]() {
            while (true) {
                if (!isRobloxRunning()) {
                    // Just in case
                    break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
                std::ifstream logFileStream(logFilePath);
                if (logFileStream) {
                    std::string line;
                    while (std::getline(logFileStream, line)) {
                        std::lock_guard<std::mutex> lock(mtx);
                        logUpdated = true;
                        logUpdatedEvent.notify_one();
                        if (isDebug) {
                            std::cout << "[INFO] new line: " << line << "\n";
                        }
                        doFunc(line);
                    }
                } else {
                    std::cerr << "[ERROR] Failed to open log file: " << logFilePath << std::endl;
                }
            }
        });
        logThread.detach();
        std::cout << "[INFO] Started main thread\n";
        while (isRobloxRunning()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(16));
            //Update(state);
        }
        logThread.~thread();
        discordThread.~thread();
    }
    std::string ScriptNeededToRun = R"(
            tell application "System Events"
                set isTerminalRunning to (exists (processes whose name is "Terminal"))
            end tell
            if isTerminalRunning then
                do shell script "killall -QUIT Terminal"
            end if)";
    runAppleScriptAndGetOutput(ScriptNeededToRun);
    std::cout << "[INFO] Closing program\n";
    return 0;
}