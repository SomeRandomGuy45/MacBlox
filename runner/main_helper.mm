//Some of this c++ code is from https://github.com/pizzaboxer/bloxstrap/blob/main/Bloxstrap/Integrations/ActivityWatcher.cs
//it is in c# but i was able to translate it to c++

/*

    TODO:
        Refactor and optimize the code into header files and other stuff could be like a v2

*/

#include "main_helper.h"
#include <objc/objc.h>
#include <objc/runtime.h>
#include <Foundation/Foundation.h>
#include <dispatch/dispatch.h>
#include <ctime>
#include <fstream>
#include <sys/time.h>
#include <pthread.h>
#include <cstdlib>
#include <iomanip>
#include <Cocoa/Cocoa.h>
#import "helper.h"


// bool
bool isDebug = false;
bool isRblxRunning = false;
bool ActivityMachineUDMUX = false;
bool ActivityIsTeleport = false;
bool _teleportMarker = false;
bool _reservedTeleportMarker = false;
bool ActivityInGame;
bool scriptFinished = true;
bool shouldKill = false;
bool isDiscordFound = true;
bool errorOccurred = false;
bool SBackground = false;

// std::string
std::string tempDirStr = getTemp();
std::string localuser = getenv("USER"); //gets the current user name
std::string logfile = "~/Library/Logs/Roblox/"; //gets the log directory path
std::string jobId = "";
std::string GameIMG = "";
std::string ActivityMachineAddress = "";
std::string basePythonScript = "python3 " + GetResourcesFolderPath() + "/discord.py";
std::string path_script = GetResourcesFolderPath() + "/helper.sh";
std::string temp_dir;
std::string fileContent = "";
std::string current_version_from_file = "";
std::string current_version = "";
std::string CustomChannel = "";
std::string bootstrapDataFileData = "";
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
std::string script_background = R"(
        tell application "System Events"
            set appList to name of every process
        end tell

        if "BackgroundApp" is in appList then
            return "true"
        else
            return "false"
        end if
    )";
std::string script_bootstrap = R"(
        tell application "System Events"
            set appList to name of every process
        end tell

        if "bootstrap" is in appList then
            return "true"
        else
            return "false"
        end if
    )";
std::string script_discord = R"(
        tell application "System Events"
            set appList to name of every process
        end tell

        if "discord" is in appList then
            return "true"
        else
            return "false"
        end if
    )";
std::string ScriptNeededToRun = R"(
            tell application "System Events"
                set isTerminalRunning to (exists (processes whose name is "Terminal"))
            end tell
            if isTerminalRunning then
                do shell script "killall -QUIT Terminal"
            end if)";

// long
long placeId = 0;

// std::time_t
std::time_t lastRPCTime = std::time(nullptr);

// std::unordered_set
std::unordered_set<std::string> processedLogs;

// std::thread
std::thread discordThread; //CHANGE ME LATER WHEN DISCORD RPC C++ IS FIX LOL

// std::mutex
std::mutex mtx;
std::mutex temp_dir_mutex;

// std::condition_variable
std::condition_variable cv;

// pid_t
pid_t currentScriptPID = -1;

// int64_t
int64_t TimeStartedUniverse = 0;

// extern char**
extern char **environ;

// namespace
namespace fs = std::filesystem;

// using
using json = nlohmann::json;
using ArgHandler = std::function<void(const std::string&)>;

// enum
enum CurrentTypes {
    Home,
    Public,
    Reserved,
    Private,
};

CurrentTypes Current = Home;

// std::map
std::map<std::string, ArgHandler> argTable;

// std::unordered_map
std::unordered_map<std::string, std::string> GeolocationCache;

// NSString
NSString* message;

std::string getApplicationSupportPath() {
    return "/Users/" + localuser + "/Library/Application Support/MacBlox_Data";
}

std::string GetBasePath() {
    try {
        std::string appSupportPath = getApplicationSupportPath();
        
        // Create the directory and any necessary parent directories
        if (fs::create_directories(appSupportPath)) {
            //NSLog(@"[INFO] Directory created successfully: " + appSupportPath );
        } else {
            //NSLog(@"[INFO] Directory already exists or failed to create: " + appSupportPath );
        }
        return appSupportPath;
    } catch (const fs::filesystem_error& e) {
        NSLog(@"[ERORR] Filesystem error");
        return "";
    } catch (const std::exception& e) {
        return "";
    }
}

std::string basePath = GetBasePath();
std::string GetModFolder() 
{
    std::string path = basePath + "/ModFolder";
    if (fs::exists(path))
    {
        std::cout << "[INFO] Folder already exists.\n";
    }
    else 
    {
		// Create the folder
		if (fs::create_directory(path)) {
			std::cout << "[INFO] Folder created successfully. at \n";
		}
		else {
			std::cerr << "[ERROR] Failed to create folder.\n";
			return "";
		}
	}
    return path;
}
std::string ModFolder = GetModFolder();

