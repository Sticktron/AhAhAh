//
//  AhAhAhPrefsTheme.m
//  Preferences for Ah!Ah!Ah!
//
//  Theme selection controller.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "../Common.h"
#import "Prefs.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>


#define THUMBNAIL_SIZE			40.0f
#define ROW_HEIGHT				60.0f

typedef NS_ENUM(NSInteger, AhAhAhSection) {
    kAhAhAhThemeSection 			= 0,
	kAhAhAhCustomThemeInfoSection 	= 1,
	kAhAhAhImportSection	 		= 2,
    kAhAhAhVideoSection				= 3,
    kAhAhAhImageSection 			= 4,
	kAhAhAhSectionCount 			= 5
};

typedef NS_ENUM(NSInteger, AhAhAhTag) {
    kAhAhAhThumbnailTag = 1,
    kAhAhAhTitleTag 	= 2,
    kAhAhAhSubtitleTag 	= 3
};

 
/* UIImage Helpers */

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


@interface AhAhAhPrefsThemeController : PSViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *themes;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSString *selectedTheme;
@property (nonatomic, strong) NSString *selectedVideo;
@property (nonatomic, strong) NSString *selectedImage;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;
@end


@implementation AhAhAhPrefsThemeController

- (instancetype)init {
	self = [super init];
	
	if (self) {
		[self setTitle:@"Customize"];
		
		_queue = [[NSOperationQueue alloc] init];
		_queue.maxConcurrentOperationCount = 4;
		_imageCache = [[NSCache alloc] init];
		
		_themes = nil;
		_images = nil;
		_videos = nil;
		
		// Get the selected theme or video or image from prefs.
		// If for some reason more than one thing is selected, choose
		// which one to use in this order: Theme > Video > Image.
		
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		HBLogDebug(@"Read user prefs: %@", settings);
		
		if (settings[@"Theme"]) {
			_selectedTheme = settings[@"Theme"];
			
		} else if (settings[@"VideoFile"]) {
			_selectedVideo = settings[@"VideoFile"];
			
		} else if (settings[@"ImageFile"]) {
			_selectedImage = settings[@"ImageFile"];
		}
		
		// if nothing has been selected auto-select the default theme
		if (!_selectedTheme && !_selectedVideo && !_selectedImage) {
			_selectedTheme = DEFAULT_THEME;
		}
		
		// create directories for user media (if needed) ...
		
		[[NSFileManager defaultManager] createDirectoryAtPath:USER_IMAGES_PATH
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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]
												  style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = ROW_HEIGHT;
	self.tableView.tintColor = TINT_COLOR;
	
	self.view = self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// tint navbar
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = TINT_COLOR;
	} else {
		self.navigationController.navigationBar.tintColor = TINT_COLOR;
	}
	
	[self scanForMedia];
}

- (void)viewWillDisappear:(BOOL)animated {
	// un-tint navbar
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = nil;
	} else {
		self.navigationController.navigationBar.tintColor = nil;
	}
	
	HBLogInfo(@"emptying image cache");
	[self.imageCache removeAllObjects];
			
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	HBLogInfo(@"emptying image cache");
	[self.imageCache removeAllObjects];
	
	[super didReceiveMemoryWarning];
}

// data model

- (void)scanForMedia {
	HBLogDebug(@"Scanning for media...");
		
	self.videos = [self indexMediaAtPath:USER_VIDEOS_PATH];
	HBLogDebug(@"self.videos = %@", self.videos);
	
	self.images = [self indexMediaAtPath:USER_IMAGES_PATH];
	HBLogDebug(@"self.images = %@", self.images);
	
	self.themes = [self indexThemes];
	HBLogDebug(@"self.themes = %@", self.themes);
}

