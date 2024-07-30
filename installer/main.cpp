#include <curl/curl.h>
#include <string>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>
#include <iostream>
#include <cstring>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <fstream>
#include <filesystem>
#include <zlib.h>
#include <minizip/unzip.h>
#include <minizip/zip.h>
#include <signal.h>  // For kill function
#include <errno.h>   // For errno
#include <cstring>   // For strerror
#include <libproc.h>
#include <objc/objc.h>
#include <objc/message.h>
#include <CoreFoundation/CoreFoundation.h>
#include <DiskArbitration/DiskArbitration.h>
#include "json.hpp"

namespace fs = std::filesystem;
using json = nlohmann::json;

std::string robloxDownloadURL = "";
std::string currentVersion = "";

// This function writes data to a file
size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    size_t written = fwrite(ptr, size, nmemb, stream);
    return written;
}

// Function to get the directory of the executable
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
std::fstream DownloadFile(const std::string& baseUrl, const std::string& filename) {
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
            std::fstream emptyFile;
            emptyFile.setstate(std::ios::failbit); // Set the failbit to indicate an error
            return emptyFile;
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

    // Check if file was created successfully
    std::fstream ifs(outfilename, std::ios::in);
    if (!ifs.is_open()) {
        std::fstream emptyFile;
        emptyFile.setstate(std::ios::failbit); // Set the failbit to indicate an error
        return emptyFile;
    }
    return ifs;
}

// Function to extract a ZIP file
bool ExtractZip(std::string& zipPath, std::string& extractPath) {
    zipPath = GetBashPath() + zipPath;
    extractPath = GetBashPath() + extractPath;
    std::cout << "[INFO] Extracting " << zipPath << " to " << extractPath << std::endl;
    unzFile zipFile = unzOpen(zipPath.c_str());
    if (!zipFile) {
        std::cerr << "[ERROR] Could not open ZIP file: " << zipPath << std::endl;
        return false;
    }

    if (unzGoToFirstFile(zipFile) != UNZ_OK) {
        std::cerr << "[ERROR] Could not locate the first file in ZIP file: " << zipPath << std::endl;
        unzClose(zipFile);
        return false;
    }

    // Ensure extraction path exists
    if (!fs::exists(extractPath)) {
        fs::create_directories(extractPath);
    }

    char filename[256];
    unz_file_info fileInfo;
    int result;

    do {
        result = unzGetCurrentFileInfo(zipFile, &fileInfo, filename, sizeof(filename), nullptr, 0, nullptr, 0);
        if (result != UNZ_OK) {
            std::cerr << "[ERROR] Could not get file info: " << result << std::endl;
            unzClose(zipFile);
            return false;
        }

        // Construct the full path for extraction
        std::string fullPath = extractPath + "/" + filename;
        if (filename[strlen(filename) - 1] == '/') {
            // Directory entry
            fs::create_directories(fullPath);
        } else {
            // File entry
            std::ofstream outFile(fullPath, std::ios::binary);
            if (!outFile.is_open()) {
                std::cerr << "[ERROR] Could not open file for extraction: " << fullPath << std::endl;
                unzClose(zipFile);
                return false;
            }

            result = unzOpenCurrentFile(zipFile);
            if (result != UNZ_OK) {
                std::cerr << "[ERROR] Could not open file inside ZIP: " << result << std::endl;
                unzClose(zipFile);
                return false;
            }

            char buffer[8192];
            int bytesRead;
            while ((bytesRead = unzReadCurrentFile(zipFile, buffer, sizeof(buffer))) > 0) {
                outFile.write(buffer, bytesRead);
            }

            if (bytesRead < 0) {
                std::cerr << "[ERROR] Read error from ZIP file: " << bytesRead << std::endl;
                unzCloseCurrentFile(zipFile);
                unzClose(zipFile);
                return false;
            }

            outFile.close();
            unzCloseCurrentFile(zipFile);
        }

    } while ((result = unzGoToNextFile(zipFile)) == UNZ_OK);

    if (result != UNZ_END_OF_LIST_OF_FILE) {
        std::cerr << "[ERROR] Could not go to next file in ZIP: " << result << std::endl;
        unzClose(zipFile);
        return false;
    }

    unzClose(zipFile);
    return true;
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
                if (kill(pid, SIGTERM) == -1)
                {
                    std::cerr << "[ERROR] Error terminating process with PID " << pid << ": " << std::strerror(errno) << std::endl;
                }
                break;
            } 
        } else {
            continue;
        }
    }
    return found;
}

