#import <Cocoa/Cocoa.h>
#import "main_helper.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSArray *arguments;
@property (strong, nonatomic) NSString * pid;

- (instancetype)initWithArguments:(NSArray *)arguments;

@end