- (NSMutableArray *)indexThemes {
	HBLogDebug(@"Indexing Themes...");
	
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *url = [NSURL fileURLWithPath:THEMES_PATH isDirectory:YES];
	NSMutableArray *folders = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
												  includingPropertiesForKeys:keys
													  				 options:NSDirectoryEnumerationSkipsHiddenFiles
																	   error:nil];
	HBLogDebug(@"Contents of folder (%@): %@", url, folders);
	
	if (!folders) {
		HBLogError(@"Default Themes are missing! Suggest re-installing the package.");
		return nil;
	}
	
	// sort folders by name
	[folders sortUsingComparator:^(NSURL *a, NSURL *b) {
		return [a.lastPathComponent compare:b.lastPathComponent];
	}];
	
		
	// iterate through themes and build index of theme objects ...
	
	NSMutableArray *themes = [NSMutableArray array];
	
	for (NSURL *folderURL in folders) {
		NSMutableDictionary *theme = [NSMutableDictionary dictionary];
		
		// store folder name
		NSString *folderName = [folderURL resourceValuesForKeys:keys error:nil][NSURLNameKey];
		theme[@"folder"] = folderName;
		
		
		// get info from the its Info.plist ...
		
		NSString *themePath = [THEMES_PATH stringByAppendingPathComponent:folderName];
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:[themePath stringByAppendingPathComponent:@"Info.plist"]];
		
		// author name
		if (themeDict[@"Author"]) {
			theme[@"author"] = themeDict[@"Author"];
		}
		
		// media type
		if (themeDict[@"Video"]) {
			theme[@"type"] = @"video";
		} else if (themeDict[@"Image"]) {
			theme[@"type"] = @"image";
		}
		
		
		// calculate the size of the theme ...
		
		double bytes = 0;
		NSString *size = nil;
		NSMutableArray *themeFiles = (NSMutableArray *)[fm contentsOfDirectoryAtURL:folderURL
													  	 includingPropertiesForKeys:keys
														  	 				options:NSDirectoryEnumerationSkipsHiddenFiles
																		  	  error:nil];
		HBLogDebug(@"Contents of folder (%@): %@", folderURL, themeFiles);
		
		for (NSURL *fileURL in themeFiles) {
			size = [fileURL resourceValuesForKeys:keys error:nil][NSURLFileSizeKey];
			bytes += [size doubleValue];
		}
		
		if (bytes < 1024*1024) {
			size = [NSString stringWithFormat:@"%.0f KB", bytes / 1024.0f];
		} else {
			size = [NSString stringWithFormat:@"%.1f MB", bytes / 1024.0f / 1024.f];
		}
		
		theme[@"size"] = size;
		
		
		// store finished theme object
		[themes addObject:theme];
	}
	HBLogDebug(@"Results: %@", themes);
	
	// move bundled themes to the front of the array
	NSMutableArray *tempArray = [themes copy];
	for (NSDictionary *theme in tempArray) {
		if ([theme[@"folder"] isEqualToString:@"Jurassic"] || [theme[@"folder"] isEqualToString:@"Classic"]) {
			[themes removeObject:theme];
			[themes insertObject:theme atIndex:0];
		}
	}
	HBLogDebug(@"Re-Sorted Results: %@", themes);
	
	return themes;
}

- (NSMutableArray *)indexMediaAtPath:(NSString *)path {
	HBLogDebug(@"Indexing media at path (%@)...", path);
	
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
	
	NSMutableArray *files = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
									includingPropertiesForKeys:keys
													   options:NSDirectoryEnumerationSkipsHiddenFiles
														 error:nil];
	HBLogDebug(@"Contents of folder (%@): %@", url, files);
	
	if (!files) {
		HBLogWarn(@"No files.");
		return nil;
	}
	
	// sort files by creation date, newest first
	[files sortUsingComparator:^(NSURL *a, NSURL *b) {
		NSDate *date1 = [[a resourceValuesForKeys:keys error:nil] objectForKey:NSURLContentModificationDateKey];
		NSDate *date2 = [[b resourceValuesForKeys:keys error:nil] objectForKey:NSURLContentModificationDateKey];
		return [date2 compare:date1];
	}];
	
	NSMutableArray *media = [NSMutableArray array];
	
	// add files to array
	for (NSURL *fileURL in files) {
		NSString *file = [fileURL resourceValuesForKeys:keys error:nil][NSURLNameKey];
		NSString *size = [fileURL resourceValuesForKeys:keys error:nil][NSURLFileSizeKey];
		
		if ([size floatValue] < 1024*1024) {
			size = [NSString stringWithFormat:@"%.0f KB", [size floatValue] / 1024.0f];
		} else {
			size = [NSString stringWithFormat:@"%.1f MB", [size floatValue] / 1024.0f / 1024.f];
		}
		
		[media addObject:@{ @"file": file, @"size": size }];
	}
	HBLogDebug(@"Results: %@", media);
	
	return media;
}

// tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kAhAhAhSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	switch (section) {
		case kAhAhAhThemeSection: title = @"Themes";
		break;
		
		case kAhAhAhCustomThemeInfoSection: title = @"Custom";
		break;
		
		case kAhAhAhVideoSection: title = @"Videos";
		break;
		
		case kAhAhAhImageSection: title = @"Images";
		break;
	}
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *title = nil;
	switch (section) {
		case kAhAhAhCustomThemeInfoSection: title = @"Use your own videos or images to customize the alarm. Import media from your Camera Roll, or copy it manually to the locations shown below each section.";
		break;
		
		case kAhAhAhVideoSection: title = @"/User/Library/AhAhAh/Videos";
		break;
		
		case kAhAhAhImageSection: title = @"/User/Library/AhAhAh/Images";
		break;
	}
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger num = 0;
	switch (section) {
		case kAhAhAhThemeSection: num = self.themes.count;
		break;
		
		case kAhAhAhCustomThemeInfoSection: num = 0;
		break;
		
		case kAhAhAhImportSection: num = 1;
		break;

		case kAhAhAhVideoSection: num = self.videos.count;
		break;
		
		case kAhAhAhImageSection: num = self.images.count;
		break;
	}
	return num;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kAhAhAhImportSection) {
		return 44.0f;
	} else {
		return ROW_HEIGHT;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kAhAhAhImportSection) {
		return [self createImportCell];
	} else {
		return [self createMediaCellForIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	HBLogDebug(@"User selected row: %ld, section: %ld", (long)indexPath.row, (long)indexPath.section);
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == kAhAhAhImportSection) { // Import Cell tapped ...
		// launch Media Picker
		[self startPicker];
		
	} else { // Media Cell tapped...
		
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			// already selected, do nothing
			HBLogDebug(@"row is already selected");
		} else {
			
			// clear old selection
			self.selectedTheme = nil;
			self.selectedVideo = nil;
			self.selectedImage = nil;

			// get the file/folder name from the cell title
			UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kAhAhAhTitleTag];
			NSString *title = titleLabel.text;
			
			// store new selection
			switch (indexPath.section) {
				case kAhAhAhThemeSection:
					self.selectedTheme = title;
					break;
				case kAhAhAhVideoSection:
					self.selectedVideo = title;
					break;
				case kAhAhAhImageSection:
					self.selectedImage = title;
					break;
			}
			HBLogDebug(@"self.selectedTheme: %@", self.selectedTheme);
			HBLogDebug(@"self.selectedVideo: %@", self.selectedVideo);
			HBLogDebug(@"self.selectedImage: %@", self.selectedImage);
			
			[self savePrefs:YES];
			[tableView reloadData];
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kAhAhAhThemeSection || indexPath.section == kAhAhAhImportSection) {
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
	HBLogDebug(@"User wants to delete media");
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		if (indexPath.section == kAhAhAhVideoSection) {
			//
			// delete video
			//
			NSString *file = self.videos[indexPath.row][@"file"];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, file];
			HBLogDebug(@"deleting video at path: %@", path);
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			
			if ([file isEqualToString:self.selectedVideo]) {
				self.selectedVideo = nil;
			}

			[self.videos removeObjectAtIndex:indexPath.row];
			
		} else if (indexPath.section == kAhAhAhImageSection) {
			//
			// delete image
			//
			NSString *file = self.images[indexPath.row][@"file"];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_IMAGES_PATH, file];
			HBLogDebug(@"deleting image at path: %@", path);
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			
			if ([file isEqualToString:self.selectedImage]) {
				self.selectedImage = nil;
			}
			
			[self.images removeObjectAtIndex:indexPath.row];
		}
		
		[self savePrefs:YES];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
		[tableView reloadData];
    }
}

