//
//  Newman.mm
//  Ah! Ah! Ah!
//
//  Created by Sticktron in 2014. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoard/SBLockScreenViewController.h>
#import <SpringBoard/SpringBoard.h>
//#import <SpringBoard/SBLockScreenView.h>
//#import <SpringBoard/SBLockScreenViewControllerBase.h>


//--------------------------------------------------------------------------------------------------
//#define __DEBUG_ON__
//
#ifdef __DEBUG_ON__
	#define DebugLog(s, ...) \
		NSLog(@" [Newman!] %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
	#define DebugLog(s, ...)
#endif
//--------------------------------------------------------------------------------------------------


#define kBluescreenImagePath	@"/Library/Application Support/AhAhAh/magicword.png"
#define kNewmanVideoPath		@"/Library/Application Support/AhAhAh/AhAhAh.m4v"

static const int maxFailures = 2; // set # of failed unlock attempts before Newman!
static int failedUnlockAttempts = 0;
static BOOL needsCleanup = NO;
static id parentViewController = nil;
static UIView *overlay = nil;
static MPMoviePlayerController *player = nil;



//--------------------------------------------------------------------------------------------------
%hook SBLockScreenViewController
//--------------------------------------------------------------------------------------------------

- (void)_handleDisplayTurnedOff {
	DebugLog(@" DISPLAY TURNED OFF: cleaning up Newman");
	
	// clean up after Newman ...
	
	if (needsCleanup == YES) {
		if (player != nil) {
			[player stop];
			player = nil;
		}
		if (overlay != nil) {
			[overlay removeFromSuperview];
			overlay = nil;
		}
		parentViewController = nil;
		
		// show statusbar
		[(SpringBoard *)[UIApplication sharedApplication] showSpringBoardStatusBar];
		
		needsCleanup = NO;
	}
	
	%orig;
}

%end
//--------------------------------------------------------------------------------------------------



//--------------------------------------------------------------------------------------------------
%hook SBLockScreenManager
//--------------------------------------------------------------------------------------------------

- (BOOL)attemptUnlockWithPasscode:(id)arg1 {
	BOOL result = %orig;
	DebugLog(@"attemptUnlockWithPasscode(XXXX) returning: %@", result?@"YES":@"NO");
	
	if (result == NO) { // Unlock Failed !!
		
		failedUnlockAttempts++;
		
		DebugLog(@"Failed Attempts: %d", failedUnlockAttempts);
		
		if (failedUnlockAttempts >= maxFailures) { // Show Newman !!
			NSLog(@"##########  Ah! Ah! Ah! You didn't say the magic word!  ##########");
			
			needsCleanup = YES;
			
			// grab the view controller instance variable
			id vcontroller = MSHookIvar<SBLockScreenViewControllerBase *>(self, "_lockScreenViewController");
			DebugLog(@"_lockScreenViewController=%@", vcontroller);
			
			// save a reference to our parent view controller
			parentViewController = [vcontroller parentViewController];
			DebugLog(@"parentViewController=%@", parentViewController);
			
			
			// create a UI-blocking overlay view...
			
			overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
			DebugLog(@"overlay=%@", overlay);

			overlay.backgroundColor = [UIColor blueColor];
			overlay.exclusiveTouch = YES;
			
			
			// add the bluescreen error image to the overlay ...
			
			UIImage *bluescreen = [[UIImage alloc] initWithContentsOfFile:kBluescreenImagePath];
			DebugLog(@"bluescreen=%@", bluescreen);
			
			UIImageView *bluescreenView = [[UIImageView alloc] initWithImage:bluescreen];
			DebugLog(@"bluescreenView=%@", bluescreenView);
			
			[overlay addSubview:bluescreenView];
			
			
			// create a movie controller and add it to the overlay ...
			
			NSURL *movieURL = [NSURL fileURLWithPath:kNewmanVideoPath];
			DebugLog(@"movieURL=%@", movieURL);
			
			player = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
			player.repeatMode = MPMovieRepeatModeOne;
			player.controlStyle = MPMovieControlStyleNone;
			//player.scalingMode = MPMovieScalingModeAspectFit;
			player.view.backgroundColor = [UIColor whiteColor];
			[player prepareToPlay];
			
			CGRect frame = overlay.bounds;
			
			// show movie at double size on iPads
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				frame.size = CGSizeMake(540.0f, 540.0f);
			} else {
				frame.size = CGSizeMake(270.0f, 270.0f);
			}
			
			player.view.frame = frame;
			player.view.center = overlay.center;
			
			[overlay addSubview:player.view];
			
			
			// show overlay and play movie ...
			
			[overlay addSubview:player.view];
			[[parentViewController view] addSubview:overlay];
			
			[player play];
			
			
			// hide statusbar
			[(SpringBoard *)[UIApplication sharedApplication] hideSpringBoardStatusBar];
		}
		
	} else { // Unlock Successfull !!
		
		// reset attempts counter
		failedUnlockAttempts = 0;
	}
	
	return result;
}

%end
//--------------------------------------------------------------------------------------------------



//--------------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------------
%ctor {
	@autoreleasepool {
		NSLog(@" [Ah! Ah! Ah!] loaded.");
		%init;
	}
}

