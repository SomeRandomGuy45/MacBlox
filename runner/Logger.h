#include <string>
#include <filesystem>
#import <Foundation/Foundation.h>

// Mark the function as inline to avoid duplicate symbol errors
inline std::string currentDateTime() {
    time_t now = time(0);
    struct tm tstruct;
    char buf[80];
    if (localtime_r(&now, &tstruct) == nullptr) {
        return "[ERROR] Failed to get local time";
    }
    if (strftime(buf, sizeof(buf), "%Y-%m-%d-%H-%M-%S", &tstruct) == 0) {
        return "[ERROR] Failed to format time";
    }
    return buf;
}

// Mark the function as inline to avoid duplicate symbol errors
inline std::string getLogPath() {
    std::string currentDate = currentDateTime();
    std::string path = "/Users/" + std::string(getenv("USER")) + "/Library/Logs/Macblox";
    if (std::filesystem::exists(path)) {
        NSLog(@"[INFO] Folder already exists.");
    } else {
        if (std::filesystem::create_directory(path)) {
            NSLog(@"[INFO] Folder created successfully.");
        } else {
            NSLog(@"[ERROR] Failed to create folder.");
            return "";
        }
    }
    return path + "/" + currentDate + "_runner_log.log";
}

// Mark the global variable as inline or static to avoid duplicate symbol errors
inline std::string filePath = getLogPath();

inline void CustomNSLog(NSString *format, ...) {
    FILE *logFile = fopen(filePath.c_str(), "a");

    if (logFile != nullptr) {
        va_list args;
        va_start(args, format);

        NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];

        struct timeval tv;
        gettimeofday(&tv, NULL);

        struct tm *timeinfo;
        char timeBuffer[80];
        timeinfo = localtime(&tv.tv_sec);
        strftime(timeBuffer, sizeof(timeBuffer), "%Y-%m-%d %H:%M:%S", timeinfo);

        int milliseconds = tv.tv_usec / 1000;

        pid_t pid = [[NSProcessInfo processInfo] processIdentifier];
        NSString *processName = [[NSProcessInfo processInfo] processName];

        NSString *logEntry = [NSString stringWithFormat:@"%s.%03d %s[%d:%x] %s\n",
                              timeBuffer,
                              milliseconds,
                              [processName UTF8String],
                              pid,
                              (unsigned int)pthread_mach_thread_np(pthread_self()),
                              [formattedMessage UTF8String]];

        fprintf(stdout, "%s", [logEntry UTF8String]);
        fprintf(logFile, "%s", [logEntry UTF8String]);

        va_end(args);

        fclose(logFile);
    } else {
        NSLog(@"[ERROR] Failed to open file for logging: %s", filePath.c_str());
    }
}

#define NSLog(format, ...) CustomNSLog(format, ##__VA_ARGS__)