//Some of this c++ code is from https://github.com/pizzaboxer/bloxstrap/blob/main/Bloxstrap/Integrations/ActivityWatcher.cs
//it is in c# but i was able to translate it to c++

/*

    TODO:
        Refactor and optimize the code into header files and other stuff could be like a v2

*/

#import "AppDelegate.h"
#import <Foundation/Foundation.h>

/*
struct DiscordState {
	std::unique_ptr<discord::Core> core;
};

namespace {
	volatile bool interrupted{ false };
}
*/

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
        createStatusBarIcon(GetResourcesFolderPath() + "/test_icon.png");
        [app setDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}