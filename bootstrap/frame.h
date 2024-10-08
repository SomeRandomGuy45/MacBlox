#pragma once
#include <wx/wx.h>
#include <wx/notifmsg.h>
#include <wx/image.h>
#include <wx/graphics.h>
#include <cerrno>
#include <sys/xattr.h>
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <mach-o/dyld.h>
#include <map>
#include <iostream>
#include <libgen.h>
#include <objc/objc.h>
#include <objc/message.h>
#include <libproc.h>
#include <string>
#include <cmath>
#include <thread>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <dispatch/dispatch.h>
#include <sstream>
#include <thread>
#include <exception>
#include "tinyxml2.h"
#include "helper.h"
#include "multi.h"
#include "json.hpp"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

namespace fs = std::filesystem;
using namespace tinyxml2;
using json = nlohmann::json;

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
        return;
    }
    std::cout << "[INFO] Notification shown successfully" << std::endl;
}

std::string getApplicationSupportPath() {
    const char* homeDir = std::getenv("HOME");  // Get the user's home directory
    if (!homeDir) {
        throw std::runtime_error("Failed to get home directory");
    }
    return std::string(homeDir) + "/Library/Application Support/MacBlox_Data";
}
std::string GetPath() {
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


class BootstrapperFrame : public wxFrame
{
public:
    BootstrapperFrame(const wxString& title, long style = wxDEFAULT_FRAME_STYLE, const wxSize& size = wxDefaultSize);
    void UpdateProgress(double progress);
    bool IsDone() const { return isDone; }
    void SetStatusText(const wxString& text);
    void DoLogic();
    void LoadBootstrapData(json BootStrapData);
private:
    void BootstrapData1(json BootStrapData);
    void DoFontLogic();
    void DoEmojiLogic();
    std::string GetModFolder();
    bool isDone = false;
    bool NeedToReinstall = false;
    std::string CustomChannel = "";
    std::string ModFolder = "";
    std::string RobloxApplicationPath;
    std::string GetBasePath = GetPath();
    std::string ResourcePath = GetResourcesFolderPath();
    std::string Download = GetDownloadsFolderPath();
    std::string findFileInDirectory(const std::string& directoryPath, const std::string& fileName);
    void CopyAndResignRoblox();
    json bootstrapData;
    wxPanel* panel = nullptr;
    wxStaticText* statusText = nullptr;
    wxGauge* progressGauge = nullptr;
    std::unordered_map<std::string, std::string> EmojiDownloads = {
        {"Catmoji", "https://github.com/bloxstraplabs/rbxcustom-fontemojis/releases/download/my-phone-is-78-percent/Catmoji.ttf"},
        {"Windows 10", "https://github.com/bloxstraplabs/rbxcustom-fontemojis/releases/download/my-phone-is-78-percent/Win10April2018SegoeUIEmoji.ttf"},
        {"Windows 11", "https://github.com/bloxstraplabs/rbxcustom-fontemojis/releases/download/my-phone-is-78-percent/Win1122H2SegoeUIEmoji.ttf"},
        {"Windows 8.1", "https://github.com/bloxstraplabs/rbxcustom-fontemojis/releases/download/my-phone-is-78-percent/Win8.1SegoeUIEmoji.ttf"},
        {"Default", "https://github.com/SomeRandomGuy45/resources/releases/download/t/TwemojiMozilla.ttf"},
    };
    std::unordered_map<std::string, std::string> IconDownloads {
        {"Default", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Default.icns"},
        {"2008", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Icon2008.icns"},
        {"2011", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Icon2011.icns"},
        {"2017", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Icon2017.icns"},
        {"2019", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Icon2019.icns"},
        {"2022", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/Icon2022.icns"},
        {"Early2015", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/IconEarly2015.icns"},
        {"Late2015", "https://github.com/SomeRandomGuy45/ICNS_Roblox_Icons/releases/download/v1.0.0/IconLate2015.icns"},
    };
    json Mod_Data;
    //Fix all of this
    int bootStrapVersion = 0;
    int statusText_X = 227;
    int statusText_Y = 270;
    int statusText_Size_X = 200;
    int statusText_Size_Y = 30;
    int progressGauge_X = 41;
    int progressGauge_Y = 300;
    int progressGauge_Size_X = 515;
    int progressGauge_Size_Y = -1;
    int imageX = 225;
    int imageY = 100;
    int imageSizeX = 128;
    int imageSizeY = 128;
    int r_color = 192;
    int g_color = 192;
    int b_color = 192;
    int _alpha = 128;
};

std::string BootstrapperFrame::findFileInDirectory(const std::string& directoryPath, const std::string& fileName)
{
    for (const auto& entry : fs::recursive_directory_iterator(directoryPath)) {
        if (entry.is_regular_file() && entry.path().filename() == fileName) {
            std::cout << "[INFO] Found file " << entry.path().string() << std::endl;
            return entry.path().string();
        }
    }
    return "File not found in the directory or its subdirectories.";
}

// Function to loop through the folder and process files
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

std::string getParentFolderOfApp() {
    // Get the bundle path
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    // Get the parent directory of the bundle
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    // Convert NSString to std::string
    return std::string([parentPath UTF8String]);
}

std::string BootstrapperFrame::GetModFolder() 
{
    std::string path = GetBasePath + "/ModFolder";
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

bool ModifyPlist(const std::string& path) {
    // Load the XML document
    XMLDocument doc;
    if (doc.LoadFile(path.c_str()) != XML_SUCCESS) {
        std::cerr << "[ERROR] Failed to load file: " << path << std::endl;
        return false;
    }

    // Access the root element <plist>
    XMLElement* root = doc.RootElement();
    if (!root || std::string(root->Name()) != "plist") {
        std::cerr << "[ERROR] Invalid plist file: " << path << std::endl;
        return false;
    }

    // Navigate to the <dict> element
    XMLElement* dictElement = root->FirstChildElement("dict");
    if (!dictElement) {
        std::cerr << "[ERROR] No <dict> element found in plist file." << std::endl;
        return false;
    }

    // Iterate over the elements in <dict>
    for (XMLElement* element = dictElement->FirstChildElement(); element != nullptr; element = element->NextSiblingElement()) {
        // Check for <key> elements
        if (std::string(element->Name()) == "key" && std::string(element->GetText()) == "CFBundleURLTypes") {
            XMLElement* arrayElement = element->NextSiblingElement("array");
            if (arrayElement) {
                // Iterate over <dict> elements inside the <array>
                for (XMLElement* dictInsideArray = arrayElement->FirstChildElement("dict"); dictInsideArray != nullptr; dictInsideArray = dictInsideArray->NextSiblingElement("dict")) {
                    for (XMLElement* dictChild = dictInsideArray->FirstChildElement(); dictChild != nullptr; dictChild = dictChild->NextSiblingElement()) {
                        if (std::string(dictChild->Name()) == "key" && std::string(dictChild->GetText()) == "CFBundleURLSchemes") {
                            XMLElement* urlSchemesArray = dictChild->NextSiblingElement("array");
                            if (urlSchemesArray) {
                                for (XMLElement* stringElement = urlSchemesArray->FirstChildElement("string"); stringElement != nullptr; stringElement = stringElement->NextSiblingElement("string")) {
                                    const char* value = stringElement->GetText();
                                    if (value) {
                                        std::string newValue(value);
                                        if (newValue == "roblox-player") {
                                            newValue = "roblox-test";
                                        } else if (newValue == "roblox") {
                                            newValue = "roblox-test";
                                        } else if (newValue == "Roblox Player URL")
                                        {
                                            newValue = "Test URL";
                                        }
                                        stringElement->SetText(newValue.c_str());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Save the modified document back to the file
    if (doc.SaveFile(path.c_str()) != XML_SUCCESS) {
        std::cerr << "Failed to save modified plist file: " << path << std::endl;
        return false;
    }

    return true;
}


void BootstrapperFrame::BootstrapData1(json BootStrapData)
{
    auto getPosition = [](const nlohmann::json& jsonObj, const std::string& key, int& x, int& y) {
        try {
            if (jsonObj.contains(key)) {
                if (jsonObj[key].contains("x")) {
                    std::string xStr = jsonObj[key]["x"].get<std::string>();
                    x = std::stoi(xStr);  // Convert std::string to int
                }
                if (jsonObj[key].contains("y")) {
                    std::string yStr = jsonObj[key]["y"].get<std::string>();
                    y = std::stoi(yStr);  // Convert std::string to int
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "[ERROR] Exception in getPosition: " << e.what() << std::endl;
        }
    };

    auto getSize = [](const nlohmann::json& jsonObj, const std::string& key, int& width, int& height) {
        try {
            if (jsonObj.contains(key)) {
                if (jsonObj[key].contains("x")) {
                    std::string widthStr = jsonObj[key]["x"].get<std::string>();
                    width = std::stoi(widthStr);  // Convert std::string to int
                }
                if (jsonObj[key].contains("y")) {
                    std::string heightStr = jsonObj[key]["y"].get<std::string>();
                    height = std::stoi(heightStr);  // Convert std::string to int
                }
            }
        } catch (const std::invalid_argument& ia) {
            std::cerr << "[ERROR] Invalid argument: " << ia.what() << std::endl;
        } catch (const std::exception& e) {
            std::cerr << "[ERROR] Exception in getSize: " << e.what() << std::endl;
        }
    };
    auto getColor = [](const nlohmann::json& jsonObj, const std::string& key, int& r, int& g, int& b, int& alpha) {
        try {
            if (jsonObj.contains(key)) {
                if (jsonObj[key].contains("r")) {
                    std::string rStr = jsonObj[key]["r"].get<std::string>();
                    r = std::stoi(rStr);  // Convert std::string to int
                }
                if (jsonObj[key].contains("g")) {
                    std::string gStr = jsonObj[key]["g"].get<std::string>();
                    g = std::stoi(gStr);  // Convert std::string to int
                }
                if (jsonObj[key].contains("b")) {
                    std::string bStr = jsonObj[key]["b"].get<std::string>();
                    b = std::stoi(bStr);  // Convert std::string to int
                }
                if (jsonObj[key].contains("a")) {
                    std::string aStr = jsonObj[key]["a"].get<std::string>();
                    alpha = std::stoi(aStr);  // Convert std::string to int
                }
            }
        } catch (const std::invalid_argument& ia) {
            std::cerr << "[ERROR] Invalid argument: " << ia.what() << std::endl;
        } catch (const std::exception& e) {
            std::cerr << "[ERROR] Exception in getSize: " << e.what() << std::endl;
        }
    };
    try {
        // Extract position and size for progressGauge
        if (BootStrapData.contains("progressGauge")) {
            getPosition(BootStrapData["progressGauge"], "position", progressGauge_X, progressGauge_Y);
            getSize(BootStrapData["progressGauge"], "size", progressGauge_Size_X, progressGauge_Size_Y);
            std::cout << "[INFO] progressGauge position: " << progressGauge_X << "x" << progressGauge_Y << std::endl;
            std::cout << "[INFO] progressGauge size: " << progressGauge_Size_X << "x" << progressGauge_Size_Y << std::endl;
        }

        // Extract position and size for image
        if (BootStrapData.contains("image")) {
            getPosition(BootStrapData["image"], "position", imageX, imageY);
            getSize(BootStrapData["image"], "size", imageSizeX, imageSizeY);
            std::cout << "[INFO] Image position: " << imageX << "x" << imageY << std::endl;
            std::cout << "[INFO] Image size: " << imageSizeX << "x" << imageSizeY << std::endl;
        }

        // Extract position for statusText
        if (BootStrapData.contains("statusText")) {
            getPosition(BootStrapData["statusText"], "position", statusText_X, statusText_Y);
            getSize(BootStrapData["statusText"], "size", statusText_Size_X, statusText_Size_Y);
            std::cout << "[INFO] statusText position: " << statusText_X << "x" << statusText_Y << std::endl;
            std::cout << "[INFO] statusText size: " << statusText_Size_X << "x" << statusText_Size_Y << std::endl;
        }

        if (BootStrapData.contains("background_color"))
        {
            wxColour bgColor = GetBackgroundColour();
            unsigned char r = bgColor.Red();
            unsigned char g = bgColor.Green();
            unsigned char b = bgColor.Blue();
            std::cout << "[INFO] Background color: (" << (int)r << ", " << (int)g << ", " << (int)b << ")\n";
            if (GetMacOSAppearance() == "Light")
            {
                getColor(BootStrapData, "background_color", r_color, g_color, b_color, _alpha);
            }
            else
            {
                getColor(BootStrapData, "background_color_back", r_color, g_color, b_color, _alpha);
            }
            std::cout << "[INFO] Background color: RGBA(" << r_color << ", " << g_color << ", " << b_color << ", " << _alpha << ")" << std::endl;
        }

        std::cout << "[INFO] Bootstrap data loaded successfully" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Exception in loadBootstrapData: " << e.what() << std::endl;
    }

    std::cout << "[INFO] Bootstrap data loaded successfully" << std::endl;
}

void BootstrapperFrame::LoadBootstrapData(json BootStrapData)
{
    if (BootStrapData.contains("BootstrapVersion"))
    {
        bootStrapVersion = std::stoi(BootStrapData["BootstrapVersion"].get<std::string>());
    }

    if (bootStrapVersion == 1)
    {
        std::cout << "[INFO] Bootstrap version 1 detected" << std::endl;
        BootstrapData1(BootStrapData);
    }
}

void Check(int result)
{
    if (result == 0) {
        std::cout << "[INFO] Command executed successfully." << std::endl;
    } else {
        std::cerr << "[ERROR] Command failed with exit code: " << result << std::endl;
    }
}

void BootstrapperFrame::UpdateProgress(double progress)
{
    int targetProgress = static_cast<int>(progress * 100);
    std::cout << "[INFO] Progress updated: " << targetProgress << "%" << std::endl;

    int currentProgress = progressGauge->GetValue();
    int step = (targetProgress > currentProgress) ? 1 : -1;

    while (std::abs(targetProgress - currentProgress) > 0)
    {
        currentProgress += step;

        // Update the gauge value using wxCallAfter to ensure it's done on the main thread
        wxTheApp->CallAfter([this, currentProgress]() {
            progressGauge->SetValue(currentProgress);
        });

        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}

json GetModData()
{
    if (!fs::exists(GetPath() + "/config_data.json")) {
        std::ofstream file(GetPath() + "/config_data.json");
        file << "{}";
        file.close();
    }
    json Data;
    std::ifstream file(GetPath() + "/config_data.json");
    if (!file.is_open()) {
        std::cerr << "[ERROR] Could not open file " << GetPath() + "/config_data.json" << std::endl;
        return Data;
    }
    try
    {
        file >> Data;
        file.close();
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Exception: " << e.what() << std::endl;
    }
    return Data;
}

void copyFolderContents(const std::string& sourcePath, const std::string& destinationPath, bool shouldRemove) {
    try {
        // Ensure the source path exists and is a directory
        if (!fs::exists(sourcePath) || !fs::is_directory(sourcePath)) {
            std::cerr << "[ERROR] Source path is invalid or not a directory: " << sourcePath << std::endl;
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
                std::cout << "[INFO] keeping old ouch.ogg file\n";
                continue;
            }
            try {
                if (fs::is_directory(path)) {
                    // Recursively copy subdirectories
                    copyFolderContents(path.string(), destination.string(), shouldRemove);
                } else if (fs::is_regular_file(path)) {
                    // Copy files
                    fs::copy_file(path, destination, fs::copy_options::overwrite_existing);
                    std::cout << "[INFO] Copied file: " << path << " to " << destination << std::endl;
                }
            } catch (fs::filesystem_error& e) {
                std::cerr << "[ERROR] cant copying " << path << ": " << e.what() << std::endl;
            }
        }
    } catch (fs::filesystem_error& e) {
        std::cerr << "[ERROR] accessing directory: " << e.what() << std::endl;
    }
}

bool removeQuarantineAttribute(const std::string& filePath) {
    const char* attributeName = "com.apple.quarantine";

    // First, get the size of the attribute value
    ssize_t attrSize = getxattr(filePath.c_str(), attributeName, nullptr, 0, 0, 0);
    if (attrSize == -1) {
        if (errno == ENOATTR) {
            std::cout << "[WARN] Attribute does not exist." << std::endl;
            return true; // Attribute does not exist, so nothing to remove
        } else {
            std::cerr << "[ERROR] Error checking attribute size: " << strerror(errno) << std::endl;
            return false;
        }
    }

    // Allocate a buffer of the appropriate size
    std::vector<char> buffer(attrSize);

    // Get the actual attribute value
    attrSize = getxattr(filePath.c_str(), attributeName, buffer.data(), buffer.size(), 0, 0);
    if (attrSize == -1) {
        std::cerr << "[ERROR] Error retrieving attribute: " << strerror(errno) << std::endl;
        return false;
    }

    // Remove the attribute
    int result = removexattr(filePath.c_str(), attributeName, 0);
    if (result == -1) {
        std::cerr << "[ERROR] Failed to remove attribute: " << strerror(errno) << std::endl;
        return false;
    }

    return true;
}

std::string modifyPath(const std::string& path) {
    // Find the position of "ModFolder"
    size_t pos = path.find("ModFolder");
    if (pos == std::string::npos) {
        return path;  // If "ModFolder" is not found, return the original path
    }

    // Remove everything before and including "ModFolder"
    std::string newPath = path.substr(pos + std::string("ModFolder").length());
    std::cout << "[INFO] Path is: " << newPath << std::endl;
    if (newPath.substr(0, 5) == "fonts")
    {
        newPath = "content/" + newPath;
    }
    return newPath;
}


void searchFolders(const std::string& rootPath, bool returnFullPath) {
    std::map<std::string, std::string> filePaths = findFilesInFolder(rootPath);
    for (const auto& [key, value] : filePaths) {
        std::string valueCopy = fs::temp_directory_path().string() + "/Roblox.app/Contents/Resources/" + modifyPath(value);
        //std::cout << "[INFO] Key info: " << key << ": " << value << " value copy: " << valueCopy << std::endl;
        copyFile(value, valueCopy);
    }
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

void BootstrapperFrame::CopyAndResignRoblox()
{
    std::string DownloadPath = fs::temp_directory_path().string() + "/Roblox.app/Contents/Resources/AppIcon.icns";
    std::string TypeOfDownload = "Default";
    std::string CopyPath = fs::temp_directory_path().string() + "/Roblox.app/Contents/Info.plist";
    std::string toPath = Download + "/Info.plist";
    static const std::unordered_map<std::string, std::string> Types = {
        {"2008 Bootstrap icon", "2008"},
        {"2011 Bootstrap icon", "2011"},
        {"Early2015 Bootstrap icon", "Early2015"},
        {"Late2015 Bootstrap icon", "Late2015"},
        {"2017 Bootstrap icon", "2017"},
        {"2019 Bootstrap icon", "2019"},
        {"2022 Bootstrap icon", "2022"},
        {"Default Bootstrap icon", "Default"},
    };
    for (const auto& [key, downloadType] : Types) {
        if (Mod_Data[key] == "true") {
            TypeOfDownload = downloadType;
            break;
        }
    }
    std::cout << "[INFO] Downloading file to " << DownloadPath << ". With URL: " << IconDownloads[TypeOfDownload] << "\n";

    downloadFile(IconDownloads[TypeOfDownload].c_str(), DownloadPath.c_str());
    fs::rename(CopyPath, toPath);
    std::cout << "[INFO] Successfully copied " << CopyPath << "\n";
    std::this_thread::sleep_for(std::chrono::seconds(1));
    fs::rename(toPath, CopyPath);
    std::string redo = "codesign --force --deep --sign - " + fs::temp_directory_path().string() + "/Roblox.app";
    std::cout << "[INFO] Resigning command is: " << redo << std::endl;
    system(redo.c_str());
}

NSString* stringToNSString(const std::string& str) {
    return [NSString stringWithUTF8String:str.c_str()];
}

NSImage* resizeImage(NSImage *image, NSSize newSize) {
    NSImage *resizedImage = [[NSImage alloc] initWithSize:newSize];
    
    [resizedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    // Draw the image into the new size
    [image drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height)
             fromRect:NSMakeRect(0, 0, image.size.width, image.size.height)
            operation:NSCompositingOperationCopy
             fraction:1.0];
    
    [resizedImage unlockFocus];
    return resizedImage;
}

bool compareFiles(const std::string& path1, const std::string& path2) {
    // Load images using NSImage from the given paths
    NSImage *image1 = [[NSImage alloc] initWithContentsOfFile:stringToNSString(path1)];
    NSImage *image2 = [[NSImage alloc] initWithContentsOfFile:stringToNSString(path2)];

    // Ensure both images are valid
    if (![image1 isValid]) {
        NSLog(@"[ERROR] Image 1 is not valid with path: %s", path1.c_str());
        return false;
    }
    else if (![image2 isValid]) {
        NSLog(@"[ERROR] Image 2 is not valid with path: %s", path2.c_str());
        return false;
    }

    // Ensure the images have the same size
    NSSize minSize;
    minSize.width = std::min(image1.size.width, image2.size.width);
    minSize.height = std::min(image1.size.height, image2.size.height);

    // Resize both images to the minimum size
    NSImage *resizedImage1 = resizeImage(image1, minSize);
    NSImage *resizedImage2 = resizeImage(image2, minSize);

    // Create bitmap representations for both resized images
    NSBitmapImageRep *bitmap1 = [[NSBitmapImageRep alloc] initWithData:[resizedImage1 TIFFRepresentation]];
    NSBitmapImageRep *bitmap2 = [[NSBitmapImageRep alloc] initWithData:[resizedImage2 TIFFRepresentation]];

    // Ensure both bitmaps are valid
    if (!bitmap1 || !bitmap2) {
        NSLog(@"[ERROR] Unable to create bitmap representations for images.");
        return false;
    }

    // Compare pixel data byte by byte
    NSInteger bytesPerRow = bitmap1.bytesPerRow;
    NSInteger totalBytes = bytesPerRow * bitmap1.pixelsHigh;

    unsigned char *data1 = [bitmap1 bitmapData];
    unsigned char *data2 = [bitmap2 bitmapData];

    for (NSInteger i = 0; i < totalBytes; i++) {
        if (data1[i] != data2[i]) {
            NSLog(@"[DEBUG] Found difference");
            return false; // Found a difference
        }
    }

    return true; // Images are identical
}

void BootstrapperFrame::DoEmojiLogic() {
    std::string DownloadPath = fs::temp_directory_path().string() + "/Roblox.app/Contents/Resources/content/fonts/TwemojiMozilla.ttf";
    std::string TypeOfDownload = "Default";  // Default type

    // Mapping Mod_Data keys to their corresponding download types
    static const std::unordered_map<std::string, std::string> emojiTypes = {
        {"Use Windows 11 Emoji", "Windows 11"},
        {"Use Windows 10 Emoji", "Windows 10"},
        {"Use Windows 8.1 Emoji", "Windows 8.1"},
        {"Use Catmoji Emoji", "Catmoji"},
        {"Use Default Emoji", "Default"}
    };

    // Iterate over the map to find the first matching key with value "true"
    for (const auto& [key, downloadType] : emojiTypes) {
        if (Mod_Data[key] == "true") {
            TypeOfDownload = downloadType;
            break;
        }
    }

    std::cout << "[INFO] Downloading file to " << DownloadPath << ". With URL: " << EmojiDownloads[TypeOfDownload] << "\n";

    downloadFile(EmojiDownloads[TypeOfDownload].c_str(), DownloadPath.c_str());

}

void BootstrapperFrame::DoFontLogic()
{
    //https://github.com/pizzaboxer/bloxstrap/blob/6d8d4824498853952d133650ab165fd89f3ef0e8/Bloxstrap/Bootstrapper.cs#L886
    if (!fs::exists(fs::temp_directory_path().string() + "/Roblox.app/Contents/Resources/content/fonts/families"))
    {
        return;
    }
    std::string modFamilyFolder = fs::path(ModFolder) / "content/fonts/families";
    if (fs::exists(ModFolder + "/content/fonts/CustomFont.ttf")) {
        fs::create_directories(modFamilyFolder);
        for (const auto& jsonFilePath : fs::directory_iterator(fs::temp_directory_path().string() + "/Roblox.app/Contents/Resources/content/fonts/families"))
        {
            std::string jsonFilename = jsonFilePath.path().filename().string();
            std::string modFilepath = fs::path(modFamilyFolder) / jsonFilename;
            if (fs::exists(modFilepath))
                continue;
            //std::cout << "[INFO] Setting font for " << modFilepath << "\n";
            //std::ifstream inputFile(jsonFilePath.path());
            std::string inputFile = FileChecker(jsonFilePath.path());
            if (inputFile.empty())
            {
                std::cout << "[ERROR] Couldn't open font file\n";
                continue;
            }
            //std::cout << "[INFO] Font Data is: " << inputFile << "\n";
            json fontFamilyData = json::parse(inputFile);

            if (!fontFamilyData.contains("faces"))
            {
                std::cout << "[ERROR] Couldn't find faces\n";
                continue;
            }

            for (auto& fontFace : fontFamilyData["faces"]) {
                fontFace["assetId"] = "rbxasset://fonts/CustomFont.ttf";
            }

            std::ofstream outputFile(modFilepath);
            if (!outputFile.is_open())
            {
                std::cout << "[ERROR] Couldn't open output font file\n";
                continue;
            }

            outputFile << fontFamilyData.dump(4);
            outputFile.close();
        }
    }
    else if (fs::exists(modFamilyFolder))
    {
        fs::remove_all(modFamilyFolder);
    }
}

std::string convertToLowercase(const std::string& str) 
{ 
    std::string result = ""; 
  
    for (char ch : str) { 
        // Convert each character to lowercase using tolower 
        result += tolower(ch); 
    } 
  
    return result; 
} 

void BootstrapperFrame::DoLogic()
{
    std::string TmpPath = fs::temp_directory_path().string();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DoFontLogic();
        int JsonCount = loadFolderCount(GetBasePath + "/mod_count_data.json");
        int currentCount = countCurrentMods(ModFolder);
        if (JsonCount != currentCount)
        {
            NeedToReinstall = true;
        }
        if (FolderExists(fs::temp_directory_path().string() + "/Roblox.app/Contents/"))
        {
            RobloxApplicationPath = fs::temp_directory_path().string() + "/Roblox.app/Contents/MacOS";
            if (!CanAccessFolder(RobloxApplicationPath))
            {
                RobloxApplicationPath = ShowOpenFileDialog("file://localhost"+RobloxApplicationPath);
            }
            if (!FolderExists(fs::temp_directory_path().string() + "/Roblox.app/Contents/MacOS/ClientSettings"))
            {
                CreateFolder(fs::temp_directory_path().string() + "/Roblox.app/Contents/MacOS/ClientSettings");
            }
        }
        else
        {
            RobloxApplicationPath = fs::temp_directory_path().string() + "/Roblox.app/Contents/MacOS";
            NeedToReinstall = true;
        }
        Mod_Data = GetModData();
        std::cout << "[INFO] Mod data is: " << Mod_Data.dump(4) << "\n";
        if (FolderExists(GetBasePath + "/Resources"))
        {
            deleteFolder(GetBasePath + "/Resources");
            deleteFolder(GetBasePath + "/__MACOSX");
        }
        std::string mainPath = GetPath() + "/";
        std::string zipPath = mainPath + "Resources.zip";
        std::string url = "https://github.com/SomeRandomGuy45/resources/releases/download/t/Resources.zip";
        downloadFile(url.c_str(), zipPath.c_str());
        std::string unzipCommand = "unzip \"" + zipPath + "\" -d \"" + mainPath + "\"";
        if (!system(unzipCommand.c_str()))
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cerr << "[ERROR] Couldn't unzip file" << std::endl;
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
               std::cout << "[INFO] unzipped file" << std::endl;
            });
        }
        UpdateProgress(0.1);
        std::cout << "[INFO] Path: " << RobloxApplicationPath << "\n";
        std::string bootstrapDataFileData = FileChecker(GetBasePath + "/bootstrap_data.json");
        bool shouldAllow = true;
        if (!bootstrapDataFileData.empty())
        {
            bootstrapData = json::parse(bootstrapDataFileData);
            if (bootstrapData.contains("channel"))
            {
                CustomChannel = bootstrapData["channel"].get<std::string>();
            }
            if (bootstrapData.contains("Force Reinstall"))
            {
                std::string ShouldReinstall = bootstrapData["Force Reinstall"].get<std::string>();
                ShouldReinstall = convertToLowercase(ShouldReinstall);
                if (ShouldReinstall.find("true") != std::string::npos)
                {
                    NeedToReinstall = true;
                }
                bootstrapData["Force Reinstall"] = "false";
                std::ofstream bootstrapDataFile(GetBasePath + "/bootstrap_data.json");
                if (bootstrapDataFile.is_open())
                {
                    bootstrapDataFile << bootstrapData.dump(4);
                    bootstrapDataFile.close();
                }
            }
            if (bootstrapData.contains("Allow Multiple Instance"))
            {
                std::string AllowMultiple = convertToLowercase(bootstrapData["Allow Multiple Instance"].get<std::string>());
                if (AllowMultiple.find("true") != std::string::npos)
                {
                    shouldAllow = false;
                }
                else
                {
                    shouldAllow = true;
                }
            }
        }
        if (RobloxApplicationPath != fs::temp_directory_path().string() + "/Roblox.app/Contents/MacOS")
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cerr << "[ERROR] Thats not the right path!" << std::endl;
            });
            std::string path = "The location of the Roblox MacOS folder isn't correct. The location of is /tmp/Roblox.app/Contents/MacOS";
            wxString toWxString(path.c_str(), wxConvUTF8);
            wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);
            Close(true);
            return;
        }
        UpdateProgress(0.35);
        SetStatusText("Checking for Updates");
        std::this_thread::sleep_for(std::chrono::seconds(1));
        std::string fileContent = FileChecker(GetBasePath + "/roblox_version_data_install.json");
        std::string current_version_from_file = "";
        std::string current_version = "";
        if (!fileContent.empty())
        {
            if (fileContent.find("Adaptive Concurrency Limits Enforced. The server is temporarily unavailable due to high load. Please retry later.") != std::string::npos)
            {
                current_version_from_file = "";
            }
            else
            {
                json data = json::parse(fileContent);
                current_version_from_file = data["clientVersionUpload"].get<std::string>();
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cout << "[WARN] Couldn't find roblox_version.json, assuming the client is not up to date." << std::endl;
            });
            NeedToReinstall = true;
        }
        std::string downloadPath = GetBasePath + "/roblox_version_data_install.json";
        std::cout << "[INFO] Downloading file " << downloadPath << std::endl;
        downloadFile("https://clientsettings.roblox.com/v2/client-version/MacPlayer", downloadPath.c_str());
        std::string v2fileContent = FileChecker(GetBasePath + "/roblox_version_data_install.json");
        std::cout << "[INFO] Downloaded file\n";
        if (!v2fileContent.empty())
        {
            if (fileContent.find("Adaptive Concurrency Limits Enforced. The server is temporarily unavailable due to high load. Please retry later.") != std::string::npos)
            {
                current_version = "";
            }
            else
            {
                json data = json::parse(v2fileContent);
                current_version = data["clientVersionUpload"].get<std::string>();
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cout << "[WARN] Couldn't find roblox_version.json after downloading, assuming the client is not up to date." << std::endl;
            });
            NeedToReinstall = true;
        }
            
        if (current_version_from_file != current_version)
        {
            NeedToReinstall = true;
        }

        if (NeedToReinstall)
        {
            std::string DownloadPath = Download +"/RobloxPlayer.zip";
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cout << "[INFO] Reinstalling Roblox" << std::endl;
            });
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
            bool isDone = false;
            /*
            std::string warn_todo = "Please extract RobloxPlayer.zip to the Application Folder and rename it to Roblox.app (if u cant see the .app just rename it to Roblox). The file path is ~/Downloads/RobloxPlayer.zip";
            wxString toWxString_warn(warn_todo.c_str(), wxConvUTF8);
            wxMessageBox(toWxString_warn, "Info", wxOK | wxICON_INFORMATION);
            do {
                if (doesAppExist(GetBasePath + "/Roblox.app"))
                {
                    isDone = true;
                    break;
                }
            } while (!isDone);
            std::string defaultPath = GetBasePath + "/Roblox.app/Contents/MacOS";
            RobloxApplicationPath = ShowOpenFileDialog("file://localhost"+defaultPath);
            if (RobloxApplicationPath != GetBasePath + "/Roblox.app/Contents/MacOS")
            {
                std::cerr << "[ERROR] Thats not the right path!" << std::endl;
                std::string path = "The location of the Roblox MacOS folder isn't correct. The location of is /tmp/Roblox.app/Contents/MacOS";
                wxString toWxString(path.c_str(), wxConvUTF8);
                wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);
                Close(true);
                return;
            }
            */
            if (!unzipFile(DownloadPath.c_str(), Download.c_str()))
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    std::cerr << "[ERROR] Failed to extract Roblox.zip" << std::endl;
                });
                Close(true);
                return;
            }
            ModifyPlist(Download + "/RobloxPlayer.app/Contents/Info.plist");
            ChangeMultiInstance(Download + "/RobloxPlayer.app/Contents/Info.plist", shouldAllow);
            fixInstall(Download + "/RobloxPlayer.app");
            removeQuarantineAttribute(Download + "/RobloxPlayer.app");
            std::string RobloxPlayerPath  = Download + "/RobloxPlayer.app";
            std::string RobloxCopyPath = fs::temp_directory_path().string() + "Roblox.app";
            RenameFile(RobloxPlayerPath.c_str(), RobloxCopyPath.c_str());
            std::this_thread::sleep_for(std::chrono::seconds(1));
            std::string command1 = "chmod +x \"" + TmpPath + "/Roblox.app/Contents/MacOS/RobloxPlayer\"";
            std::string command2 = "chmod +x \"" + TmpPath + "/Roblox.app/Contents/MacOS/RobloxCrashHandler\"";
            std::string command3 = "chmod +x \"" + TmpPath + "/Roblox.app/Contents/MacOS/Roblox.app/Contents/MacOS/Roblox\"";
            std::string command4 = "chmod +x \"" + TmpPath + "/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app/Contents/MacOS/RobloxPlayerInstaller\"";;
            int result = system(command1.c_str());
            Check(result);
            result = system(command2.c_str());
            Check(result);
            result = system(command3.c_str());
            Check(result);
            result = system(command4.c_str());
            Check(result);
            std::string spam = TmpPath + "/Roblox.app";
            fixInstall(spam);
            ChangeMultiInstance(TmpPath + "/Roblox.app/Contents/Info.plist", shouldAllow);
            ModifyPlist(TmpPath + "/Roblox.app/Contents/Info.plist");
            std::string redo = "codesign --force --deep --sign - " + fs::temp_directory_path().string() + "/Roblox.app";
            std::cout << "[INFO] Resigning command is: " << redo << std::endl;
            std::filesystem::remove(TmpPath + "/Roblox.app/Contents/Resources/Assets.car");
            system(redo.c_str());
            removeQuarantineAttribute(spam);
            if (!FolderExists(TmpPath + "/Roblox.app/Contents/MacOS/ClientSettings"))
            {
                CreateFolder(TmpPath + "/Roblox.app/Contents/MacOS/ClientSettings");
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::cout << "[INFO] Roblox is up to date" << std::endl;
            });
        }
        std::this_thread::sleep_for(std::chrono::seconds(2));
        SetStatusText("Adding Modifications");
        CopyAndResignRoblox();
        DoEmojiLogic();
        std::string ResourcePath = GetBasePath + "/Resources";
        std::string cursorVersion = "Current";  // Default version
        std::map<std::string, std::string> paths = {
            {"ArrowCursor", TmpPath + "/Roblox.app/Contents/Resources/content/textures/Cursors/KeyboardMouse/ArrowCursor.png"},
            {"ArrowFarCursor", TmpPath + "/Roblox.app/Contents/Resources/content/textures/Cursors/KeyboardMouse/ArrowFarCursor.png"},
            {"OldWalk", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_footsteps_plastic.mp3"},
            {"OldJump", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_jump.mp3"},
            {"OldUp", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_get_up.mp3"},
            {"OldFall", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_falling.mp3"},
            {"OldLand", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_jump_land.mp3"},
            {"OldSwim", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/action_swim.mp3"},
            {"OldImpact",TmpPath + "/Roblox.app/Contents/Resources/content/sounds/impact_water.mp3"},
            {"OOF_Path", TmpPath + "/Roblox.app/Contents/Resources/content/sounds/ouch.ogg"},
            {"Mobile_Path", TmpPath + "/Roblox.app/Contents/Resources/ExtraContent/places/Mobile.rbxl"}
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
            RenameFile(CurrentCopy.c_str(), paths["OldWalk"].c_str());
            CurrentCopy = BaseCopyPath + "/OldJump.mp3";
            RenameFile(CurrentCopy.c_str(), paths["OldJump"].c_str());
            CurrentCopy = BaseCopyPath + "/OldGetUp.mp3";
            RenameFile(CurrentCopy.c_str(), paths["OldUp"].c_str());
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
            copyFolderContents(BaseCopyPath, TmpPath + "/Roblox.app/Contents/Resources/content/sounds/", shouldDelete);
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
        std::cout << "[INFO] Arrow Paths: " << ArrowCursor << " " << ArrowFarCursor << std::endl;
        // Copy both the ArrowCursor and ArrowFarCursor files
        RenameFile(ArrowCursor.c_str(), paths["ArrowCursor"].c_str());
        RenameFile(ArrowFarCursor.c_str(), paths["ArrowFarCursor"].c_str());
        copyFile(GetBasePath + "/data.json", TmpPath + "/Roblox.app/Contents/MacOS/ClientSettings/ClientAppSettings.json");
        searchFolders(ModFolder, false);
        /*
        if (compareFiles(GetResourcesFolderPath() + "/bootstrap_icon.ico","/tmp/Roblox.app/Contents/Resources/AppIcon.icns") == false)
        {
            std::string fixCommand ="\"" + GetResourcesFolderPath() + "/helper.sh\"";
            system(fixCommand.c_str());
        }
        */
        GetCurrentCountOfModFolder(ModFolder, GetBasePath);
        std::this_thread::sleep_for(std::chrono::seconds(2));
        UpdateProgress(1);
        std::this_thread::sleep_for(std::chrono::seconds(2));
        exit(0);
    });
}

void BootstrapperFrame::SetStatusText(const wxString& text)
{
    statusText->SetLabel("");
    std::this_thread::sleep_for(std::chrono::microseconds(25));
    statusText->SetLabel(text);
    //Layout();
}

BootstrapperFrame::BootstrapperFrame(const wxString& title, long style, const wxSize& size)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, size, style)
{
    TestCommand();
    ModFolder = GetModFolder();
    std::cout << "[INFO] Mod folder is: " << ModFolder << std::endl;
    // Initialize image handlers
    wxInitAllImageHandlers();

    // Create the panel
    panel = new wxPanel(this);
    panel->SetBackgroundStyle(wxBG_STYLE_PAINT);
    panel->SetBackgroundColour(wxColour(r_color, g_color, b_color, _alpha));
    panel->Refresh();
    // Load the image using wxImage
    wxImage image(ResourcePath + "/bootstrap_icon.ico", wxBITMAP_TYPE_ICO);
    if (!image.IsOk())
    {
        std::cerr << "[ERROR] Failed to load image with path: " << ResourcePath + "/bootstrap_icon.png" << std::endl;
        return;
    }

    // Convert wxImage to wxBitmap
    wxBitmap bitmap(image);

    wxSize fixedSize = wxSize(statusText_Size_X, statusText_Size_Y);

    // Create the static text control with a fixed size
    statusText = new wxStaticText(panel, wxID_ANY, "Getting files ready",
                                 wxPoint(statusText_X, statusText_Y), fixedSize,
                                 wxST_NO_AUTORESIZE | wxALIGN_CENTER_VERTICAL);
    // Create the progress gauge
    progressGauge = new wxGauge(panel, wxID_ANY, 100, wxPoint(progressGauge_X, progressGauge_Y), wxSize(progressGauge_Size_X, progressGauge_Size_Y), wxGA_SMOOTH);

    // Create the static bitmap to display the image
    wxStaticBitmap* displayImage = new wxStaticBitmap(panel, wxID_ANY, bitmap, wxPoint(imageX, imageY), wxSize(imageSizeX, imageSizeY));

    // Raise the controls so they are displayed on top
    statusText->Raise();
    progressGauge->Raise();
    std::cout << "[INFO] " << Download << std::endl;
}
