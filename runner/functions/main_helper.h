/*
* Very funny .h file lol
*/

#include <iostream>
#include <vector>
#include <libproc.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <cstring>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string>
#include <fstream>
#include <filesystem>
#include <regex>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <map>
#include <cstdlib>
#include <functional>
#include <sys/stat.h>
#include <curl/curl.h>
#include <libgen.h>
#include <signal.h>
#include <errno.h>
#include <thread>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <chrono>
#include <algorithm>
#include <CoreFoundation/CoreFoundation.h>
#include <DiskArbitration/DiskArbitration.h>
#include <sstream>
#include <condition_variable>
#include <mutex>
#include <stdexcept>
#include <future>
#include <ctime>
#include <spawn.h>
#include <sys/wait.h>
#include <wx/notifmsg.h>
#include <wx/msgdlg.h>
#include <unordered_set>
#include <utility>
#include <iomanip>
#include <cstdio>
#include "json.hpp"
#include "helper.h"
#include <Foundation/Foundation.h>

int main_loop(NSArray *arguments, std::string supercoolvar, bool dis);

static void UpdDiscordActivity(
    const std::string& details, 
    const std::string& state, 
    int64_t startTimestamp, 
    std::string AssetIDLarge, 
    std::string AssetIDSmall, 
    const std::string& largeImgText, 
    const std::string& smallImageText, 
    const std::string& button1Text, 
    const std::string& button2Text, 
    const std::string& button1url, 
    const std::string& button2url,
    int64_t endTimestamp
    );
