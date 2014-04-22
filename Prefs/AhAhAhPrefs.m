//
//  AhAhAhPrefs.m
//  Preferences for Ah! Ah! Ah!
//
//  Created by Sticktron in 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "Headers/Preferences/PSViewController.h"
#import "Headers/Preferences/PSListController.h"
#import "Headers/Preferences/PSSpecifier.h"

#define DEBUG_MODE_ON
#define DEBUG_PREFIX @"😏 [Newman Prefs]"
#import "../DebugLog.h"


#define URL_EMAIL			@"mailto:sticktron@hotmail.com"
#define URL_GITHUB			@"http://github.com/Sticktron/AhAhAh"
#define URL_PAYPAL			@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=AhAhAh&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted"
#define URL_TWITTER_WEB		@"http://twitter.com/Sticktron"
#define URL_TWITTER_APP		@"twitter://user?screen_name=Sticktron"

#define PREFS_PLIST					@"/User/Library/Preferences/com.sticktron.ahahah.plist"

#define USER_VIDEOS_PATH			@"/var/mobile/Media/AhAhAh/Videos"
#define USER_BACKGROUNDS_PATH		@"/var/mobile/Media/AhAhAh/Backgrounds"

#define VIDEO_SECTION				0
#define BACKGROUND_SECTION			1



@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
@end


//--------------------------------------------------------------------------------------------------
// Settings Controller
//--------------------------------------------------------------------------------------------------
@interface AhAhAhPrefsController : PSListController
- (void)respring;
- (void)openPayPal;
- (void)openEmail;
- (void)openTwitter;
- (void)openGitHub;
@end


@implementation AhAhAhPrefsController

- (id)specifiers {
	
	if (_specifiers == nil) {
		DebugLog(@"Loading specifiers...");
		NSMutableArray *specs = [self loadSpecifiersFromPlistName:@"AhAhAhPrefs" target:self];
		
		
		// remove TouchID-related specifiers if not iPhone 5S ...
		
		NSString *deviceId = [[UIDevice currentDevice] _deviceInfoForKey:@"ProductType"];
		
		if ([deviceId isEqualToString:@"iPhone6,1"]) { // iPhone 5S
			DebugLog(@"Found an iPhone 5S");
		} else {
			DebugLog(@"Not an iPhone 5S, removing some preferences...");
			
			NSMutableArray *specsToRemove = [NSMutableArray array];
			
			for (PSSpecifier *spec in specs) {
				if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"IgnoreBioFailure"]) {
					[specsToRemove addObject:spec];
				} else if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"AllowBioRemoval"]) {
					[specsToRemove addObject:spec];
				}
			}
			
			for (PSSpecifier *spec in specsToRemove) {
				[specs removeObject:spec];
			}
			
			DebugLog(@"finished.");
		}
		
		_specifiers = [specs copy];
	}
	
	return _specifiers;
}

- (void)respring {
	NSLog(@"Ah!Ah!Ah! called for respring");
	system("killall -HUP SpringBoard");
}

- (void)openPayPal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_PAYPAL]];
}

- (void)openEmail {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_EMAIL]];
}

- (void)openTwitter {
	// try the app first
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_TWITTER_APP]];
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_TWITTER_WEB]];
	}
}

- (void)openGitHub {
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:URL_GITHUB]];
}

@end
//--------------------------------------------------------------------------------------------------





//--------------------------------------------------------------------------------------------------
// Media Controller
//--------------------------------------------------------------------------------------------------
@interface AhAhAhPrefsMediaController : PSViewController <UITableViewDataSource, UITableViewDelegate,
										UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) NSMutableArray *backgrounds;
@property (nonatomic, strong) NSString *selectedVideo;
@property (nonatomic, strong) NSString *selectedBackground;

- (void)updateMedia;
- (void)syncPrefs:(BOOL)notificate;
- (BOOL)startPicker;
@end



@implementation AhAhAhPrefsMediaController

- (instancetype)init {
	self = [super init];
	
	if (self) {
		DebugLog(@"AhAhAhPrefsMediaController init'd");
		
		[self setTitle:@"Customize"];
		
		// init lists with default items
		_videos = [NSMutableArray arrayWithObject:@{ @"file": @"Ah! Ah! Ah!" }];
		_backgrounds = [NSMutableArray arrayWithObject:@{ @"file": @"BlueScreen Error" }];
		
		// set selected items
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST];
		DebugLog(@"Read user prefs: %@", prefs);
		_selectedVideo = prefs[@"Video"] ? prefs[@"Video"][@"file"] : _videos[0][@"file"];
		_selectedBackground = prefs[@"Background"] ? prefs[@"Background"][@"file"] : _backgrounds[0][@"file"];
	}
	
	return self;
}

