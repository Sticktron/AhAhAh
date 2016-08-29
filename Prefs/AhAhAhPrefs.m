//
//  AhAhAhPrefs.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#define DEBUG_PREFIX @"⚠️ [AhAhAhPrefs]"
#import "../DebugLog.h"

#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <LocalAuthentication/LAContext.h>
#import <Social/Social.h>


#define BUNDLE_PATH			@"/Library/PreferenceBundles/AhAhAhPrefs.bundle"

#define PREFS_PLIST_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.sticktron.ahahah.plist"]

#define USER_VIDEOS_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Videos"]
#define USER_BGS_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Backgrounds"]

#define DEFAULT_PATH				@"/Library/Application Support/AhAhAh"

#define DEFAULT_BG_TITLE			@"BlueScreen Error"
#define DEFAULT_BG_THUMB			@"thumb_BlueScreenError.png"

#define DEFAULT_VIDEO_TITLE			@"Ah! Ah! Ah!"
#define DEFAULT_VIDEO_THUMB			@"thumb_AhAhAh.png"

#define KEVIN_VIDEO_TITLE			@"Mind your damn business!"
#define KEVIN_VIDEO_THUMB			@"thumb_MindYoDamnBusiness.png"

#define DEX_VIDEO_TITLE				@"I feel like dying"
#define DEX_VIDEO_THUMB				@"thumb_IFeelLikeDying.png"

#define IMPORT_SECTION			0
#define VIDEO_SECTION			1
#define BACKGROUND_SECTION		2

#define THUMBNAIL_TAG			1
#define TITLE_TAG				2
#define SUBTITLE_TAG			3

#define ID_NONE				@"_none"
#define ID_DEFAULT			@"_default"
#define ID_KEVIN			@"_kevin"
#define ID_DEX				@"_dex"

#define FILE_KEY			@"file"
#define SIZE_KEY			@"size"


// Private APIs.

@interface UIDevice (Private)
- (id)_deviceInfoForKey:(NSString *)key;
@end

@interface UIColor (SystemColorsPending)
+ (id)systemMidGrayColor;
+ (id)systemGrayColor;
+ (id)systemPinkColor;
+ (id)systemTealColor;
+ (id)systemYellowColor;
+ (id)systemOrangeColor;
+ (id)systemBlueColor;
+ (id)systemGreenColor;
+ (id)systemRedColor;
@end


// Helpers.

@implementation UIImage (AhAhAh)
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
	BOOL opaque = YES;
	
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		// In next line, pass 0.0 to use the current device's pixel scaling factor
		// (and thus account for Retina resolution).
		// Pass 1.0 to force exact pixel size.
        //UIGraphicsBeginImageContextWithOptions(size, opaque, [[UIScreen mainScreen] scale]);
        UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0f);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return newImage;
}
+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;
	
    CGFloat scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;
	
    CGFloat newHeight = oldHeight * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
	
    return [self imageWithImage:image scaledToSize:newSize];
}
- (UIImage *)normalizedImage {
	if (self.imageOrientation == UIImageOrientationUp) {
		return self;
	} else {
		UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
		[self drawInRect:(CGRect){{0, 0}, self.size}];
		UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return normalizedImage;
	}
}
- (NSString *)orientation {
	NSString *result;
	
	switch (self.imageOrientation) {
		case UIImageOrientationUp:
			result = @"UIImageOrientationUp";
			break;
		case UIImageOrientationDown:
			result = @"UIImageOrientationDown";
			break;
		case UIImageOrientationLeft:
			result = @"UIImageOrientationLeft";
			break;
		case UIImageOrientationRight:
			result = @"UIImageOrientationRight";
			break;
		case UIImageOrientationUpMirrored:
			result = @"UIImageOrientationUpMirrored";
			break;
		case UIImageOrientationDownMirrored:
			result = @"UIImageOrientationDownMirrored";
			break;
		case UIImageOrientationLeftMirrored:
			result = @"UIImageOrientationLeftMirrored";
			break;
		case UIImageOrientationRightMirrored:
			result = @"UIImageOrientationRightMirrored";
			break;
		default:
			result = @"Error";
	}
	
	return result;
}
@end