json GetModData()
{
    json Data;
    std::ifstream file(basePath + "/config_data.json");
    if (!file.is_open()) {
        return Data;
    }
    file >> Data;
    file.close();
    return Data;
}

// json
json Mod_Data = GetModData();
json bootstrapData;

std::string currentDateTime() {
    time_t now = time(0);
    struct tm tstruct;
    char buf[80];
    if (localtime_r(&now, &tstruct) == nullptr) {
        return "[ERROR] Failed to get local time";
    }
    if (strftime(buf, sizeof(buf), "%Y-%m-%d-%H-%M-%S", &tstruct) == 0) {
        return "[ERROR] Failed to format time";
    }
    return buf;
}

std::string getLogPath() {
    std::string currentDate = currentDateTime();
    std::string path = "/Users/" + localuser + "/Library/Logs/Macblox";
    if (std::filesystem::exists(path)) {
        NSLog(@"[INFO] Folder already exists.");
    } else {
        if (std::filesystem::create_directory(path)) {
            NSLog(@"[INFO] Folder created successfully.");
        } else {
            NSLog(@"[ERROR] Failed to create folder.");
            return "";
        }
    }
    return path + "/" + currentDate + "_runner_log.log";
}


std::string urlEncode(const std::string& value) {
    std::ostringstream encoded;
    encoded.fill('0');
    encoded << std::hex;

    for (char c : value) {
        // Keep alphanumeric characters and a few special characters as they are
        if (isalnum(static_cast<unsigned char>(c)) || 
            c == '-' || c == '_' || c == '.' || c == '~') {
            encoded << c;
        } else {
            // Convert other characters to their percent-encoded form
            encoded << '%' << std::setw(2) << static_cast<int>(static_cast<unsigned char>(c));
        }
    }

    return encoded.str();
}

std::string filePath = getLogPath();

void CustomNSLog(NSString *format, ...) {
    // Open the file in append mode
    FILE *logFile = fopen(filePath.c_str(), "a");

    if (logFile != nullptr) {
        va_list args;
        va_start(args, format);

        // Create an NSString with the formatted message
        NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];

        // Get the current time with microseconds
        struct timeval tv;
        gettimeofday(&tv, NULL);

        // Format the time
        struct tm *timeinfo;
        char timeBuffer[80];
        timeinfo = localtime(&tv.tv_sec);
        strftime(timeBuffer, sizeof(timeBuffer), "%Y-%m-%d %H:%M:%S", timeinfo);

        // Calculate milliseconds
        int milliseconds = tv.tv_usec / 1000;

        // Get the current process ID and process name
        pid_t pid = [[NSProcessInfo processInfo] processIdentifier];
        NSString *processName = [[NSProcessInfo processInfo] processName];

        // Format the log message to match the NSLog style
        NSString *logEntry = [NSString stringWithFormat:@"%s.%03d %s[%d:%x] %s\n",
                              timeBuffer,
                              milliseconds,
                              [processName UTF8String],
                              pid,
                              (unsigned int)pthread_mach_thread_np(pthread_self()),
                              [formattedMessage UTF8String]];

        // Print to the console
        fprintf(stdout, "%s", [logEntry UTF8String]);

        // Print to the file
        fprintf(logFile, "%s", [logEntry UTF8String]);

        va_end(args);

        // Close the file
        fclose(logFile);
    } else {
        NSLog(@"[ERROR] Failed to open file for logging: %s", filePath.c_str());
    }
}

#define NSLog(format, ...) CustomNSLog(format, ##__VA_ARGS__)

NSString* toNSString(const std::string& value) {
    return [NSString stringWithUTF8String:value.c_str()];
}

NSString* toNSString(long value) {
    return [NSString stringWithFormat:@"%ld", value];
}

NSString* toNSString(const char* value) {
    return [NSString stringWithUTF8String:value];
}

// Specialization for int
NSString* toNSString(const int& value) {
    return [NSString stringWithFormat:@"%d", value];
}

// Specialization for double
NSString* toNSString(const double& value) {
    return [NSString stringWithFormat:@"%f", value];
}

