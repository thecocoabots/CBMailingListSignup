/*
 *  CBMailingListSignupWindowController.m CBMailingListSignup
 *
 *  Created by Tony Arnold on 12/01/10. Copyright 2010 The CocoaBots. All rights reserved.
 *
 */

#import "CBMailingListSignupWindowController.h"
#import <AddressBook/AddressBook.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCNetwork.h>


/* The following strings MUST be set, otherwise this will not work. Login to your Campaign Monitor account to get the values for these keys. */
static NSString *sCMListID = @"";
static NSString *sCMAPIKey = @"";


CBMailingListSignupWindowController *gSignupController = nil;


@interface CBMailingListSignupWindowController (Private)

+ (NSURL *)postURL;

@end

#pragma mark -
@implementation CBMailingListSignupWindowController

+ (void)showSignupWindow {
	SInt32 systemVersionMajor = 0;
	SInt32 systemVersionMinor = 0;

	Gestalt(gestaltSystemVersionMajor, &systemVersionMajor);
	Gestalt(gestaltSystemVersionMinor, &systemVersionMinor);

	BOOL local_isSnowLeopard = systemVersionMajor >= 10 && systemVersionMinor >= 6;

	SCNetworkConnectionFlags reachabilityFlags;
	const char              *hostname = [[[[self class] postURL] host] UTF8String];
	Boolean                  reachabilityResult;

	if (local_isSnowLeopard) {
		SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, hostname);
		reachabilityResult = SCNetworkReachabilityGetFlags(reachability, &reachabilityFlags);
		CFRelease(reachability);
	} else {
		reachabilityResult = SCNetworkCheckReachabilityByName(hostname, &reachabilityFlags);
	}

	/*    NSLog(@"reachabilityFlags: %lx", reachabilityFlags); */
	BOOL showSignupWindow = reachabilityResult
													&& (reachabilityFlags & kSCNetworkFlagsReachable)
													&& !(reachabilityFlags & kSCNetworkFlagsConnectionRequired)
													&& !(reachabilityFlags & kSCNetworkFlagsConnectionAutomatic)
													&& !(reachabilityFlags & kSCNetworkFlagsInterventionRequired);

	if (!showSignupWindow) {
		int alertResult = [[NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"Signup Host Not Reachable", @"CBMailingListSignup", nil)
																			 defaultButton:NSLocalizedStringFromTable(@"Proceed Anyway", @"CBMailingListSignup", nil)
																		 alternateButton:NSLocalizedStringFromTable(@"Cancel", @"CBMailingListSignup", nil)
																				 otherButton:nil
													 informativeTextWithFormat:NSLocalizedStringFromTable(@"Unreachable Explanation", @"CBMailingListSignup", nil), [[CBMailingListSignupWindowController postURL] host]
											 ] runModal];

		if (NSAlertDefaultReturn == alertResult) {
			showSignupWindow = YES;
		}
	}

	if (showSignupWindow) {
		if (!gSignupController) {
			gSignupController = [[CBMailingListSignupWindowController alloc] init];
		}

		[gSignupController showWindow:self];
	}
}

- (id)init {
	if (self = [super initWithWindowNibName:@"CBMailingListSignup"]) {}

	return self;
}

- (void)dealloc {
	[gSignupController release];
	[super dealloc];
}

