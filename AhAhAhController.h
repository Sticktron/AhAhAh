//
//  AhAhAhController.h
//  Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

@class MPMoviePlayerController;

@interface AhAhAhController : NSObject

@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic, readonly) BOOL isShowing;
@property (nonatomic, readonly) BOOL hasTouchID;
@property (nonatomic, readonly) BOOL ignoreBioFailure;
@property (nonatomic, readonly) BOOL disableLockButton;

- (void)loadPrefs;
- (void)unlockFailed;
- (void)unlockSucceeded;
- (void)remove;

@end