static BOOL hasTouchID() {
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    } else {
    	return NO;
    }
}


//------------------------------------------------------------------------------


// Root Controller.

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
				
		_specifiers = [self loadSpecifiersFromPlistName:@"AhAhAhPrefs" target:self];
		
		// Alter the specefier list, removing some settings if we aren't
		// running on a device with TouchID.
		if (hasTouchID() == NO) {
			DebugLog(@"No TouchID on this device, disabling some settings...");
			
			PSSpecifier *specifier = [self specifierForID:@"IgnoreBioFailure"];
			[specifier setProperty:@NO forKey:@"enabled"];
			[specifier setProperty:@NO forKey:@"default"];
			
			specifier = [self specifierForID:@"AllowBioRemoval"];
			[specifier setProperty:@NO forKey:@"enabled"];
			[specifier setProperty:@NO forKey:@"default"];
		}
	}
	
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// add a heart button to the navbar
	NSString *path = [BUNDLE_PATH stringByAppendingPathComponent:@"Heart.png"];
	UIImage *heartImage = [[UIImage alloc] initWithContentsOfFile:path];
	
	UIBarButtonItem *heartButton = [[UIBarButtonItem alloc] initWithImage:heartImage
																	style:UIBarButtonItemStylePlain
																   target:self
																   action:@selector(showLove)];
	heartButton.imageInsets = (UIEdgeInsets){2, 0, -2, 0};
	heartButton.tintColor = UIColor.redColor;
	
	[self.navigationItem setRightBarButtonItem:heartButton];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:PREFS_PLIST_PATH atomically:NO]; //sandbox issue if atomic

	NSString *notificationValue = specifier.properties[@"PostNotification"];
	if (notificationValue) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFStringRef(notificationValue), NULL, NULL, YES);
	}
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	if (!settings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return settings[specifier.properties[@"key"]];
}

- (void)respring {
	NSLog(@"Ah!Ah!Ah! called for respring");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
										 CFSTR("com.sticktron.ahahah.respring"),
										 NULL,
										 NULL,
										 true);
}

- (void)openEmail {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:sticktron@hotmail.com"]];
}

- (void)openTwitter {
	NSURL *url;
	
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		url = [NSURL URLWithString:@"tweetbot:///user_profile/sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		url = [NSURL URLWithString:@"twitterrific:///profile?screen_name=sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		url = [NSURL URLWithString:@"tweetings:///user?screen_name=sticktron"];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		url = [NSURL URLWithString:@"twitter://user?screen_name=sticktron"];
		
	} else {
		url = [NSURL URLWithString:@"http://twitter.com/sticktron"];
	}
	
	[[UIApplication sharedApplication] openURL:url];
}

- (void)openGitHub {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/Sticktron/AhAhAh"]];
}

- (void)openPayPal {
	NSString *url = @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=AhAhAh&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted";
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)showLove {
	// send a nice tweet ;)
	SLComposeViewController *composeController = [SLComposeViewController
												  composeViewControllerForServiceType:SLServiceTypeTwitter];
	
	[composeController setInitialText:@"I'm using Ah! Ah! Ah! by @Sticktron to scare away nosey people!"];
	
	[self presentViewController:composeController
					   animated:YES
					 completion:nil];
}

@end


//------------------------------------------------------------------------------


// Media List Controller

@interface AhAhAhPrefsMediaController : PSViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) NSMutableArray *backgrounds;
@property (nonatomic, strong) NSString *selectedVideo;
@property (nonatomic, strong) NSString *selectedBackground;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) UIPopoverController *popover;
- (void)scanForMedia;
- (UIImage *)thumbnailForVideo:(NSString *)filename withMaxSize:(CGSize)size;
- (void)savePrefs:(BOOL)notificate;
- (BOOL)startPicker;
@end


@implementation AhAhAhPrefsMediaController