// Specialization for bool
NSString* toNSString(const bool& value) {
    return [NSString stringWithFormat:@"%s", value ? "true" : "false"];
}

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
        NSLog(@"[ERROR] curlpp::LogicError: " );
        return e.what();
    }
    catch (curlpp::RuntimeError &e)
    {
        NSLog(@"[ERROR] curlpp::RuntimeError: " );
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
        NSLog(@"[ERROR] Failed to show notification");
    }
    else
    {
        NSLog(@"[INFO] Notification shown successfully");
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
    std::string chmodCommand = "chmod +x " + path_script;
    system(chmodCommand.c_str());
    scriptFinished = false;

    std::string appleScript = R"(osascript -e '
        tell application "Terminal"
            if (count of windows) > 0 then
                -- Run the script in the first existing Terminal window
                do script ")" + path_script + R"(" in front window
            else
                -- If no windows are open, open a new window and run the script
                do script ")" + path_script + R"("
            end if
        end tell')";
    NSString* appleScriptStr = toNSString(appleScript);
    NSString* msg = [NSString stringWithFormat:@"[INFO] Running AppleScript command: %@", appleScriptStr];
    NSLog(@"%@", msg);

    // Run the AppleScript command
    int result = system(appleScript.c_str());

    if (result != 0) {
        NSLog(@"[ERROR] Failed to execute the AppleScript." );
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

    NSString* scriptFix = toNSString(new_script);
    NSString* msg = [NSString stringWithFormat:@"[INFO] Running script: %@", scriptFix];
    NSLog(@"%@",msg);
    std::ofstream scriptFile(path_script);
    if (!scriptFile.is_open()) {
        return;
    }
    scriptFile << "#!/bin/bash" << std::endl;
    scriptFile << new_script;
    scriptFile.close();
    pid_t pidToTerminate = -1;
    {
        pidToTerminate = currentScriptPID;
    }
    
    if (pidToTerminate != -1) {
        kill(pidToTerminate, SIGINT);
        currentScriptPID = -1; // Reset PID after waiting
    }

    std::string filename = GetResourcesFolderPath() + "/kill.txt";

    std::ofstream outfile(filename);

    if (outfile.is_open()) {
        // Write to the file
        outfile << "if kill then kill_thing() end" << std::endl;
        outfile.close();
    }
    // Run the custom function in a separate thread
    discordThread = std::thread([new_script, filename]() {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        try {
            if (std::filesystem::remove(filename)) {
                NSLog(@"[INFO] Successfully deleted kill.txt" );
            }
        } catch (const std::filesystem::filesystem_error& e) {
            std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
        }
        std::this_thread::sleep_for(std::chrono::seconds(1));
        executeScript(new_script);
    });

    discordThread.detach();

    NSLog(@"[INFO] Updated activity" );
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
    std::string output = runAppleScriptAndGetOutput(script);
    return output == "true" ? true : false;
}

bool isBackgroundAppRunning()
{
    std::string output = runAppleScriptAndGetOutput(script_background);
    return output == "true" ? true : false;
}

bool isBootstrapRunning()
{
    std::string output = runAppleScriptAndGetOutput(script_bootstrap);
    return output == "true" ? true : false;
}

bool isDiscordRunning()
{
    std::string output = runAppleScriptAndGetOutput(script_discord);
    return output == "true" ? true : false;
}

std::string ReadFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        NSLog(@"[ERROR] Unable to open file");
        return "";
    }
    return std::string((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
}

std::string GetGameURL(long customID, bool isMacblox) {
    std::string returnString = "roblox-player://placeId="+ std::to_string(customID) +"&gameId=" + jobId;
    if (!isMacblox)
    {
        returnString = "roblox://experiences/start?placeId="+  std::to_string(customID) +"&gameInstanceId=" + jobId;
    }
    NSLog(@"[INFO] Returning string %s", returnString.c_str());
    return returnString;
}

json GetGameData(long customID) {
    // Download the JSON file
    std::string url_getunid = "https://apis.roblox.com/universes/v1/places/" + std::to_string(customID) + "/universe";
    std::string downloadedFilePath = GetDataFromURL(url_getunid);
    //NSLog(@"[INFO] Got data " + downloadedFilePath );
    json data;
    try {
        data = json::parse(downloadedFilePath);
    } catch (const json::parse_error& e) {
        NSLog(@"[ERROR] JSON parse error");
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
                NSLog(@"[ERROR] Unexpected type for 'universeId'");
            }
        } else {
            NSLog(@"[ERROR] 'universeId' not found in JSON" );
        }
    } catch (const json::type_error& e) {
        NSLog(@"[ERROR] JSON type error");
    }
    if (!universeID.empty() && std::stol(universeID) <= 0) {
        universeID = std::to_string(std::stol(universeID) * -1);
    }
    NSString *universeFixed = toNSString(universeID);
    NSString* msg = [NSString stringWithFormat:@"[INFO] new universeId: %@", universeFixed];
    NSLog(@"%@", msg);
    std::string URL = "https://games.roblox.com/v1/games?universeIds=" + universeID;
    std::string downloadData = GetDataFromURL(URL);
    json data_game_data;
    try {
        data_game_data = json::parse(downloadData);
    } catch (const json::parse_error& e) {
        NSLog(@"[ERROR] JSON parse error: "  );
    }
    return data_game_data;
}

