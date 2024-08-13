#ifndef HELPER_H
#define HELPER_H

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>
#include <libproc.h>

bool isAppRunning(const std::string &appName);
std::string GetResourcesFolderPath();
std::string ShowOpenFileDialog_WithCustomText(const std::string& defaultDirectory, const std::string& customText);
std::string getTemp();
std::string getLogFile(const std::string& logDir);
std::string ShowOpenFileDialog(const std::string& defaultDirectory);
void runApp(const std::string &launchPath, bool Check);
bool canAccessFile(const std::string& path);
bool doesAppExist(const std::string& path);

std::string runAppleScriptAndGetOutput(const std::string &script);

void terminateApplicationByName(const std::string& appName);

bool CanAccessFolder(const std::string& path);

#endif // HELPER_H
