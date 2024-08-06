// Downloader.h

#ifndef DOWNLOADER_H
#define DOWNLOADER_H

#include <string>
#include <iostream>

extern "C" void downloadFile(const char* urlString, const char* destinationPath);
std::string downloadFile_WITHOUT_DESTINATION(const char* urlString);
bool unzipFile(const char* zipFilePath, const char* destinationPath);

void runApp(const std::string &launchPath, bool Check);

bool isAppRunning(const std::string &appName);

#endif // DOWNLOADER_H