/*

REFACTOR MEEEEEEEE

*/

#include "BackgroundTask.h"
#include "helper.h"
#include <thread>
#include "json.hpp"
#include <Foundation/Foundation.h>
#include <string>
#include <sys/xattr.h>
#include <cstring>
#include <unistd.h>
#include <fstream>
#include <sys/types.h>
#include <sys/wait.h>
#include <sstream>
#include <dispatch/dispatch.h>
#include <filesystem>
#import <minizip/unzip.h>

namespace fs = std::filesystem;
using json = nlohmann::json;

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
std::string getApplicationSupportPath() {
    const char* homeDir = std::getenv("HOME");  // Get the user's home directory
    if (!homeDir) {
        throw std::runtime_error("Failed to get home directory");
    }
    return std::string(homeDir) + "/Library/Application Support/MacBlox_Data";
}
std::string Path() {
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
        return "";
    } catch (const std::exception& e) {
        return "";
    }
}

std::string Checker(const std::string path) {
    // Convert std::string to NSString
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    
    // Create an NSFileManager instance
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the file exists
    if ([fileManager fileExistsAtPath:nsPath]) {
        std::ifstream file(path);
        
        if (file.is_open()) {
            std::string line;
            std::string fileContent;
            
            // Read file contents
            while (std::getline(file, line)) {
                fileContent += line + "\n";
            }
            file.close();
            
            return fileContent;
        } else {
            return "";
        }
    } else {
        return "";
    }
}

bool removeQuarantineAttribute(const std::string& filePath) {
    const char* attributeName = "com.apple.quarantine";

    // First, get the size of the attribute value
    ssize_t attrSize = getxattr(filePath.c_str(), attributeName, nullptr, 0, 0, 0);
    if (attrSize == -1) {
        if (errno == ENOATTR) {
            return true; // Attribute does not exist, so nothing to remove
        } else {
            return false;
        }
    }

    // Allocate a buffer of the appropriate size
    std::vector<char> buffer(attrSize);

    // Get the actual attribute value
    attrSize = getxattr(filePath.c_str(), attributeName, buffer.data(), buffer.size(), 0, 0);
    if (attrSize == -1) {
        return false;
    }

    // Remove the attribute
    int result = removexattr(filePath.c_str(), attributeName, 0);
    if (result == -1) {
        return false;
    }

    return true;
}

bool ensureDirectoryExists(const std::string& path) {
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    
    // Check if the directory exists
    BOOL exists = [fileManager fileExistsAtPath:nsPath isDirectory:&isDirectory];
    if (exists && isDirectory) {
        return true; // Directory exists
    }
    
    // Attempt to create the directory
    NSError *error = nil;
    BOOL success = [fileManager createDirectoryAtPath:nsPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        return false;
    }
    
    return true;
}

std::string GetDownloads() {
    NSString *downloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    // Convert NSString to std::string
    const char *pathCString = [downloadsPath UTF8String];
    std::string pathString(pathCString);
    
    // Ensure the directory exists
    if (!ensureDirectoryExists(pathString)) {
        return "";
    }
    
    return pathString;
}

void Check(int result)
{
    return;
}

void RenameFile(const char* oldPathCStr, const char* newPathCStr)
{
    // Convert C strings to NSString
    NSString *oldPath = [NSString stringWithUTF8String:oldPathCStr];
    NSString *newPath = [NSString stringWithUTF8String:newPathCStr];
    
    // Initialize an error object
    NSError *error = nil;
    
    // Check if the file at the new path already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
        // Remove the existing file
        if (![[NSFileManager defaultManager] removeItemAtPath:newPath error:&error]) {
            return; // Exit if the removal failed
        }
    }
    
}

json GetModData()
{
    json Data;
    std::ifstream file(Path() + "/config_data.json");
    if (!file.is_open()) {
        return Data;
    }
    file >> Data;
    file.close();
    return Data;
}

std::string GetBasePath = Path();
std::string Download = GetDownloads();
std::string CustomChannel = "";
json Mod_Data = GetModData();

void fixInstall(std::string path) {
    // Convert the std::string to an NSString
    NSString *applicationPath = [NSString stringWithUTF8String:path.c_str()];

    // Create the command with the application path
    NSString *cmd = [NSString stringWithFormat:@"xattr -w com.apple.quarantine \"\" %@", applicationPath];

    // Execute the command
    system([cmd UTF8String]);
}

