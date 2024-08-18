#include "app.h"
#include "frame.h"

wxIMPLEMENT_APP(App);

void App::LoadConfig(std::string configPath)
{
    std::cout << "[INFO] Loading Config" << std::endl;
    std::string configContents = FileChecker(configPath);
    if (configContents.empty())
    {
        std::cout << "[WARN] Config file not found will use default settings" << std::endl;
        return;
    }
    ConfigData = json::parse(configContents);
    BootstrapJsonVersion = std::stoi(ConfigData["BootstrapVersion"].get<std::string>());
    std::cout << "[INFO] Bootstrap Version: " << BootstrapJsonVersion << std::endl;
    WinSize_X = std::stoi(ConfigData["win_size"]["x"].get<std::string>());
    WinSize_Y = std::stoi(ConfigData["win_size"]["y"].get<std::string>());
    std::cout << "[INFO] Window Size: " << WinSize_X << "x" << WinSize_Y << std::endl;
    WinName = ConfigData["WinName"].get<std::string>();
    std::cout << "[INFO] Window Name: " << WinName << std::endl;
}

bool App::OnInit() {
    std::string path = GetResourcesFolderPath() + "/bootstrap_data.json";
    LoadConfig(path);
    if (BootstrapJsonVersion != 1)
    {
        CreateNotification("Error", "Unsupported Bootstrap version", -1);
        return -1;
    }
    long frameStyle = wxFRAME_SHAPED | wxBORDER_NONE;
    BootstrapperFrame* frame = new BootstrapperFrame(WinName, frameStyle, wxSize(WinSize_X, WinSize_Y));
    frame->LoadBootstrapData(ConfigData);
    frame->Center();
    if (!frame->Show())
    {
        CreateNotification("Error", "Unable to start up app", -1);
        return -1;
    }
    frame->DoLogic();
    return true;
}