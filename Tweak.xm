//
//  Tweak.xm
//  Ah!Ah!Ah! - You Didn't Say The Magic Word!
//
//  A Themeable unlock error alarm inspired by Jurassic Park.
//  Supports iOS 7-10 on all devices.
//
//  Copyright (c) 2014-2017 Sticktron. All rights reserved.
//
//

#import "Common.h"
#import "Privates.h"
#import "AhAhAhController.h"
#import <version.h>

static AhAhAhController *newman = nil;

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
						 const void *object, CFDictionaryRef userInfo) {
	HBLogInfo(@"----- Got Notification: %@ -----", (__bridge NSString *)name);
	[newman loadPrefs];
}


//==============================================================================

%group Main

%hook SpringBoard

/* iOS 7 only. */
- (void)_lockButtonDownFromSource:(int)arg1 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
- (void)_lockButtonUpFromSource:(int)arg1 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}

/* iOS 7 and 8. */
- (void)lockButtonDown:(id)arg1 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
- (void)lockButtonUp:(id)arg1 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}

/* iOS 8 and 9. */
- (void)_lockButtonDown:(id)arg1 fromSource:(int)arg2 {
	%log;
	
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
- (void)_lockButtonUp:(id)arg1 fromSource:(int)arg2 {
	%log;
	
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}

%end

//------------------------------------------------------------------------------

%hook SBLockScreenViewController
- (void)setInScreenOffMode:(BOOL)off {
	%log;
	
	if (newman.isShowing && off) {
		HBLogInfo(@"Screen is turning off, stopping alarm.")
		[newman remove];
	}
	%orig;
}
%end

//------------------------------------------------------------------------------

%hook SBLockScreenManager
- (BOOL)attemptUnlockWithPasscode:(id)passcode {
	%log;
	
	if (!newman.isEnabled) {
		return %orig;
	}

	BOOL didUnlock = %orig;
	if (didUnlock) {
		HBLogInfo(@"Passcode unlock successful.");
		if (newman.isShowing) {
			// device is unlocking, stop the alarm
			[newman remove];
		}
	} else {
		HBLogWarn(@"Passcode unlock failed.");
		[newman unlockFailed];
	}

	return didUnlock;
}
%end

%end//group:Main


//==============================================================================


%group BioSupport

%hook SBLockScreenManager
- (void)biometricEventMonitor:(SBUIBiometricEventMonitor *)arg1 handleBiometricEvent:(unsigned long long)event {
	%log;
	// Event values
	// 0: scanner off
	// 1: scanner on
	// 2: ?
	// 4: success
	// 9: fail (iOS 7.0.x)
	// 10: fail (iOS >= 7.1.x)

	//HBLogDebug(@"Touch ID: event %llu", event);

	if (newman.isEnabled) {
		if (event == 4) {
			HBLogInfo(@"BioEvent 4: Touch ID match successful.");
			[newman unlockSucceeded];

		} else if (event == 9 || event == 10) {
			if (newman.isShowing == NO && newman.ignoreBioFailure == NO) {
				HBLogWarn(@"BioEvent %llu: Touch ID match failed.", event);
				[newman unlockFailed];
			}
		}
	}

	%orig;
}
%end

%end//group:BioSupport


//==============================================================================
//==============================================================================


%group Main10

%hook SBLockHardwareButton
- (void)singlePress:(id)arg1 {
	%log;
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
- (void)longPress:(id)arg1 {
	%log;
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
// - (void)buttonDown:(id)arg1 {
// 	%log;
// 	%orig;
// }
%end

//------------------------------------------------------------------------------

%hook SBDashBoardViewController
- (void)setInScreenOffMode:(BOOL)off forAutoUnlock:(BOOL)arg2 {
	%log;
	if (newman.isShowing && off) {
		HBLogInfo(@"Screen is turning off, stopping alarm.")
		[newman remove];
	}
	%orig;
}
%end

//------------------------------------------------------------------------------

%hook SBLockScreenManager
// below only called on success??
/*
- (void)attemptUnlockWithPasscode:(id)passcode {
	%log;
	HBLogDebug(@"(before orig) self.isUILocked = %d", self.isUILocked);
	%orig;
	HBLogDebug(@"(after orig) self.isUILocked = %d", self.isUILocked);
}
- (_Bool)_attemptUnlockWithPasscode:(id)arg1 mesa:(_Bool)arg2 finishUIUnlock:(_Bool)arg3 {
	%log;
	BOOL success = %orig;
	HBLogDebug(@" = %d", success);
	return success;
}
- (_Bool)_attemptUnlockWithPasscode:(id)arg1 finishUIUnlock:(_Bool)arg2 {
	%log;
	BOOL success = %orig;
	HBLogDebug(@" = %d", success);
	return success;
}
- (void)_handleAuthenticationFeedback:(id)arg1 {
	%log;
	%orig;
}
- (void)dashBoardViewController:(id)arg1 unlockWithRequest:(id)arg2 completion:(id)arg3 {
	%log;
	%orig;
}
*/
%end


%hook SBDashBoardPasscodeViewController

// - (void)_passcodeLockViewPasscodeEntered:(id)arg1 viaMesa:(_Bool)arg2 {
// 	%log;
// 	HBLogDebug(@"(before orig) isUILocked = %d", [[%c(SBLockScreenManager) sharedInstance] isUILocked]);
// 	%orig;
// 	HBLogDebug(@"(after orig) isUILocked = %d", [[%c(SBLockScreenManager) sharedInstance] isUILocked]);
// }

- (void)passcodeLockViewPasscodeEntered:(id)arg1 {
	%log;
	%orig;
	
	if (!newman.isEnabled) {
		return;
	}
	
	BOOL failed = [[%c(SBLockScreenManager) sharedInstance] isUILocked];
	if (failed) {
		HBLogWarn(@"Passcode unlock failed.");
		[newman unlockFailed];
	} else {
		HBLogInfo(@"Passcode unlock successful.");
		if (newman.isShowing) {
			// device is unlocking, stop the alarm
			[newman remove];
		}
	}
}

// - (_Bool)handleEvent:(id)arg1 {
// 	%log;
// 	BOOL r = %orig;
// 	HBLogDebug(@" = %d", r);
// 	return r;
// }

%end

%end//group:Main10


//==============================================================================


%group BioSupport10

%hook SBDashBoardViewController

/* iOS 10.2 */
- (void)handleBiometricEvent:(unsigned long long)event {
	%log;

	if (newman.isEnabled) {
		if (event == 4) {
			HBLogDebug(@"BioEvent 4: Touch ID match successful.");
			[newman unlockSucceeded];

		} else if (event == 9 || event == 10) {
			if (newman.isShowing == NO && newman.ignoreBioFailure == NO) {
				HBLogDebug(@"BioEvent %llu: Touch ID match failed.", event);
				[newman unlockFailed];
			}
		}
	}
	
	%orig;
}

/* iOS 10, 10.1 */
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	%log;
	
	if (newman.isEnabled) {
		if (event == 4) {
			HBLogInfo(@"BioEvent 4: Touch ID match successful.");
			[newman unlockSucceeded];

		} else if (event == 9 || event == 10) {
			if (newman.isShowing == NO && newman.ignoreBioFailure == NO) {
				HBLogWarn(@"BioEvent %llu: Touch ID match failed.", event);
				[newman unlockFailed];
			}
		}
	}

	%orig;
}

%end

//------------------------------------------------------------------------------

%hook SBDashBoardMesaUnlockBehavior
// - (void)_handleMesaFailure {}
// - (void)handleBiometricEvent:(unsigned long long)event {}
%end

%end//group:BioSupport10


//==============================================================================

%ctor {
	@autoreleasepool {
		HBLogDebug(@"Ah!Ah!Ah! init.");
		
		newman = [[AhAhAhController alloc] init];
		
		BOOL is10 = IS_IOS_OR_NEWER(iOS_10_0);
		HBLogDebug(@"iOS version is >= 10.0: %@", is10?@"Yes":@"No")
		
		if (is10) {
			%init(Main10);
		} else {
			%init(Main);
		}
		
		HBLogDebug(@"Touch ID supported: %@", newman.hasTouchID?@"Yes":@"No");
		if (newman.hasTouchID) {
			if (is10) {
				%init(BioSupport10);
			} else {
				%init(BioSupport);
			}
		}
		
		// listen for notifications about changes to Preferences
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
										NULL,
										(CFNotificationCallback)prefsChanged,
										CFSTR("com.sticktron.ahahah.prefschanged"),
										NULL,
										CFNotificationSuspensionBehaviorDeliverImmediately);
		
		HBLogDebug(@"Loaded and %@!", newman.isEnabled?@"enabled":@"disabled");
	}
}
