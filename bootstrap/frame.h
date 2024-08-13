#pragma once
#include <wx/wx.h>
#include <wx/notifmsg.h>
#include <wx/image.h>
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
#include <libproc.h>
#include <string>
#include <cmath>
#include <thread>
#include <chrono>
#include <filesystem>
#include "helper.h"
#include "json.hpp"

namespace fs = std::filesystem;
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
    }
    else
    {
        std::cout << "[INFO] Notification shown successfully" << std::endl;
    }
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

    bool isDone = false;
    bool NeedToReinstall = false;
    std::string CustomChannel = "";
    std::string RobloxApplicationPath;
    std::string GetBasePath = GetPath();
    std::string ResourcePath = GetResourcesFolderPath();
    std::string Download = GetDownloadsFolderPath();
    json bootstrapData;
    wxPanel* panel = nullptr;
    wxStaticText* statusText = nullptr;
    wxGauge* progressGauge = nullptr;
    //Fix all of this
    int bootStrapVersion = 0;
    int statusText_X = 235;
    int statusText_Y = 270;
    int statusText_Size_X = 0;
    int statusText_Size_Y = 0;
    int progressGauge_X = 41;
    int progressGauge_Y = 300;
    int progressGauge_Size_X = 515;
    int progressGauge_Size_Y = -1;
    int imageX = 235;
    int imageY = 100;
    int imageSizeX = 128;
    int imageSizeY = 128;
};

void BootstrapperFrame::BootstrapData1(json BootStrapData)
{
    if (BootStrapData.contains("progressGauge") && BootStrapData["progressGauge"].contains("position"))
    {
        if (BootStrapData["progressGauge"]["position"].contains("x"))
        {
            progressGauge_X = std::stoi(BootStrapData["progressGauge"]["position"]["x"].get<std::string>());
        }

        if (BootStrapData["progressGauge"]["position"].contains("y"))
        {
            progressGauge_Y = std::stoi(BootStrapData["progressGauge"]["position"]["y"].get<std::string>());
        }
    }
    if (BootStrapData.contains("progressGauge") && BootStrapData["progressGauge"].contains("size"))
    {
        if (BootStrapData["progressGauge"]["size"].contains("x"))
        {
            progressGauge_Size_X = std::stoi(BootStrapData["progressGauge"]["size"]["x"].get<std::string>());
        }

        if (BootStrapData["progressGauge"]["size"].contains("y"))
        {
           progressGauge_Size_Y = std::stoi(BootStrapData["progressGauge"]["size"]["y"].get<std::string>());
        }
    }
    if (BootStrapData.contains("image") && BootStrapData["image"].contains("position"))
    {
        if (BootStrapData["image"]["position"].contains("x"))
        {
            imageX = std::stoi(BootStrapData["image"]["position"]["x"].get<std::string>());
        }

        if (BootStrapData["image"]["position"].contains("y"))
        {
            imageY = std::stoi(BootStrapData["image"]["position"]["y"].get<std::string>());
        }
        std::cout << "[INFO] Image position: " << imageX << "x" << imageY << std::endl;
    }
    if (BootStrapData.contains("image") && BootStrapData["image"].contains("size"))
    {
        if (BootStrapData["image"]["size"].contains("x"))
        {
            imageSizeX = std::stoi(BootStrapData["image"]["size"]["x"].get<std::string>());
        }

        if (BootStrapData["image"]["size"].contains("y"))
        {
            imageSizeY = std::stoi(BootStrapData["image"]["size"]["y"].get<std::string>());
        }
    }
    if (BootStrapData.contains("statusText") && BootStrapData["statusText"].contains("position"))
    {
        if (BootStrapData["statusText"]["position"].contains("x"))
        {
            statusText_X = std::stoi(BootStrapData["statusText"]["position"]["x"].get<std::string>());
        }

        if (BootStrapData["statusText"]["position"].contains("y"))
        {
            statusText_Y = std::stoi(BootStrapData["statusText"]["position"]["y"].get<std::string>());
        }
    }
    std::cout << "[INFO] Bootstrap data loaded successfully" << std::endl;
}

