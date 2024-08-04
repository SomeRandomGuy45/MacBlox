#ifndef HELPER_H
#define HELPER_H

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>

bool isAppRunning(const std::string &appName);
std::string getLogFile(const std::string& logDir);
std::string ShowOpenFileDialog(const std::string& defaultDirectory);

#endif // HELPER_H
