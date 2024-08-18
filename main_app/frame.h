#pragma once
#include <wx/wx.h>
#include <wx/notifmsg.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <mach-o/dyld.h>
#include <map>
#include <iostream>
#include <libgen.h>
#include <libproc.h>
#include <string>
#include "EditableListBox.h"
#include "Downloader.h"
#include "json.hpp"

using json = nlohmann::json;

bool isRobloxRunning()
{
    return isAppRunning("Roblox");
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

class MainFrame : public wxFrame
{
public:
    MainFrame(const wxString& title, long style = wxDEFAULT_FRAME_STYLE, const wxSize& size = wxDefaultSize);

private:
    void OnLaunchButtonClick(wxCommandEvent& event);
    void OnModSelection(wxCommandEvent& event);
    void OpenPages(wxCommandEvent& event);
    void DestroyPanel();
    void ReinitializePanels();
    void LoadModsJson(const std::string& filepath);
    void SaveModsJson(const std::string& filepath);
    wxPanel* panel = nullptr;
    wxButton* button = nullptr;
    wxGridSizer* gridSizer = nullptr; 
    wxButton* closeButton_EditBox = nullptr;
    wxCheckListBox* EditBox = nullptr;
    std::map<std::string, wxButton*> buttons;
    std::map<std::string, bool> modsEnabled = {
        {"2006 Cursor", false},
        {"2013 Cursor", false},
        {"Old Death sound", false},
        {"Old Sounds", false},
        {"Old Avatar Background", false},
    };
    int lastX = 250;
    enum IDS {
        LaunchID = 2,
        BtnID_START = 3  // Start button IDs from a different base
    };
};

void MainFrame::SaveModsJson(const std::string& filepath)
{
    std::cout << "[INFO] Saving to file " << filepath << std::endl;

    json jsonData;

    for (const auto& item : modsEnabled)
    {
        jsonData[item.first] = item.second == true ? "true" : "false";
    }

    std::cout << "[INFO] Saving with json data " << jsonData.dump(4) << std::endl;
    std::ofstream file(filepath);
    if (file.is_open())
    {
        if (jsonData.dump(4) == "null")
        {
            std::cout << "[WARN] json data is null" << std::endl;
            file << "{}";
        }
        else
        {
            file << jsonData.dump(4);
        }
        file.close();
    }
}

void MainFrame::LoadModsJson(const std::string& filepath)
{
    std::ifstream file(filepath);
    if (!file.is_open()) {
        std::cerr << "[ERROR] Could not open file " << filepath << std::endl;
        return;
    }
    try 
    {
        nlohmann::json jsonData;
        file >> jsonData;
        file.close();
        for (const auto& el : jsonData.items()) {
            std::string name = el.key();
            std::string value = "";
            if (el.value().is_boolean())
            {
                bool val = el.value().get<bool>();
                value = val == true ? "true" : "false";
            }
            else if (el.value().is_string()) 
            {
                value = el.value().get<std::string>();
            }
            else 
            {
                value = el.value().dump();
            }
            if (modsEnabled.find(name) != modsEnabled.end())
            {
                modsEnabled[name] = value == "true" ? true : false;
            }
        }
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Exception: " << e.what() << std::endl;
    }
}

MainFrame::MainFrame(const wxString& title, long style, const wxSize& size)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, size, style)
{
    ReinitializePanels();
}

void MainFrame::DestroyPanel()
{
    if (panel)
    {
        panel->Destroy();
        panel = nullptr;  // Nullify the pointer after destruction
    }
    if (gridSizer)
    {
        delete gridSizer;
        gridSizer = nullptr;  // Nullify the pointer after deletion
    }
}

void MainFrame::ReinitializePanels()
{
    // Clear and reinitialize the map
    DestroyPanel();  // Ensure the old panel is destroyed before creating a new one
    buttons.clear(); // Clear buttons map
    panel = new wxPanel(this);
    button = new wxButton(panel, LaunchID, "Add To Install", wxPoint(250, 325), wxSize(100, 35));
    button->Bind(wxEVT_BUTTON, &MainFrame::OnLaunchButtonClick, this);

    // Initialize map with dummy data to create buttons
    buttons = {
        {"Config", nullptr},
        {"Mods", nullptr},
        {"Test Button", nullptr},
    };

    gridSizer = new wxGridSizer(0, 1, 0,0);
    int idCounter = BtnID_START;  // Unique ID counter for buttons

    for (auto& [key, value] : buttons)
    {
        if (value == nullptr)  // Check if button is uninitialized
        {
            value = new wxButton(panel, idCounter++, key, wxDefaultPosition, wxSize(100, 35));
            value->Bind(wxEVT_BUTTON, &MainFrame::OpenPages, this);
            gridSizer->Add(value);
        }
    }
    wxBoxSizer* mainSizer = new wxBoxSizer(wxHORIZONTAL);
    mainSizer->Add(gridSizer, 1, wxEXPAND | wxALL, 5);
    panel->SetSizer(mainSizer);  // Ensure that the sizer is set for the panel
    panel->Layout();
}

