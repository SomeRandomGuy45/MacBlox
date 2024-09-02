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
#include <fstream>
#include <libproc.h>
#include <unordered_map>
#include <string>
#include <functional>
#include "EditableListBox.h"
#include "Downloader.h"
#include "json.hpp"

#import <Foundation/Foundation.h>

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

std::string getParentFolderOfApp() {
    // Get the bundle path
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    // Get the parent directory of the bundle
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    
    // Convert NSString to std::string
    return std::string([parentPath UTF8String]);
}

class MainFrame : public wxFrame
{
public:
    MainFrame(const wxString& title, long style = wxDEFAULT_FRAME_STYLE, const wxSize& size = wxDefaultSize);

private:
    void OnLaunchButtonClick(wxCommandEvent& event);
    void SetBootstrapIcon(std::string selectedIcon);
    void SetMenu(std::string selected);
    void OnModSelection(wxCommandEvent& event);
    void OnBootstrapSelection(wxCommandEvent& event);
    void OpenPages(wxCommandEvent& event);
    void DestroyPanel();
    void ReinitializePanels();
    void LoadModsJson(const std::string& filepath);
    void SaveModsJson(const std::string& filepath);
    void LoadBootstrapJson(const std::string& filepath);
    void SaveBootstrapJson(const std::string& filepath);
    void CreateModsFolder();
    void OnRightClickDisable(wxMouseEvent& event);
    void SetSlider(std::string selected);
    void SetLight(std::string selected);
    void SetEmoji(std::string selected);
    void ProcessModName(const std::string& modName);
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
        {"2008 Bootstrap icon", false},
        {"2011 Bootstrap icon", false},
        {"Early2015 Bootstrap icon", false},
        {"Late2015 Bootstrap icon", false},
        {"2017 Bootstrap icon", false},
        {"2019 Bootstrap icon", false},
        {"2022 Bootstrap icon", false},
        {"V1 Menu", false},
        {"V2 Menu", false},
        {"V4 Menu", false},
        {"Chrome Menu", false},
        {"Use 21 Slider", false},
        {"Use 10 Slider", false},
        {"Use Voxel Lighting", false},
        {"Use Shadowmap Lighting", false},
        {"Use Future Lighting", false},
        {"Use Game Lighting", false},
        {"Use Catmoji Emoji", false},
        {"Use Windows 11 Emoji", false},
        {"Use Windows 10 Emoji", false},
        {"Use Windows 8.1 Emoji", false},
        {"Use Default Emoji", false},
    };
    std::map<std::string, bool> BootstrapEnable = {
        {"Force Reinstall", false},
        {"Allow Multiple Instance", false},
    };
    int lastX = 250;
    enum IDS {
        LaunchID = 2,
        BtnID_START = 3  // Start button IDs from a different base
    };
    json bootstrapJson;
private:
    std::unordered_map<std::string, std::function<void(const std::string&)>> actions = {
        {"Bootstrap icon", std::bind(&MainFrame::SetBootstrapIcon, this, std::placeholders::_1)},
        {"Menu", std::bind(&MainFrame::SetMenu, this, std::placeholders::_1)},
        {"Slider", std::bind(&MainFrame::SetSlider, this, std::placeholders::_1)},
        {"Lighting", std::bind(&MainFrame::SetLight, this, std::placeholders::_1)},
        {"Emoji", std::bind(&MainFrame::SetEmoji, this, std::placeholders::_1)}
    };
};

void MainFrame::SetEmoji(std::string selected)
{
    for (auto& mod : modsEnabled) {
        if (mod.first.find("Emoji") != std::string::npos && mod.first != selected) {
            mod.second = false;
        }
    }
    modsEnabled[selected] = true;
}