bool unzipFile(const char* zipFilePath, const char* destinationPath) {
    @autoreleasepool {
        NSString *zipPath = [NSString stringWithUTF8String:zipFilePath];
        NSString *destPath = [NSString stringWithUTF8String:destinationPath];
        
        unzFile zipFile = unzOpen([zipPath fileSystemRepresentation]);
        if (!zipFile) {
            return false;
        }
        
        int ret = unzGoToFirstFile(zipFile);
        if (ret != UNZ_OK) {
            unzClose(zipFile);
            return false;
        }

        do {
            char filename[256];
            unz_file_info fileInfo;
            ret = unzGetCurrentFileInfo(zipFile, &fileInfo, filename, sizeof(filename), NULL, 0, NULL, 0);
            if (ret != UNZ_OK) {
                unzClose(zipFile);
                return false;
            }

            NSString *filePath = [destPath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
            if (filename[strlen(filename) - 1] == '/') {
                [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            } else {
                ret = unzOpenCurrentFile(zipFile);
                if (ret != UNZ_OK) {
                    unzClose(zipFile);
                    return false;
                }

                FILE *outFile = fopen([filePath fileSystemRepresentation], "wb");
                if (!outFile) {
                    unzCloseCurrentFile(zipFile);
                    unzClose(zipFile);
                    return false;
                }

                char buffer[8192];
                int bytesRead;
                while ((bytesRead = unzReadCurrentFile(zipFile, buffer, sizeof(buffer))) > 0) {
                    fwrite(buffer, 1, bytesRead, outFile);
                }

                fclose(outFile);
                unzCloseCurrentFile(zipFile);
            }
        } while (unzGoToNextFile(zipFile) == UNZ_OK);

        unzClose(zipFile);
        return true;
    }
}

std::string GetModFolder() 
{
    std::string path = GetBasePath + "/ModFolder";
    if (fs::exists(path))
    {
        //
    }
    else 
    {
		// Create the folder
		if (fs::create_directory(path)) {
			//std::cout << "[INFO] Folder created successfully. at \n";
		}
		else {
			//std::cerr << "[ERROR] Failed to create folder.\n";
			return "";
		}
	}
    return path;
}

std::string ModFolder = GetModFolder();

std::string modifyPath(const std::string& path) {
    // Find the position of "ModFolder"
    size_t pos = path.find("ModFolder");
    if (pos == std::string::npos) {
        return path;  // If "ModFolder" is not found, return the original path
    }

    // Remove everything before and including "ModFolder"
    std::string newPath = path.substr(pos + std::string("ModFolder").length());

    // Map with specific values to check in the path
    std::map<std::string, std::string> cool_stuff = {
        {"value1", "PlatformContent"},
        {"value2", "ExtraContent"},
        {"value3", "Content"},
    };

    // Split the path into segments by '/'
    std::istringstream stream(newPath);
    std::string segment;
    std::vector<std::string> segments;
    
    while (std::getline(stream, segment, '/')) {
        segments.push_back(segment);
    }

    if (segments.size() < 2) {
        return newPath;  // If there are fewer than two segments, return the original newPath
    }

    // Check if the second segment matches any value in cool_stuff
    bool shouldContinue = false;
    std::string secondSegment = segments[1];
    for (const auto& [key, value] : cool_stuff) {
        if (secondSegment == value) {
            shouldContinue = true;
            break;
        }
    }

    //std::cout << "[INFO] Checking: " << (shouldContinue ? "yes" : "no") << std::endl;

    if (!shouldContinue) {
        // Remove two segments from the path
        segments.erase(segments.begin(), segments.begin() + 2);

        // Reassemble the path from remaining segments
        std::ostringstream newPathStream;
        for (size_t i = 0; i < segments.size(); ++i) {
            if (i > 0) {
                newPathStream << '/';
            }
            newPathStream << segments[i];
        }

        //std::cout << "[INFO] Path is: " << newPathStream.str() << std::endl;
        return newPathStream.str();
    } else {
        //std::cout << "[INFO] Path is: " << newPath << std::endl;
        return newPath;
    }
}

std::map<std::string, std::string> findFilesInFolder(const fs::path& folderPath, bool returnFullPath = false) {
    std::map<std::string, std::string> filePaths;
    int itemIndex = 1;
    std::string parentFolderPath;

    for (const auto& entry : fs::recursive_directory_iterator(folderPath)) {
        if (!entry.is_directory() && entry.path().extension() != ".DS_Store") {
            // Get the parent path of the file
            std::string parentPath = entry.path().string();
            std::string fileName = entry.path().filename().string();
            if (fileName == ".DS_Store")
            {
                continue;
            }

            // Store the processed path in the map with an index key
            filePaths["item_" + std::to_string(itemIndex)] = parentPath;
            itemIndex++;
            
            /*
            // Store the parent path for the first file found
            if (parentFolderPath.empty()) {
                parentFolderPath = entry.path().parent_path().string();
                // Add an entry for the parent path in the map
                filePaths["parent_path"] = parentFolderPath;
            }
            */
        }
    }

    return filePaths;
}

bool deleteFolder(const std::string& folderPath) {
    @autoreleasepool {
        // Convert std::string to NSString
        NSString* path = [NSString stringWithUTF8String:folderPath.c_str()];
        
        // Get a reference to the shared file manager
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        // Check if the folder exists
        if ([fileManager fileExistsAtPath:path]) {
            NSError* error = nil;
            // Attempt to remove the folder
            if ([fileManager removeItemAtPath:path error:&error]) {
                ////NSLog(@"Folder deleted successfully at path: %@", path);
                return true;
            } else {
                ////NSLog(@"Failed to delete folder at path: %@, error: %@", path, error);
            }
        } else {
            ////NSLog(@"Folder does not exist at path: %@", path);
        }
    }
    return false;
}

void copyFile(const std::string& oldPath, const std::string& newPath) {
    @autoreleasepool {
        // Convert std::string to NSString
        NSString *sourcePath = [NSString stringWithUTF8String:oldPath.c_str()];
        NSString *destinationPath = [NSString stringWithUTF8String:newPath.c_str()];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        
        // Check if source file exists
        if (![fileManager fileExistsAtPath:sourcePath]) {
            ////NSLog(@"[ERROR] Source file does not exist: %@", sourcePath);
            return;
        }

        // Create necessary directories for the destination path
        NSString *destinationDirectory = [destinationPath stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:destinationDirectory]) {
            if (![fileManager createDirectoryAtPath:destinationDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                ////NSLog(@"[ERROR] Failed to create directory: %@", destinationDirectory);
                return;
            }
        }

        // Check if destination file already exists and remove it
        if ([fileManager fileExistsAtPath:destinationPath]) {
            if (![fileManager removeItemAtPath:destinationPath error:&error]) {
                ////NSLog(@"[ERROR] Failed to remove existing file at destination: %@", error.localizedDescription);
                return;
            }
        }

        // Copy the file from oldPath to newPath
        if (![fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error]) {
            ////NSLog(@"[ERROR] Failed to copy file: %@", error.localizedDescription);
        } else {
            ////NSLog(@"[INFO] File copied successfully from %@ to %@", sourcePath, destinationPath);
        }
    }
}

void searchFolders(const std::string& rootPath, bool returnFullPath) {
    std::map<std::string, std::string> filePaths = findFilesInFolder(rootPath);
    for (const auto& [key, value] : filePaths) {
        std::string valueCopy = "/Applications/Roblox.app/Contents/Resources/" + modifyPath(value);
        //std::cout << "[INFO] Key info: " << key << ": " << value << " value copy: " << valueCopy << std::endl;
        copyFile(value, valueCopy);
    }
}

void copyFolderContents(const std::string& sourcePath, const std::string& destinationPath, bool shouldRemove) {
    try {
        // Ensure the source path exists and is a directory
        if (!fs::exists(sourcePath) || !fs::is_directory(sourcePath)) {
            //std::cerr << "[ERROR] Source path is invalid or not a directory: " << sourcePath << std::endl;
            return;
        }

        // Create the destination directory if it doesn't exist
        if (!fs::exists(destinationPath)) {
            fs::create_directories(destinationPath);
        }

        // Iterate over the contents of the source directory
        for (const auto& entry : fs::directory_iterator(sourcePath)) {
            const auto& path = entry.path();
            auto destination = fs::path(destinationPath) / path.filename();
            if (entry.path().filename() == "ouch.ogg" && !shouldRemove)
            {
                //std::cout << "[INFO] keeping old ouch.ogg file\n";
                continue;
            }
            try {
                if (fs::is_directory(path)) {
                    // Recursively copy subdirectories
                    copyFolderContents(path.string(), destination.string(), shouldRemove);
                } else if (fs::is_regular_file(path)) {
                    // Copy files
                    fs::copy_file(path, destination, fs::copy_options::overwrite_existing);
                    //std::cout << "[INFO] Copied file: " << path << " to " << destination << std::endl;
                }
            } catch (fs::filesystem_error& e) {
                //std::cerr << "[ERROR] cant copying " << path << ": " << e.what() << std::endl;
            }
        }
    } catch (fs::filesystem_error& e) {
        //std::cerr << "[ERROR] accessing directory: " << e.what() << std::endl;
    }
}

json bootstrapData;

bool FolderExists(const std::string& path) {
    NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:nsPath];
}

void runCppTask() {
    std::string folder_parent_path = checkParentDirectory(getParentFolderOfApp());
    //std::cout << "[INFO] Path to parent folder is: " << folder_parent_path << "\n";

    while (true) {
        while (!isRobloxRunning() && !isRunnerRunning()) {
            std::string fileContent = Checker(GetBasePath + "/roblox_version_data_install.json");
            std::string current_version_from_file = "";
            std::string current_version = "";
            std::string bootstrapDataFileData = Checker(GetBasePath + "/bootstrap_data.json");
            Mod_Data = GetModData();
            if (!bootstrapDataFileData.empty())
            {
                bootstrapData = json::parse(bootstrapDataFileData);
                CustomChannel = bootstrapData["channel"].get<std::string>();
            }
            if (!fileContent.empty())
            {
                json data = json::parse(fileContent);
                current_version_from_file = data["clientVersionUpload"].get<std::string>();
            }
            else
            {
                //std::cout << "[WARN] Couldn't find roblox_version.json, assuming the client is not up to date." << std::endl;
            }
            std::string downloadPath = GetBasePath + "/roblox_version_data_install.json";
            downloadFile("https://clientsettings.roblox.com/v2/client-version/MacPlayer", downloadPath.c_str());
            std::string v2fileContent = Checker(GetBasePath + "/roblox_version_data_install.json");
            if (!v2fileContent.empty())
            {
                json data = json::parse(v2fileContent);
                current_version = data["clientVersionUpload"].get<std::string>();
            }
            else
            {
                //std::cout << "[WARN] Couldn't find roblox_version.json after downloading, assuming the client is not up to date." << std::endl;
            }
            if (current_version_from_file != current_version)
            {
                if (FolderExists(GetBasePath + "/Resources"))
                {
                    deleteFolder(GetBasePath + "/Resources");
                    deleteFolder(GetBasePath + "/__MACOSX");
                }
                std::string mainPath = Path() + "/";
                std::string zipPath = mainPath + "Resources.zip";
                std::string url = "https://github.com/SomeRandomGuy45/resources/releases/download/t/Resources.zip";
                downloadFile(url.c_str(), zipPath.c_str());
                std::string unzipCommand = "unzip \"" + zipPath + "\" -d \"" + mainPath + "\"";
                if (!system(unzipCommand.c_str()))
                {

                }
                else
                {

                }
                std::string DownloadPath = Download +"/RobloxPlayer.zip";
                if (!CustomChannel.empty())
                {
                    std::string URL = "https://roblox-setup.cachefly.net/channel/" + CustomChannel + "/mac/" + current_version + "-RobloxPlayer.zip";
                    downloadFile(URL.c_str(), DownloadPath.c_str());
                }
                else
                {
                    std::string URL = "https://roblox-setup.cachefly.net/mac/" + current_version + "-RobloxPlayer.zip";
                    downloadFile(URL.c_str(), DownloadPath.c_str());
                }
                if (!unzipFile(DownloadPath.c_str(), Download.c_str()))
                {
                    std::cerr << "[ERROR] Failed to extract Roblox.zip" << std::endl;
                    return;
                }
                fixInstall(Download + "/RobloxPlayer.app");
                removeQuarantineAttribute(Download + "/RobloxPlayer.app");
                std::string pa_th  = Download + "/RobloxPlayer.app";
                RenameFile(pa_th.c_str(), "/Applications/Roblox.app");
                std::string command1 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxPlayer";
                std::string command2 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxCrashHandler";
                std::string command3 = "chmod +x /Applications/Roblox.app/Contents/MacOS/Roblox.app/Contents/MacOS/Roblox";
                std::string command4 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app/Contents/MacOS/RobloxPlayerInstaller";
                int result = system(command1.c_str());
                Check(result);
                result = system(command2.c_str());
                Check(result);
                result = system(command3.c_str());
                Check(result);
                result = system(command4.c_str());
                Check(result);
                std::string spam = "/Applications/Roblox.app";
                fixInstall(spam);
                removeQuarantineAttribute(spam);
                std::string ResourcePath = GetBasePath + "/Resources";
                std::string cursorVersion = "Current";  // Default version
                std::map<std::string, std::string> paths = {
                    {"ArrowCursor", "/Applications/Roblox.app/Contents/Resources/content/textures/Cursors/KeyboardMouse/ArrowCursor.png"},
                    {"ArrowFarCursor", "/Applications/Roblox.app/Contents/Resources/content/textures/Cursors/KeyboardMouse/ArrowFarCursor.png"},
                    {"OldWalk", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_footsteps_plastic.mp3"},
                    {"OldJump", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_jump.mp3"},
                    {"OldUp", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_get_up.mp3"},
                    {"OldFall", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_falling.mp3"},
                    {"OldLand", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_jump_land.mp3"},
                    {"OldSwim", "/Applications/Roblox.app/Contents/Resources/content/sounds/action_swim.mp3"},
                    {"OldImpact","/Applications/Roblox.app/Contents/Resources/content/sounds/impact_water.mp3"},
                    {"OOF_Path", "/Applications/Roblox.app/Contents/Resources/content/sounds/ouch.ogg"},
                    {"Mobile_Path", "/Applications/Roblox.app/Contents/Resources/ExtraContent/places/Mobile.rbxl"}
                };
                if (Mod_Data["2006 Cursor"] == "true") {
                    cursorVersion = "From2006";
                } else if (Mod_Data["2013 Cursor"] == "true") {
                    cursorVersion = "From2013";
                }
                if (Mod_Data["Old Death sound"] == "true")
                {
                    std::string BaseCopyPath = ResourcePath + "/Mods/Sounds/OldDeath.ogg";
                    copyFile(BaseCopyPath.c_str(), paths["OOF_Path"].c_str());
                }
                if (Mod_Data["Old Sounds"] == "true") {
                    std::string BaseCopyPath = ResourcePath + "/Mods/Sounds";
                    std::string CurrentCopy = BaseCopyPath + "/OldWalk.mp3";
                    copyFile(CurrentCopy.c_str(), paths["OldWalk"].c_str());
                    CurrentCopy = BaseCopyPath + "/OldJump.mp3";
                    copyFile(CurrentCopy.c_str(), paths["OldJump"].c_str());
                    CurrentCopy = BaseCopyPath + "/OldGetUp.mp3";
                    copyFile(CurrentCopy.c_str(), paths["OldUp"].c_str());
                    CurrentCopy = BaseCopyPath + "/Empty.mp3";
                    copyFile(CurrentCopy.c_str(), paths["OldFall"].c_str());
                    copyFile(CurrentCopy.c_str(), paths["OldLand"].c_str());
                    copyFile(CurrentCopy.c_str(), paths["OldSwim"].c_str());
                    copyFile(CurrentCopy.c_str(), paths["OldImpact"].c_str());
                }
                else
                {
                    std::string BaseCopyPath = ResourcePath + "/Mods/CurrentSounds";
                    bool shouldDelete = Mod_Data["Old Death sound"] == "true" ? false : true;
                    copyFolderContents(BaseCopyPath, "/Applications/Roblox.app/Contents/Resources/content/sounds/", shouldDelete);
                }

                if (Mod_Data["Old Avatar Background"] == "true")
                {
                    std::string BaseCopyPath = ResourcePath + "/Mods/OldAvatarBackground.rbxl";
                    copyFile(BaseCopyPath.c_str(), paths["Mobile_Path"].c_str());
                }
                else
                {
                    std::string BaseCopyPath = ResourcePath + "/Mods/CurrentAvatarBackground.rbxl";
                    copyFile(BaseCopyPath.c_str(), paths["Mobile_Path"].c_str());
                }

                std::string ArrowCursor = ResourcePath + "/Mods/Cursor/" + cursorVersion + "/ArrowCursor.png";
                std::string ArrowFarCursor = ResourcePath + "/Mods/Cursor/" + cursorVersion + "/ArrowFarCursor.png";
                //std::cout << "[INFO] Arrow Paths: " << ArrowCursor << " " << ArrowFarCursor << std::endl;
                // Copy both the ArrowCursor and ArrowFarCursor files
                copyFile(ArrowCursor.c_str(), paths["ArrowCursor"].c_str());
                copyFile(ArrowFarCursor.c_str(), paths["ArrowFarCursor"].c_str());
                copyFile(GetBasePath + "/data.json", "/Applications/Roblox.app/Contents/MacOS/ClientSettings/ClientAppSettings.json");
                searchFolders(ModFolder, false);
            }
            std::this_thread::sleep_for(std::chrono::seconds(5));
        }

        //std::cout << "[INFO] Roblox is running! Starting background task..." << std::endl;
        runApp(folder_parent_path + "/Play.app", true);
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}