// helpers

- (void)savePrefs:(BOOL)notificate {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
	
	if (!prefs) {
		prefs = [NSMutableDictionary dictionary];
	}
	
	// only save one selection ...
	
	if (self.selectedTheme) {
		prefs[@"Theme"] = self.selectedTheme;
		prefs[@"VideoFile"] = nil;
		prefs[@"ImageFile"] = nil;
		
		// check Info.plist for a ContentMode setting
		// NSString *themePath = [THEMES_PATH stringByAppendingPathComponent:self.selectedTheme];
		// NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:[themePath stringByAppendingPathComponent:@"Info.plist"]];
		// if (themeDict[@"ContentMode"]) {
		// 	HBLogDebug(@"Setting content mode for theme (%@) to: %@", self.selectedTheme, themeDict[@"ContentMode"]);
		// 	prefs[@"ContentMode"] = themeDict[@"ContentMode"];
		// }
		
	} else if (self.selectedVideo) {
		prefs[@"Theme"] = nil;
		prefs[@"VideoFile"] = self.selectedVideo;
		prefs[@"ImageFile"] = nil;
		
	} else if (self.selectedImage) {
		prefs[@"Theme"] = nil;
		prefs[@"VideoFile"] = nil;
		prefs[@"ImageFile"] = self.selectedImage;
	}
	
	// reset content mode
	prefs[@"ContentMode"] = @"Default";
	
	HBLogDebug(@"##### Writing Preferences: %@", prefs);
	[prefs writeToFile:PREFS_PLIST_PATH atomically:YES];
	
	// apply settings to tweak
	if (notificate) {
		HBLogDebug(@"notified tweak");
		
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
											 CFSTR("com.sticktron.ahahah.prefschanged"),
											 NULL,
											 NULL,
											 true);
	}
}

- (BOOL)isPathToLastRowInSection:(NSIndexPath *)indexPath {
	if (indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
		return YES;
	}
	return NO;
}

- (UITableViewCell *)createImportCell {
	static NSString *ImportCellIdentifier = @"ImportCell";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ImportCellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									  reuseIdentifier:ImportCellIdentifier];
		cell.opaque = YES;
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		// icon
		NSString *path = [NSString stringWithFormat:@"%@/Import.png", BUNDLE_PATH];
		UIImage *icon = [UIImage imageWithContentsOfFile:path];
		UIImageView *imageView = [[UIImageView alloc] initWithImage:icon];
		CGRect frame = imageView.frame;
		frame.origin = CGPointMake(15.0f, (44.0f - frame.size.height) / 2);
		imageView.frame = frame;
		imageView.opaque = YES;
		[cell.contentView addSubview:imageView];
		
		
		// title
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0f + imageView.frame.size.width, 0, 215.0f, 44.0f)];
		titleLabel.text = @"Import From Camera Roll";
		titleLabel.opaque = YES;
		titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[cell.contentView addSubview:titleLabel];
	}
	return cell;
}

