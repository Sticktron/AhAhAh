//
//  Tweak.xm
//  Ah! Ah! Ah! You didn't say the magic word!
//
//  Custom Unlock Error Alarm.
//  Inspired by Jurassic Park.
//
//  Created by Sticktron in 2014. All rights reserved.
//
//

#import <AhAhAhController.h>

#import "Headers/SpringBoard/SBLockScreenManager.h"
#import "Headers/SpringBoard/SBLockScreenViewController.h"
#import "Headers/SpringBoardUIServices/SBUIBiometricEventMonitor.h"

#define DEBUG_MODE_ON
#define DEBUG_PREFIX @"😈 [Newman!]"
#import "DebugLog.h"


#define PREFS_PLIST_PATH		@"/User/Library/Preferences/com.sticktron.ahahah.plist"


@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
@end


static AhAhAhController *newman = nil;


// handle notifications from settings
NS_INLINE void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
							const void *object, CFDictionaryRef userInfo) {
	
	DebugLog1(@"******** Preferences Changed Notification ********");
	
	if (newman) {
		[newman loadPrefs];
	}
}





//--------------------------------------------------------------------------------------------------
%group Main
//--------------------------------------------------------------------------------------------------

%hook SBLockScreenViewController

//
// Remove Newman when the screen turns off (Lock Button)
//
- (void)_handleDisplayTurnedOff {
	DebugLog0;
	
	if (newman.isShowing && newman.allowLockRemoval) {
		[newman remove];
		[newman reset];
	}
	
	%orig;
}


/* other hooks to try */
/*
- (void)prepareForMesaUnlockWithCompletion:(id)arg1 {
	DebugLog(@"arg=%@", arg1);
	%orig;
}
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1 {
	DebugLog(@"!!!!!!!!!!!!!!!!!!  arg=%@", arg1);
	%orig;
}
- (void)passcodeLockViewPasscodeEntered:(id)arg1 {
	DebugLog(@"arg=%@", arg1);
	%orig;
}
- (void)setInScreenOffMode:(_Bool)arg1 {
	DebugLog(@"arg=%@", arg1?@"YES":@"NO");
	%orig;
}
- (void)_passcodeStateChanged {
	DebugLog0;
	%orig;
}
- (void)_handlePasscodeLockStateChanged {
	DebugLog0;
	%orig;
}
*/


%end

//--------------------------------------------------------------------------------------------------

%hook SBLockScreenManager

//
//	Attempting Passcode Unlock.
//
//	Returns success = YES|NO.
//
- (BOOL)attemptUnlockWithPasscode:(id)passcode {
	DebugLog(@"attempting unlock via passcode");
	
	BOOL result = %orig;
	DebugLog(@"result=%@", result?@"YES":@"NO");
	
	if (result) {
		//
		// Passcode successful
		//
		[newman reset];
		
	} else {
		//
		// Passcode failed
		//
		newman.failedAttempts++;
		DebugLog(@"newman.failedAttempts=%d", newman.failedAttempts);
		
		if (newman.failedAttempts >= newman.maxFailures) {
			// show Newman
			[newman show];
		}
	}
	
	return result;
}


/* other methods to hook maybe ? */
/*
- (void)_deviceLockedChanged:(id)arg1 {
	DebugLog(@"notification=%@", arg1);
	
	// NSConcreteNotification {
	//	name = SBDevicePasscodeLockStateDidChangeNotification
	// }
	
	%orig;
}
- (void)_lockUI { %log; %orig }
- (void)_setUILocked:(_Bool)arg1 { %log; %orig; }
- (void)_postLockCompletedNotification:(_Bool)arg1 { %log; %orig; }
- (_Bool)handleMenuButtonTap; { return %orig; }
*/


%end

//--------------------------------------------------------------------------------------------------

%end //group





//--------------------------------------------------------------------------------------------------
%group BioSupport
//--------------------------------------------------------------------------------------------------

%hook SBUIBiometricEventMonitor

//
// Block TouchID matching.
//
- (void)_setMatchingEnabled:(BOOL)enable {
	if (enable && newman.isShowing && !newman.allowBioRemoval) {
		// don't allow it
		DebugLog(@"blocked");
		%orig(NO);
	} else {
		enable ? DebugLog(@"enabling") : DebugLog(@"disabling");
		%orig;
	}
}

%end

//--------------------------------------------------------------------------------------------------

%hook SBLockScreenManager

//
//	Handle TouchID Event. Event has already occured.
//
//	Event 4: was a successful match.
//	Event 9: was a failed match.
//
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	// arg1 is an SBUIBiometricEventMonitor
	
	if (event == 4) {
		//
		// TouchID match successful !!
		//
		DebugLog(@"TouchID: Event %llu (bio unlock successful)", event);
		
		if (newman.isShowing) {
			[newman remove];
		}
		
		[newman reset];
	}
	
	if (event == 9) {
		//
		// TouchID match failed !!
		//
		DebugLog(@"TouchID: Event %llu (bio unlock failed)", event);
		
		if (newman.ignoreBioFailure == NO) {
			newman.failedAttempts++;
			DebugLog(@"newman.failedAttempts=%d", newman.failedAttempts);
			
			if (newman.failedAttempts >= newman.maxFailures) {
				DebugLog(@"failed too many times!");
				[newman show];
			}
		}
	}
	
	%orig;
}

/*
//
// Handle TouchID Unlock Notification.
//		NSConcreteNotification {
//		  name = SBBiometricEventMonitorHasAuthenticated;
//		  object = <SBUIBiometricEventMonitor>
//		}
//
- (void)_bioAuthenticated:(id)notification {
	DebugLog(@"notification=%@", notification);
	
	[newman hideAndReset];
	%orig;
}
*/

%end

//--------------------------------------------------------------------------------------------------

%end //group





//--------------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------------
%ctor {
	@autoreleasepool {
		NSLog(@" [Ah! Ah! Ah!] loaded.");
		
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		
		if (prefs && prefs[@"Enabled"] && ([prefs[@"Enabled"] boolValue] == NO)) {
			NSLog(@" [Ah! Ah! Ah!] I'm DISABLED !!");
			
		} else {
			newman = [[AhAhAhController alloc] init];
			
			// check if the device has a TouchID sensor
			NSString *deviceId = [[UIDevice currentDevice] _deviceInfoForKey:@"ProductType"];
			DebugLog1(@"DeviceID=%@", deviceId);
			
			if ([deviceId isEqualToString:@"iPhone6,1"]) { // iPhone 5S
				newman.hasTouchID = YES;
				DebugLog1(@"TouchID detected");
				
				%init(BioSupport);
			}
			
			%init(Main);
			
			// register for notifications from Settings
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
											NULL,
											(CFNotificationCallback)prefsChanged,
											CFSTR("com.sticktron.ahahah.prefschanged"),
											NULL,
											CFNotificationSuspensionBehaviorDeliverImmediately);
		}
	}
}

