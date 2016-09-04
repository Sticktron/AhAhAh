//
//  Tweak.xm
//  Ah!Ah!Ah!
//
//  Themable Unlock Alarm for iOS.
//  Supports iOS 7-9.3.3 on all devices.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#define DEBUG_PREFIX @"🦄  [AhAhAh]"
#import "DebugLog.h"

#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import <LocalAuthentication/LAContext.h>


//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

#define DEFAULT_BACKGROUND	@"/Library/Application Support/AhAhAh/BlueScreenError.png"
#define DEFAULT_VIDEO		@"/Library/Application Support/AhAhAh/AhAhAh.mp4"
#define KEVIN_VIDEO			@"/Library/Application Support/AhAhAh/MindYoDamnBusiness.m4v"
#define DEX_VIDEO			@"/Library/Application Support/AhAhAh/IFeelLikeDying.m4v"

#define ID_NONE				@"_none"
#define ID_DEFAULT			@"_default"
#define ID_KEVIN			@"_kevin"
#define ID_DEX				@"_dex"

#define iPad				(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define PREFS_PLIST_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.sticktron.ahahah.plist"]
#define USER_VIDEOS_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Videos"]
#define USER_BGS_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Backgrounds"]



//------------------------------------------------------------------------------
// Private Interfaces
//------------------------------------------------------------------------------

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
- (void)_stopMatching;
@end



//------------------------------------------------------------------------------
// Ah!Ah!Ah! Controller
//------------------------------------------------------------------------------

@interface AhAhAhController : NSObject

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) NSString *videoFile;
@property (nonatomic, strong) NSString *backgroundFile;
@property (nonatomic, assign) int maxFailures;
@property (nonatomic, assign) int failedAttempts;
@property (nonatomic, assign) BOOL hasTouchID;
@property (nonatomic, assign) BOOL ignoreBioFailure;
@property (nonatomic, assign) BOOL allowLockRemoval;
@property (nonatomic, assign) BOOL allowBioRemoval;
@property (nonatomic, assign) BOOL fullScreenVideo;
@property (nonatomic, assign) BOOL isShowing;
- (void)loadPrefs;
- (void)unlockFailed;
- (void)show;
- (void)remove;
@end


@implementation AhAhAhController

- (instancetype)init {
	if (self = [super init]) {
		DebugLog(@"AhAhAhController init'ing");
		
		_failedAttempts = 0;
		_isShowing = NO;
		_hasTouchID = NO;
		
		// default settings
		_maxFailures = 2;
		_ignoreBioFailure = YES;
		_allowBioRemoval = NO;
		_allowLockRemoval = YES;
		_fullScreenVideo = NO;
		_videoFile = ID_DEFAULT;
		_backgroundFile = ID_DEFAULT;
		
		// load user prefs if any
		[self loadPrefs];
	}
	return self;
}

- (void)loadPrefs {
	NSDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	DebugLog(@"loading prefs: %@", prefs);
	
	if (prefs) {
		
		if (prefs[@"VideoFile"]) {
			self.videoFile = prefs[@"VideoFile"];
		}
		
		if (prefs[@"BackgroundFile"]) {
			self.backgroundFile = prefs[@"BackgroundFile"];
		}
		
		if (prefs[@"MaxFailures"]) {
			self.maxFailures = [prefs[@"MaxFailures"] intValue];
		}
		
		if (prefs[@"IgnoreBioFailure"]) {
			self.ignoreBioFailure = [prefs[@"IgnoreBioFailure"] boolValue];
		}
		
		if (prefs[@"AllowLockRemoval"]) {
			self.allowLockRemoval = [prefs[@"AllowLockRemoval"] boolValue];
		}
		
		if (prefs[@"AllowBioRemoval"]) {
			self.allowBioRemoval = [prefs[@"AllowBioRemoval"] boolValue];
		}
		
		if (prefs[@"FullScreenVideo"]) {
			self.fullScreenVideo = [prefs[@"FullScreenVideo"] boolValue];
		}
		
		DebugLog(@"user settings applied");
	}
}

- (void)unlockFailed {
	self.failedAttempts++;
	DebugLog(@"Failed Attempts: %d", self.failedAttempts);
	
	if (self.failedAttempts >= self.maxFailures) {
		[self show];
	}
}

