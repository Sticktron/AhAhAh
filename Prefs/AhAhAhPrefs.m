//
//  AhAhAhPrefs.m
//  Preferences for Ah! Ah! Ah!
//
//  Created by Sticktron in 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Headers/Preferences/PSListController.h"
#import "Headers/Preferences/PSSpecifier.h"

#define DEBUG_MODE_ON
#define DEBUG_PREFIX @"💾 [Newman Prefs]"
#import "../DebugLog.h"


#define kURL_Email			@"mailto:sticktron@hotmail.com"
#define kURL_GitHub			@"http://github.com/Sticktron/AhAhAh"
#define kURL_PayPal			@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=AhAhAh&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted"
#define kURL_Twitter_Web	@"http://twitter.com/Sticktron"
#define kURL_Twitter_App	@"twitter://user?screen_name=Sticktron"



@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
@end



@interface AhAhAhPrefsController : PSListController
- (void)respring;
- (void)openPayPal;
- (void)openEmail;
- (void)openTwitter;
- (void)openGitHub;
@end



@implementation AhAhAhPrefsController

- (id)specifiers {
	
	if (_specifiers == nil) {
		
		NSMutableArray *specs = [self loadSpecifiersFromPlistName:@"AhAhAhPrefs" target:self];
		
		
		// remove TouchID-related specifiers if not iPhone 5S ...
		
		NSString *deviceId = [[UIDevice currentDevice] _deviceInfoForKey:@"ProductType"];
		
		if ([deviceId isEqualToString:@"iPhone6,1"]) { // iPhone 5S
			DebugLog(@"Found an iPhone 5S");
		} else {
			DebugLog(@"Not an iPhone 5S, removing some preferences...");
			
			NSMutableArray *specsToRemove = [NSMutableArray array];
			
			for (PSSpecifier *spec in specs) {
				if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"IgnoreBioFailure"]) {
					[specsToRemove addObject:spec];
				} else if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"AllowBioRemoval"]) {
					[specsToRemove addObject:spec];
				}
			}
			
			for (PSSpecifier *spec in specsToRemove) {
				[specs removeObject:spec];
			}
		}
		
		
		_specifiers = [specs copy];
	}
	
	return _specifiers;
}

- (void)respring {
	DebugLog(@"Respringing");
	system("killall -HUP SpringBoard");
}


- (void)openPayPal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kURL_PayPal]];
}

- (void)openEmail {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kURL_Email]];
}

- (void)openTwitter {
	// try the app first
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kURL_Twitter_App]];
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kURL_Twitter_Web]];
	}
}

- (void)openGitHub {
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:kURL_GitHub]];
}

@end

