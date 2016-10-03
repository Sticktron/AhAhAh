//
//  Common.h
//  Ah!Ah!Ah!
//
//  Shared project settings.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import <LocalAuthentication/LAContext.h>


#define BUNDLE_PATH				@"/Library/PreferenceBundles/AhAhAhPrefs.bundle"
#define THEMES_PATH				@"/Library/AhAhAh/Themes"

#define PREFS_PLIST_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.sticktron.ahahah.plist"]

#define USER_VIDEOS_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Videos"]
#define USER_IMAGES_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Backgrounds"]

#define TINT_COLOR				[UIColor colorWithRed:0.941 green:0 blue:0 alpha:1] // #F00000
#define LINK_COLOR				[UIColor blackColor]

#define DEFAULT_THEME			@"Jurassic"
#define DEFAULT_CONTENT_MODE 	@"AspectFit"


NS_INLINE BOOL hasTouchID() {
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    } else {
    	return NO;
    }
}
