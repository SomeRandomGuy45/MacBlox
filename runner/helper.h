#ifndef HELPER_H
#define HELPER_H

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>
#include <libproc.h>
#include <fstream>

std::string GetResourcesFolderPath();
std::string ShowOpenFileDialog_WithCustomText(const std::string& defaultDirectory, const std::string& customText);
std::string getTemp();
std::string getLogFile(const std::string& logDir);
std::string ShowOpenFileDialog(const std::string& defaultDirectory);
std::string runAppleScriptAndGetOutput(const std::string &script);
std::string FileChecker(std::string path);
bool canAccessFile(const std::string& path);
bool doesAppExist(const std::string& path);
bool isAppRunning(const std::string &appName);
bool CanAccessFolder(const std::string& path);
void runApp(const std::string &launchPath, bool Check);
void terminateApplicationByName(const std::string& appName);
void createStatusBarIcon(const std::string &imagePath);

#endif // HELPER_H
