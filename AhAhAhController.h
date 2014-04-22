//
//  AhAhAhController.h
//  Ah! Ah! Ah! You didn't say the magic word!
//
//  Custom Unlock Error Alarm.
//  Inspired by Jurassic Park.
//
//  Created by Sticktron in 2014. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>


@interface AhAhAhController : NSObject

@property (nonatomic, assign) int failedAttempts;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL hasTouchID;

@property (nonatomic, strong) id parentViewController;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) NSString *pathToVideo;
@property (nonatomic, strong) NSString *pathToBackgroundImage;

// settings
@property (nonatomic, assign) int maxFailures;
@property (nonatomic, assign) BOOL ignoreBioFailure;
@property (nonatomic, assign) BOOL allowLockRemoval;
@property (nonatomic, assign) BOOL allowBioRemoval;

- (void)show;
- (void)remove;
- (void)reset;
- (void)loadPrefs;

@end

