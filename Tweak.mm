//
//  Tweak.xm
//  Ah! Ah! Ah! You didn't say the magic word!
//
//  Custom Unlock Error Alarm.
//  Inspired by Jurassic Park.
//
//  Created by Sticktron in 2014.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>

//#define DEBUG_MODE_ON
#define DEBUG_PREFIX @"😈 [Ah!Ah!Ah!]"
#import "DebugLog.h"


#define DEFAULT_BACKGROUND	@"/Library/Application Support/AhAhAh/BlueScreenError.png"
#define DEFAULT_VIDEO		@"/Library/Application Support/AhAhAh/AhAhAh.mp4"

#define ID_NONE				@"_none"
#define ID_DEFAULT			@"_default"

#define iPad				(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define PREFS_PLIST_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.sticktron.ahahah.plist"]
#define USER_VIDEOS_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Videos"]
#define USER_BGS_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Backgrounds"]



//------------------------------//
// Private Interfaces
//------------------------------//

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
@end

@interface SBLockScreenViewController : UIViewController
- (void)setInScreenOffMode:(BOOL)off;
@end

@interface SBLockScreenManager : NSObject
- (BOOL)attemptUnlockWithPasscode:(id)passcode;
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event;
@end

@interface SBUIBiometricEventMonitor : NSObject
+ (id)sharedInstance;
- (void)_stopMatching;
@end



//------------------------------//
// AhAhAh Controller
//------------------------------//

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

//------------------------------//

@implementation AhAhAhController

