#import "AppDelegate.h"
#import <Foundation/Foundation.h>

int main(int argc, char* argv[]) {
    //discord::Core* core = nullptr;
    //DiscordState state;
    @autoreleasepool {
        NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argc];
        for (int i = 0; i < argc; ++i) {
            [arguments addObject:[NSString stringWithUTF8String:argv[i]]];
        }
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] initWithArguments:arguments];
        NSLog(@"[INFO] Creating status bar icon!");
        createStatusBarIcon(GetResourcesFolderPath() + "/display.png");
        NSLog(@"[INFO] Status bar icon created!");
        [app setDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}