- (UITableViewCell *)createMediaCellForIndexPath:(NSIndexPath *)indexPath {
	static NSString *MediaCellIdentifier = @"MediaCell";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MediaCellIdentifier];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
		   		  					  reuseIdentifier:MediaCellIdentifier];
		cell.opaque = YES;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		// thumbnail
		CGSize size = (CGSize){ THUMBNAIL_SIZE, THUMBNAIL_SIZE };
		CGPoint origin = (CGPoint){ 16.0f, (ROW_HEIGHT - THUMBNAIL_SIZE) / 2 };
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){origin, size}];
		imageView.opaque = YES;
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.tag = kAhAhAhThumbnailTag;
		[cell.contentView addSubview:imageView];
		
		// title
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 17.0f, 215.0f, 16.0f)];
		titleLabel.opaque = YES;
		titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		titleLabel.tag = kAhAhAhTitleTag;
		[cell.contentView addSubview:titleLabel];
		
		// subtitle
		UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 34.0f, 215.0f, 12.0f)];
		subtitleLabel.opaque = YES;
		subtitleLabel.font = [UIFont systemFontOfSize:10.0];
		subtitleLabel.textColor = [UIColor colorWithRed:0.427 green:0.427 blue:0.447 alpha:1]; // #6D6D72
		subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		subtitleLabel.tag = kAhAhAhSubtitleTag;
		[cell.contentView addSubview:subtitleLabel];
	}
	
	
	// configure cell...
	
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kAhAhAhThumbnailTag];
	UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kAhAhAhTitleTag];
	UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:kAhAhAhSubtitleTag];
	
	// ...for Video
	if (indexPath.section == kAhAhAhVideoSection) {
		NSDictionary *video = self.videos[indexPath.row];
		NSString *filename = video[@"file"];
		titleLabel.text = filename;
		subtitleLabel.text = video[@"size"];
		
		// get thumbnail from cache, or else load and cache it in the background
		UIImage *thumbnail = [self.imageCache objectForKey:filename];
		if (thumbnail) {
			imageView.image = thumbnail;
		} else {
			[self.queue addOperationWithBlock:^{
				UIImage *image = [self thumbnailForVideo:filename withMaxSize:imageView.bounds.size];
				if (image) {
					[self.imageCache setObject:image forKey:filename];
					
					// update UI on the main thread
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
						if (cell) {
							UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kAhAhAhThumbnailTag];
							imageView.image = image;
						}
					}];
				}
			}];
		}
		
		if ([self.selectedVideo isEqualToString:video[@"file"]]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
	// ...for Image
} else if (indexPath.section == kAhAhAhImageSection) {
		NSDictionary *image = self.images[indexPath.row];
		NSString *filename = image[@"file"];
		titleLabel.text = filename;
		subtitleLabel.text = image[@"size"];
		
		// get thumbnail from cache, or else load and cache it in the background
		UIImage *thumbnail = [self.imageCache objectForKey:filename];
		if (thumbnail) {
			imageView.image = thumbnail;
		} else {
			[self.queue addOperationWithBlock:^{
				NSString *path = [NSString stringWithFormat:@"%@/%@", USER_IMAGES_PATH, filename];
				UIImage *image = [UIImage imageWithContentsOfFile:path];
				if (image) {
					image = [UIImage imageWithImage:image scaledToMaxWidth:imageView.bounds.size.height
										  maxHeight:imageView.bounds.size.height];
					[self.imageCache setObject:image forKey:filename];
					
					// update UI on main thread
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
						
						if (cell) {
							UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kAhAhAhThumbnailTag];
							imageView.image = image;
						}
					}];
				}
			}];
		}
		
		if ([self.selectedImage isEqualToString:image[@"file"]]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
	// ...for Theme
	} else if (indexPath.section == kAhAhAhThemeSection) {
		NSDictionary *theme = self.themes[indexPath.row];
		NSString *folderName = theme[@"folder"];
		titleLabel.text = folderName;
		subtitleLabel.text = [NSString stringWithFormat:@"%@  |  %@", theme[@"type"], theme[@"size"]];
		NSString *authorName = theme[@"author"];
		if (authorName) {
			subtitleLabel.text = [NSString stringWithFormat:@"%@  |  %@", authorName, subtitleLabel.text];
		}
		
		[self.queue addOperationWithBlock:^{
			NSString *path = [NSString stringWithFormat:@"%@/%@/Thumbnail.png", THEMES_PATH, folderName];
			UIImage *image = [UIImage imageWithContentsOfFile:path];
			if (image) {
				image = [UIImage imageWithImage:image scaledToMaxWidth:imageView.bounds.size.height
									  maxHeight:imageView.bounds.size.height];
				[self.imageCache setObject:image forKey:folderName];
				
				// update UI on main thread
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
					
					if (cell) {
						UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kAhAhAhThumbnailTag];
						imageView.image = image;
					}
				}];
			}
		}];
		
		if ([self.selectedTheme isEqualToString:theme[@"folder"]]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	return cell;
}

