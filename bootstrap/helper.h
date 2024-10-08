#ifndef HELPER_H
#define HELPER_H

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>
#include <libproc.h>
#include <fstream>

bool isAppRunning(const std::string &appName);
bool deleteFolder(const std::string& folderPath);
std::string getLogFile(const std::string& logDir);
std::string ShowOpenFileDialog(const std::string& defaultDirectory);
std::string ShowOpenFileDialog_WithCustomText(const std::string& defaultDirectory, const std::string& customText);
std::string GetMacOSAppearance();
void runApp(const std::string &launchPath, bool Check);

std::string runAppleScriptAndGetOutput(const std::string &script);

void terminateApplicationByName(const std::string& appName);

void CreateFolder(std::string path);

bool FolderExists(const std::string& path);

bool CanAccessFolder(const std::string& path);

bool doesAppExist(const std::string& path);

void copyFile(const std::string& oldPath, const std::string& newPath);

extern "C" void downloadFile(const char* urlString, const char* destinationPath);

std::string FileChecker(std::string path);

bool unzipFile(const char* zipFilePath, const char* destinationPath);

void RenameFile(const char* oldPath, const char* newPath);

void TestCommand();

void fixInstall(std::string path);

std::string GetResourcesFolderPath();

std::string GetDownloadsFolderPath();

#endif // HELPER_H