- (void)windowDidLoad {
	SInt32 systemVersionMajor = 0;
	SInt32 systemVersionMinor = 0;

	Gestalt(gestaltSystemVersionMajor, &systemVersionMajor);
	Gestalt(gestaltSystemVersionMinor, &systemVersionMinor);

	isSnowLeopard = systemVersionMajor >= 10 && systemVersionMinor >= 6;


	NSString *titleLabelFormatString = [NSString stringWithFormat:@"%@ Window Title", nil];
	NSString *fmtTitle               = NSLocalizedStringFromTable(titleLabelFormatString, @"CBMailingListSignup", nil);

	NSString *title = [NSString stringWithFormat:fmtTitle, [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey]];
	[[self window] setTitle:title];

	ABPerson *me = [[ABAddressBook sharedAddressBook] me];

	if (me) {
		[contactNameField setStringValue:[NSString stringWithFormat:@"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty]]];
		ABMutableMultiValue *emailAddresses = [me valueForProperty:kABEmailProperty];
		unsigned             addyIndex      = 0, addyCount = [emailAddresses count];

		if (addyCount) {
			for (; addyIndex < addyCount; addyIndex++) {
				[contactEmailBox addItemWithObjectValue:[emailAddresses valueAtIndex:addyIndex]];
			}

			[contactEmailBox selectItemAtIndex:0];
		}
	}
}

- (IBAction)submitAction:(id)sender {
	[joinButton setEnabled:NO];
	[cancelButton setEnabled:NO];

	[progressIndicator startAnimation:self];

	[self postSignup];
}

- (void)postSignup {
	/* Construct a valid SOAP response */
	NSString *soapURIString             = [NSString stringWithString:@"http://schemas.xmlsoap.org/soap/envelope/"];
	NSString *defaultNameSpaceURIString = [NSString stringWithString:@"http://api.createsend.com/api/"];

	NSXMLNode *rootNamespace = [NSXMLNode namespaceWithName:@"" stringValue:defaultNameSpaceURIString];
	NSXMLNode *xsiNamespace  = [NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"];
	NSXMLNode *xsdNamespace  = [NSXMLNode namespaceWithName:@"xsd" stringValue:@"http://www.w3.org/2001/XMLSchema"];
	NSXMLNode *soapNamespace = [NSXMLNode namespaceWithName:@"soap" stringValue:soapURIString];

	NSXMLElement *EnvelopeElement = [NSXMLNode elementWithName:@"soap:Envelope"];
	NSXMLElement *BodyElement     = [NSXMLNode elementWithName:@"soap:Body"];
	NSXMLElement *MethodElement   = [NSXMLNode elementWithName:@"Subscriber.AddAndResubscribeWithCustomFields" URI:defaultNameSpaceURIString];

	NSMutableDictionary *requiredFields = [NSMutableDictionary dictionary];

	if ([[contactEmailBox stringValue] length]) {
		[requiredFields setObject:[contactEmailBox stringValue] forKey:@"Email"];
	}

	if ([[contactNameField stringValue] length]) {
		[requiredFields setObject:[contactNameField stringValue] forKey:@"Name"];
	}

	if ([sCMAPIKey length]) {
		[requiredFields setObject:sCMAPIKey forKey:@"ApiKey"];
	}

	if ([sCMListID length]) {
		[requiredFields setObject:sCMListID forKey:@"ListID"];
	}

	/* Setup our custom fields */
	NSDictionary *customFieldsDict = [NSDictionary dictionaryWithObjectsAndKeys:
																		[[[NSBundle                bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleName"], @"Application",
																		[[[NSBundle                bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"], @"Build",
																		[[[NSBundle                bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"Version",
																		nil];

	/* Append the custom field elements to a transient XML element */
	NSXMLElement *customFieldElement = [NSXMLNode elementWithName:@"CustomFields"];

	for (NSString *key in customFieldsDict) {
		id value = [customFieldsDict objectForKey:key];

		if ((value != nil) && ([value isKindOfClass:[NSNull class]] == NO)) {
			NSXMLElement *newCustomFieldElement = [NSXMLNode elementWithName:@"SubscriberCustomField"];
			[newCustomFieldElement addChild:[NSXMLNode elementWithName:@"Key" stringValue:key]];
			[newCustomFieldElement addChild:[NSXMLNode elementWithName:@"Value" stringValue:value]];

			[customFieldElement addChild:newCustomFieldElement];
		}
	}

	/* Now add the required fields to the Method Element */
	for (NSString *key in requiredFields) {
		id value = [requiredFields objectForKey:key];

		if ((value != nil) && ([value isKindOfClass:[NSNull class]] == NO)) {
			[MethodElement addChild:[NSXMLNode elementWithName:key stringValue:value]];
		}
	}

	/* Finally append our custom field elements */
	[MethodElement addChild:customFieldElement];
	[MethodElement addNamespace:rootNamespace];

	/* Setup the element's namespaces */
	[EnvelopeElement addNamespace:xsiNamespace];
	[EnvelopeElement addNamespace:xsdNamespace];
	[EnvelopeElement addNamespace:soapNamespace];

	[BodyElement addChild:MethodElement];
	[EnvelopeElement addChild:BodyElement];

	NSXMLDocument *newSOAPPost = [NSXMLDocument documentWithRootElement:EnvelopeElement];

	/* Get a reference to the post URL */
	NSURL *postURL = [[self class] postURL];

	/* Send the request, using this class as the delegate for handling the response⁄ */
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"http://api.createsend.com/api/Subscriber.AddAndResubscribeWithCustomFields" forHTTPHeaderField:@"SOAPAction"];
	[request setHTTPBody:[newSOAPPost XMLData]];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)closeSignup {
	[[self window] orderOut:self];
}

- (IBAction)cancelAction:(id)sender {
	[self closeSignup];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSError       *xmlDocumentError = nil;
	NSXMLDocument *response         = [[NSXMLDocument alloc] initWithData:loadedData options:NSXMLNodePreserveAll error:&xmlDocumentError];

	if ([xmlDocumentError code]) {
		/* If the previous attempt failed, try tidying the document */
		response = [[NSXMLDocument alloc] initWithData:loadedData options:NSXMLDocumentTidyXML error:&xmlDocumentError];
	}

	if ([xmlDocumentError code]) {
		NSLog(@"xmlDocumentError (%i): %@", [xmlDocumentError code], [xmlDocumentError localizedDescription]);
	}

	NSString *responseCodeXPath = [NSString stringWithString:@".//node()[local-name() = 'Subscriber.AddAndResubscribeWithCustomFieldsResult']/node()[local-name() = 'Code']/text()"];
	NSArray  *responseCodeNodes = [[response rootElement] nodesForXPath:responseCodeXPath error:&xmlDocumentError];

	if ([xmlDocumentError code]) {
		NSLog(@"xmlDocumentError (%i): %@", [xmlDocumentError code], [xmlDocumentError localizedDescription]);
	}

	NSXMLNode *responseCodeNode = nil;

	if ([responseCodeNodes count] > 0) {
		responseCodeNode = [responseCodeNodes objectAtIndex:0];
	}

	[response release];
	[loadedData release];
	loadedData = nil;


	NSNumber    *responseCodeNumber = [[[NSNumberFormatter alloc] numberFromString:[responseCodeNode stringValue]] autorelease];
	NSString    *alertTitle         = nil;
	NSString    *alertMessage       = nil;
	NSAlertStyle alertStyle         = NSInformationalAlertStyle;

	if ([responseCodeNumber integerValue] == 0) { /* Success: The subscription was successful. */
		alertTitle   = [NSString stringWithString:@"SuccessTitle"];
		alertMessage = [NSString stringWithString:@"SuccessMessage"];
		alertStyle   = NSInformationalAlertStyle;
	} else if ([responseCodeNumber integerValue] == 1) { /* Invalid email address: The email value passed in was invalid. */
		alertTitle   = [NSString stringWithString:@"InvalidEmailAddressTitle"];
		alertMessage = [NSString stringWithString:@"InvalidEmailAddresMessage"];
		alertStyle   = NSWarningAlertStyle;
	} else if ([responseCodeNumber integerValue] == 100) { /* Invalid API key: The API key pass was not valid or has expired. */
		alertTitle   = [NSString stringWithString:@"InvalidAPIKeyTitle"];
		alertMessage = [NSString stringWithString:@"InvalidAPIKeyMessage"];
		alertStyle   = NSCriticalAlertStyle;
	} else if ([responseCodeNumber integerValue] == 101) { /* Invalid ListID: The ListID value passed in was not valid. */
		alertTitle   = [NSString stringWithString:@"InvalidListIDTitle"];
		alertMessage = [NSString stringWithString:@"InvalidListIDMessage"];
		alertStyle   = NSCriticalAlertStyle;
	}

#if USE_GROWL
		[GrowlApplicationBridge setGrowlDelegate:@""];
		[GrowlApplicationBridge notifyWithTitle:NSLocalizedStringFromTable(alertTitle, @"CBMailingListSignup", nil)
																description:NSLocalizedStringFromTable(alertMessage, @"CBMailingListSignup", nil)
													 notificationName:@"Signup Sent"
																	 iconData:nil
																	 priority:0
																	 isSticky:NO
															 clickContext:nil];
		[self closeSignup];
#else
		/*	drop thank you sheet */
		[self displayAlertMessage:NSLocalizedStringFromTable(alertTitle, @"CBMailingListSignup", nil)
					withInformativeText:NSLocalizedStringFromTable(alertMessage, @"CBMailingListSignup", nil)
								andAlertStyle:alertStyle];
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (loadedData == nil) {
		loadedData = [[NSMutableData alloc] init];
	}

	[loadedData appendData:data];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[alert window] orderOut:nil];
	[self closeSignup]; /* moved from connectionDidFinishLoading: */
	[joinButton setEnabled:YES];
	[cancelButton setEnabled:YES];
}

- (void)displayAlertMessage:(NSString *)message withInformativeText:(NSString *)text andAlertStyle:(NSAlertStyle)alertStyle {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];

	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"OKButtonLabel", @"CBMailingListSignup", nil)];
	[alert setMessageText:message];
	[alert setInformativeText:text];
	[alert setAlertStyle:alertStyle];

	[progressIndicator stopAnimation:self];

	/*	display thank you */
	[alert beginSheetModalForWindow:[gSignupController window]
										modalDelegate:self
									 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
											contextInfo:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"-[%@ connection:didFailWithError:%@]", [self className], error);

	/*	drop fail sheet */
	[self displayAlertMessage:@"An Error Occured"
				withInformativeText:@"There was a problem sending your request.  Please try again later."
							andAlertStyle:NSInformationalAlertStyle];
}

+ (NSURL *)postURL {
	NSString *postURLBundleKey = @"CBMailingListSignupURL";
	NSString *postURLString    = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:postURLBundleKey];

	if ([[NSUserDefaults standardUserDefaults] stringForKey:postURLBundleKey]) {
		postURLString = [[NSUserDefaults standardUserDefaults] stringForKey:postURLBundleKey];
	}

	return [NSURL URLWithString:postURLString];
}

- (void)windowWillClose:(NSNotification *)notification {
	[self closeSignup];
}

/* overloaded to center the window after display */
- (void)showWindow:(id)sender {
	[[self window] center];
	[super showWindow:sender];
}

@end
