// Downloader.h

#ifndef DOWNLOADER_H
#define DOWNLOADER_H

#include <string>
#include <iostream>

extern "C" void downloadFile(const char* urlString, const char* destinationPath);

void copyFile(const std::string& oldPath, const std::string& newPath);
void runApp(const std::string &launchPath, bool Check);

bool unzipFile(const char* zipFilePath, const char* destinationPath);
bool isAppRunning(const std::string &appName);
std::string downloadFile_WITHOUT_DESTINATION(const char* urlString);
std::string PromptUserForRobloxID();
std::string GetMacOSAppearance();
std::string FileChecker(std::string path);
std::string GetResourcesFolderPath();
#endif // DOWNLOADER_H