- (UIImage *)thumbnailForVideo:(NSString *)filename withMaxSize:(CGSize)size {
	UIImage *thumbnail = nil;
	
	NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, filename];
	NSURL *url = [NSURL fileURLWithPath:path];
	HBLogDebug(@"Requested thumbnail for file at url: %@", url);
	
	AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
	HBLogDebug(@"found asset (%@)", asset);
	
	if (asset) {
		AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
		generator.appliesPreferredTrackTransform = YES;
		
		CMTime time = CMTimeMake(1, 1);
		CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:NULL error:NULL];
		
		UIImage *image = [UIImage imageWithCGImage:imageRef];
		HBLogDebug(@"got thumbnail image (size=%@)", NSStringFromCGSize(image.size));
		
		thumbnail = [UIImage imageWithImage:image scaledToMaxWidth:size.width maxHeight:size.height];
		HBLogDebug(@"scaled thumbnail to size: %@", NSStringFromCGSize(thumbnail.size));
		
		CFRelease(imageRef);
	}
	
	return thumbnail;
}

// image picker

- (BOOL)startPicker {
	HBLogDebug(@"Starting UIImagePicker...");
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) {
		HBLogError(@"Snap! ImagePicker can't access Photo Library!");
		return NO;
	}
	
	// configure picker
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.mediaTypes = @[ (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage ];
	picker.allowsEditing = NO;
	picker.navigationBar.barStyle = UIBarStyleDefault;
	picker.delegate = self;
	
	// present picker
	if (IS_IPAD) {
		if (IS_IOS_OR_NEWER(iOS_8_0)) {
			picker.modalPresentationStyle = UIModalPresentationPopover;
			[self presentViewController:picker animated:YES completion:nil];
			UIPopoverPresentationController *presentationController = [picker popoverPresentationController];
			presentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight;
			presentationController.sourceView = self.tableView;
			presentationController.sourceRect = CGRectZero;
		} else {
			self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
			[self.popover presentPopoverFromRect:CGRectZero inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	} else {
		picker.modalPresentationStyle = UIModalPresentationCurrentContext;
		[self presentViewController:picker animated:YES completion:nil];
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
	HBLogDebug(@"picker returned with this: %@", info);
	
	
	// callback
	ALAssetsLibraryAssetForURLResultBlock resultHandler = ^(ALAsset *asset) {
		NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
		
		if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
			
			// handle image ...
			
			ALAssetRepresentation *imageRep = [asset defaultRepresentation];
			HBLogDebug(@"Picked image asset with representation: %@", imageRep);
			
			NSString *filename = [imageRep filename];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_IMAGES_PATH, filename];
			
			UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
			HBLogDebug(@"image size=%@", NSStringFromCGSize(image.size));
			
			HBLogDebug(@"image orientation=%@", [image orientation]);
			image = [image normalizedImage];
			HBLogDebug(@"normalized image orientation: %@", [image orientation]);
			
			NSData *imageData = UIImagePNGRepresentation(image);
			[imageData writeToFile:path atomically:YES];
			
		} else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
			
			// handle video ...
			
			ALAssetRepresentation *videoRep = [asset defaultRepresentation];
			HBLogDebug(@"Picked video asset with representation: %@", videoRep);
			
			NSString *filename = [videoRep filename];
			
			// save to disk
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, filename];
			NSURL *videoURL = info[UIImagePickerControllerMediaURL];
			NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
			[videoData writeToFile:path atomically:YES];
		}
		
		// reload table data
		[self scanForMedia];
		[self.tableView reloadData];
		
		if (IS_IPAD) {
			[self.popover dismissPopoverAnimated:YES];
		} else {
			[picker dismissViewControllerAnimated:YES completion:nil];
		}
	};
	
	
	// fetch the asset from the library
	NSURL *assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
	ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
	[library assetForURL:assetURL resultBlock:resultHandler failureBlock:nil];
}

- (void)imagePickerControllerDidCancel: (UIImagePickerController *)picker {
	if (IS_IPAD && !IS_IOS_OR_NEWER(iOS_8_0)) {
		[self.popover dismissPopoverAnimated:YES];
	} else {
		[picker dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