- (instancetype)init {
	self = [super init];
	
	if (self) {
		DebugLog(@"AhAhAhPrefsMediaController init'd");
		
		[self setTitle:@"Customize"];
		
		_queue = [[NSOperationQueue alloc] init];
		_queue.maxConcurrentOperationCount = 4;
		_imageCache = [[NSCache alloc] init];
		
		
		// init lists with default items
		_backgrounds = [NSMutableArray arrayWithObject:@{FILE_KEY: ID_DEFAULT}];
		_videos = [NSMutableArray arrayWithObjects:@{FILE_KEY: ID_DEFAULT}, @{FILE_KEY: ID_KEVIN}, @{FILE_KEY: ID_DEX}, nil];
		
		
		// set selected items
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		DebugLog(@"Read user prefs: %@", prefs);
		_selectedVideo = prefs[@"VideoFile"] ?: ID_DEFAULT;
		_selectedBackground = prefs[@"BackgroundFile"] ?: ID_DEFAULT;
		
		
		// create directories for user media if needed...
		
		[[NSFileManager defaultManager] createDirectoryAtPath:USER_BGS_PATH
								  withIntermediateDirectories:YES
												   attributes:nil
														error:nil];
		
		[[NSFileManager defaultManager] createDirectoryAtPath:USER_VIDEOS_PATH
								  withIntermediateDirectories:YES
												   attributes:nil
														error:nil];
	}
	return self;
}

- (void)loadView {
	DebugLog(@"loadView");

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]
												  style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 44.0f;
	self.tableView.tintColor = UIColor.redColor;
	
	self.view = self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];	
	[self scanForMedia];
}

- (void)didReceiveMemoryWarning {
	DebugLog(@"emptying image cache");
	[self.imageCache removeAllObjects];
	[super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
	DebugLog(@"emptying image cache");
	[self.imageCache removeAllObjects];
	[super viewWillDisappear:animated];
}

// helpers

- (void)scanForMedia {
	DebugLog0;
	
	// reset the lists (keep default entries)
	[self.videos removeObjectsInRange:NSMakeRange(3, self.videos.count - 3)];
	[self.backgrounds removeObjectsInRange:NSMakeRange(1, self.backgrounds.count - 1)];
	
	
	// scan filesystem for custom media...
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSURL *url;
	
	
	// background images ...
	
	url = [NSURL fileURLWithPath:USER_BGS_PATH isDirectory:YES];
	NSMutableArray *backgrounds = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
									includingPropertiesForKeys:keys
													   options:NSDirectoryEnumerationSkipsHiddenFiles
														 error:nil];
	DebugLog(@"Contents of (%@): %@", url, backgrounds);
	
	// sort by creation date (newest first)
	[backgrounds sortUsingComparator:^(NSURL *a, NSURL *b) {
		NSDate *date1 = [[a resourceValuesForKeys:keys error:nil] objectForKey:NSURLContentModificationDateKey];
		NSDate *date2 = [[b resourceValuesForKeys:keys error:nil] objectForKey:NSURLContentModificationDateKey];
		return [date2 compare:date1];
	}];
	
	// add files to list
	for (NSURL *bgURL in backgrounds) {
		if ([UIImage imageWithContentsOfFile:[bgURL path]]) {
			NSString *file = [bgURL resourceValuesForKeys:keys error:nil][NSURLNameKey];
			NSString *size = [bgURL resourceValuesForKeys:keys error:nil][NSURLFileSizeKey];
			
			if ([size floatValue] < 1024*1024) { // < 1MB
				size = [NSString stringWithFormat:@"%.0f KB", [size floatValue] / 1024.0f];
			} else {
				size = [NSString stringWithFormat:@"%.1f MB", [size floatValue] / 1024.0f / 1024.f];
			}
			
			[self.backgrounds addObject:@{ FILE_KEY: file, SIZE_KEY: size }];
		} else {
			// unsupported image
		}
	}
	
	
	// videos ...
	
	url = [NSURL fileURLWithPath:USER_VIDEOS_PATH isDirectory:YES];
	NSMutableArray *videos = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
										  includingPropertiesForKeys:keys
															 options:NSDirectoryEnumerationSkipsHiddenFiles
															   error:nil];
	DebugLog(@"Contents of (%@): %@", url, videos);
	
	// sort by creation date (newest first)
	[videos sortUsingComparator:^(NSURL *a, NSURL *b) {
		NSDate *date1 = [[a resourceValuesForKeys:keys error:nil] objectForKey:NSURLCreationDateKey];
		NSDate *date2 = [[b resourceValuesForKeys:keys error:nil] objectForKey:NSURLCreationDateKey];
		return [date1 compare:date2];
	}];
	
	// add to list
	for (NSURL *videoURL in videos) {
		// TODO: check if video format is valid
		
		NSString *file = [videoURL resourceValuesForKeys:keys error:nil][NSURLNameKey];
		NSString *size = [videoURL resourceValuesForKeys:keys error:nil][NSURLFileSizeKey];
		size = [NSString stringWithFormat:@"%.1f MB", [size floatValue] / 1024.0f / 1024.0f]; // B->MB
		
		[self.videos addObject:@{ FILE_KEY: file, SIZE_KEY: size }];
	}
}

