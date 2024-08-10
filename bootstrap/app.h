#pragma once
#include <iostream>
#include <wx/wx.h>
#include "json.hpp"

using json = nlohmann::json;

class App : public wxApp
{
public:
    void LoadConfig(std::string configPath);
    bool OnInit();
private:
    json ConfigData;
    int BootstrapJsonVersion = 1;
    int WinSize_X = 600;
    int WinSize_Y = 400;
    std::string WinName = "MacBlox";
};