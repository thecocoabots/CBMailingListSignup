/*
 *  CBMailingListSignupAppDelegate.m CBMailingListSignup
 *
 *  Created by Tony Arnold on 12/01/10. Copyright 2010 The CocoaBots. All rights reserved.
 *
 */

#import "CBMailingListSignupAppDelegate.h"
#import "CBMailingListSignupWindowController.h"

@implementation CBMailingListSignupAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Insert code here to initialize your application */
}

#pragma mark Interface Builder Actions

- (IBAction)signMeUp:(id)sender {
	[CBMailingListSignupWindowController showSignupWindow];
}

@end