- (void)loadView {
	DebugLog(@"loadView");
	
	[self updateMedia];
	
	if (self.videos.count > 1 || self.backgrounds.count > 1) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	
	self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]
												  style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 44.0f;
	
	self.view = self.tableView;
	
}

- (void)updateMedia {
	DebugLog0;
	
	// reset the lists (keep the first item)
	[self.videos removeObjectsInRange:NSMakeRange(1, self.videos.count - 1)];
	[self.backgrounds removeObjectsInRange:NSMakeRange(1, self.backgrounds.count - 1)];
	
	NSArray *videos = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:USER_VIDEOS_PATH error:nil];
	NSArray *backgrounds = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:USER_BACKGROUNDS_PATH error:nil];
	DebugLog(@"found user videos: %@", videos);
	DebugLog(@"found user backgrounds: %@", backgrounds);
	
	for (NSString *file in videos) {
		// TODO: test if filetype is supported
		
		NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, file];
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
		NSString *size = [NSString stringWithFormat:@"%.1f MB", [attrs[@"NSFileSize"] floatValue] /1024/1024 ];
		[self.videos addObject:@{ @"file": file, @"size": size }];
	}
	
	for (NSString *file in backgrounds) {
		NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, file];
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
		
		if ([UIImage imageWithContentsOfFile:path]) {
			NSString *size = [NSString stringWithFormat:@"%.0f KB", [attrs[@"NSFileSize"] floatValue] /1024];
			[self.backgrounds addObject:@{@"file": file, @"size": size }];
		} else {
			// unsupported file
		}
	}
	
	DebugLog(@"finished scanning for user media");
	DebugLog(@"self.videos=%@", self.videos);
	DebugLog(@"self.backgrounds=%@", self.backgrounds);
}

- (void)syncPrefs:(BOOL)notificate {
	DebugLog(@"########## SyncPrefs()");
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST];
	
	if (!prefs) {
		prefs = [NSMutableDictionary dictionary];
	}
	
	DebugLog(@"prefs=%@", prefs);
	
//    if (self.enabledMeters) {
//        prefs[@"EnabledMeters"] = self.enabledMeters;
//    }
//    
//    if (self.disabledMeters) {
//        prefs[@"DisabledMeters"] = self.disabledMeters;
//    }
//    
//	DebugLog(@"########## Writing Preferences: %@", prefs);
//    [prefs writeToFile:PLIST_PATH atomically:YES];
//    
//	if (notificate) {
//		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
//											 CFSTR("com.sticktron.ccmeters.prefschanged"),
//											 NULL, NULL, true);
//	}
}



// Media Picker stuff

- (BOOL)startPicker {
	DebugLog(@"starting picker");
	
	if ([UIImagePickerController isSourceTypeAvailable:
		 UIImagePickerControllerSourceTypePhotoLibrary] == NO) {
		return NO;
	}
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.mediaTypes = @[ (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage ];
	picker.allowsEditing = NO;
	picker.delegate = self;
	
	[[self parentController] presentViewController:picker animated:YES completion:NULL];
	
	return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	DebugLog(@"picked something: %@", info);
	
//	image info: {
//	    UIImagePickerControllerMediaType = "public.image";
//	    UIImagePickerControllerOriginalImage = "<UIImage: 0x178285e60>";
//	    UIImagePickerControllerReferenceURL = "assets-library://asset/asset.PNG?id=4FDCF5C9-611E-4793-A244-A5DB53B2F0D3&ext=PNG";
//	}
	
//	movie info: {
//		UIImagePickerControllerMediaType = "public.movie";
//		UIImagePickerControllerMediaURL = "file:///var/tmp/trim.B9F20C5C-7267-401B-B62F-799C1242E0E1.MOV";
//		UIImagePickerControllerReferenceURL = "assets-library://asset/asset.mp4?id=61F81E92-97B5-4AEB-848D-321D31EA104A&ext=mp4";
//	}
	
	
	// do something with it
	
	NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
	
	if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
		//
		// handle image
		//
        UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
		NSData *imageData = UIImagePNGRepresentation(image);
		
		// callback
		ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset) {
			// get filename
			ALAssetRepresentation *imageRep = [imageAsset defaultRepresentation];
			NSString *filename = [imageRep filename];
			DebugLog(@"Picked IMAGE (%@)", filename);
			
			// save
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, filename];
			[imageData writeToFile:path atomically:YES];
			
			[self updateMedia];
			[self.tableView reloadData];
			
			[picker dismissViewControllerAnimated:YES completion:NULL];
		};
		
		// get the asset library and fetch the asset
		NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
		ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
		[assetslibrary assetForURL:imageURL resultBlock:resultblock failureBlock:nil];
		
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
		//
		// handle video
		//
		NSURL *videoURL = info[UIImagePickerControllerMediaURL];
		NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
		
		// callback
		ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *videoAsset) {
			// get filename
			ALAssetRepresentation *videoRep = [videoAsset defaultRepresentation];
			NSString *filename = [videoRep filename];
			DebugLog(@"Picked VIDEO (%@)", filename);
			
			// save
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, filename];
			[videoData writeToFile:path atomically:YES];
			
			[self updateMedia];
			[self.tableView reloadData];
			
			[picker dismissViewControllerAnimated:YES completion:NULL];
		};

		// get the asset library and fetch the asset
		ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
		[assetslibrary assetForURL:videoURL resultBlock:resultblock failureBlock:nil];
	}
}