- (void)show {
	NSLog(@"•••••••••• Ah!Ah!Ah! says RING THE ALARM! ••••••••••");
	
	self.isShowing = YES;
	
	// disable TouchID
	if (self.hasTouchID && !self.allowBioRemoval) {
		SBUIBiometricEventMonitor *monitor;
		monitor = [NSClassFromString(@"SBUIBiometricEventMonitor") sharedInstance];
		[monitor _stopMatching];
	}
	
	// delay sleep
	//
	//Class $SBBacklightController = NSClassFromString(@"SBBacklightController");
	//[[$SBBacklightController sharedInstance] preventIdleSleep];
	//
	//self.sleepTimer = [NSTimer scheduledTimerWithTimeInterval:self.sleepDelay
	//												 target:self
	//											   selector:@selector(enableSleep)
	//											   userInfo:nil
	//												repeats:NO];
	//
	//DebugLog(@"delaying sleep by: %f", self.sleepDelay);
	
	
	// create the overlay view
	self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.overlay.opaque = YES;
	self.overlay.backgroundColor = [UIColor blackColor];
	self.overlay.autoresizesSubviews = NO;
	self.overlay.exclusiveTouch = YES;
	
	// show the overlay
	UIViewController *parentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	DebugLog(@"our gracious host: %@", parentViewController);
	[parentViewController.view addSubview:self.overlay];
	[parentViewController.view bringSubviewToFront:self.overlay];
	
	// hide the statusbar
	[(SpringBoard *)[UIApplication sharedApplication] hideSpringBoardStatusBar];
	
	
	// create the background image view...
	
	if ([self.backgroundFile isEqualToString:ID_NONE]) {
		DebugLog(@"no backgound");
		
	} else {
		BOOL isDefaultBG = [self.backgroundFile isEqualToString:ID_DEFAULT];
		NSString *bgPath;
		
		if (isDefaultBG) {
			bgPath = DEFAULT_BACKGROUND;
		} else {
			bgPath = [USER_BGS_PATH stringByAppendingPathComponent:self.backgroundFile];
		}
		DebugLog(@"using background: %@", bgPath);
		
		UIImage *bgImage = [[UIImage alloc] initWithContentsOfFile:bgPath];
		if (bgImage) {
			UIImageView *bgImageView = [[UIImageView alloc] initWithImage:bgImage];
			bgImageView.frame = self.overlay.bounds;
			bgImageView.backgroundColor = [UIColor clearColor]; // not necessary
			bgImageView.contentScaleFactor = 2.0f;
			bgImageView.contentMode = isDefaultBG ? UIViewContentModeTopLeft : UIViewContentModeScaleAspectFit;
			DebugLog(@"bgImageView=%@", bgImageView);
			
			[self.overlay addSubview:bgImageView];
		}
	}
	
	
	// create the movie view...
	
	if ([self.videoFile isEqualToString:ID_NONE]) {
		DebugLog(@"no video");
		self.player = nil;
		
	} else {
		NSString *videoPath;
		
		if ([self.videoFile isEqualToString:ID_DEFAULT]) {
			videoPath = DEFAULT_VIDEO;
			
		} else if ([self.videoFile isEqualToString:ID_KEVIN]) {
			videoPath = KEVIN_VIDEO;
				
		} else if ([self.videoFile isEqualToString:ID_DEX]) {
			videoPath = DEX_VIDEO;
			
		} else {
			videoPath = [USER_VIDEOS_PATH stringByAppendingPathComponent:self.videoFile];
		}
		DebugLog(@"video path: %@", videoPath);
		
		NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
		
		self.player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
		self.player.controlStyle = MPMovieControlStyleNone;
		self.player.repeatMode = MPMovieRepeatModeOne;
		self.player.scalingMode = MPMovieScalingModeAspectFit;
		self.player.view.backgroundColor = [UIColor clearColor];
		self.player.backgroundView.backgroundColor = [UIColor clearColor];
		
		// set frame
		if (self.fullScreenVideo) {
			self.player.view.frame = self.overlay.bounds;
		} else {
			// play in a centered window; double-sized on iPads
			
			CGSize size;
			if ([self.videoFile isEqualToString:ID_KEVIN]) {
				size = iPad ? CGSizeMake(540.0f, 408.0f) : CGSizeMake(270.0f, 204.0f);
			} else {
				size = iPad ? CGSizeMake(540.0f, 540.0f) : CGSizeMake(270.0f, 270.0f);
			}
			self.player.view.frame = (CGRect){{0,0}, size};
			self.player.view.center = self.overlay.center;
		}
		
		[self.overlay addSubview:self.player.view];
		[self.player play];
	}
}

- (void)remove {
	NSLog(@"•••••••••• Ah!Ah!Ah! is going away (for now) ••••••••••");
	
	if (self.player) {
		[self.player stop];
		self.player = nil;
	}
	
	[self.overlay removeFromSuperview];
	self.overlay = nil;
	
	self.failedAttempts = 0;
	
	// allow sleep again
	//
	//Class $SBBacklightController = NSClassFromString(@"SBBacklightController");
	//[[$SBBacklightController sharedInstance] allowIdleSleep];
	//
	//[self enableSleep];
	
	self.isShowing = NO;
}