void MainFrame::SetLight(std::string selected)
{
    for (auto& mod : modsEnabled) {
        if (mod.first.find("Lighting") != std::string::npos && mod.first != selected) {
            mod.second = false;
        }
    }
    modsEnabled[selected] = true;
    if (selected.find("Lighting") != std::string::npos)
    {
        std::string ClientAppSettingsJson = FileChecker(GetBasePath() + "/data.json");
        json ClientAppSettings = json::parse(ClientAppSettingsJson);
        if (selected == "Use Voxel Lighting")
        {
            ClientAppSettings["DFFlagDebugRenderForceTechnologyVoxel"] = "True";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase2"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase3"] = "False";
        }
        else if (selected == "Use Shadowmap Lighting")
        {
            ClientAppSettings["DFFlagDebugRenderForceTechnologyVoxel"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase2"] = "True";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase3"] = "False";
        }
        else if (selected == "Use Future Lighting")
        {
            ClientAppSettings["DFFlagDebugRenderForceTechnologyVoxel"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase2"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase3"] = "True";
        }
        else
        {
            ClientAppSettings["DFFlagDebugRenderForceTechnologyVoxel"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase2"] = "False";
            ClientAppSettings["FFlagDebugForceFutureIsBrightPhase3"] = "False";
        }
        std::ofstream ClientJSONDump(GetBasePath() + "/data.json");
        if (ClientJSONDump.is_open())
        {
            ClientJSONDump << ClientAppSettings.dump(4);
            ClientJSONDump.close();
        }
    }
}

void MainFrame::SetSlider(std::string selected)
{
    for (auto& mod : modsEnabled) {
        if (mod.first.find("Slider") != std::string::npos && mod.first != selected) {
            mod.second = false;
        }
    }
    modsEnabled[selected] = true;
    if (selected.find("Slider") != std::string::npos)
    {
        std::string ClientAppSettingsJson = FileChecker(GetBasePath() + "/data.json");
        json ClientAppSettings = json::parse(ClientAppSettingsJson);
        if (selected == "Use 21 Slider")
        {
            ClientAppSettings["FFlagCommitToGraphicsQualityFix"] = "True";
            ClientAppSettings["FFlagFixGraphicsQuality"] = "True";
        }
        else
        {
            ClientAppSettings["FFlagCommitToGraphicsQualityFix"] = "False";
            ClientAppSettings["FFlagFixGraphicsQuality"] = "False";
        }
        std::ofstream ClientJSONDump(GetBasePath() + "/data.json");
        if (ClientJSONDump.is_open())
        {
            ClientJSONDump << ClientAppSettings.dump(4);
            ClientJSONDump.close();
        }
    }
}

void MainFrame::OnRightClickDisable(wxMouseEvent& event)
{
    // Get the mouse position relative to the checklist box
    wxPoint pos = event.GetPosition();
    
    // Get the index of the item at that position
    int selectionIndex = EditBox->HitTest(pos);
    
    if (selectionIndex != wxNOT_FOUND) // If a valid item was right-clicked
    {
        wxString itemWx = EditBox->GetString(selectionIndex);
        std::string itemName = itemWx.ToStdString();

        // Disable (uncheck) the item
        EditBox->Check(selectionIndex, false);

        // Update the corresponding map (either modsEnabled or BootstrapEnable)
        if (modsEnabled.find(itemName) != modsEnabled.end())
        {
            modsEnabled[itemName] = false;
            SaveModsJson(GetBasePath() + "/config_data.json");
        }
        else if (BootstrapEnable.find(itemName) != BootstrapEnable.end())
        {
            BootstrapEnable[itemName] = false;
            SaveBootstrapJson(GetBasePath() + "/bootstrap_data.json");
        }

        std::cout << "[INFO] Item " << itemName << " has been disabled via right-click." << std::endl;
    }

    // Skip event to allow other handlers to process it if needed
    event.Skip();
}

