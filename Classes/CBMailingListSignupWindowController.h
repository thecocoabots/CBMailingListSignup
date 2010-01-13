/*
 *  CBMailingListSignupWindowController.h CBMailingListSignup
 *
 *  Created by Tony Arnold on 12/01/10. Copyright 2010 The CocoaBots. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>


@interface CBMailingListSignupWindowController : NSWindowController {
	IBOutlet NSButton            *joinButton;
	IBOutlet NSButton            *cancelButton;
	IBOutlet NSTextField         *contactNameField;
	IBOutlet NSComboBox          *contactEmailBox;
	IBOutlet NSProgressIndicator *progressIndicator;

	NSMutableData *loadedData;
	BOOL           isSnowLeopard;
}

+ (void)showSignupWindow;
- (IBAction)submitAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (void)postSignup;
- (void)closeSignup;
- (void)displayAlertMessage:(NSString *)message withInformativeText:(NSString *)text andAlertStyle:(NSAlertStyle)alertStyle;
- (void)showWindow:(id)sender;

@end
