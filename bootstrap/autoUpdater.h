#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface autoUpdater : NSObject

@property (strong) NSWindow *popUpWindow;
@property (strong) NSProgressIndicator * progressIndicator;
@property (strong, nonatomic) NSTextView *textView;

- (BOOL)updateToData;
- (void)fetchLatestTagWithCompletion:(void (^)(NSString *downloadLatestVersion, NSError *error))completion;
- (void)fetchLatestVersionWithCompletion:(void (^)(NSString *downloadLatestVersion, NSError *error))completion;
- (void)doUpdate;
- (void)forceQuit;

@end