void MainFrame::OnModSelection(wxCommandEvent& event)
{
    int selectionIndex = event.GetInt();
    wxString modNameWx = EditBox->GetString(selectionIndex);
    std::string modName = modNameWx.ToStdString();

    // Toggle the mod's enabled state
    if (modsEnabled.find(modName) != modsEnabled.end())
    {
        if (modName == "2006 Cursor" || modName == "2013 Cursor")
        {
            std::string Check = modName == "2006 Cursor" ? "2013 Cursor" : "2006 Cursor";
            if (modsEnabled.find(Check) != modsEnabled.end() && modsEnabled[Check] == true)
            {
                modsEnabled[Check] =!modsEnabled[Check];
                std::cout << "[INFO] " << Check << " has been toggled" << std::endl;
            }
        }
        modsEnabled[modName] = EditBox->IsChecked(selectionIndex);
    }
    EditBox->Clear();
    // Loop through the modsEnabled map and print the status
    std::cout << "[INFO] Current mod statuses:" << std::endl;
    for (const auto& [mod, isEnabled] : modsEnabled)
    {
        std::cout << "[INFO] Mod: " << mod << " is " << (isEnabled ? "enabled" : "disabled") << std::endl;
    }
    SaveModsJson(GetBasePath() + "/config_data.json");
    for (const auto& [modName, isEnabled] : modsEnabled)
    {
        int index = EditBox->Append(modName);
        if (isEnabled == true)
        {
            EditBox->Check(index, true);
        }
    }
}

void MainFrame::OpenPages(wxCommandEvent& event)
{
    wxButton* clickedButton = dynamic_cast<wxButton*>(event.GetEventObject());
    if (clickedButton)
    {
        wxString buttonText = clickedButton->GetLabel();
        std::string buttonName = buttonText.ToStdString();
        std::cout << "[INFO] Button clicked with text: " << buttonName << std::endl;
        if (EditBox != nullptr)
        {
            EditBox->Destroy();
            EditBox = nullptr;
        }
        if (buttonName == "Config")
        {
            wxEditableListBox* editableListBox = new wxEditableListBox(panel, wxID_ANY);
            wxBoxSizer* mainSizer = new wxBoxSizer(wxHORIZONTAL);
            mainSizer->Add(editableListBox, 1, wxEXPAND | wxALL, 5);
            panel->SetSizer(mainSizer);
            panel->Layout();
        }
        else if (buttonName == "Mods")
        {
            LoadModsJson(GetBasePath() + "/config_data.json");
            wxArrayString items;

            for (const auto& [modName, isEnabled] : modsEnabled)
            {
                items.Add(modName);  // Add mod name to wxArrayString
            }
            
            // Initialize the checklist box
            EditBox = new wxCheckListBox(panel, wxID_ANY, wxPoint(170, 15), wxSize(425, 300), items);

            int index = 0;
            for (const auto& [modName, isEnabled] : modsEnabled)
            {
                EditBox->Check(index, isEnabled);
                index++;
            }

            // Bind the checklist box event
            EditBox->Bind(wxEVT_CHECKLISTBOX, &MainFrame::OnModSelection, this);
        }
    }
}

void MainFrame::OnLaunchButtonClick(wxCommandEvent& event)
{
    std::cout << "[INFO] Launching..." << std::endl;
    std::string basePath = GetBasePath();
    std::string robloxInstallAppPath = basePath +"/RobloxPlayerInstaller.app";
    std::string robloxZip = basePath + "/Roblox.zip";
    if (!fs::exists("/Applications/Roblox.app")) 
    {
        std::cout << "[INFO] Didn't find Roblox.app\n";
        const char* Version_URL = "https://clientsettings.roblox.com/v2/client-version/MacPlayer";
        std::string Version_Data = downloadFile_WITHOUT_DESTINATION(Version_URL);
        json Version_JSON = json::parse(Version_Data);
        std::string Latest_Version = Version_JSON["clientVersionUpload"].get<std::string>();
        std::cout << "[INFO] Latest Roblox version: " << Latest_Version << std::endl;
        std::string DownloadURL = "https://setup.rbxcdn.com/mac/" + Latest_Version + "-Roblox.zip";
        std::cout << "[INFO] Download URL: " << DownloadURL << std::endl;
        downloadFile(DownloadURL.c_str(), robloxZip.c_str());
        if (unzipFile(robloxZip.c_str(), basePath.c_str()))
        {
            std::cout << "[INFO] Unzipped Roblox.zip at path: " << robloxInstallAppPath << std::endl;
        }
        else
        {

            std::cerr << "[ERROR] Failed to unzip file\n";
            return;
        }
        runApp(robloxInstallAppPath, true);
    }
    wxMessageBox("Added config to Roblox app","Info", wxOK | wxICON_INFORMATION);
    runApp("/Applications/Roblox.app", false);
}