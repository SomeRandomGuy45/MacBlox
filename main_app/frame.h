#pragma once
#include <wx/wx.h>
#include <mach-o/dyld.h>
#include <map>
#include <iostream>

class MainFrame : public wxFrame
{
public:
    MainFrame(const wxString& title, long style = wxDEFAULT_FRAME_STYLE, const wxSize& size = wxDefaultSize);

private:
    void OnLaunchButtonClick(wxCommandEvent& event);
    void OpenPages(wxCommandEvent& event);
    void DestroyPanel();
    void ReinitializePanels();
    wxPanel* panel = nullptr;
    wxButton* button = nullptr;
    wxGridSizer* gridSizer = nullptr; 
    std::map<std::string, wxButton*> buttons;
    int lastX = 250;

    enum IDS {
        LaunchID = 2,
        BtnID_START = 3  // Start button IDs from a different base
    };
};

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
    button = new wxButton(panel, LaunchID, "Launch", wxPoint(250, 325), wxSize(100, 35));
    button->Bind(wxEVT_BUTTON, &MainFrame::OnLaunchButtonClick, this);

    // Initialize map with dummy data to create buttons
    buttons = {
        {"Config", nullptr},
        {"Test", nullptr},
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

    panel->SetSizer(gridSizer);  // Ensure that the sizer is set for the panel
    panel->Layout();
}

void MainFrame::OpenPages(wxCommandEvent& event)
{
    wxButton* clickedButton = dynamic_cast<wxButton*>(event.GetEventObject());
    if (clickedButton)
    {
        wxString buttonText = clickedButton->GetLabel();
        std::string buttonName = buttonText.ToStdString();
        std::cout << "[INFO] Button clicked with text: " << buttonName << std::endl;

        if (buttonName == "Config")
        {
           
        }
    }
}

void MainFrame::OnLaunchButtonClick(wxCommandEvent& event)
{
    std::cout << "[INFO] Launching..." << std::endl;
}
