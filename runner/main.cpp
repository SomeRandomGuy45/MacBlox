//Some of this c++ code is from https://github.com/pizzaboxer/bloxstrap/blob/main/Bloxstrap/Integrations/ActivityWatcher.cs
//it is in c# but i was able to translate it to c++

#include <iostream>
#include <vector>
#include <libproc.h>
#include <libgen.h>
#include <limits.h>
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
#include <signal.h>  // For kill function
#include <errno.h>   // For errno
#include <thread>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <algorithm>
#include <CoreFoundation/CoreFoundation.h>
#include <DiskArbitration/DiskArbitration.h>
#include <mach-o/dyld.h>
#include <sstream>
#include <condition_variable>
#include <mutex>
#include <ctime>
#include "json.hpp"

std::string user = getenv("USER"); //gets the current user name
std::string logfile = "/Users/" + user + "/Library/Logs/Roblox/"; //creates the log directory path
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

// Function to download a file from a URL
std::string DownloadFile(const std::string& baseUrl, const std::string& filename) {
    CURL *curl;
    FILE *fp;
    CURLcode res;
    std::string outfilename = GetBashPath() + "/" + filename;

    // Initialize libcurl
    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    if (curl) {
        fp = fopen(outfilename.c_str(), "wb"); // Open file for writing in binary mode
        if (fp == nullptr) {
            perror("[ERROR] Error opening file");
            curl_easy_cleanup(curl);
            curl_global_cleanup();
            return "Error";
        }

        // Set URL and write function
        curl_easy_setopt(curl, CURLOPT_URL, baseUrl.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);

        // Perform the request
        res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        }

        // Clean up
        fclose(fp);
        curl_easy_cleanup(curl);
    }
    curl_global_cleanup();

    std::fstream ifs(outfilename, std::ios::in);
    if (!ifs.is_open()) {
        std::fstream emptyFile;
        emptyFile.setstate(std::ios::failbit); // Set the failbit to indicate an error
        return "error";
    }
    return outfilename;
}

void InitTable()
{
    argTable["--d"] = [](const std::string&) {isDebug = true; };
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

std::string getLatestLogFile() {
    std::vector<std::string> logFiles;
    for (const auto& entry : fs::directory_iterator(logfile)) {
        if (entry.path().extension() == ".log" && entry.path().filename().string().find("Player") != std::string::npos) { //make sure that the file ends with ".log" and has "Player"
            logFiles.push_back(entry.path().string());
        }
    }
    if (logFiles.empty()) return "";

    auto latestLogFile = *std::max_element(logFiles.begin(), logFiles.end(), [](const std::string& a, const std::string& b) {
        return fs::last_write_time(a) < fs::last_write_time(b);
    });
    return latestLogFile;
}

std::string getLatestLogFilePath() {
    std::vector<std::string> logFiles;
    
    // Iterate through the directory entries
    for (const auto& entry : fs::directory_iterator(logfile)) {
        if (entry.path().extension() == ".log" && entry.path().filename().string().find("Player") != std::string::npos) {
            logFiles.push_back(entry.path().string());
        }
    }
    
    if (logFiles.empty()) return "";

    // Sort logFiles to get the latest log file
    std::sort(logFiles.begin(), logFiles.end(), [](const std::string& a, const std::string& b) {
        return fs::last_write_time(a) > fs::last_write_time(b);
    });

    // Return the latest log file path
    return logFiles.front();
}

bool isRobloxRunning()
{
    bool found = false;
    const int maxProcesses = 1024;
    pid_t pids[maxProcesses];
    int count;

    // Get the list of process IDs
    count = proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));

    if (count < 0) {
        std::cerr << "[ERROR] Failed to get list of processes" << std::endl;
        return 1;
    }

    for (int i = 0; i < count / sizeof(pid_t); ++i) {
        pid_t pid = pids[i];
        if (pid == 0) continue; // Skip unused slots

        // Get the process name
        char procName[PROC_PIDPATHINFO_MAXSIZE];
        if (proc_pidpath(pid, procName, sizeof(procName)) > 0) {
            std::string processName = procName;
            size_t find = processName.find("RobloxPlayer");
            if (find != std::string::npos) {
                found = true;
                break;
            } 
        } else {
            continue;
        }
    }
    return found;
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
        Current = CurrentTypes::Private;
        std::cout << "[INFO] Attempting to join private server\n";
    } 
    else if (logtxt.find("[FLog::Output] ! Joining game") != std::string::npos && !ActivityInGame && placeId == 0) 
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
                Current = CurrentTypes::Reserved;
                _reservedTeleportMarker = false;
            }

            std::cout << "[INFO] Joining Game (" << placeId << "/" << jobId << "/" << ActivityMachineAddress << ")" << std::endl;
        }
    }
    else if (logtxt.find("[FLog::Network] serverId:") != std::string::npos && !ActivityInGame && placeId != 0) 
    {
        std::regex pattern(R"(serverId: ([0-9\.]+)\|[0-9]+)");
        std::smatch match;

        if (std::regex_search(logtxt, match, pattern) && match.size() == 2 && match[1].str() == ActivityMachineAddress) {
            std::cout << "[INFO] Joined Game (" << placeId << "/" << jobId << "/" << ActivityMachineAddress << ")" << std::endl;
            ActivityInGame = true;
        }
    } 
    else if (logtxt.find("[FLog::Network] Time to disconnect replication data:") != std::string::npos || logtxt.find("[FLog::SingleSurfaceApp] leaveUGCGameInternal") != std::string::npos && !ActivityInGame && placeId != 0) 
    {
        std::cout << "[INFO] User disconnected\n";
        if (Current != CurrentTypes::Home) {
            jobId = "";
            placeId = 0;
            ActivityInGame = false;
            ActivityMachineAddress = "";
            ActivityMachineUDMUX = false;
            ActivityIsTeleport = false;
            Current = CurrentTypes::Home;
            GameIMG = "";
        }
    }
    else if (logtxt.find("[FLog::Network] UDMUX Address = ") != std::string::npos && !ActivityInGame && placeId != 0) 
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
    else if (logtxt.find("[FLog::Output] [BloxstrapRPC]") != std::string::npos)
    {
        if (time(0) - lastRPCTime > 1)
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

int main(int argc, char* argv[]) {
    InitTable();
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
    if (!canRun)
    {
        std::cerr << "[ERROR] This program can only be run on macOS\n";
        return 1;
    }
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
        std::string LogLocation = getLatestLogFilePath();
        std::condition_variable logUpdatedEvent;
        std::mutex mtx;
        std::ifstream logFile(LogLocation);
        std::thread logWatcher([&]() {
            while (true) {
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
                //std::cout << "Hello world!\n";
                std::ifstream logFileStream(LogLocation);
                if (logFileStream) {
                    std::string line;
                    while (std::getline(logFileStream, line)) {
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
        });
        logWatcher.detach();
        while (isRobloxRunning()) {
            std::unique_lock<std::mutex> lock(mtx);
            logUpdatedEvent.wait(lock, [&] { return logUpdated; });
            logUpdated = false;
        }
    }
    return 0;
}
