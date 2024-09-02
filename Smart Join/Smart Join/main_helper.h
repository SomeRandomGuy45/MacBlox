//
//  main_helper.h
//  Smart Join
//

#ifndef main_helper_h
#define main_helper_h

@interface Main_Helper : NSObject
-(void) RunScript:(NSString * ) commandString;
-(BOOL) CheckIfRobloxIsRunning;
-(BOOL) canConvertToLong:(NSString * ) stringValue;
-(BOOL) doesFileExistAtPath:(NSString * ) path;
-(NSString*)runAppleScript:(NSString *) scriptString;
-(NSString*)extractGameIDFromURL:(NSString * )urlString;
-(NSString*)downloadFileWithoutDestination:(NSString * )urlString;
-(NSDictionary*)decodeJSONString:(NSString * ) jsonString;
@end

#endif /* main_helper_h */
