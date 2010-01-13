CBMailingListSignup
===================
This is Cocoa code for signing users up to Campaign Monitor mailing lists from within your application. It automatically looks in the user's address book for their name and their possible email addresses and asks the user to confirm before using the Campaign Monitor web services API to register the user. It allows submitting custom information via the API - by default it will push through the App name, and the long and short version strings.

This code is heavily based upon [UKCrashReporter](http://zathras.de/angelweb/sourcecode.htm) and [JRFeedbackProvider](http://github.com/rentzsch/jrfeedbackprovider/).

_This code is currently a work in progress._

Usage
=====

1. Drag the following files to your own project:

    Classes/CBMailingListSignupWindowController.h
    Classes/CBMailingListSignupWindowController.m
    Resources/CBMailingListSignup.xib
    Resources/CBMailingListSignup.xib
	
2. Add a new key and value to your application's Info.plist:

    CBMailingListSignupURL = http://api.createsend.com/api/api.asmx
	
3. Modify both the `sCMListID` (ListID) and `sCMAPIKey` (API Key) to reflect your own List ID and API Key (you can find these in your Campaign Monitor account).
3. Import the "`CBMailingListSignupWindowController.h`" header into your application delegate.
4. Call the following code from somewhere within your code (I'd suggest an IBAction) to show the signup:

    [CBMailingListSignupWindowController showSignupWindow];
	

LICENSE
=======

This code is licensed under [Creative Commons Attribution 2.5](http://creativecommons.org/licenses/by/2.5/).