- (UIImage *)thumbnailForVideo:(NSString *)filename withMaxSize:(CGSize)size {
	UIImage *thumbnail = nil;
	
	NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, filename];
	NSURL *url = [NSURL fileURLWithPath:path];
	DebugLog(@"Requested thumbnail for file at url: %@", url);
	
	AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
	DebugLog(@"found asset (%@)", asset);
	
	if (asset) {
		AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
		generator.appliesPreferredTrackTransform = YES;
		
		CMTime time = CMTimeMake(1, 1);
		CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:NULL error:NULL];
		
		UIImage *image = [UIImage imageWithCGImage:imageRef];
		DebugLog(@"got thumbnail image (size=%@)", NSStringFromCGSize(image.size));
		
		thumbnail = [UIImage imageWithImage:image scaledToMaxWidth:size.width maxHeight:size.height];
		DebugLog(@"scaled thumbnail to size: %@", NSStringFromCGSize(thumbnail.size));
		
		CFRelease(imageRef);
	}
	
	return thumbnail;
}

- (void)savePrefs:(BOOL)notificate {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	
	if (!prefs) {
		prefs = [NSMutableDictionary dictionary];
	}
	
	// new settings
	prefs[@"VideoFile"] = self.selectedVideo;
	prefs[@"BackgroundFile"] = self.selectedBackground;
	
	DebugLog(@"##### Writing Preferences: %@", prefs);
	[prefs writeToFile:PREFS_PLIST_PATH atomically:YES];
	
	// apply settings to tweak
	if (notificate) {
		DebugLog(@"notified tweak");
		
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
											 CFSTR("com.sticktron.ahahah.prefschanged"),
											 NULL,
											 NULL,
											 true);
	}
}

// image picker

- (BOOL)startPicker {
	DebugLog0;
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) {
		return NO;
	}
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.modalPresentationStyle = UIModalPresentationCurrentContext;
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.mediaTypes = @[ (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage ];	
	picker.allowsEditing = YES;	
	picker.navigationBar.barStyle = UIBarStyleDefault;
	picker.delegate = self;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self presentViewController:picker animated:YES completion:NULL];
		
	} else {
		self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
		[self.popover presentPopoverFromRect:CGRectZero inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	
	return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	/*
		< Info Object Format >
	 
		image: {
			UIImagePickerControllerMediaType = "public.image";
			UIImagePickerControllerOriginalImage = <UIImage>;
			UIImagePickerControllerReferenceURL = "assets-library://asset/asset.PNG?id={GUID}&ext=PNG";
		}

		movie: {
			UIImagePickerControllerMediaType = "public.movie";
			UIImagePickerControllerMediaURL = "file:///var/tmp/trim.{GUID}.MOV";
			UIImagePickerControllerReferenceURL = "assets-library://asset/asset.mp4?id={GUID}&ext=mp4";
		}
	*/
	DebugLog(@"picker returned with this: %@", info);
	
	
	// callback
	ALAssetsLibraryAssetForURLResultBlock resultHandler = ^(ALAsset *asset) {
		NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
		
		if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
			
			// handle image ...
			
			ALAssetRepresentation *imageRep = [asset defaultRepresentation];
			DebugLog(@"Picked image asset with representation: %@", imageRep);
			
			NSString *filename = [imageRep filename];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BGS_PATH, filename];
			
			UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
			DebugLog(@"image size=%@", NSStringFromCGSize(image.size));
			
			DebugLog(@"image orientation=%@", [image orientation]);
			image = [image normalizedImage];
			DebugLog(@"normalized image orientation: %@", [image orientation]);
			
			NSData *imageData = UIImagePNGRepresentation(image);
			[imageData writeToFile:path atomically:YES];
			
			// auto-select as new background
			self.selectedBackground = filename;
			
		} else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
			
			// handle video ...
			
			ALAssetRepresentation *videoRep = [asset defaultRepresentation];
			DebugLog(@"Picked video asset with representation: %@", videoRep);
			
			NSString *filename = [videoRep filename];
			
			// save to disk
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, filename];
			NSURL *videoURL = info[UIImagePickerControllerMediaURL];
			NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
			[videoData writeToFile:path atomically:YES];
			
			// auto-select new video
			self.selectedVideo = filename;
		}
		
		[self savePrefs:YES];
		[self scanForMedia];
		[self.tableView reloadData];
		
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[picker dismissViewControllerAnimated:YES completion:NULL];
		} else {
			[self.popover dismissPopoverAnimated:YES];
		}
	};
	
	
	// fetch the asset from the library
	NSURL *assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
	ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
	[library assetForURL:assetURL resultBlock:resultHandler failureBlock:nil];
}

