#pragma once
#include <wx/wx.h>
#include <wx/listctrl.h>
#include <mach-o/dyld.h>
#include <libgen.h>
#include <vector>
#include <string>
#include <fstream>
#include <sstream> 
#include <filesystem>
#include <objc/objc.h>
#include <objc/message.h>
#include <Foundation/Foundation.h>
#include "json.hpp"  // Include the nlohmann JSON library

using json = nlohmann::json;
namespace fs = std::filesystem;

class wxEditableListBox : public wxPanel
{
public:
    wxEditableListBox(wxWindow* parent, wxWindowID id = wxID_ANY);
    ~wxEditableListBox();

    void LoadFromFile(const wxString& filePath);
    void SaveToFile(const wxString& filePath);

private:
    void OnListCtrlItemActivated(wxListEvent& event);
    void OnListCtrlItemRightClick(wxListEvent& event); // New event handler for right-click
    void OnNameTextEnter(wxCommandEvent& event);
    void OnValueTextEnter(wxCommandEvent& event);
    void OnCloseButtonClick(wxCommandEvent& event);  // Event handler for close button

    wxListCtrl* listCtrl;
    wxTextCtrl* nameTextCtrl;
    wxTextCtrl* valueTextCtrl;
    wxButton* closeButton;  // Close button member variable
    long lastSelectedItemIndex;

    std::vector<std::pair<wxString, wxString>> items;  // Vector to store name-value pairs

    wxDECLARE_EVENT_TABLE();
};

enum
{
    ID_LISTCTRL = 1001,
    ID_NAME_TEXTCTRL,
    ID_VALUE_TEXTCTRL,
    ID_CLOSE_BUTTON  // ID for close button
};
std::string user = getenv("USER");
bool is_number(const std::string& s)
{
    return !s.empty() && std::find_if(s.begin(), 
        s.end(), [](unsigned char c) { return !std::isdigit(c); }) == s.end();
}

wxBEGIN_EVENT_TABLE(wxEditableListBox, wxPanel)
    EVT_LIST_ITEM_ACTIVATED(ID_LISTCTRL, wxEditableListBox::OnListCtrlItemActivated)
    EVT_LIST_ITEM_RIGHT_CLICK(ID_LISTCTRL, wxEditableListBox::OnListCtrlItemRightClick) // Bind the right-click event
    EVT_TEXT_ENTER(ID_NAME_TEXTCTRL, wxEditableListBox::OnNameTextEnter)
    EVT_TEXT_ENTER(ID_VALUE_TEXTCTRL, wxEditableListBox::OnValueTextEnter)
    EVT_BUTTON(ID_CLOSE_BUTTON, wxEditableListBox::OnCloseButtonClick)
wxEND_EVENT_TABLE()

std::string GetMacOSApperance()
{
    // Get the NSUserDefaults instance
    id userDefaults = ((id(*)(Class, SEL))objc_msgSend)(objc_getClass("NSUserDefaults"), sel_registerName("standardUserDefaults"));
    
    // Get the AppleInterfaceStyle key
    id appearance = ((id(*)(id, SEL, id))objc_msgSend)(userDefaults, sel_registerName("stringForKey:"), (id)@"AppleInterfaceStyle");
    
    if (appearance != nil)
    {
        NSString* appearanceString = (NSString*)appearance;
        return [appearanceString UTF8String];
    }
}

