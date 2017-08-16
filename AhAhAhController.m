//
//  AhAhAhController.m
//  Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "AhAhAhController.h"
#import "Common.h"
#import "Privates.h"
// #import <version.h>
#import <AVFoundation/AVAudioSession.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import <MediaPlayer/MPMusicPlayerController.h>


/* AhAhAh Controller */

@interface AhAhAhController ()
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL hasTouchID;
@property (nonatomic, assign) int maxFailures;
@property (nonatomic, assign) int failedAttempts;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL ignoreBioFailure;
@property (nonatomic, assign) BOOL disableLockButton;
@property (nonatomic, assign) BOOL forceVolume;
@property (nonatomic, assign) float volumeLevel;
@property (nonatomic, assign) float originalVolume;
@property (nonatomic, assign) BOOL wasMuted;
@property (nonatomic, strong) NSString *contentMode;
@property (nonatomic, strong) NSString *theme;
@property (nonatomic, strong) NSString *videoFile;
@property (nonatomic, strong) NSString *imageFile;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, assign) CGFloat originalWindowLevel;
@property (nonatomic, strong) UIWindow *keyWindow;
@end


@implementation AhAhAhController

- (instancetype)init {
	if (self = [super init]) {
		_isShowing = NO;
		_failedAttempts = 0;
		
		_hasTouchID = hasTouchID();
		HBLogDebug(@"hasTouchID() = %@", _hasTouchID?@"YES":@"NO");
		
		[self loadPrefs];
	}
	return self;
}

- (void)loadPrefs {
	NSDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	HBLogDebug(@"loaded user prefs from plist = %@", prefs);
	
	self.isEnabled = prefs[@"Enabled"] ? [prefs[@"Enabled"] boolValue] : YES;
	self.maxFailures = prefs[@"MaxFailures"] ? [prefs[@"MaxFailures"] intValue] : 2;
	self.ignoreBioFailure = prefs[@"IgnoreBioFailure"] ? [prefs[@"IgnoreBioFailure"] boolValue] : NO;
	self.disableLockButton = prefs[@"DisableLockButton"] ? [prefs[@"DisableLockButton"] boolValue] : YES;
	self.contentMode = prefs[@"ContentMode"] ?: @"Default";
	self.videoFile = nil;
	self.imageFile = nil;
	self.forceVolume = prefs[@"ForceVolume"] ? [prefs[@"ForceVolume"] boolValue] : YES;
	self.volumeLevel = prefs[@"VolumeLevel"] ? [prefs[@"VolumeLevel"] floatValue] / 100.0f : 0.75f;
	
	// Determine if the user has selected a theme, video, or image.
	// If there is no selection, auto-select the default theme.
	self.theme = prefs[@"Theme"] ?: nil;
	if (!self.theme) {
		// no theme is selected, check for a video
		self.videoFile = prefs[@"VideoFile"] ?: nil;
		if (!self.videoFile) {
			// no theme or video are selected, check for an image
			self.imageFile = prefs[@"ImageFile"] ?: nil;
			if (!self.imageFile) {
				// if nothing at all is selected, use the default theme...
				HBLogDebug(@"User settings don't exist yet; select default theme");
				self.theme = DEFAULT_THEME;
			}
		}
	}
	
	// If a theme is selected, apply its settings.
	// If a video or image is selected, get its path.
	if (self.theme) {
		[self loadThemeSettingsFromPlist];
	} else if (self.videoFile) {
		self.videoFile = [USER_VIDEOS_PATH stringByAppendingPathComponent:self.videoFile];
	} else if (self.imageFile) {
		self.imageFile = [USER_IMAGES_PATH stringByAppendingPathComponent:self.imageFile];
	}
	
	HBLogDebug(@"== Prefs ============================");
	HBLogDebug(@"self.isEnabled = %@", self.isEnabled ? @"YES" : @"NO");
	HBLogDebug(@"self.maxFailures = %d", self.maxFailures);
	HBLogDebug(@"self.ignoreBioFailure = %@", self.ignoreBioFailure ? @"YES" : @"NO");
	HBLogDebug(@"self.disableLockButton = %@", self.disableLockButton ? @"YES" : @"NO");
	HBLogDebug(@"-------------------------------------");
	HBLogDebug(@"self.contentMode = %@", self.contentMode);
	HBLogDebug(@"-------------------------------------");
	HBLogDebug(@"self.theme = %@", self.theme);
	HBLogDebug(@"self.videoFile = %@", self.videoFile);
	HBLogDebug(@"self.imageFile = %@", self.imageFile);
	HBLogDebug(@"-------------------------------------");
	HBLogDebug(@"self.forceVolume = %@", self.forceVolume ? @"YES" : @"NO");
	HBLogDebug(@"self.volumeLevel = %f", self.volumeLevel);
	HBLogDebug(@"self.wasMuted = %@", self.wasMuted ? @"YES" : @"NO");
	HBLogDebug(@"=====================================");
}

