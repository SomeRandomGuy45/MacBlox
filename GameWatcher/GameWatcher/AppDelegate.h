//
//  AppDelegate.h
//  GameWatcher
//
//

#import <Cocoa/Cocoa.h>
#import "Main_Helper.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
    @property (strong, nonatomic) NSWindow *window;
    @property (strong, nonatomic) NSScrollView *scrollView;
    @property (strong, nonatomic) NSView *contentView;
    @property (strong, nonatomic) NSProcessInfo *processInfo;
    @property (strong, nonatomic) Main_Helper *mainHelper;
    @property (strong, nonatomic) NSString * pid;

    - (NSString *)correctJsonFormatting:(NSString *)jsonString;
@end