std::string GetGameThumb(long customID) {
    // Download the JSON file
    std::string url_getunid = "https://apis.roblox.com/universes/v1/places/" + std::to_string(customID) + "/universe";
    std::string downloadedFilePath = GetDataFromURL(url_getunid);
    //NSLog(@"[INFO] Got data " + downloadedFilePath );
    json data;
    try {
        data = json::parse(downloadedFilePath);
    } catch (const json::parse_error& e) {
        NSLog(@"[ERROR] JSON parse error: "  );
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
                NSLog(@"[ERROR] Unexpected type for 'universeId'" );
                return "";
            }
        } else {
            NSLog(@"[ERROR] 'universeId' not found in JSON" );
            return "";
        }
    } catch (const json::type_error& e) {
        NSLog(@"[ERROR] JSON type error: "  );
        return "";
    }
    if (!universeID.empty() && std::stol(universeID) <= 0) {
        universeID = std::to_string(std::stol(universeID) * -1);
    }
    NSString *universeFixed = toNSString(universeID);
    NSString* msg = [NSString stringWithFormat:@"[INFO] new universeId: %@", universeFixed];
    NSLog(@"%@", msg);

    // Download the game thumbnail JSON file
    std::string gameThumbURL = "https://thumbnails.roblox.com/v1/games/icons?universeIds=" + universeID + "&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false";
    //std::string universeThumbnailResponsePath = DownloadFile(gameThumbURL, "getunid.json");
    // Read and parse the thumbnail JSON file
    std::string thumbnailFileContent = GetDataFromURL(gameThumbURL);
    json thumbnailData;
    try {
        thumbnailData = json::parse(thumbnailFileContent);
    } catch (const json::parse_error& e) {
        NSLog(@"[ERROR] JSON parse error: "  );
        return "";
    }
    std::string thumbnailUrl = "";
    for (const auto& item : thumbnailData["data"])
    {
        thumbnailUrl = item["imageUrl"].get<std::string>();
    }

    return thumbnailUrl;
}

template <typename T>
std::string to_string(const T& value) {
    std::ostringstream oss;
    oss + value;
    return oss.str();
}