- (instancetype)init {
	if (self = [super init]) {
		DebugLog(@"AhAhAhController init'd");
		
		_failedAttempts = 0;
		_isShowing = NO;
		_hasTouchID = NO;
		
		_maxFailures = 2;
		_ignoreBioFailure = YES;
		_allowBioRemoval = NO;
		_allowLockRemoval = YES;
		_fullScreenVideo = NO;
		_videoFile = ID_DEFAULT;
		_backgroundFile = ID_DEFAULT;
		
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
	
	if (self.failedAttempts == self.maxFailures) {
		[self show];
	}
}

- (void)show {
	NSLog(@"••• Ah!Ah!Ah! says RING THE ALARM •••");
	
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
	
	
	// create the overlay view...
	
	self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	DebugLog(@"[[UIScreen mainScreen] bounds]=%@", NSStringFromCGRect([[UIScreen mainScreen] bounds]));
	
	self.overlay.opaque = YES;
	self.overlay.backgroundColor = [UIColor blackColor];
	self.overlay.autoresizesSubviews = NO;
	self.overlay.exclusiveTouch = YES;
	
	UIViewController *parentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	DebugLog(@"our gracious host: %@", parentViewController);
	[parentViewController.view addSubview:self.overlay];
	[parentViewController.view bringSubviewToFront:self.overlay];
	
	
	// hide the statusbar
	[(SpringBoard *)[UIApplication sharedApplication] hideSpringBoardStatusBar];
	
	
	// background view...
	
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
	
	
	// movie view...
	
	if ([self.videoFile isEqualToString:ID_NONE]) {
		DebugLog(@"no video");
		self.player = nil;
		
	} else {
		NSString *videoPath;
		
		if ([self.videoFile isEqualToString:ID_DEFAULT]) {
			videoPath = DEFAULT_VIDEO;
		} else {
			videoPath = [USER_VIDEOS_PATH stringByAppendingPathComponent:self.videoFile];
		}
		DebugLog(@"video path: %@", videoPath);
		
		NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
		DebugLog(@"video URL: %@", videoURL);
		
		self.player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
		//[self.player prepareToPlay];
		
		// (todo: check if movie loaded)
		
		self.player.controlStyle = MPMovieControlStyleNone;
		self.player.repeatMode = MPMovieRepeatModeOne;
		self.player.scalingMode = MPMovieScalingModeAspectFit;
		self.player.view.backgroundColor = [UIColor clearColor];
		self.player.backgroundView.backgroundColor = [UIColor clearColor];
		//self.player.view.opaque = NO;
		//self.player.backgroundView.opaque = NO;
		
		// set frame
		if (self.fullScreenVideo) {
			self.player.view.frame = self.overlay.bounds;
		} else {
			// play in a centered window; double-sized on iPads
			CGSize size = iPad ? CGSizeMake(540.0f, 540.0f) : CGSizeMake(270.0f, 270.0f);
			self.player.view.frame = (CGRect){{0,0}, size};
			self.player.view.center = self.overlay.center;
		}
		
		[self.overlay addSubview:self.player.view];
		[self.player play];
	}
}

- (void)remove {
	NSLog(@"••• Ah!Ah!Ah! is going away (for now!) •••");
	
	if (self.player) {
		[self.player stop];
		self.player = nil;
	}
	
	[self.overlay removeFromSuperview];
	self.overlay = nil;
	
	// un-hide the statusbar
	//[(SpringBoard *)[UIApplication sharedApplication] showSpringBoardStatusBar];
	
	self.failedAttempts = 0;
	self.isShowing = NO;
	
	
	// allow sleep
	//
	//Class $SBBacklightController = NSClassFromString(@"SBBacklightController");
	//[[$SBBacklightController sharedInstance] allowIdleSleep];
	//
	//[self enableSleep];

	
	// re-enable TouchID
	//
	//if (self.hasTouchID && !self.allowBioRemoval) {
	//	SBUIBiometricEventMonitor *monitor = [NSClassFromString(@"SBUIBiometricEventMonitor") sharedInstance];
	//	[monitor _setMatchingEnabled:YES];
	//	//[monitor _startMatching];
	//}
	
}

@end



//------------------------------//
// Stuff
//------------------------------//

static AhAhAhController *newman = nil;

static BOOL deviceHasTouchID() {
	BOOL result = NO;
	UIDevice *device = [UIDevice currentDevice];
	
	if ([device respondsToSelector:@selector(_deviceInfoForKey)]) { // iOS 7
		NSString *productType = [device _deviceInfoForKey:@"ProductType"];
		
		if ([productType isEqualToString:@"iPhone6,1"]) { // iPhone 5s
			result = YES;
		} else if ([productType isEqualToString:@"iPhone6,2"]) { // iPhone 5s (world?)
			result = YES;
		}
	}
	return result;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
						 const void *object, CFDictionaryRef userInfo) {
	DebugLog1(@"******** Preferences Changed Notification ********");
	
	if (newman) {
		[newman loadPrefs];
	}
}



//------------------------------//
// Main Hooks
//------------------------------//

%group Main


%hook SpringBoard

- (void)_lockButtonDownFromSource:(int)arg1 {
	DebugLog0;
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

- (void)lockButtonDown:(id)arg1 {
	DebugLog0;
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

- (void)lockButtonUp:(id)arg1 {
	DebugLog0;
	if (newman.isShowing && !newman.allowLockRemoval) {
		// no-op
	} else {
		%orig;
	}
}

- (void)_lockButtonUpFromSource:(int)arg1 {
	DebugLog0;
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

/*
- (void)_handleDisplayTurnedOff;
- (void)prepareForMesaUnlockWithCompletion:(id)arg1;
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1;
- (void)passcodeLockViewPasscodeEntered:(id)arg1;
- (void)_passcodeStateChanged;
- (void)_handlePasscodeLockStateChanged;
*/

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

/*
- (void)_deviceLockedChanged:(id)arg1 {
	// NSConcreteNotification {
	//	name = SBDevicePasscodeLockStateDidChangeNotification
	// }
	
	%orig;
}
- (void)_lockUI;
- (void)_setUILocked:(BOOL)locked;
- (void)_postLockCompletedNotification:(BOOL)arg1;
- (BOOL)handleMenuButtonTap;
*/

%end


%end //group:Main



//------------------------------//
// TouchID Hooks
//------------------------------//

%group BioSupport


//%hook SBUIBiometricEventMonitor
//- (void)_setMatchingEnabled:(BOOL)enable;
//%end


%hook SBLockScreenManager

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	// arg1 is <SBUIBiometricEventMonitor>
	
	if (event == 4) {			// TouchID match successful //
		if (newman.isShowing) {
			DebugLog(@"TouchID: Event %llu (unlock successful)", event);
			[newman remove];
		}
		
	} else if (event == 9) {	// TouchID match failed //
		if (newman.ignoreBioFailure == NO) {
			DebugLog(@"TouchID: Event %llu (unlock failed)", event);
			[newman unlockFailed];
		}
	}
	
	%orig;
}

//
// Handle TouchID Unlock Notification.
//		NSConcreteNotification {
//		  name = SBBiometricEventMonitorHasAuthenticated;
//		  object = <SBUIBiometricEventMonitor>
//		}
//
//- (void)_bioAuthenticated:(id)notification {
//	DebugLog(@"notification=%@", notification);
//	%orig;
//}

%end


%end //group:BioSupport



//------------------------------//
// Constructor
//------------------------------//

%ctor {
	@autoreleasepool {
		BOOL enabled = YES;
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		
		if (prefs && prefs[@"Enabled"] && ([prefs[@"Enabled"] boolValue] == NO)) {
			enabled = NO;
		} else {
			newman = [[AhAhAhController alloc] init];
			%init(Main);
			
			if (deviceHasTouchID()) {
				NSLog(@" [Ah! Ah! Ah!] detected iPhone 5S");
				newman.hasTouchID = YES;
				
				%init(BioSupport);
			}
			
			// register for notifications from Settings
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
											NULL,
											(CFNotificationCallback)prefsChanged,
											CFSTR("com.sticktron.ahahah.prefschanged"),
											NULL,
											CFNotificationSuspensionBehaviorDeliverImmediately);
		}
		
		NSLog(@" [Ah!Ah!Ah!] Loaded. I'm %@.", enabled?@"Enabled":@"Disabled");
	}
}