- (void)imagePickerControllerDidCancel: (UIImagePickerController *) picker {
	DebugLog(@"cancelling picker...");
//    [[picker parentViewController] dismissViewControllerAnimated:YES completion:NULL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}



// TableView stuff

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == VIDEO_SECTION) {
		return @"Videos";
	} else {
		return @"Background Images";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == VIDEO_SECTION) {
		return self.videos.count + 1;
	} else {
		return self.backgrounds.count + 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"MyCellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									  reuseIdentifier:CellIdentifier];
		cell.opaque = YES;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
		cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:10.0];
		cell.detailTextLabel.textColor = [UIColor grayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	if (indexPath.section == VIDEO_SECTION) {
		//
		// video list
		//
		if (indexPath.row == self.videos.count) { // last row
			cell.textLabel.text = @"Import...";
			cell.detailTextLabel.text = @"Add a new video from your Camera Roll";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			
		} else {
			// checkmark
			BOOL isSelected = ([self.videos[indexPath.row][@"file"] isEqualToString:self.selectedVideo]);
			cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			
			// title
			cell.textLabel.text = self.videos[indexPath.row][@"file"];
			
			// subtitle
			if (indexPath.row == 0) {
				cell.detailTextLabel.text = @"*Default";
			} else {
				cell.detailTextLabel.text = self.videos[indexPath.row][@"size"];
			}
			
//			// thumbnail
//			MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
//			moviePlayer.shouldAutoplay = NO;
//			UIImage *thumbnail = [moviePlayer thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];

		}
		
	} else {
		//
		// backgrounds list
		//
		if (indexPath.row == self.backgrounds.count) { // last row
			cell.textLabel.text = @"Import...";
			cell.detailTextLabel.text = @"Add a new background image from your Camera Roll";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			
		} else {
			NSDictionary *background = self.backgrounds[indexPath.row];
			NSString *file = background[@"file"];
			
			// checkmark
			BOOL isSelected = [file isEqualToString:self.selectedBackground];
			cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			
			// title
			cell.textLabel.text = file;
			
			// subtitle
			if (indexPath.row == 0) {
				cell.detailTextLabel.text = @"*Default";
			} else {
				cell.detailTextLabel.text = background[@"size"];
			}
			
			// thumbnail
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, file];
//			UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
//			imageView.frame = CGRectMake(2, 2, 40, 40);
//			imageView.contentMode = UIViewContentModeScaleAspectFit;
//			imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
//			imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
//			[cell.contentView addSubview:imageView];
			
			cell.imageView.image = [UIImage imageWithContentsOfFile:path];
		}
	}
		
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.row == self.videos.count) {
		// start picker
		[self startPicker];
		
	} else if (indexPath.row == self.backgrounds.count) {
		// start picker
		[self startPicker];
		
	} else { // selectable rows
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		if (cell.accessoryType == UITableViewCellAccessoryNone) {
			
			// uncheck previous
			for (int i=0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
				NSIndexPath	*path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:path];
				
				if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
			
			// check new
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			
			// save
			if (indexPath.section == VIDEO_SECTION) {
				self.selectedVideo = self.videos[indexPath.row];
				DebugLog(@"selected: %@", self.selectedVideo);
			} else {
				self.selectedBackground = self.backgrounds[indexPath.row];
				DebugLog(@"selected: %@", self.selectedBackground);
			}
			
		}
		
	}
	
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL isLastRow = (indexPath.section == VIDEO_SECTION) ? (indexPath.row == self.videos.count) : (indexPath.row == self.backgrounds.count);
	
	if (indexPath.row == 0 || isLastRow) {
		return NO;
	} else {
		return YES;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// remove item
		if (indexPath.section == 0) {
			[self.videos removeObjectAtIndex:indexPath.row];
			
			// 1. delete video from disk
			
			// 2. updateMedia()
			
		} else {
			[self.backgrounds removeObjectAtIndex:indexPath.row];
			
			// 1. delete image from disk

			// 2. updateMedia()
		}
		
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end