void BootstrapperFrame::LoadBootstrapData(json BootStrapData)
{
    /*
    
            TODO:
                Refactor this so its better and more readable.

    */
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
        std::cout << "[INFO] Current progress: " << currentProgress << "%" << std::endl;
        progressGauge->SetValue(currentProgress);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
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

void BootstrapperFrame::DoLogic()
{
    if (FolderExists("/Applications/Roblox.app/Contents/"))
    {
        RobloxApplicationPath = "/Applications/Roblox.app/Contents/MacOS";
        if (!CanAccessFolder(RobloxApplicationPath))
        {
            RobloxApplicationPath = ShowOpenFileDialog("file://localhost"+RobloxApplicationPath);
        }
        if (!FolderExists("/Applications/Roblox.app/Contents/MacOS/ClientSettings"))
        {
            CreateFolder("/Applications/Roblox.app/Contents/MacOS/ClientSettings");
        }
    }
    else
    {
        RobloxApplicationPath = "/Applications/Roblox.app/Contents/MacOS";
        NeedToReinstall = true;
    }
    std::cout << "[INFO] Path: " << RobloxApplicationPath << "\n";
    std::string bootstrapDataFileData = FileChecker(GetBasePath + "/bootstrap_data.json");
    if (!bootstrapDataFileData.empty())
    {
        bootstrapData = json::parse(bootstrapDataFileData);
        CustomChannel = bootstrapData["channel"].get<std::string>();
        std::string ShouldReinstall = bootstrapData["force_reinstall"].get<std::string>();
        if (ShouldReinstall == "true")
        {
            NeedToReinstall = true;
        }
    }
    if (RobloxApplicationPath != "/Applications/Roblox.app/Contents/MacOS")
    {
        std::cerr << "[ERROR] Thats not the right path!" << std::endl;
        std::string path = "The location of the Roblox MacOS folder isn't correct. The location of is /Applications/Roblox.app/Contents/MacOS";
        wxString toWxString(path.c_str(), wxConvUTF8);
        wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);
        Close(true);
        return;
    }
    UpdateProgress(0.1);
    SetStatusText("Checking for Updates");
    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::string fileContent = FileChecker(GetBasePath + "/roblox_version_data_install.json");
    std::string current_version_from_file = "";
    std::string current_version = "";
    if (!fileContent.empty())
    {
        json data = json::parse(fileContent);
        current_version_from_file = data["clientVersionUpload"].get<std::string>();
    }
    else
    {
        std::cout << "[WARN] Couldn't find roblox_version.json, assuming the client is not up to date." << std::endl;
    }
    std::string downloadPath = GetBasePath + "/roblox_version_data_install.json";
    downloadFile("https://clientsettings.roblox.com/v2/client-version/MacPlayer", downloadPath.c_str());
    std::string v2fileContent = FileChecker(GetBasePath + "/roblox_version_data_install.json");
    if (!v2fileContent.empty())
    {
        json data = json::parse(v2fileContent);
        current_version = data["clientVersionUpload"].get<std::string>();
    }
    else
    {
       std::cout << "[WARN] Couldn't find roblox_version.json after downloading, assuming the client is not up to date." << std::endl;
    }
        
    if (current_version_from_file != current_version)
    {
        NeedToReinstall = true;
    }
    else
    {
        NeedToReinstall = false;
    }
    if (NeedToReinstall)
    {
        std::string DownloadPath = Download +"/RobloxPlayer.zip";
        std::cout << "[INFO] Reinstalling Roblox" << std::endl;
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
            if (doesAppExist("/Applications/Roblox.app"))
            {
                isDone = true;
                break;
            }
        } while (!isDone);
        std::string defaultPath = "/Applications/Roblox.app/Contents/MacOS";
        RobloxApplicationPath = ShowOpenFileDialog("file://localhost"+defaultPath);
        if (RobloxApplicationPath != "/Applications/Roblox.app/Contents/MacOS")
        {
            std::cerr << "[ERROR] Thats not the right path!" << std::endl;
            std::string path = "The location of the Roblox MacOS folder isn't correct. The location of is /Applications/Roblox.app/Contents/MacOS";
            wxString toWxString(path.c_str(), wxConvUTF8);
            wxMessageBox(toWxString, "Error", wxOK | wxICON_ERROR);
            Close(true);
            return;
        }
        */
        if (!unzipFile(DownloadPath.c_str(), Download.c_str()))
        {
            std::cerr << "[ERROR] Failed to extract Roblox.zip" << std::endl;
            Close(true);
            return;
        }
        fixInstall(Download + "/RobloxPlayer.app");
        removeQuarantineAttribute(Download + "/RobloxPlayer.app");
        std::string pa_th  = Download + "/RobloxPlayer.app";
        RenameFile(pa_th.c_str(), "/Applications/Roblox.app");
        std::this_thread::sleep_for(std::chrono::seconds(1));
        std::string command1 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxPlayer";
        std::string command2 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxCrashHandler";
        std::string command3 = "chmod +x /Applications/Roblox.app/Contents/MacOS/Roblox.app/Contents/MacOS/Roblox";
        std::string command4 = "chmod +x /Applications/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app/Contents/MacOS/RobloxPlayerInstaller";
        std::string fixCommand = ResourcePath + "/helper.sh";
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
        if (!FolderExists("/Applications/Roblox.app/Contents/MacOS/ClientSettings"))
        {
            CreateFolder("/Applications/Roblox.app/Contents/MacOS/ClientSettings");
        }
    }
    else
    {
        std::cout << "[INFO] Roblox is up to date" << std::endl;
    }
    std::this_thread::sleep_for(std::chrono::seconds(1));
    SetStatusText("Adding Modifications");
    copyFile(GetBasePath + "/data.json", "/Applications/Roblox.app/Contents/MacOS/ClientSettings/ClientAppSettings.json");
    UpdateProgress(0.35);
}

