#import <Cocoa/Cocoa.h>
#import "main_helper.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSArray *arguments;

- (instancetype)initWithArguments:(NSArray *)arguments;

@end