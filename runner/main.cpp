//Some of this c++ code is from https://github.com/pizzaboxer/bloxstrap/blob/main/Bloxstrap/Integrations/ActivityWatcher.cs
//it is in c# but i was able to translate it to c++

#include <iostream>
#include <vector>
#include <libproc.h>
#include <unistd.h>
#include <cstring>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string>
#include <fstream>
#include <algorithm>
#include <filesystem>
#include <regex>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <map>
#include <functional>
#include <string>

std::string user = getenv("USER"); //gets the current user name
std::string logfile = "/Users/" + user + "/Library/Logs/Roblox/"; //creates the log directory path
bool isRblxRunning = false;
int placeId = 0;
std::string jobId = "";
std::string ActivityMachineAddress = "";
bool ActivityMachineUDMUX = false;
bool ActivityIsTeleport = false;
bool _teleportMarker = false;
bool _reservedTeleportMarker = false;
bool ActivityInGame;
#ifdef __APPLE__
    bool canRun = true;
#else
    bool canRun = false;
#endif
bool isDebug = false; //todo

namespace fs = std::filesystem;

enum CurrentTypes {
    Home,
    Public,
    Reserved,
    Private,
};

using ArgHandler = std::function<void(const std::string&)>;
std::map<std::string, ArgHandler> argTable;

void InitTable()
{
    argTable["-d"] = [](const std::string&) {isDebug = true; };
    argTable["-debug"] = [](const std::string&) {isDebug = true; };
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
    else if (!isRobloxRunning())
    {
        std::cout << "[INFO] Roblox is closing\n";
        isRblxRunning = false;
    }
}

int main(int argc, char* argv[]) {
    InitTable();
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
    do {} while (!isRobloxRunning());
    isRblxRunning = isRobloxRunning();
    std::cout << "[INFO] Roblox player is running\n";
    std::string latestLogFile = getLatestLogFile();
    do {latestLogFile = getLatestLogFile();} while (latestLogFile.empty());
    std::cout << "[INFO] Reading log file now!\n";
    if (latestLogFile.empty()) {
        throw std::runtime_error("Roblox is not running");
    } else {
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
    }
    return 0;
}
