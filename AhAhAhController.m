//
//  AhAhAhController.m
//  Ah! Ah! Ah! You didn't say the magic word!
//
//  Custom Unlock Error Alarm.
//  Inspired by Jurassic Park.
//
//  Created by Sticktron in 2014. All rights reserved.
//
//

#import "AhAhAhController.h"

#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoard/SBLockScreenViewController.h>
#import <SpringBoardUIServices/SBUIBiometricEventMonitor.h>

#define DEBUG_MODE_ON
#define DEBUG_PREFIX @"😈 [Newman!]"
#import "DebugLog.h"


#define PREFS_PLIST_PATH				@"/User/Library/Preferences/com.sticktron.ahahah.plist"
#define DEFAULT_BG_IMAGE_PATH			@"/Library/Application Support/AhAhAh/magicword.png"
#define DEFAULT_VIDEO_PATH				@"/Library/Application Support/AhAhAh/AhAhAh.m4v"

#define iPad							(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
//- (id)_deviceInfoForKey:(CFStringRef)key;
@end





@implementation AhAhAhController

- (id)init {
	if (self = [super init]) {
		DebugLog(@"AhAhAhController init'd");
		
		_failedAttempts = 0;
		_isShowing = NO;
		_hasTouchID = NO;
		_pathToVideo = DEFAULT_VIDEO_PATH;
		_pathToBackgroundImage = DEFAULT_BG_IMAGE_PATH;
		
		
		// default preferences ...
				
		_maxFailures = 2;					// Number of failed attempts before alarm goes off.
		_ignoreBioFailure = YES;			// Don't count failed TouchID attempts.
		_allowLockRemoval = YES;			// Remove the alarm using the Lock Button.
		_allowBioRemoval = NO;				// Remove the alarm using TouchID.
		
		
		// apply user preferences if they exist
		[self loadPrefs];
	}
	
	return self;
}

- (void)show {
	DebugLog(@"** BRING ON NEWMAN! **");
	
	// disable TouchID
	if (self.hasTouchID && !self.allowBioRemoval) {
		SBUIBiometricEventMonitor *monitor = [NSClassFromString(@"SBUIBiometricEventMonitor") sharedInstance];
		[monitor _setMatchingEnabled:NO];
		[monitor _stopMatching];
	}
	
	
	// hide the statusbar
	[(SpringBoard *)[UIApplication sharedApplication] hideSpringBoardStatusBar];
	
	
	// find a suitable view controller to host us ...
	
	SBLockScreenViewControllerBase *controller;
	controller = [[NSClassFromString(@"SBLockScreenManager") sharedInstance] lockScreenViewController];
	id parentViewController = controller.parentViewController;
	DebugLog(@"LSM.lockScreenViewController=%@", controller);
	DebugLog(@"LSM.LSVC.parentViewController=%@", parentViewController);
	
	self.parentViewController = parentViewController;
	
	
	// create a UI-blocking overlay view
	self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.overlay.backgroundColor = [UIColor blackColor];
	self.overlay.exclusiveTouch = YES;
	
	
	// setup the background image ...
	
	UIImage *bgImage = [[UIImage alloc] initWithContentsOfFile:self.pathToBackgroundImage];
	DebugLog(@"bgImage=%@", bgImage);
	
	UIImageView *bgImageView = [[UIImageView alloc] initWithImage:bgImage];
	[self.overlay addSubview:bgImageView];
	
	
	// setup the movie controller ...
	
	NSURL *videoURL = [NSURL fileURLWithPath:self.pathToVideo];
	
	self.player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
	self.player.controlStyle = MPMovieControlStyleNone;
	self.player.repeatMode = MPMovieRepeatModeOne;
	self.player.scalingMode = MPMovieScalingModeAspectFit;
	self.player.view.backgroundColor = [UIColor whiteColor];
	
	[self.player prepareToPlay];
	
	CGRect frame = self.overlay.bounds;
	
	// show movie double-sized on iPads
	frame.size = iPad ? CGSizeMake(540.0f, 540.0f) : CGSizeMake(270.0f, 270.0f);
	
	self.player.view.frame = frame;
	self.player.view.center = self.overlay.center; // *is this necessary?
	[self.overlay addSubview:self.player.view];
	
	
	// show the overlay and play the movie
	[[self.parentViewController view] addSubview:self.overlay];
	[self.player play];
	
	
	// stop auto-lock
	//[[UIApplication sharedApplication] setIdleTimerDisabled:NO]; //hack-y
	//[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	
	self.isShowing = YES;
}

- (void)reset {
	DebugLog(@"** Resetting Newman **");
	self.failedAttempts = 0;
}

- (void)remove {
	DebugLog(@"** Removing Newman **");
	
	if (self.player) {
		[self.player stop];
		self.player = nil;
	}
	
	if (self.overlay) {
		[self.overlay removeFromSuperview];
		self.overlay = nil;
	}
	
	// un-hide statusbar
	[(SpringBoard *)[UIApplication sharedApplication] showSpringBoardStatusBar];
	
	// re-enable auto-lock
	//[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	// re-enable TouchID
	if (self.hasTouchID) {
		SBUIBiometricEventMonitor *monitor = [NSClassFromString(@"SBUIBiometricEventMonitor") sharedInstance];
		[monitor _setMatchingEnabled:YES];
		[monitor _startMatching];
	}
	
	self.isShowing = NO;
}

- (void)loadPrefs {
	NSDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	DebugLog(@"loaded prefs, got this: %@", prefs);
	
	if (prefs) {
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
		
		DebugLog(@"new prefs have been applied.");
		
		
		/* DEBUG */
		#ifdef DEBUG_MODE_ON
		NSDictionary *settings = @{ @"MaxFailures": [NSString stringWithFormat:@"%d", self.maxFailures],
									@"IgnoreBioFailure": self.ignoreBioFailure?@"YES":@"NO",
									@"AllowLockRemoval": self.allowLockRemoval?@"YES":@"NO",
									@"AllowBioRemoval": self.allowBioRemoval?@"YES":@"NO"
									};
		
		DebugLog(@"SETTINGS = %@", settings);
		#endif
		/* */
	}
}

@end