- (void)loadThemeSettingsFromPlist {
	HBLogDebug(@"Reading Info.plist for theme: %@", self.theme);
	
	NSString *themePath = [THEMES_PATH stringByAppendingPathComponent:self.theme];
	NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:[themePath stringByAppendingPathComponent:@"Info.plist"]];
	if (!themeDict) {
		HBLogWarn(@"Theme contains no Info.plist file.");
		self.videoFile = nil;
		self.imageFile = nil;
		return;
	}
	
	// if the content mode is default get the content mode from the plist
	if (!self.contentMode || [self.contentMode isEqualToString:@"Default"]) {
		self.contentMode = themeDict[@"ContentMode"];
	}
		
	// Let's look for the theme's video or image file,
	// make sure it exists, and select it.
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path;
	
	if (themeDict[@"Video"]) {
		path = [themePath stringByAppendingPathComponent:themeDict[@"Video"]];
		if ([fm fileExistsAtPath:path]) {
			HBLogDebug(@"found Video for theme at path: %@", path);
			self.videoFile = path;
		} else {
			HBLogError(@"Couldn't find Video for theme at path: %@", path);
			self.videoFile = nil;
		}
		
	} else if (themeDict[@"Image"]) {
		path = [themePath stringByAppendingPathComponent:themeDict[@"Image"]];
		if ([fm fileExistsAtPath:path]) {
			HBLogDebug(@"found image for theme at path: %@", path);
			self.imageFile = path;
		} else {
			HBLogError(@"Couldn't find image for theme at path: %@", path);
			self.imageFile = nil;
		}
		
	} else {
		HBLogWarn(@"Theme contains no Video or Image key.");
	}
	
	if (!self.videoFile && !self.imageFile) {
		HBLogError(@"Can't find files for theme: %@", self.theme);
	}
}

- (void)unlockFailed {
	if (self.isShowing) {
		return;
	}
	
	self.failedAttempts++;
	HBLogDebug(@"self.failedAttempts = %d", self.failedAttempts);
	
	if (self.failedAttempts >= self.maxFailures) {
		// too many failures, show the alarm
		[self show];
	}
}

- (void)unlockSucceeded {
	self.failedAttempts = 0;
	
	if (self.isShowing) {
		[self remove];
	}
}

