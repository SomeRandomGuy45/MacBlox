#import <Cocoa/Cocoa.h>

BOOL showTimedAlert() {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Caution";
    alert.informativeText = @"Using FFlags could lead to unexpected results and please do NOT pay for them.";
    [alert addButtonWithTitle:@"Confirm"];
    [alert addButtonWithTitle:@"Cancel"];

    alert.icon = [NSImage imageNamed:NSImageNameCaution]; // Use the warning icon

    NSButton *confirmButton = alert.buttons[0];
    confirmButton.enabled = NO;

    // Use dispatch_after to enable the Confirm button after 10 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        confirmButton.enabled = YES;
    });

    // Run the modal and get the user's response
    NSModalResponse response = [alert runModal];

    // Return YES if the user clicked Confirm and the button was enabled
    return response == NSAlertFirstButtonReturn && confirmButton.enabled;
}