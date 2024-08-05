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
#include <functional>
#include <sys/stat.h>
#include <discord-rpc/discord_rpc.h>
#include <discord-rpc/discord_register.h>
#include <curl/curl.h> //for downloading files
#include <curlpp/cURLpp.hpp> //requests with out creating files
#include <curlpp/Options.hpp>
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
#include <wx/notifmsg.h>
#include <unordered_set>
#include "json.hpp"
#include "helper.h"
#include "AppDelegate.h"

std::string user = getenv("USER"); //gets the current user name
std::string logfile = "~/Library/Logs/Roblox/"; //creates the log directory path
bool isRblxRunning = false;
int placeId = 0;
std::string jobId = "";
std::string GameIMG = "";
std::string ActivityMachineAddress = "";
bool ActivityMachineUDMUX = false;
bool ActivityIsTeleport = false;
bool _teleportMarker = false;
bool _reservedTeleportMarker = false;
bool ActivityInGame;
int64_t lastRPCTime = 0;
std::unordered_set<std::string> processedLogs;
#ifdef __APPLE__
    bool canRun = true;
#else
    bool canRun = false;
#endif
bool isDebug = false; //todo

namespace fs = std::filesystem;
using json = nlohmann::json;

enum CurrentTypes {
    Home,
    Public,
    Reserved,
    Private,
};

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

void InitDiscord()
{
    DiscordEventHandlers handlers;
    memset(&handlers, 0, sizeof(handlers)); //memset funny
    handlers.ready = [](const DiscordUser* user) {
        std::cout << "[INFO] Connected as: " << user->username << "\n";
    };
    handlers.errored = [](int errorCode, const char* message) {
        std::cerr << "[ERROR] " << message << " (" << errorCode << ")\n";
    };
    Discord_Initialize("1267308900420419664", &handlers, 1, NULL);
}

void UpdDiscordActivity(std::string details, std::string state, std::string button1_url, std::string button2_url, std::string button1_label, std::string button2_label, int64_t startTimestamp, int64_t endTimestamp, int AssetIDLarge, int AssetIDSmall, std::string largeImgText, std::string smallImageText)
{
    DiscordRichPresence presence;
    startTimestamp = startTimestamp != 0 ? startTimestamp : time(0);
    endTimestamp = endTimestamp != 0 ? endTimestamp : time(0) + 5 * 60;
    AssetIDLarge = AssetIDLarge != 0 ? AssetIDLarge : 0;
    AssetIDSmall = AssetIDSmall != 0 ? AssetIDSmall : 0;
    std::string key_large = AssetIDLarge != 0 ? "https://assetdelivery.roblox.com/v1/asset/?id=" + std::to_string(AssetIDLarge) : GameIMG;
    std::string key_small = "https://assetdelivery.roblox.com/v1/asset/?id=" + std::to_string(AssetIDSmall);
    memset(&presence, 0, sizeof(presence));
    presence.button1_url = button1_url.c_str();
    presence.button2_url = button2_url.c_str();
    presence.button1_label = button1_label.c_str();
    presence.button2_label = button2_label.c_str();
    presence.details = details.c_str();
    presence.state = state.c_str();
    presence.startTimestamp = startTimestamp;
    presence.endTimestamp = endTimestamp;
    presence.largeImageKey = key_large.c_str();
    presence.largeImageText = largeImgText.c_str();
    presence.smallImageKey = key_small.c_str();
    presence.smallImageText = smallImageText.c_str();
    Discord_UpdatePresence(&presence);
}

CurrentTypes Current = Home;
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

std::string getLatestLogFile() {
    return getLogFile(logfile);
}

bool isRobloxRunning()
{
    return isAppRunning("Roblox");
}