void MainFrame::SetMenu(std::string selected)
{
    for (auto& mod : modsEnabled) {
        if (mod.first.find("Menu") != std::string::npos && mod.first != selected) {
            mod.second = false;
        }
    }
    modsEnabled[selected] = true;

    if (selected.find("Menu") != std::string::npos)
    {
        std::string ClientAppSettingsJson = FileChecker(GetBasePath() + "/data.json");
        json ClientAppSettings = json::parse(ClientAppSettingsJson);
        if (selected == "V1 Menu")
        {
            ClientAppSettings["FFlagDisableNewIGMinDUA"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuControls"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuModernization"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuChrome"] = "False";
            ClientAppSettings["FFlagEnableMenuControlsABTest"] = "False";
            ClientAppSettings["FFlagEnableV3MenuABTest3"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuChromeABTest3"] = "False";
            if (ClientAppSettings.contains("FStringNewInGameMenuForcedUserIds"))
            {
                ClientAppSettings.erase("FStringNewInGameMenuForcedUserIds");
            }
        }
        else if (selected == "V2 Menu")
        {
            ClientAppSettings["FFlagDisableNewIGMinDUA"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuControls"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuModernization"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuChrome"] = "False";
            ClientAppSettings["FFlagEnableMenuControlsABTest"] = "True";
            ClientAppSettings["FFlagEnableV3MenuABTest3"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuChromeABTest3"] = "True";
            if (!ClientAppSettings.contains("FStringNewInGameMenuForcedUserIds"))
            {
                std::string USER_ID = PromptUserForRobloxID();
                ClientAppSettings["FStringNewInGameMenuForcedUserIds"] = USER_ID;
            }
        }
        else if (selected == "V4 Menu")
        {
            ClientAppSettings["FFlagDisableNewIGMinDUA"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuControls"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuModernization"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuChrome"] = "False";
            ClientAppSettings["FFlagEnableMenuControlsABTest"] = "False";
            ClientAppSettings["FFlagEnableV3MenuABTest3"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuChromeABTest3"] = "False";
            if (ClientAppSettings.contains("FStringNewInGameMenuForcedUserIds"))
            {
                ClientAppSettings.erase("FStringNewInGameMenuForcedUserIds");
            }
        }
        else if (selected == "Chrome Menu")
        {
            ClientAppSettings["FFlagDisableNewIGMinDUA"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuControls"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuModernization"] = "True";
            ClientAppSettings["FFlagEnableInGameMenuChrome"] = "True";
            ClientAppSettings["FFlagEnableMenuControlsABTest"] = "False";
            ClientAppSettings["FFlagEnableV3MenuABTest3"] = "False";
            ClientAppSettings["FFlagEnableInGameMenuChromeABTest3"] = "False";
            if (ClientAppSettings.contains("FStringNewInGameMenuForcedUserIds"))
            {
                ClientAppSettings.erase("FStringNewInGameMenuForcedUserIds");
            }
        }
        std::ofstream ClientJSONDump(GetBasePath() + "/data.json");
        if (ClientJSONDump.is_open())
        {
            ClientJSONDump << ClientAppSettings.dump(4);
            ClientJSONDump.close();
        }
    }
}
void MainFrame::SetBootstrapIcon(std::string selectedIcon) {
    // Iterate through the map and disable all Bootstrap icons
    for (auto& mod : modsEnabled) {
        if (mod.first.find("Bootstrap icon") != std::string::npos && mod.first != selectedIcon) {
            mod.second = false;
        }
    }

    // Enable the selected icon
    modsEnabled[selectedIcon] = true;

    if (selectedIcon.find("Bootstrap icon") != std::string::npos) {
        std::string cutted_selected_icon = GetBasePath() + "/Resources/Icon" + selectedIcon.substr(0, selectedIcon.find("Bootstrap icon") - 1) + ".png";
        std::cout << "[INFO] Selected icon: " << cutted_selected_icon << std::endl;
        std::string copyPath = getParentFolderOfApp() + "/Play.app/Contents/MacOS/Bootstrap.app/Contents/Resources/bootstrap_icon.ico";
        std::cout << "[INFO] Copying to this path: " << copyPath << "\n";
        copyFile(cutted_selected_icon, copyPath);
    }
}

void MainFrame::CreateModsFolder()
{
    if (fs::exists(GetBasePath() + "/ModFolder"))
    {

        std::cout << "[INFO] Folder already exists.\n";
    }
    else 
    {
		// Create the folder
		if (fs::create_directory(GetBasePath() + "/ModFolder")) {
			std::cout << "[INFO] Folder created successfully. at \n";
		}
		else {
			std::cerr << "[ERROR] Failed to create folder.\n";
			return;
		}
	}
}

void MainFrame::SaveBootstrapJson(const std::string& filepath) {
    std::cout << "[INFO] Saving to file " << filepath << std::endl;

    json jsonData;

    for (const auto& item : BootstrapEnable)
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

void MainFrame::LoadBootstrapJson(const std::string& filepath)
{
    std::ifstream file(filepath);
    if (!file.is_open()) {
        std::cerr << "[ERROR] Could not open file " << filepath << std::endl;
        return;
    }
    try 
    {
        json jsonData;
        file >> jsonData;
        file.close();
        if (jsonData.contains("Force Reinstall"))
        {
            jsonData["Force Reinstall"] = "false";
            std::ofstream file_of(filepath);
            if (file_of.is_open())
            {
                file_of << jsonData.dump(4);
                file_of.close();
            }
        }
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
            if (BootstrapEnable.find(name) != BootstrapEnable.end())
            {
                BootstrapEnable[name] = value == "true" ? true : false;
            }
        }
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Exception: " << e.what() << std::endl;
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
        json jsonData;
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
    CreateModsFolder();
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
        {"Bootstrap", nullptr},
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

void MainFrame::ProcessModName(const std::string& modName) {
    // Iterate through the map to find and execute the corresponding function
    for (const auto& [key, action] : actions) {
        if (modName.find(key) != std::string::npos) {
            action(modName);
            return; // Exit after the first match
        }
    }
}

void MainFrame::OnBootstrapSelection(wxCommandEvent& event)
{
    int selectionIndex = event.GetInt();
    wxString nameWx = EditBox->GetString(selectionIndex);
    std::string name = nameWx.ToStdString();

    // Toggle the mod's enabled state
    if (BootstrapEnable.find(name) != BootstrapEnable.end())
    {
        BootstrapEnable[name] = EditBox->IsChecked(selectionIndex);
    }
    EditBox->Clear();
    // Loop through the modsEnabled map and print the status
    std::cout << "[INFO] Current mod statuses:" << std::endl;
    for (const auto& [mod, isEnabled] : BootstrapEnable)
    {
        std::cout << "[INFO] name: " << mod << " is " << (isEnabled ? "enabled" : "disabled") << std::endl;
    }
    SaveBootstrapJson(GetBasePath() + "/bootstrap_data.json");
    for (const auto& [Name, isEnabled] : BootstrapEnable)
    {
        int index = EditBox->Append(Name);
        if (isEnabled == true)
        {
            EditBox->Check(index, true);
        }
    }
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
    ProcessModName(modName);
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
            EditBox->Bind(wxEVT_RIGHT_DOWN, &MainFrame::OnRightClickDisable, this);
            EditBox->Bind(wxEVT_CHECKLISTBOX, &MainFrame::OnModSelection, this);
        }
        else if (buttonName == "Bootstrap")
        {
            LoadBootstrapJson(GetBasePath() + "/bootstrap_data.json");
            wxArrayString items;

            for (const auto& [Name, isEnabled] : BootstrapEnable)
            {
                items.Add(Name);  // Add mod name to wxArrayString
            }
            
            // Initialize the checklist box
            EditBox = new wxCheckListBox(panel, wxID_ANY, wxPoint(170, 15), wxSize(425, 300), items);

            int index = 0;
            for (const auto& [Name, isEnabled] : BootstrapEnable)
            {
                EditBox->Check(index, isEnabled);
                index++;
            }
            EditBox->Bind(wxEVT_RIGHT_DOWN, &MainFrame::OnRightClickDisable, this);
            EditBox->Bind(wxEVT_CHECKLISTBOX, &MainFrame::OnBootstrapSelection, this);
        }
    }
}

void MainFrame::OnLaunchButtonClick(wxCommandEvent& event)
{
    std::cout << "[INFO] Launching..." << std::endl;
    std::string basePath = GetBasePath();
    std::string robloxInstallAppPath = basePath +"/RobloxPlayerInstaller.app";
    std::string robloxZip = basePath + "/Roblox.zip";
    if (!fs::exists("/tmp/Roblox.app")) 
    {
        /*
        
            TODO
        
        */
    }
    wxMessageBox("Added config to Roblox app","Info", wxOK | wxICON_INFORMATION);
    std::string command__ = "open " + getParentFolderOfApp() + "/Play.app --args --supercoolhackthing";
    std::cout << "[INFO] Command is: " << command__ << "\n";
    system(command__.c_str());
    exit(0);
}