//
//  Privates.h
//  Ah!Ah!Ah!
//
//  Themable Unlock Alarm for iOS.
//  Supports iOS 7-9.3.3 on all devices.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
@end

@interface SpringBoard : UIApplication
- (void)showSpringBoardStatusBar;
- (void)hideSpringBoardStatusBar;
- (void)lockButtonDown:(id)arg1;
- (void)_lockButtonDownFromSource:(int)arg1;
- (void)lockButtonUp:(id)arg1;
- (void)_lockButtonUpFromSource:(int)arg1;
- (void)_relaunchSpringBoardNow;
- (void)_lockButtonDown:(id)arg1 fromSource:(int)arg2;
- (void)_lockButtonUp:(id)arg1 fromSource:(int)arg2;
@end

@interface SBBacklightController : NSObject
- (double)defaultLockScreenDimInterval;
- (void)preventIdleSleepForNumberOfSeconds:(float)arg1;
- (void)preventIdleSleep;
- (void)allowIdleSleep;
- (void)setIdleTimerDisabled:(_Bool)arg1;
- (void)resetLockScreenIdleTimerWithDuration:(double)arg1;
- (void)_resetLockScreenIdleTimerWithDuration:(double)arg1 mode:(int)arg2;
@end

@interface SBLockScreenViewController : UIViewController
- (void)setInScreenOffMode:(BOOL)off;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
// iOS 7-9
- (BOOL)attemptUnlockWithPasscode:(id)passcode;
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event;
// iOS 10
// - (void)attemptUnlockWithPasscode:(id)passcode;
@property (nonatomic, assign) BOOL isUILocked;
- (_Bool)_attemptUnlockWithPasscode:(id)arg1 mesa:(_Bool)arg2 finishUIUnlock:(_Bool)arg3;
- (_Bool)_attemptUnlockWithPasscode:(id)arg1 finishUIUnlock:(_Bool)arg2;
- (void)_setMesaUnlockingDisabled:(_Bool)arg1 forReason:(id)arg2;
- (_Bool)unlockWithRequest:(id)arg1 completion:(id/*block*/)arg2;
@end

@interface SBDashBoardMesaUnlockBehavior : NSObject
@end

@interface SBDashBoardViewController : UIViewController
- (void)setInScreenOffMode:(BOOL)arg1 forAutoUnlock:(BOOL)arg2;
@end

@interface SBDashBoardPasscodeViewController : UIViewController
- (void)_passcodeLockViewPasscodeEntered:(id)arg1 viaMesa:(_Bool)arg2;
- (void)passcodeLockViewPasscodeEntered:(id)arg1;
- (_Bool)handleEvent:(id)arg1;
@end

@interface SBUIBiometricEventMonitor : NSObject
+ (id)sharedInstance;
- (void)_setMatchingEnabled:(_Bool)arg1;
- (void)_startMatching;
- (void)_stopMatching;
- (void)setMatchingDisabled:(_Bool)arg1 requester:(id)arg2;
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (float)volume;
- (void)setVolume:(float)arg1;
- (_Bool)muted;
@end

@interface AVSystemController : NSObject
+ (id)sharedAVSystemController;
- (BOOL)getVolume:(float *)arg1 forCategory:(id)arg2;
- (BOOL)getActiveCategoryVolume:(float *)arg1 andName:(id *)arg2;
- (BOOL)setActiveCategoryVolumeTo:(float)arg1;
@end

@interface SBLockHardwareButton : NSObject
- (void)_sendButtonUpEventToAppForRecognizer:(id)arg1;
- (_Bool)_tryToSendButtonDownEventsToAppForRecognizer:(id)arg1;
- (void)longPress:(id)arg1;
- (void)singlePress:(id)arg1;
- (void)buttonDown:(id)arg1;
@property(readonly, nonatomic) _Bool isButtonDown;
@end

@interface UIPressesEvent (Private)
@property (nonatomic, retain) UIPress *_triggeringPhysicalButton;
@end
