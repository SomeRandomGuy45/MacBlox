#ifndef HELPER_H
#define HELPER_H

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>
#include <libproc.h>

bool isAppRunning(const std::string &appName);
std::string getLogFile(const std::string& logDir);
std::string ShowOpenFileDialog(const std::string& defaultDirectory);
void runApp(const std::string &launchPath, bool Check);

std::string runAppleScriptAndGetOutput(const std::string &script);

void terminateApplicationByName(const std::string& appName);

#endif // HELPER_H
