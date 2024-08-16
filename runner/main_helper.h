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
//#include "discord-game-sdk/discord.h"
#include <curl/curl.h> //for downloading files
#include "curlpp/cURLpp.hpp" //requests with out creating files
#include "curlpp/Options.hpp"
#include <libgen.h>
#include <signal.h>  // For kill function
#include <errno.h>   // For errno
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

int main_loop();