- (void)imagePickerControllerDidCancel: (UIImagePickerController *)picker {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[picker dismissViewControllerAnimated:YES completion:NULL];
	} else {
		[self.popover dismissPopoverAnimated:YES];
	}
}

// tableview data

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	
	switch (section) {
		case VIDEO_SECTION: title = @"Videos";
			break;
		case BACKGROUND_SECTION: title = @"Background Images";
			break;
		case IMPORT_SECTION: title = @"Import Media";
			break;
	}
	
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger num = 0;
	
	switch (section) {
		case VIDEO_SECTION: num = self.videos.count;
			break;
		case BACKGROUND_SECTION: num = self.backgrounds.count;
			break;
		case IMPORT_SECTION: num = 1;
			break;
	}
	
	return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	
	if (indexPath.section == IMPORT_SECTION) {
		//
		// media picker cell
		//
		static NSString *ImportCellIdentifier = @"ImportCell";
		cell = [tableView dequeueReusableCellWithIdentifier:ImportCellIdentifier];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										  reuseIdentifier:ImportCellIdentifier];
			cell.opaque = YES;
			cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		cell.textLabel.text = @"Add new video or image from Camera Roll";
		
	} else {
		//
		// media item cell
		//
		static NSString *CustomCellIdentifier = @"CustomCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CustomCellIdentifier];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
										  reuseIdentifier:CustomCellIdentifier];
			cell.opaque = YES;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
			
			// thumbnail
			UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0f, 2.0f, 40.0f, 40.0f)];
			imageView.opaque = YES;
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.tag = THUMBNAIL_TAG;
			[cell.contentView addSubview:imageView];
			
			// title
			UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 10.0f, 215.0f, 16.0f)];
			titleLabel.opaque = YES;
			titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
			titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
			titleLabel.tag = TITLE_TAG;
			[cell.contentView addSubview:titleLabel];
			
			// subtitle
			UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 28.0f, 215.0f, 12.0f)];
			subtitleLabel.opaque = YES;
			subtitleLabel.font = [UIFont italicSystemFontOfSize:10.0];
			subtitleLabel.textColor = [UIColor grayColor];
			subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
			subtitleLabel.tag = SUBTITLE_TAG;
			[cell.contentView addSubview:subtitleLabel];
		}
		
		UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:THUMBNAIL_TAG];
		UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
		UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:SUBTITLE_TAG];
		
		if (indexPath.section == VIDEO_SECTION) {
			NSDictionary *video = self.videos[indexPath.row];
			
			if (indexPath.row == 0) {
				//
				// Default video
				//
				titleLabel.text = DEFAULT_VIDEO_TITLE;
				subtitleLabel.text = @"*Default";
				NSString *path = [NSString stringWithFormat:@"%@/%@", DEFAULT_PATH, DEFAULT_VIDEO_THUMB];
				imageView.image = [UIImage imageWithContentsOfFile:path];
				
				// checked ?
				if ([self.selectedVideo isEqualToString:ID_DEFAULT]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
				
			} else if (indexPath.row == 1) {
				//
				// Kevin Hart video
				//
				titleLabel.text = KEVIN_VIDEO_TITLE;
				subtitleLabel.text = @"???";
				NSString *path = [NSString stringWithFormat:@"%@/%@", DEFAULT_PATH, KEVIN_VIDEO_THUMB];
				imageView.image = [UIImage imageWithContentsOfFile:path];
				
				// checked ?
				if ([self.selectedVideo isEqualToString:ID_KEVIN]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
				
				
			} else if (indexPath.row == 2) {
				//
				// Dexter video
				//
				titleLabel.text = DEX_VIDEO_TITLE;
				subtitleLabel.text = @"???";
				NSString *path = [NSString stringWithFormat:@"%@/%@", DEFAULT_PATH, DEX_VIDEO_THUMB];
				imageView.image = [UIImage imageWithContentsOfFile:path];
				
				// checked ?
				if ([self.selectedVideo isEqualToString:ID_DEX]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
				
				
			} else {
				//
				// User video
				//
				NSString *filename = video[FILE_KEY];
				titleLabel.text = filename;
				subtitleLabel.text = video[SIZE_KEY];
				
				// get thumbnail from cache, or else load and cache it in the background...
				
				UIImage *thumbnail = [self.imageCache objectForKey:filename];
				
				if (thumbnail) {
					imageView.image = thumbnail;
					
				} else {
					[self.queue addOperationWithBlock:^{
						// load
						UIImage *image = [self thumbnailForVideo:filename withMaxSize:imageView.bounds.size];
						
						if (image) {
							// add to cache
							[self.imageCache setObject:image forKey:filename];
							
							// update UI on the main thread
							[[NSOperationQueue mainQueue] addOperationWithBlock:^{
								UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
								
								if (cell) {
									UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:THUMBNAIL_TAG];
									imageView.image = image;
								}
							}];
						}
					}];
				}
				
				// checked ?
				if ([self.selectedVideo isEqualToString:video[FILE_KEY]]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
			
		} else if (indexPath.section == BACKGROUND_SECTION) {
			NSDictionary *background = self.backgrounds[indexPath.row];
			
			if (indexPath.row == 0) {
				//
				// Default background
				//
				titleLabel.text = DEFAULT_BG_TITLE;
				subtitleLabel.text = @"*Default";
				NSString *path = [NSString stringWithFormat:@"%@/%@", DEFAULT_PATH, DEFAULT_BG_THUMB];
				imageView.image = [UIImage imageWithContentsOfFile:path];
				
				// checked ?
				if ([self.selectedBackground isEqualToString:ID_DEFAULT]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
				
			} else {
				//
				// Custom background
				//
				NSString *filename = background[FILE_KEY];
				titleLabel.text = filename;
				subtitleLabel.text = background[SIZE_KEY];
				
				// get thumbnail from cache, or else load and cache it in the background...
				
				UIImage *thumbnail = [self.imageCache objectForKey:filename];
				
				if (thumbnail) {
					imageView.image = thumbnail;
					
				} else {
					[self.queue addOperationWithBlock:^{
						// load
						NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BGS_PATH, filename];
						UIImage *image = [UIImage imageWithContentsOfFile:path];
						
						if (image) {
							image = [UIImage imageWithImage:image scaledToMaxWidth:imageView.bounds.size.height
												  maxHeight:imageView.bounds.size.height];
							
							// add to cache
							[self.imageCache setObject:image forKey:filename];
							
							// update UI on main thread
							[[NSOperationQueue mainQueue] addOperationWithBlock:^{
								UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
								
								if (cell) {
									UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:THUMBNAIL_TAG];
									imageView.image = image;
								}
							}];
						}
					}];
				}
				
				// is checked ?
				if ([self.selectedBackground isEqualToString:background[FILE_KEY]]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
		}
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == IMPORT_SECTION) {
		return @"Media can also be copied to /User/Library/AhAhAh/ and will appear in the lists automatically.";
	} else {
		return nil;
	}
}

// tableview selecting & deleting

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DebugLog(@"User selected row: %ld, section: %ld", (long)indexPath.row, (long)indexPath.section);
	
	if (indexPath.section == IMPORT_SECTION) {
		[self startPicker];
		
	} else {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			//
			// de-selected the selected row
			//
			cell.accessoryType = UITableViewCellAccessoryNone;
			
			if (indexPath.section == VIDEO_SECTION) {
				self.selectedVideo = ID_NONE;
			} else {
				self.selectedBackground = ID_NONE;
			}
			
		} else {
			//
			// selected a new row
			//
			
			// uncheck old selection
			for (NSInteger i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
				NSIndexPath	 *path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:path];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
			// check new selection
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			
			// get the file name
			UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
			
			// save selection
			if (indexPath.section == VIDEO_SECTION) {
				if (indexPath.row == 0) {
					self.selectedVideo = ID_DEFAULT;
				} else if (indexPath.row == 1) {
					self.selectedVideo = ID_KEVIN;
				} else if (indexPath.row == 2) {
					self.selectedVideo = ID_DEX;
				} else {
					self.selectedVideo = titleLabel.text;
				}
				DebugLog(@"selected video: %@", self.selectedVideo);
				
			} else if (indexPath.section == BACKGROUND_SECTION) {
				if (indexPath.row == 0) {
					self.selectedBackground = ID_DEFAULT;
				} else {
					self.selectedBackground = titleLabel.text;
				}
				DebugLog(@" selected background: %@", self.selectedBackground);
			}
		}
			
		[self savePrefs:YES];
		[tableView reloadData];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row <= 2) {
		return NO;
	} else {
		return YES;
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	DebugLog(@"User wants to delete media");
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		if (indexPath.section == VIDEO_SECTION) {
			//
			// delete video
			//
			NSString *file = self.videos[indexPath.row][FILE_KEY];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, file];
			DebugLog(@"deleting video at path: %@", path);
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			
			// if row was checked, check the default row instead
			if ([file isEqualToString:self.selectedVideo]) {
				self.selectedVideo = ID_DEFAULT;
			}
			
			[self.videos removeObjectAtIndex:indexPath.row];
			
		} else if (indexPath.section == BACKGROUND_SECTION) {
			//
			// delete image
			//
			NSString *file = self.backgrounds[indexPath.row][FILE_KEY];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BGS_PATH, file];
			DebugLog(@"deleting image at path: %@", path);
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			
			// if image was selected, select default after deletion
			if ([file isEqualToString:self.selectedBackground]) {
				self.selectedBackground = ID_DEFAULT;
			}
			
			[self.backgrounds removeObjectAtIndex:indexPath.row];
		}
		
		[self savePrefs:YES];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
		[tableView reloadData];
    }
}

@end


//------------------------------------------------------------------------------


// Custom Cells

@interface AAASwitchCell : PSSwitchTableCell
@end

@implementation AAASwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:UIColor.redColor];
	}
	return self;
}
@end


@interface AAAButtonCell : PSTableCell
@end

@implementation AAAButtonCell
- (void)layoutSubviews {
	[super layoutSubviews];
	
	// if I do this at init it doesn't stick :(
	[self.textLabel setTextColor:UIColor.redColor];
}
@end


@interface AAALogoCell : PSTableCell
@end

@implementation AAALogoCell
- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:@"LogoCell"
					  specifier:specifier];
	
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		
		CGRect frame = self.contentView.bounds;
		frame.origin.y += 10;
		frame.size.height -= 10;
		
		UILabel *label = [[UILabel alloc] initWithFrame:frame];
		label.text = @"a Sticktron joint";
		label.font = [UIFont boldSystemFontOfSize:10];
		label.textColor = UIColor.darkGrayColor;
		label.textAlignment = NSTextAlignmentCenter;
		
		[self.contentView addSubview:label];
	}
	return self;
}
- (CGFloat)preferredHeightForWidth:(CGFloat)height {
	return 22.0f;
}
@end


