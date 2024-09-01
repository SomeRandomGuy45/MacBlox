#import "multi.h"
#import <Foundation/Foundation.h>

void ChangeMultiInstance(std::string path, bool allow)
{
    NSString* nsPlistPath = [NSString stringWithUTF8String:path.c_str()];
    NSString* nsKey = @"LSMultipleInstancesProhibited";

    // Load the plist file
    NSMutableDictionary* plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:nsPlistPath];
    if (!plistDict) {
        return; // Failed to load plist file
    }

    // Update the value for the specified key
    [plistDict setObject:@(allow) forKey:nsKey];

    // Write the updated dictionary back to the plist file
    BOOL success = [plistDict writeToFile:nsPlistPath atomically:YES];
    if (success == YES)
    {
        NSLog(@"[INFO] Changed LSMultipleInstancesProhibited value to: %s", allow == true ? "true" : "false");
    }
    else
    {
        NSLog(@"[ERROR] Failed to write LSMultipleInstancesProhibited value to plist file");
    }
}