std::string ReadFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "[ERROR] Failed to open file: " << filename << std::endl;
        return "";
    }
    return std::string((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
}

std::string GetGameThumb(long customID) {
    // Define or replace placeId with your actual value
    customID = customID == 0 ? placeId : customID;

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
                universeID = std::to_string(data["universeId"].get<int>());
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

void doFunc(const std::string& logtxt) {
    //std::cout << logtxt << std::endl;
    if (processedLogs.find(logtxt) != processedLogs.end()) {
        return; // Skip processing if the log entry has already been handled
    }
    processedLogs.insert(logtxt);
    if (logtxt.find("[FLog::GameJoinUtil] GameJoinUtil::initiateTeleportToReservedServer]") != std::string::npos) 
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
    else if (logtxt.find("[FLog::Output] ! Joining game") != std::string::npos && !ActivityInGame && placeId == 0 && Current == Home) 
    {
        std::regex pattern(R"(! Joining game '([0-9a-f\-]{36})' place ([0-9]+) at ([0-9\.]+))");
        std::smatch match;

        if (std::regex_search(logtxt, match, pattern) && match.size() == 4) {
            ActivityInGame = false;
            placeId = std::stoll(match[2].str());
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
            CreateNotification(Title_Text, Msg_Text, -1);
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
    }
    else if (logtxt.find("[FLog::Network] UDMUX Address = ") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::regex pattern(R"(UDMUX Address = ([0-9\.]+), Port = [0-9]+ \| RCC Server Address = ([0-9\.]+), Port = [0-9]+)");
        std::smatch match;
        std::regex_search(logtxt, match, pattern);
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
        if (time(0) - lastRPCTime <= 1)
        {
            return;
        }
        std::regex pattern("\\[BloxstrapRPC\\] (.*)");
        std::smatch match;
        std::regex_search(logtxt, match, pattern);
        std::string data = match[1].str();
        std::cout << "[INFO] BloxstrapRPC: " << data << "\n";
        json _data = json::parse(data);
        lastRPCTime = time(0);
        GameIMG = GetGameThumb(placeId);
    }
    else if (!isRobloxRunning())
    {
        std::cout << "[INFO] Roblox is closing\n";
        isRblxRunning = false;
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

int main(int argc, char* argv[]) {
    if (!canRun)
    {
        std::cerr << "[ERROR] This program can only be run on macOS\n";
        return 1;
    }
    if (!isRobloxRunning())
    {
        runApp("/Applications/Roblox.app",false);
    }
    InitTable();
    std::string defaultPath = "/Users/" + user + "/Library/Logs/Roblox";
    std::cout << "[INFO] Defualt log directory url is: " << "file://localhost"+defaultPath << "\n";
    logfile = ShowOpenFileDialog("file://localhost"+defaultPath);
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
    CreateNotification("Hello world!", "Test lol", 0);
    std::cout << "[INFO] Username: " << user << " Path to log file is: " << logfile << "\n";
    //std::cout << "[INFO] start time " << time(0) << ", add time " << time(0) + 5 * 60 << "\n";
    InitDiscord();
    UpdDiscordActivity("Test", "Playing", "https://roblox.com/home", "https://roblox.com/home", "roblox open test", "roblox open test", 0, 0, 154835815, 154835815, "Test", "Test");
    do {} while (!isRobloxRunning());
    isRblxRunning = isRobloxRunning();
    std::cout << "[INFO] Roblox player is running\n";
    std::string latestLogFile = getLatestLogFile();
    do {latestLogFile = getLatestLogFile();} while (latestLogFile.empty());
    std::cout << "[INFO] Reading log file now!\n";
    if (latestLogFile.empty()) {
        throw std::runtime_error("[ERROR] Roblox log file not found!");
    } else {
        /*
        int fd[2];
        pipe(fd);
        pid_t pid = fork();
        if (pid == 0) {
            // Child process
            close(fd[0]);
            dup2(fd[1], STDOUT_FILENO);
            execlp("tail", "tail", "-f", latestLogFile.c_str(), nullptr);
            exit(1);
        } else {
            // Parent process
            close(fd[1]);
            char buffer[512];
            while (isRobloxRunning()) {
                ssize_t bytesRead = read(fd[0], buffer, sizeof(buffer) - 1);
                if (isDebug)
                {
                    std::cout << "[INFO] new buffer: " << buffer << "\n";
                }
                if (bytesRead > 0) {
                    buffer[bytesRead] = '\0';
                    doFunc(buffer);
                }
            }
        }
        */
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
        std::condition_variable logUpdatedEvent;
        std::mutex mtx;
        std::ifstream logFile(logFilePath);
        while (true) {
            //std::cout << "Hello world!\n";
            if (!isRobloxRunning())
            {
                //just incase yk
                break;
            }
            std::ifstream logFileStream(logFilePath);
            if (logFileStream) 
            {
                std::string line;
                while (std::getline(logFileStream, line)) 
                {
                    std::lock_guard<std::mutex> lock(mtx);
                    logUpdated = true;
                    logUpdatedEvent.notify_one();
                    if (isDebug)
                    {
                        std::cout << "[INFO] new line: " << line << "\n";
                    }
                    doFunc(line);
                }
            }
        }
    }
    std::cout << "[INFO] App Closing..\n";
    return 0;
}
