//
//  AhAhAhPrefs.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"

#import <LocalAuthentication/LAContext.h>
#import <Social/Social.h>


/* Checks if Touch ID is available. */
static BOOL hasTouchID() {
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    } else {
    	return NO;
    }
}


/* Root Settings Controller */

@interface AhAhAhPrefsController : PSListController
@end


@implementation AhAhAhPrefsController

- (id)specifiers {	
	if (_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"AhAhAhPrefs" target:self];
		
		// Alter the specefier list, removing some settings if we aren't
		// running on a device with TouchID.
		if (hasTouchID() == NO) {
			DebugLog(@"No TouchID on this device, disabling some settings...");
			
			PSSpecifier *specifier = [self specifierForID:@"IgnoreBioFailure"];
			[specifier setProperty:@NO forKey:@"enabled"];
			[specifier setProperty:@NO forKey:@"default"];
			
			specifier = [self specifierForID:@"AllowBioRemoval"];
			[specifier setProperty:@NO forKey:@"enabled"];
			[specifier setProperty:@NO forKey:@"default"];
		}
	}
	
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// add a heart button to the navbar
	NSString *path = [BUNDLE_PATH stringByAppendingPathComponent:@"Heart.png"];
	UIImage *heartImage = [[UIImage alloc] initWithContentsOfFile:path];	
	UIBarButtonItem *heartButton = [[UIBarButtonItem alloc] initWithImage:heartImage
																	style:UIBarButtonItemStylePlain
																   target:self
																   action:@selector(showLove)];
	heartButton.imageInsets = (UIEdgeInsets){2, 0, -2, 0};
	heartButton.tintColor = TINT_COLOR;	
	[self.navigationItem setRightBarButtonItem:heartButton];
}

- (void)setTitle:(id)title {
	// no thanks
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	
	if (!settings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return settings[specifier.properties[@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:PREFS_PLIST_PATH atomically:YES];
	
	CFStringRef notificationValue = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationValue) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationValue, NULL, NULL, YES);
	}
}

//

- (void)respring {
	NSLog(@"Ah!Ah!Ah! called for respring");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
										 CFSTR("com.sticktron.ahahah.respring"),
										 NULL,
										 NULL,
										 true);
}

- (void)showLove {
	// send a nice tweet ;)
	SLComposeViewController *composeController = [SLComposeViewController
												  composeViewControllerForServiceType:SLServiceTypeTwitter];
	
	[composeController setInitialText:@"I'm using Ah! Ah! Ah! by @Sticktron to scare away nosey people!"];
	
	[self presentViewController:composeController
					   animated:YES
					 completion:nil];
}

- (void)openEmail {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:sticktron@hotmail.com"]];
}

- (void)openTwitter {
	NSURL *url;
	
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		url = [NSURL URLWithString:@"tweetbot:///user_profile/sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		url = [NSURL URLWithString:@"twitterrific:///profile?screen_name=sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		url = [NSURL URLWithString:@"tweetings:///user?screen_name=sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		url = [NSURL URLWithString:@"twitter://user?screen_name=sticktron"];
		
	} else {
		url = [NSURL URLWithString:@"http://twitter.com/sticktron"];
	}
	
	[[UIApplication sharedApplication] openURL:url];
}

- (void)openGitHub {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/Sticktron/AhAhAh"]];
}

- (void)openReddit {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://reddit.com/u/Sticktron"]];
}

- (void)openPayPal {
	NSString *url = @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=AhAhAh&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted";
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

@end

