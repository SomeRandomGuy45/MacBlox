//
//  AppDelegate.h
//  Smart Join
//
//

#import <Cocoa/Cocoa.h>
#import "main_helper.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
    @property (nonatomic, strong) NSMutableArray *serverArrayFPS;
    @property (nonatomic, strong) NSMutableArray *serverArrayPING;
    @property (nonatomic, strong) NSString* gameId;
    @property (nonatomic, strong) NSString* customInstallPath;
    @property (nonatomic) BOOL useLowPing;
    @property (nonatomic, strong) Main_Helper *main_helper;
    @property (weak) IBOutlet NSTextField* gameIdText;
    - (IBAction)gameId:(id)sender;
    @property (weak) IBOutlet NSButton *closeButton;
    - (IBAction)Close:(id)sender;
    @property (weak) IBOutlet NSTextField* installPathText;
    - (IBAction)installPath:(id)sender;
    - (IBAction)highfps:(id)sender;
    - (IBAction)lowping:(id)sender;
@end