void HideApp(const std::string& appPath) {
    // Extract the application name from the path
    std::string appName = appPath.substr(appPath.find_last_of('/') + 1);

    // Remove the ".app" extension if it exists
    if (appName.size() > 4 && appName.substr(appName.size() - 4) == ".app") {
        appName = appName.substr(0, appName.size() - 4);
    }

    // Escape double quotes within the AppleScript command
    std::string appleScript = "tell application \\\"System Events\\\" to set visible of application process \\\"" + appName + "\\\" to false";

    // Construct the full osascript command
    std::string command = "osascript -e \"" + appleScript + "\"";
    std::cout << "[INFO] Command that is going to run is: " << command << "\n";
    system(command.c_str());
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
    //NSLog(@logtxt );
    if (processedLogs.find(logtxt) != processedLogs.end()) {
        return; // Skip processing if the log entry has already been handled
    }
    processedLogs.insert(logtxt);
    if (logtxt.find("[FLog::SingleSurfaceApp] initiateTeleport") != std::string::npos) 
    {
        _teleportMarker = true;
        NSLog(@"[INFO] Attempting to teleport into new server");
    }
    else if (_teleportMarker && logtxt.find("[FLog::GameJoinUtil] GameJoinUtil::initiateTeleportToReservedServer") != std::string::npos) 
    {
        _reservedTeleportMarker = true;
        NSLog(@"[INFO] Attempting to join reserved server");
    } 
    else if (logtxt.find("[FLog::GameJoinUtil] GameJoinUtil::joinGamePostPrivateServer") != std::string::npos) 
    {
        Current = Private;
        NSLog(@"[INFO] Attempting to join private server");
    } 
    else if (logtxt.find("[FLog::Output] ! Joining game") != std::string::npos && !ActivityInGame && placeId == 0 && (Current == Home)) 
    {
        std::regex pattern(R"(! Joining game '([0-9a-f\-]{36})' place ([0-9]+) at ([0-9\.]+))");
        std::smatch match;
        if (std::regex_search(logtxt, match, pattern) && match.size() == 4) {
            ActivityInGame = false;
            placeId = std::stol(match[2].str());
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

        }
    }
    else if (logtxt.find("[FLog::Network] serverId:") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::regex pattern(R"(serverId: ([0-9\.]+)\|[0-9]+)");
        std::smatch match;

        if (std::regex_search(logtxt, match, pattern) && match.size() == 2 && match[1].str() == ActivityMachineAddress) {
            ActivityInGame = true;
            std::future<std::string> test_ig = GetServerLocation(ActivityMachineAddress, ActivityInGame);
            std::string serverLocationStr = test_ig.get();
            wxString Title_Text = "";
            wxString ServerLocationText(serverLocationStr.c_str(), wxConvUTF8);
            wxString Msg_Text = "Located at " + ServerLocationText;
            if (Current != CurrentTypes::Home) {
                if (Current == CurrentTypes::Private) {
                    Title_Text = "Connected to private server";
                }
                else if (Current == CurrentTypes::Reserved) {
                    Title_Text = "Connected to reserved server";
                }
                else
                {
                    Title_Text = "Connected to public server";
                }
            }
            try {
                // Create notification
                CreateNotification(Title_Text, Msg_Text, wxNotificationMessage::Timeout_Auto);

                // Convert C++ strings to NSString
                NSString* placeIdStr = toNSString(placeId);
                NSString* jobIdStr = toNSString(jobId);
                NSString* activityMachineAddressStr = toNSString(ActivityMachineAddress);
                
                // Log the game joining info
                NSString* message = [NSString stringWithFormat:@"[INFO] Joining Game (%@/%@/%@)", placeIdStr, jobIdStr, activityMachineAddressStr];
                NSLog(@"%@", message);

                // Get game thumbnail
                GameIMG = GetGameThumb(placeId);
                if (GameIMG.empty()) {
                    NSLog(@"[ERROR] Failed to get game thumbnail");
                    return;
                }

                // Initialize button pairs
                std::vector<std::pair<std::string, std::string>> buttonPairs;
                if (Current != CurrentTypes::Reserved && Current != CurrentTypes::Private) {
                    std::string URL = GetGameURL(placeId, true);
                    buttonPairs.emplace_back("Join Server (Macblox)", URL);
                    URL = GetGameURL(placeId, false);
                    buttonPairs.emplace_back("Join Server (Other)", URL);
                } else {
                    std::string URL = "https://www.roblox.com/home";
                    buttonPairs.emplace_back("Roblox", URL);
                    std::string page = "https://www.roblox.com/games/" + std::to_string(placeId);
                    buttonPairs.emplace_back("See game page", page);
                }

                // Get game data from the server
                json GameDetails = GetGameData(placeId);
                std::string status = "";

                // Determine status based on server type
                if (Current == CurrentTypes::Private) {
                    status = "In a private server";
                } else if (Current == CurrentTypes::Reserved) {
                    status = "In a reserved server";
                } else {
                    status = "by " + to_string(GameDetails["data"][0]["creator"]["name"]);
                    status.erase(std::remove(status.begin(), status.end(), '"'), status.end());
                    if (GameDetails["data"][0]["creator"]["hasVerifiedBadge"]) {
                        status += " ☑️";
                    }
                }

                // Store the time when the universe started
                TimeStartedUniverse = getCurrentTimeMillis();

                // Get and clean up the game name
                std::string gameName = to_string(GameDetails["data"][0]["name"]);
                if (!gameName.empty() && gameName.front() == '"' && gameName.back() == '"') {
                    gameName = gameName.substr(1, gameName.size() - 2);
                }

                // Find the relevant buttons for the Discord activity
                auto it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                    [](const std::pair<std::string, std::string>& pair) {
                        return pair.first == "Join Server (Macblox)";
                    });
                auto it2 = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                    [](const std::pair<std::string, std::string>& pair) {
                        return pair.first == "Join Server (Other)";
                    });

                // Check if Discord is installed and running
                if (!doesAppExist("/Applications/Discord.app")) {
                    NSLog(@"[INFO] Discord not found in /Applications/Discord.app");
                    return;
                }
                if (!isAppRunning("Discord")) {
                    NSLog(@"[INFO] Discord not running");
                    return;
                }
                if (!isDiscordFound) {
                    NSLog(@"[ERROR] Discord is not found. Please make sure Discord is running and the Discord RPC library is correctly integrated.");
                    return;
                }

                // Update Discord activity
                if (it != buttonPairs.end() && it2 != buttonPairs.end()) {
                    UpdDiscordActivity("Playing " + gameName, status, TimeStartedUniverse, 0, -1, gameName, "Roblox", it->first, it2->first, it->second, it2->second, 0);
                } else {
                    it = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                        [](const std::pair<std::string, std::string>& pair) {
                            return pair.first == "Roblox";
                        });
                    it2 = std::find_if(buttonPairs.begin(), buttonPairs.end(),
                        [](const std::pair<std::string, std::string>& pair) {
                            return pair.first == "See game page";
                        });
                    if (it != buttonPairs.end() && it2 != buttonPairs.end()) {
                        UpdDiscordActivity("Playing " + gameName, status, TimeStartedUniverse, 0, -1, gameName, "Roblox", it->first, it2->first, it->second, it2->second, 0);
                    }
                }
            } catch (const std::bad_alloc& e) {
                // Handle memory allocation failure
                NSLog(@"[ERROR] Memory allocation failed: %s", e.what());
            } catch (const std::exception& e) {
                // Handle any other exceptions
                NSLog(@"[ERROR] Exception: %s", e.what());
            } catch (...) {
                // Catch any unexpected exceptions
                NSLog(@"[ERROR] An unknown error occurred");
            }
        }
    } 
    else if (logtxt.find("[FLog::Network] Time to disconnect replication data:") != std::string::npos || logtxt.find("[FLog::SingleSurfaceApp] leaveUGCGameInternal") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        NSLog(@"[INFO] player disconnected");
        jobId = "";
        placeId = 0;
        ActivityInGame = false;
        ActivityMachineAddress = "";
        ActivityMachineUDMUX = false;
        ActivityIsTeleport = false;
        Current = Home;
        GameIMG = "";
        TimeStartedUniverse = 0;
        std::string filename = GetResourcesFolderPath() + "/kill.txt";

        std::ofstream outfile(filename);

        if (outfile.is_open()) {
            // Write to the file
            outfile << "if kill then kill_thing() end" << std::endl;
            outfile.close();
        }

        try {
            if (std::filesystem::remove(filename)) {
                NSLog(@"[INFO] Successfully deleted kill.txt" );
            }
        } catch (const std::filesystem::filesystem_error& e) {
            std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
        }
    }
    else if (logtxt.find("[FLog::Network] UDMUX Address = ") != std::string::npos && !ActivityInGame && placeId != 0 && Current != Home) 
    {
        std::regex pattern(R"(UDMUX Address = ([0-9\.]+), Port = [0-9]+ \| RCC Server Address = ([0-9\.]+), Port = [0-9]+)");
        std::smatch match;
        if (std::regex_search(logtxt, match, pattern) && match.size() == 3 && match[2].str() == ActivityMachineAddress) {
            ActivityMachineAddress = match[1].str();
            ActivityMachineUDMUX = true;
        }
        else
        {
            NSLog(@"[ERROR] Something happened" );
        }
    }
    else if (logtxt.find("[FLog::Output] [BloxstrapRPC]") != std::string::npos && Current != Home)
    {
        if (std::time(nullptr) - lastRPCTime <= 1)
        {
            NSLog(@"[WARN] Dropping message (rate limit exceeded)");
            return;
        }
        std::regex pattern("\\[BloxstrapRPC\\] (.*)");
        std::smatch match;
        if (std::regex_search(logtxt, match, pattern) && match.size() == 2)
        {
            std::string data = match[1].str();
            json _data = json::parse(data);
            lastRPCTime = std::time(nullptr);

            if (_data["command"] == "SetRichPresence")
            {
                GameIMG = GetGameThumb(placeId);
                std::vector<std::pair<std::string, std::string>> buttonPairs;

                if (Current != CurrentTypes::Reserved && Current != CurrentTypes::Private)
                {
                    std::string URL = GetGameURL(placeId, true);
                    buttonPairs.emplace_back("Join Server (Macblox)", URL);
                    URL = GetGameURL(placeId, false);
                    buttonPairs.emplace_back("Join Server (Other)", URL);
                }
                else
                {
                    std::string URL = "https://www.roblox.com/home";
                    buttonPairs.emplace_back("Roblox", URL);
                    std::string page = "https://www.roblox.com/games/" + std::to_string(placeId);
                    buttonPairs.emplace_back("See game page", page);
                }

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
                if (!doesAppExist("/Applications/Discord.app"))
                {
                    NSLog(@"[INFO] Discord not found in /Applications/Discord.app");
                    return;
                }
                if (!isAppRunning("Discord"))
                {
                    NSLog(@"[INFO] Discord not running");
                    return;
                }
                if (!isDiscordFound) {
                    NSLog(@"[ERROR] Discord is not found. Please make sure Discord is running and the Discord");
                    return;
                }
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

void downloadFile(const char* urlString, const char* destinationPath) {
    @autoreleasepool {
        NSString *urlStr = [NSString stringWithUTF8String:urlString];
        NSString *destPath = [NSString stringWithUTF8String:destinationPath];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLSession *session = [NSURLSession sharedSession];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                if ([error isKindOfClass:[NSError class]]) {
                    //NSLog(@"[ERROR] Download failed with error: %@", [error localizedDescription]);
                } else {
                    //NSLog(@"[ERROR] Download failed with unknown error: %@", error);
                }
            } else {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    //NSLog(@"[INFO] Response status code: %ld", (long)[httpResponse statusCode]);
                    //NSLog(@"[INFO] Response headers: %@", [httpResponse allHeaderFields]);
                } else {
                    //NSLog(@"[INFO] Response: %@", response);
                }
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *fileError;
                
                // Check if the file already exists at the destination path
                if ([fileManager fileExistsAtPath:destPath]) {
                    // Remove the existing file
                    BOOL removeSuccess = [fileManager removeItemAtPath:destPath error:&fileError];
                    if (!removeSuccess) {
                        if ([fileError isKindOfClass:[NSError class]]) {
                            //NSLog(@"[ERROR] Failed to remove existing file: %@", [fileError localizedDescription]);
                        } else {
                            //NSLog(@"[ERROR] Failed to remove existing file with unknown error: %@", fileError);
                        }
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                }
                
                // Move the downloaded file to the destination path
                BOOL success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&fileError];
            }
            
            dispatch_semaphore_signal(semaphore);
        }];
        
        [downloadTask resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
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

int loadFolderCount(const std::string& jsonFilePath) {
    std::ifstream inFile(jsonFilePath);
    if (!inFile.is_open()) {
        std::cerr << "[ERROR] Failed to open the JSON file." << std::endl;
        return -1;
    }

    json inputJson;
    inFile >> inputJson;

    inFile.close();

    if (inputJson.contains("folder_count")) {
        return inputJson["folder_count"].get<int>();
    } else {
        std::cerr << "[ERROR] JSON file does not contain 'folder_count'." << std::endl;
        return -1;
    }
}

void GetCurrentCountOfModFolder(std::string& directoryPath, std::string& folder)
{
    int folderCount = 0;

    try {
        for (const auto& entry : fs::recursive_directory_iterator(directoryPath)) {
            if (entry.path().filename().string() != ".DS_Store") {
                folderCount++;
            }
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
        return;
    }

    // Create the JSON object
    json outputJson;
    outputJson["folder_count"] = folderCount;

    // Write the JSON object to a file
    std::ofstream outFile(folder+"/mod_count_data.json");
    if (outFile.is_open()) {
        outFile << outputJson.dump(4); // Pretty-print with an indentation of 4 spaces
        outFile.close();
        std::cout << "[INFO] JSON file created successfully!" << std::endl;
    } else {
        std::cerr << "[ERROR] Failed to create the JSON file." << std::endl;
        return;
    }
}

int countCurrentMods(std::string& directoryPath)
{
    int folderCount = 0;

    try {
        for (const auto& entry : fs::recursive_directory_iterator(directoryPath)) {
            if (entry.path().filename().string() != ".DS_Store") {
                folderCount++;
            }
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
        return -1;
    }
    return folderCount;
}

bool OpenAppWithPath(const std::string &appPath) {
    // Escape the appPath for use in the AppleScript
    std::string escapedPath = appPath;
    // Replace double quotes with escaped double quotes
    size_t pos = 0;
    while ((pos = escapedPath.find('"', pos)) != std::string::npos) {
        escapedPath.insert(pos, "\\");
        pos += 2;  // Skip past the newly added escape character
    }

    // Construct the AppleScript command
    std::string appleScript = "osascript -e 'tell application \"";
    appleScript += escapedPath;
    appleScript += "\" to activate'";

    // Execute the AppleScript command
    FILE *pipe = popen(appleScript.c_str(), "r");
    if (!pipe) {
        return false;
    }

    // Read and discard the output of the command
    char buffer[128];
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        // Do nothing with the output
    }

    int status = pclose(pipe);
    if (status != 0) {
        return false;
    }

    return true;
}

std::string getParentFolderOfApp() {
    // Get the bundle path
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    // Get the parent directory of the bundle
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    // Convert NSString to std::string
    return std::string([parentPath UTF8String]);
}

std::string GetExPath() {
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

int main_loop(NSArray *arguments, std::string supercoolvar, bool dis) {
    std::vector<std::string> stdArguments;
    for (NSString *arg in arguments) {
        stdArguments.push_back([arg UTF8String]);
    }
    isDiscordFound = dis;
    for (const auto& arg: stdArguments)
    {
        std::cout << "[INFO] new arg is: " << arg << "\n";
        if (arg == "--supercoolhackthing" | arg == "-scht")
        {
            NSLog(@"[INFO] supercoolhackthing found >:)");
            SBackground = false;
        }
    }
    NSLog(@"[INFO] supercoolvar is: %s",supercoolvar.c_str());
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //while (true) {

            InitTable();

            std::string defaultPath = "/Users/" + localuser + "/Library/Logs/Roblox";
            if (!CanAccessFolder(defaultPath))
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    logfile = ShowOpenFileDialog("file://localhost" + defaultPath);

                    if (logfile != "/Users/" + localuser + "/Library/Logs/Roblox")
                    {
                        std::string path = "The location of the Roblox log file isn't correct. The location is /Users/" + localuser + "/Library/Logs/Roblox";
                        wxString toWxString(path.c_str(), wxConvUTF8);
                        wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);

                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            errorOccurred = true;
                        });

                        return;
                    }
                });

            }
            else
            {
                logfile = defaultPath;
            }
            bool shouldEnd = false;
            while (!isRobloxRunning() && shouldEnd == false) {
                if (SBackground == false)
                {
                    NSLog(@"[INFO] Opening app");
                    OpenAppWithPath(GetExPath() + "/Bootstrap.app");
                    do {} while (isBootstrapRunning());
                    if (supercoolvar.empty())
                    {
                        runApp("/Applications/Roblox.app", false);
                    }
                    else
                    {
                        std::string run_to_open_lol = "open \"" + supercoolvar + "\"";
                        NSLog(@"[INFO] Ok got it running this command %s", run_to_open_lol.c_str());
                        system(run_to_open_lol.c_str());
                    }
                    shouldEnd = true;
                    SBackground = true;
                }
                else
                {
                    if (isBootstrapRunning())
                    {
                        continue;
                    }
                    std::cout << "[INFO] Base Path is : " << basePath << "\n";
                    fileContent = FileChecker(basePath + "/roblox_version_data_install.json");
                    std::cout << "[INFO] Data is: " << fileContent << "\n";
                    current_version_from_file = "";
                    current_version = "";
                    bootstrapDataFileData = FileChecker(basePath + "/bootstrap_data.json");
                    Mod_Data = GetModData();
                    int JsonCount = loadFolderCount(basePath + "/mod_count_data.json");
                    int currentCount = countCurrentMods(ModFolder);
                    if (!bootstrapDataFileData.empty())
                    {
                        bootstrapData = json::parse(bootstrapDataFileData);
                        CustomChannel = bootstrapData["channel"].get<std::string>();
                        NSLog(@"[INFO] Got custom channel");
                    }
                    if (!fileContent.empty())
                    {
                        json data = json::parse(fileContent);
                        current_version_from_file = data["clientVersionUpload"].get<std::string>();
                        std::cout << "[INFO] Current version from file: " << current_version_from_file << " : dump is: " << data.dump(4) << "\n";
                    }
                    else
                    {
                        NSLog(@"[INFO] Updating roblox!");
                        //std::cout << "[WARN] Couldn't find roblox_version.json, assuming the client is not up to date." << std::endl;
                    }
                    std::string downloadPath = basePath + "/roblox_version_data_install.json";
                    std::string v2fileContent = GetDataFromURL("https://clientsettings.roblox.com/v2/client-version/MacPlayer");
                    if (!v2fileContent.empty())
                    {
                        json data = json::parse(v2fileContent);
                        current_version = data["clientVersionUpload"].get<std::string>();
                        std::cout << "[INFO] Version from download: " << current_version << "\n";
                    }
                    else
                    {
                        NSLog(@"[INFO] Updating roblox!");
                        //std::cout << "[WARN] Couldn't find roblox_version.json after downloading, assuming the client is not up to date." << std::endl;
                    }
                    if (!doesAppExist("/Applications/Roblox.app")) {
                        NSLog(@"Couldn't find /Applications/Roblox.app");
                        current_version = "";
                    }
                    if (current_version_from_file != current_version || JsonCount != currentCount) {
                        NSLog(@"[INFO] Doing thing");
                        OpenAppWithPath(GetExPath() + "/Bootstrap.app");
                        HideApp(GetExPath() + "/Bootstrap.app");
                        GetCurrentCountOfModFolder(ModFolder, basePath);
                        std::this_thread::sleep_for(std::chrono::milliseconds(500));
                    }
                }
            }
            SBackground = true;
            isRblxRunning = isRobloxRunning();
            std::this_thread::sleep_for(std::chrono::seconds(5));

            std::string latestLogFile = getLatestLogFile(false);
            do {latestLogFile = getLatestLogFile(false);} while (latestLogFile.empty());

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
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                }

                if (fs::path(getLatestLogFile(true)).filename().string() != fs::path(logFilePath).filename().string())
                {
                    logFilePath = getLatestLogFile(true);
                }
                std::condition_variable logUpdatedEvent;
                std::ifstream logFile(logFilePath);
                bool lastDiscord = false;
                while (true) {
                    if (!isRobloxRunning()) {
                        break;
                    }
                    std::this_thread::sleep_for(std::chrono::milliseconds(250));
                    std::ifstream logFileStream(logFilePath);
                    if (logFileStream) {
                        std::string line;
                        while (std::getline(logFileStream, line)) {
                            logUpdated = true;
                            doFunc(line);
                        }
                    } else {
                        break;
                    }
                }
                discordThread = std::thread([&]() {
                    NSLog(@"[INFO] Stopping discord thread");
                });
                if (discordThread.joinable())
                {
                    discordThread.join();
                }
            }
            std::string filename = GetResourcesFolderPath() + "/kill.txt";

            std::ofstream outfile(filename);

            if (outfile.is_open()) {
                // Write to the file
                outfile << "if kill then kill_thing() end" << std::endl;
                outfile.close();
            }

            try {
                if (std::filesystem::remove(filename)) {
                    NSLog(@"[INFO] Successfully deleted kill.txt" );
                }
            } catch (const std::filesystem::filesystem_error& e) {
                std::cerr << "[ERROR] Filesystem error: " << e.what() << std::endl;
            }
            runAppleScriptAndGetOutput(ScriptNeededToRun);
            SBackground = true;
            shouldEnd = false;
            [NSApp terminate:nil];
        //}
    });
    return 0;
}