void BootstrapperFrame::SetStatusText(const wxString& text)
{
    statusText->SetLabel(text);
    Layout();
}

BootstrapperFrame::BootstrapperFrame(const wxString& title, long style, const wxSize& size)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, size, style)
{
    TestCommand();
    // Initialize image handlers
    wxInitAllImageHandlers();

    // Create the panel
    panel = new wxPanel(this);

    // Load the image using wxImage
    wxImage image(ResourcePath + "/bootstrap_icon.png", wxBITMAP_TYPE_PNG);
    if (!image.IsOk())
    {
        std::cerr << "[ERROR] Failed to load image!" << std::endl;
        return;
    }

    // Convert wxImage to wxBitmap
    wxBitmap bitmap(image);

    // Create the status text
    if (statusText_Size_Y != 0 && statusText_Size_X != 0)
    {
        statusText = new wxStaticText(panel, wxID_ANY, "Getting files ready", wxPoint(statusText_X, statusText_Y), wxSize(statusText_Size_X, statusText_Size_Y));
    }
    else
    {
        statusText = new wxStaticText(panel, wxID_ANY, "Getting files ready", wxPoint(statusText_X, statusText_Y), wxDefaultSize);
    }

    // Create the progress gauge
    progressGauge = new wxGauge(panel, wxID_ANY, 100, wxPoint(progressGauge_X, progressGauge_Y), wxSize(progressGauge_Size_X, progressGauge_Size_Y));

    // Create the static bitmap to display the image
    wxStaticBitmap* displayImage = new wxStaticBitmap(panel, wxID_ANY, bitmap, wxPoint(imageX, imageY), wxSize(imageSizeX, imageSizeY));

    // Raise the controls so they are displayed on top
    statusText->Raise();
    progressGauge->Raise();
    std::cout << "[INFO] " << Download << std::endl;
}