std::string getApplicationSupportPath() {
    const char* homeDir = std::getenv("HOME");  // Get the user's home directory
    if (!homeDir) {
        throw std::runtime_error("Failed to get home directory");
    }
    return std::string(homeDir) + "/Library/Application Support/MacBlox_Data";
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

wxEditableListBox::wxEditableListBox(wxWindow* parent, wxWindowID id)
    : wxPanel(parent, id), lastSelectedItemIndex(-1)
{
    // Set the background color of the panel to black
    wxColour bgColor = GetBackgroundColour();
    unsigned char r = bgColor.Red();
    unsigned char g = bgColor.Green();
    unsigned char b = bgColor.Blue();
    std::cout << "[INFO] Background color: (" << (int)r << ", " << (int)g << ", " << (int)b << ")\n";
    if (GetMacOSApperance() == "Light") {
        SetBackgroundColour(wxColour(128, 128, 128));
    }
    else
    {
        SetBackgroundColour(*wxBLACK);
    }

    listCtrl = new wxListCtrl(this, ID_LISTCTRL, wxDefaultPosition, wxSize(400, 200),
                              wxLC_REPORT | wxLC_SINGLE_SEL);

    if (int(r) == 231 && int(g) == 231 && int(b) == 231) {
        listCtrl->SetBackgroundColour(wxColour(128, 128, 128));
    }
    else
    {
        listCtrl->SetBackgroundColour(*wxBLACK);
    }

    listCtrl->InsertColumn(0, "Items", wxLIST_FORMAT_LEFT, 400);

    nameTextCtrl = new wxTextCtrl(this, ID_NAME_TEXTCTRL, "", wxDefaultPosition, wxSize(200, 25), wxTE_PROCESS_ENTER, wxDefaultValidator, "Name");
    valueTextCtrl = new wxTextCtrl(this, ID_VALUE_TEXTCTRL, "", wxDefaultPosition, wxSize(200, 25), wxTE_PROCESS_ENTER, wxDefaultValidator, "Value");

    closeButton = new wxButton(this, ID_CLOSE_BUTTON, "Close", wxDefaultPosition, wxSize(100, 40));  // Initialize close button

    wxBoxSizer* sizer = new wxBoxSizer(wxVERTICAL);
    sizer->Add(listCtrl, 1, wxEXPAND | wxALL, 5);
    sizer->Add(nameTextCtrl, 0, wxEXPAND | wxALL, 5);
    sizer->Add(valueTextCtrl, 0, wxEXPAND | wxALL, 5);
    sizer->Add(closeButton, 0, wxALIGN_RIGHT | wxALL, 5);  // Add close button to sizer
    SetSizer(sizer);

    // Optional: Set minimum sizes
    listCtrl->SetMinSize(wxSize(400, 200));
    nameTextCtrl->SetMinSize(wxSize(200, 25));
    valueTextCtrl->SetMinSize(wxSize(200, 25));

    // Load existing data if available
    std::string path = GetBasePath() + "/data.json";
    wxString toWxString(path.c_str(), wxConvUTF8);
    LoadFromFile(toWxString);
}

wxEditableListBox::~wxEditableListBox()
{
    // Save items to file when destructed
    SaveToFile(GetBasePath()+"/data.json");
}

void wxEditableListBox::OnListCtrlItemActivated(wxListEvent& event)
{
    long itemIndex = event.GetIndex();
    if (itemIndex != -1)
    {
        wxString itemText = listCtrl->GetItemText(itemIndex);
        wxString name, value;

        // Extract the name and value from the itemText
        name = itemText.BeforeFirst(':').Trim().AfterFirst('{').Trim();
        value = itemText.AfterFirst(':').Trim().BeforeLast('}').Trim();

        // Set the text controls with the extracted values
        nameTextCtrl->SetValue(name);
        valueTextCtrl->SetValue(value);
        
        // Store the index of the selected item for further updates
        lastSelectedItemIndex = itemIndex;
        
        // Set focus on the value text control to allow immediate editing
        valueTextCtrl->SetFocus();
    }
}

void wxEditableListBox::OnListCtrlItemRightClick(wxListEvent& event)
{
    long itemIndex = event.GetIndex();
    if (itemIndex != -1)
    {
        listCtrl->DeleteItem(itemIndex); // Remove item from list control
        items.erase(items.begin() + itemIndex); // Remove item from vector
        SaveToFile(GetBasePath() + "/data.json"); // Save updated data
    }
}

void wxEditableListBox::OnNameTextEnter(wxCommandEvent& event)
{
    wxString name = nameTextCtrl->GetValue().Trim();
    wxString value = valueTextCtrl->GetValue().Trim();

    if (name.IsEmpty())
        return;

    if (lastSelectedItemIndex != -1)
    {
        // Update the selected item in the list
        wxString itemText = wxString::Format("{%s: %s}", name, value);
        listCtrl->SetItem(lastSelectedItemIndex, 0, itemText);

        // Update the corresponding item in the items vector
        items[lastSelectedItemIndex] = std::make_pair(name, value);
    }
    else
    {
        // Add new item if no item is selected
        wxString itemText = wxString::Format("{%s: %s}", name, value);
        long index = listCtrl->InsertItem(listCtrl->GetItemCount(), itemText);
        items.push_back(std::make_pair(name, value));
    }

    // Save changes to the file
    SaveToFile(GetBasePath() + "/data.json");

    // Clear the text controls and reset the selection index
    nameTextCtrl->Clear();
    valueTextCtrl->Clear();
    lastSelectedItemIndex = -1;
}

void wxEditableListBox::OnValueTextEnter(wxCommandEvent& event)
{
    wxString name = nameTextCtrl->GetValue().Trim();
    wxString value = valueTextCtrl->GetValue().Trim();
    if (name.IsEmpty())
        return;

    bool found = false;
    for (size_t i = 0; i < items.size(); ++i)
    {
        if (items[i].first == name)
        {
            // Update existing item
            wxString itemText = wxString::Format("{%s: %s}", name, value);
            listCtrl->SetItem(i, 0, itemText);
            items[i].second = value;
            found = true;
            break;
        }
    }

    if (!found)
    {
        // Add new item if name is not found
        wxString itemText = wxString::Format("{%s: %s}", name, value);
        long index = listCtrl->InsertItem(listCtrl->GetItemCount(), itemText);
        items.push_back(std::make_pair(name, value));  // Add new item
    }
    SaveToFile(GetBasePath()+"/data.json");
    nameTextCtrl->Clear();
    valueTextCtrl->Clear();
    lastSelectedItemIndex = -1;
}

void wxEditableListBox::OnCloseButtonClick(wxCommandEvent& event)
{
    SaveToFile(GetBasePath() + "/data.json"); // Save updated data
    this->Destroy();
}

void wxEditableListBox::LoadFromFile(const wxString& filePath)
{
    std::cout << "[INFO] Loading from file " << filePath.ToStdString() << std::endl;

    // Open file
    std::ifstream file(filePath.ToStdString());
    if (!file.is_open()) {
        std::cerr << "[ERROR] Could not open file " << filePath.ToStdString() << std::endl;
        return;
    }

    try {
        // Parse JSON
        nlohmann::json jsonData;
        file >> jsonData;

        // Close file
        file.close();

        // Clear current items
        listCtrl->DeleteAllItems();
        items.clear();

        // Process JSON data
        for (const auto& el : jsonData.items()) {
            wxString name = wxString::FromUTF8(el.key().c_str());
            wxString value;

            if (el.value().is_string()) {
                value = wxString::FromUTF8(el.value().get<std::string>().c_str());
            } else if (el.value().is_number_integer()) {
                try {
                    int intValue = el.value().get<int>();
                    value = wxString::Format("%d", intValue);
                } catch (const std::out_of_range&) {
                    value = wxString::FromUTF8("Out of range integer value");
                }
            } else if (el.value().is_number_float()) {
                try {
                    double floatValue = el.value().get<double>();
                    value = wxString::Format("%g", floatValue);
                } catch (const std::out_of_range&) {
                    value = wxString::FromUTF8("Out of range float value");
                }
            } else {
                value = wxString::FromUTF8(el.value().dump().c_str());
            }

            wxString itemText = wxString::Format("{%s: %s}", name, value);
            long index = listCtrl->InsertItem(listCtrl->GetItemCount(), itemText);
            items.push_back(std::make_pair(name, value));
        }

    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "[ERROR] JSON parse error: " << e.what() << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Exception: " << e.what() << std::endl;
    }

    std::cout << "[INFO] Loading finished from file " << filePath.ToStdString() << std::endl;
}

void wxEditableListBox::SaveToFile(const wxString& filePath)
{

    std::cout << "[INFO] Saving to file " << filePath.ToStdString() << std::endl;

    json jsonData;

    for (const auto& item : items)
    {
        if (is_number(item.second.ToStdString()))
        {
            jsonData[item.first.ToStdString()] = std::stol(item.second.ToStdString());
        }
        else
        {
            jsonData[item.first.ToStdString()] = item.second.ToStdString();
        }
    }

    std::cout << "[INFO] Saving with json data " << jsonData.dump(4) << std::endl;
    std::ofstream file(filePath.ToStdString());
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
