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
@end

@interface SBLockScreenViewController : UIViewController
- (void)setInScreenOffMode:(BOOL)off;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (BOOL)attemptUnlockWithPasscode:(id)passcode;
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event;
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