int main() {
    std::string robloxDataPath = "roblox_data";
    std::string robloxDataJsonPath = robloxDataPath + "/roblox_data.json";

    // Ensure the directory exists
    if (!fs::exists(robloxDataPath)) {
        if (fs::create_directory(robloxDataPath)) {
            std::cout << "[INFO] Folder created successfully at " << robloxDataPath << std::endl;
        } else {
            std::cerr << "[ERROR] Failed to create folder " << robloxDataPath << std::endl;
            return 1;
        }
    }

    // Check if the JSON file exists and read it
    if (fs::exists(robloxDataJsonPath)) {
        std::fstream ifs(robloxDataJsonPath, std::ios::in);
        if (ifs.is_open()) {
            json data = json::parse(ifs);
            currentVersion = data["clientVersionUpload"].get<std::string>();
        } else {
            std::cerr << "[ERROR] Failed to open JSON file for reading: " << robloxDataJsonPath << std::endl;
            return 1;
        }
    }
    std::cout << "[INFO] Base path: " << GetBashPath() << std::endl;
    // Download the latest version JSON
    std::fstream file = DownloadFile("https://clientsettings.roblox.com/v2/client-version/MacPlayer", "roblox_data/roblox_data.json");
    if (!file.is_open()) {
        std::cerr << "[ERROR] Failed to download or open the JSON file" << std::endl;
        return 1;
    }
    json data = json::parse(file);
    std::string latestVersion = data["clientVersionUpload"].get<std::string>();
    std::cout << "[INFO] Latest version: " << latestVersion << std::endl;

    if (latestVersion == currentVersion) {
        std::cout << "[INFO] No update needed." << std::endl;
        return 0; // No update needed
    }

    // Construct the download URL and download the latest ZIP file
    robloxDownloadURL = "https://setup.rbxcdn.com/mac/" + latestVersion + "-Roblox.zip";
    std::cout << "[INFO] Downloading the latest version from: " << robloxDownloadURL << std::endl;
    std::fstream file2 = DownloadFile(robloxDownloadURL, "roblox_data/roblox_latest.zip");
    if (!file2.is_open()) {
        std::cerr << "[ERROR] Failed to download or open the ZIP file" << std::endl;
        return 1;
    }
    
    // Extract the ZIP file
    std::string zipPath = "/roblox_data/roblox_latest.zip";
    std::string extractPath = "/roblox_data";

    if (!ExtractZip(zipPath, extractPath)) {
        std::cerr << "[ERROR] Failed to extract ZIP file" << std::endl;
        return 1;
    }

    std::cout << "[INFO] ZIP file extracted successfully." << std::endl;
    std::string pathToInstaler =  GetBashPath() + "/roblox_data/RobloxPlayerInstaller.app/Contents/MacOS/RobloxPlayerInstaller";
    std::string command = "chmod +x " + pathToInstaler + "\n" + pathToInstaler;
    std::string copyCommand = "mv /Applications/Roblox.app " + GetBashPath() + "/roblox_data/Roblox.app";
    system(command.c_str());
    system(copyCommand.c_str());
    //later on we will init the runner
    if (isRobloxRunning()) {
        std::cout << "[INFO] Roblox is already running. Terminating it..." << std::endl;
    }
    return 0;
}