@end



//------------------------------------------------------------------------------
// Functions and Globals
//------------------------------------------------------------------------------

static AhAhAhController *newman = nil;

static BOOL hasTouchID() {
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    } else {
    	return NO;
    }
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
						 const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"***** Ah!Ah!Ah! Preferences Changed Notification *****");
	
	if (newman) {
		[newman loadPrefs];
	}
}

static void respring() {
	[(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
}



//------------------------------------------------------------------------------
// Main Hooks
//------------------------------------------------------------------------------

%group Main

%hook SpringBoard

// iOS 7 & 8
- (void)lockButtonDown:(id)arg1 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}
- (void)lockButtonUp:(id)arg1 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

// iOS 7
- (void)_lockButtonDownFromSource:(int)arg1 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}
- (void)_lockButtonUpFromSource:(int)arg1 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

// iOS 8
- (void)_lockButtonDown:(id)arg1 fromSource:(int)arg2 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}
- (void)_lockButtonUp:(id)arg1 fromSource:(int)arg2 {
	DebugLog(@"isShowing=%@; allowLockButton=%@", newman.isShowing?@"YES":@"NO", newman.allowLockRemoval?@"YES":@"NO");
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

%end


%hook SBLockScreenViewController

- (void)setInScreenOffMode:(BOOL)off {
	DebugLog(@"arg=%@", off?@"YES":@"NO");
	%orig;
	
	if (off && newman.isShowing) {
		[newman remove];
	}
}

%end


%hook SBLockScreenManager

- (BOOL)attemptUnlockWithPasscode:(id)passcode {
	DebugLog(@"attempting unlock via passcode");
	
	BOOL successful = %orig;
	DebugLog(@"result=%@", successful?@"YES":@"NO");
	
	if (successful) {
		[newman remove];
	} else {
		[newman unlockFailed];
	}
	
	return successful;
}

%end

%end //group:Main



//------------------------------------------------------------------------------
// TouchID Hooks
//------------------------------------------------------------------------------

%group BioSupport

%hook SBLockScreenManager

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	//
	// Notes:
	//
	// • arg1 is an SBUIBiometricEventMonitor
	//
	// • event values seem to be:
	//		0: scanner off
	//		1: scanner on
	//		2: ?
	//		4: success
	//		9: fail (iOS 7.0.x)
	//		10: fail (iOS >= 7.1.x)
	//
	
	if (event == 4) {
		// TouchID match successful !!
		if (newman.isShowing) {
			DebugLog(@"TouchID: Event %llu (unlock successful)", event);
			[newman remove];
		}
		
	} else if (event == 9 || event == 10) {
		// TouchID match failed !!
		if (newman.ignoreBioFailure == NO) {
			DebugLog(@"TouchID: Event %llu (unlock failed)", event);
			[newman unlockFailed];
		}
	} else {
		DebugLog(@"TouchID: Event %llu", event);
	}
	
	%orig;
}

%end

%end //group:BioSupport



/* Init */

%ctor {
	@autoreleasepool {
		DebugLogC(@"initing tweak...");
		
		if (1==2) { %init(Main); }
		if (1==3) { %init(BioSupport); }
		
		
		/*
		BOOL enabled = YES;
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		
		if (prefs && prefs[@"Enabled"] && ([prefs[@"Enabled"] boolValue] == NO)) {
			enabled = NO;
			
		} else {
			newman = [[AhAhAhController alloc] init];
			
			%init(Main);
						
			// init TouchID hooks if supported...
			if (hasTouchID()) {
				DebugLogC(@" [Ah! Ah! Ah!] TouchID supported");
				newman.hasTouchID = YES;
				%init(BioSupport);
			} else {
				DebugLogC(@" [Ah! Ah! Ah!] TouchID not supported");
			}
			
			// listen for notifications from Settings
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
											NULL,
											(CFNotificationCallback)prefsChanged,
											CFSTR("com.sticktron.ahahah.prefschanged"),
											NULL,
											CFNotificationSuspensionBehaviorDeliverImmediately);
											
			// listen for notifications for respring from Settings
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
											NULL,
											(CFNotificationCallback)respring,
											CFSTR("com.sticktron.ahahah.respring"),
											NULL,
											CFNotificationSuspensionBehaviorDeliverImmediately);
		}
		NSLog(@"[Ah!Ah!Ah!] Loaded and %@.", enabled?@"Enabled":@"Disabled");
		*/
	}
}

