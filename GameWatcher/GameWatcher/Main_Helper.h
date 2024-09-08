//
//  Main_Helper.h
//  GameWatcher
//
//

#ifndef Main_Helper_h
#define Main_Helper_h

#import <Cocoa/Cocoa.h>

@interface Main_Helper : NSObject

@property (nonatomic, strong) NSNumber *numberOfItems;

- (void)addCustomFramesToContentView:(NSView *)contentView name:(NSString *) NameOfGame imgUrl:(NSString *) URLOfGame deepLink:(NSString *) DeeplinkOfGame startTime:(NSString *) startTime endTime:(NSString *) endTime shouldTimes2:(BOOL) shouldTimes2;
- (void)openApplicationWithDeeplink:(NSString *) deeplink;
- (void)buttonClicked:(id)sender;
- (void)ensureFileExists:(NSString *)filePath;
- (void)addToJson:(NSString *)addedData;
- (void)resetJson;

- (NSString *)getApplicationSupportPath;

- (NSDictionary *)decodeJSONFromFilePath:(NSString *)jsonString;

@end


#endif /* Main_Helper_h */