- (void)show {
	HBLogWarn(@"********** Ah!Ah!Ah! You didn't say the magic word! **********");
	HBLogWarn(@"********** Ah!Ah!Ah! You didn't say the magic word! **********");
	HBLogWarn(@"********** Ah!Ah!Ah! You didn't say the magic word! **********");
	
	// make sure counter gets reset
	self.failedAttempts = 0;
	
	// delay sleep
	[[NSClassFromString(@"SBBacklightController") sharedInstance] preventIdleSleepForNumberOfSeconds:30.0f];

	// create the overlay view for the alarm
	self.overlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.overlay.opaque = YES;
	self.overlay.backgroundColor = [UIColor blackColor];
	
	
	// add the overlay view to the main window,
	// and set the window level to waaay above statusbar ...
	
	self.keyWindow = [UIApplication sharedApplication].keyWindow;
	[self.keyWindow addSubview:self.overlay];
	[self.keyWindow bringSubviewToFront:self.overlay];
	
	self.originalWindowLevel = self.keyWindow.windowLevel;
	HBLogDebug(@"original window level = %f", self.originalWindowLevel);
	
	//keyWindow.windowLevel = UIWindowLevelStatusBar + 420.0f;
	self.keyWindow.windowLevel = 9999.0f;
	

	// create the movie player or imageview ...
	
	if (self.videoFile) {
		HBLogDebug(@"using video: %@", self.videoFile);
		
		self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoFile]];
		self.player.controlStyle = MPMovieControlStyleNone;
		self.player.repeatMode = MPMovieRepeatModeOne;
		self.player.scalingMode = [self videoModeForSetting:self.contentMode];
		self.player.view.backgroundColor = [UIColor clearColor];
		self.player.backgroundView.backgroundColor = [UIColor clearColor];
		self.player.view.frame = self.overlay.bounds;
		[self.overlay addSubview:self.player.view];
		
		[self.player play];
		
		// this gives us sound even if the device is muted
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error: nil];
		
		// apply the volume override if option is set
		if (self.forceVolume) {
			float originalVolume = 0.0f;
	    	if (![[AVSystemController sharedAVSystemController] getVolume:&originalVolume forCategory:AVAudioSessionCategoryPlayback]) {
	            originalVolume = 0.5f;
				HBLogDebug(@"failed to get original volume level, setting to %f", originalVolume);
	        }
			HBLogDebug(@"original volume for category is: %f, originalVolume", originalVolume);
			self.originalVolume = originalVolume;
			
        	[[AVSystemController sharedAVSystemController] setActiveCategoryVolumeTo:self.volumeLevel];
		}
		
	} else if (self.imageFile) {
		HBLogDebug(@"using image: %@", self.imageFile);
		
		UIImage *bgImage = [[UIImage alloc] initWithContentsOfFile:self.imageFile];
		if (bgImage) {
			UIImageView *bgImageView = [[UIImageView alloc] initWithImage:bgImage];
			bgImageView.frame = self.overlay.bounds;
			bgImageView.contentScaleFactor = [UIScreen mainScreen].scale;
			bgImageView.contentMode = [self imageModeForSetting:self.contentMode];
			HBLogDebug(@"bgImageView=%@", bgImageView);
			
			[self.overlay addSubview:bgImageView];
		}
	}
	
	self.isShowing = YES;
}

- (void)remove {
	HBLogWarn(@"---------- Ah!Ah!Ah! is going away ----------");
	
	// restore original volume level
	if (self.forceVolume) {
		[[AVSystemController sharedAVSystemController] setActiveCategoryVolumeTo:self.originalVolume];
	}
	
	// kill the movie player
	if (self.player) {
		[self.player stop];
		self.player = nil;
	}
	
	// restore the original window level
	if (self.keyWindow) {
		self.keyWindow.windowLevel = self.originalWindowLevel;
	}
	
	// kill the overlay
	[self.overlay removeFromSuperview];
	self.overlay = nil;
	
	self.isShowing = NO;
}

- (UIViewContentMode)imageModeForSetting:(NSString *)mode {
	HBLogDebug(@"mode = %@", mode);
	
	if ([mode isEqualToString:@"AspectFit"]) {
		return UIViewContentModeScaleAspectFit;
		
	} else if ([mode isEqualToString:@"AsectFill"]) {
		return UIViewContentModeScaleAspectFill;
		
	} else if ([mode isEqualToString:@"Fill"]) {
		return UIViewContentModeScaleToFill;
		
	} else {
		HBLogError(@"Content Mode (%@) is an invalid option. This shouldn't occur. But it did, so we'll choose UIViewContentModeScaleAspectFit instead.", mode);
		return UIViewContentModeScaleAspectFit;
	}
}

- (MPMovieScalingMode)videoModeForSetting:(NSString *)mode {
	HBLogDebug(@"mode = %@", mode);
	
	if ([mode isEqualToString:@"AspectFit"]) {
		return MPMovieScalingModeAspectFit;
		
	} else if ([mode isEqualToString:@"AspectFill"]) {
		return MPMovieScalingModeAspectFill;
		
	} else if ([mode isEqualToString:@"Fill"]) {
		return MPMovieScalingModeFill;
		
	} else {
		HBLogError(@"Content Mode (%@) is an invalid option. This shouldn't occur. But it did, so we'll choose MPMovieScalingModeAspectFit instead.", mode);
		return MPMovieScalingModeAspectFit;
	}
}

@end
