#pragma once
#include <wx/wx.h>
#include <wx/listctrl.h>
#include <mach-o/dyld.h>
#include <libgen.h>
#include <vector>
#include <string>
#include <fstream>
#include <sstream> 
#include "json.hpp"  // Include the nlohmann JSON library

using json = nlohmann::json;

class wxEditableListBox : public wxPanel
{
public:
    wxEditableListBox(wxWindow* parent, wxWindowID id = wxID_ANY);
    ~wxEditableListBox();

    void LoadFromFile(const wxString& filePath);
    void SaveToFile(const wxString& filePath);

private:
    void OnListCtrlItemActivated(wxListEvent& event);
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

bool is_number(const std::string& s)
{
    return !s.empty() && std::find_if(s.begin(), 
        s.end(), [](unsigned char c) { return !std::isdigit(c); }) == s.end();
}

wxBEGIN_EVENT_TABLE(wxEditableListBox, wxPanel)
    EVT_LIST_ITEM_ACTIVATED(ID_LISTCTRL, wxEditableListBox::OnListCtrlItemActivated)
    EVT_TEXT_ENTER(ID_NAME_TEXTCTRL, wxEditableListBox::OnNameTextEnter)
    EVT_TEXT_ENTER(ID_VALUE_TEXTCTRL, wxEditableListBox::OnValueTextEnter)
    EVT_BUTTON(ID_CLOSE_BUTTON, wxEditableListBox::OnCloseButtonClick)  // Bind close button event
wxEND_EVENT_TABLE()

std::string GetBasePath() {
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


wxEditableListBox::wxEditableListBox(wxWindow* parent, wxWindowID id)
    : wxPanel(parent, id), lastSelectedItemIndex(-1)
{
    listCtrl = new wxListCtrl(this, ID_LISTCTRL, wxDefaultPosition, wxSize(400, 200),
                              wxLC_REPORT | wxLC_SINGLE_SEL);
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
    LoadFromFile("data.json");
}

wxEditableListBox::~wxEditableListBox()
{
    // Save items to file when destructed
    SaveToFile("data.json");
}

void wxEditableListBox::OnListCtrlItemActivated(wxListEvent& event)
{
    long itemIndex = event.GetIndex();
    if (itemIndex != -1)
    {
        wxString itemText = listCtrl->GetItemText(itemIndex);
        // Extract name and value from formatted string {name: value}
        wxString name, value;
        if (itemText.BeforeFirst(':').Trim().AfterFirst('{').Trim().BeforeLast('}').Trim().Length())
        {
            name = itemText.BeforeFirst(':').Trim();
            value = itemText.AfterFirst(':').Trim().BeforeLast('}').Trim();
        }
        nameTextCtrl->SetValue(name);
        valueTextCtrl->SetValue(value);
        lastSelectedItemIndex = itemIndex;
    }
}

void wxEditableListBox::OnNameTextEnter(wxCommandEvent& event)
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
    SaveToFile("data.json");
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
    SaveToFile("data.json");
    nameTextCtrl->Clear();
    valueTextCtrl->Clear();
    lastSelectedItemIndex = -1;
}

void wxEditableListBox::OnCloseButtonClick(wxCommandEvent& event)
{
    this->Hide();
}

void wxEditableListBox::LoadFromFile(const wxString& filePath)
{
    std::ifstream file(filePath.ToStdString());
    if (file.is_open())
    {
        json jsonData;
        file >> jsonData;
        file.close();

        listCtrl->DeleteAllItems();
        items.clear();

        for (auto& el : jsonData.items())
        {
            wxString name = wxString::FromUTF8(el.key().c_str());
            wxString value = wxString::FromUTF8(el.value().get<std::string>().c_str());
            wxString itemText = wxString::Format("{%s: %s}", name, value);
            long index = listCtrl->InsertItem(listCtrl->GetItemCount(), itemText);
            items.push_back(std::make_pair(name, value));
        }
    }
}

void wxEditableListBox::SaveToFile(const wxString& filePath)
{

    std::cout << "[INFO] Saving to file " << filePath.ToStdString() << std::endl;

    json jsonData;

    for (const auto& item : items)
    {
        if (is_number(item.second.ToStdString()))
        {
            jsonData[item.first.ToStdString()] = std::stoi(item.second.ToStdString());
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
