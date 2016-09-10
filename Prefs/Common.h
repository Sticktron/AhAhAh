//
//  Common.h
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#define DEBUG_PREFIX @"••• [AhAhAhPrefs]"
#import "../DebugLog.h"

#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>


#define BUNDLE_PATH			@"/Library/PreferenceBundles/AhAhAhPrefs.bundle"
#define PREFS_PLIST_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.sticktron.ahahah.plist"]

#define TINT_COLOR			[UIColor colorWithRed:0.941 green:0 blue:0 alpha:1] // #F00000
#define LINK_COLOR			[UIColor colorWithRed:0.427 green:0.427 blue:0.447 alpha:1] // #6D6D72

