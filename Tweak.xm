//
//  Tweak.xm
//  Ah!Ah!Ah! - You Didn't Say The Magic Word!
//
//  Themable Unlock Alarm for iOS.
//  Supports iOS 7-9.3.3 on all devices.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
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


/* Hooks */

%group Main
/*
%hook SBBacklightController
- (double)defaultLockScreenDimInterval {
	if (newman.isEnabled && newman.isShowing) {
		HBLogWarn(@"LockScreen sleep timeout paused for 30 seconds.");
		return 30.0;
	} else {
		return %orig;
	}
}
%end
*/


%hook SpringBoard

// iOS 7
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

// iOS 7-8
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

// iOS 8-9
- (void)_lockButtonDown:(id)arg1 fromSource:(int)arg2 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}
- (void)_lockButtonUp:(id)arg1 fromSource:(int)arg2 {
	if (newman.isEnabled && newman.isShowing && newman.disableLockButton) {
		// eat the event
		HBLogWarn(@"Lock Button press cancelled.");
	} else {
		%orig;
	}
}

%end


%hook SBLockScreenViewController
- (void)setInScreenOffMode:(BOOL)off {
	if (newman.isShowing && off) {
		HBLogInfo(@"Screen is turning off, stopping alarm.")
		[newman remove];
	}
	%orig;
}
%end


%hook SBLockScreenManager
- (BOOL)attemptUnlockWithPasscode:(id)passcode {
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

%end


//------------------------------------------------------------------------------


/* Touch ID Hooks */

%group BioSupport

%hook SBLockScreenManager
- (void)biometricEventMonitor:(SBUIBiometricEventMonitor *)arg1 handleBiometricEvent:(unsigned long long)event {
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

%end


//------------------------------------------------------------------------------


/* Init */

%ctor {
	@autoreleasepool {
		HBLogDebug(@"initing tweak...");
		
		newman = [[AhAhAhController alloc] init];
		
		%init(Main);
					
		// init TouchID hooks if supported...
		if (newman.hasTouchID) {
			%init(BioSupport);
		} else {
			HBLogWarn(@"Touch ID is not supported on this device.");
		}
		
		// listen for notifications about changes to Preferences
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
										NULL,
										(CFNotificationCallback)prefsChanged,
										CFSTR("com.sticktron.ahahah.prefschanged"),
										NULL,
										CFNotificationSuspensionBehaviorDeliverImmediately);
		
		HBLogInfo(@"Loaded and %@!", newman.isEnabled?@"enabled":@"disabled");
	}
}
