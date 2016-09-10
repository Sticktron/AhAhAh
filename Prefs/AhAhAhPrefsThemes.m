//
//  AhAhAhPrefsTheme.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"

#import <Preferences/PSViewController.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>


#define THEMES_PATH				@"/Library/AhAhAh/Themes"
#define USER_VIDEOS_PATH		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Videos"]
#define USER_BACKGROUNDS_PATH	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/AhAhAh/Backgrounds"]

#define THUMBNAIL_SIZE			40.0f
#define ROW_HEIGHT				60.0f

#define ID_NONE			@"_none"
#define ID_DEFAULT		@"_default"
#define ID_KEVIN		@"_kevin"
#define ID_DEX			@"_dex"

typedef NS_ENUM(NSInteger, AhAhAhSection) {
    kAhAhAhThemeSection 	 = 0,
    kAhAhAhVideoSection 	 = 1,
    kAhAhAhBackgroundSection = 2
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


/* Theme Controller */

@interface AhAhAhPrefsThemeController : PSViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *themes;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) NSMutableArray *backgrounds;
@property (nonatomic, strong) NSString *selectedTheme;
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


@implementation AhAhAhPrefsThemeController

- (instancetype)init {
	self = [super init];
	
	if (self) {
		[self setTitle:@"Customize"];
		
		_queue = [[NSOperationQueue alloc] init];
		_queue.maxConcurrentOperationCount = 4;
		_imageCache = [[NSCache alloc] init];
		
		// @[ @{ folder:abc, title:def, author:ghi }, ... ]
		_themes = nil;
		
		// [( @{ file:abc, size:123 }, ... ]
		_backgrounds = nil;
		_videos = nil;
		
		// load user prefs...
		
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		DebugLog(@"Read user prefs: %@", prefs);
		_selectedTheme = prefs[@"Theme"] ?: nil;
		_selectedVideo = prefs[@"VideoFile"] ?: nil;
		_selectedBackground = prefs[@"BackgroundFile"] ?: nil;
				
		// create directories for user media (if needed)...
		
		[[NSFileManager defaultManager] createDirectoryAtPath:USER_BACKGROUNDS_PATH
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
	self.tableView.rowHeight = ROW_HEIGHT;
	self.tableView.tintColor = TINT_COLOR;
	
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

// data model

- (void)scanForMedia {
	DebugLog0;
		
	self.videos = [self indexMediaAtPath:USER_VIDEOS_PATH];
	DebugLog(@"self.videos = %@", self.videos);	
	
	self.backgrounds = [self indexMediaAtPath:USER_BACKGROUNDS_PATH];
	DebugLog(@"self.backgrounds = %@", self.backgrounds);
	
	self.themes = [self indexThemes];
	DebugLog(@"self.themes = %@", self.themes);
}

- (NSMutableArray *)indexThemes {
	DebugLog0;
	
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *url = [NSURL fileURLWithPath:THEMES_PATH isDirectory:YES];	
	NSMutableArray *folders = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
												  includingPropertiesForKeys:keys
													  				 options:NSDirectoryEnumerationSkipsHiddenFiles
																	   error:nil];
	DebugLog(@"Contents of (%@): %@", url, folders);
	
	if (!folders) {
		HBLogError(@"Default Themes are missing! Suggest re-installing the package.");
		return nil;
	}
	
	// sort folders by name
	[folders sortUsingComparator:^(NSURL *a, NSURL *b) {
		return [a.lastPathComponent compare:b.lastPathComponent];
	}];
		
	// build index...
	
	NSMutableArray *themes = [NSMutableArray array];
	
	for (NSURL *folderURL in folders) {
		NSString *folder = [folderURL resourceValuesForKeys:keys error:nil][NSURLNameKey];
		//NSString *size = [folderURL resourceValuesForKeys:keys error:nil][NSURLFileSizeKey];
		[themes addObject:@{ @"folder": folder, @"size": @"Video & Background" }];
	}
	DebugLog(@"Results: %@", themes);
	
	return themes;
}

- (NSMutableArray *)indexMediaAtPath:(NSString *)path {
	DebugLog0;
	
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
	
	NSMutableArray *files = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
									includingPropertiesForKeys:keys
													   options:NSDirectoryEnumerationSkipsHiddenFiles
														 error:nil];
	DebugLog(@"Contents of (%@): %@", url, files);
	
	if (!files) {
		DebugLog(@"No files.");
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
	DebugLog(@"Results: %@", media);
	return media;
}


// tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	
	switch (section) {
		case kAhAhAhThemeSection: title = @"Themes";
		break;
		
		case kAhAhAhVideoSection: title = @"Your Videos";
		break;
		
		case kAhAhAhBackgroundSection: title = @"Your Backgrounds";
		break;
	}
	
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger num = 0;
	
	switch (section) {
		case kAhAhAhThemeSection: num = self.themes.count;
			break;
		case kAhAhAhVideoSection: num = self.videos.count + 1; // add extra row for Import Cell
			break;
		case kAhAhAhBackgroundSection: num = self.backgrounds.count + 1; // add extra row for Import Cell
			break;
	}
	
	return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// for the last row in the Video and Background sections,
	// make Import cells...
	if ([self isPathToLastRowInSection:indexPath]) {
		if (indexPath.section == kAhAhAhVideoSection || indexPath.section == kAhAhAhBackgroundSection) {			
			return [self createImportCell];
		}
	}
	
	// for the rest, make Media Item cells...
	return [self createMediaCellForIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == kAhAhAhThemeSection) {
		return @"Themes can be found in Cydia, or copied to /Library/AhAhAh/Themes.";
	} else {
		return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DebugLog(@"User selected row: %ld, section: %ld", (long)indexPath.row, (long)indexPath.section);
	
	// Import Cell tapped, launch Media Picker...	
	if ([self isPathToLastRowInSection:indexPath]) {
		if (indexPath.section == kAhAhAhVideoSection || indexPath.section == kAhAhAhBackgroundSection) {
			[self startPicker];
		}
	
	// Media Cell tapped, select it...		
	} else {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];		
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {			
			
			// was already selected, uncheck cell...
			
			cell.accessoryType = UITableViewCellAccessoryNone;
			
			switch (indexPath.section) {
				case kAhAhAhVideoSection:
					self.selectedVideo = ID_NONE;
					break;
				case kAhAhAhBackgroundSection:
					self.selectedBackground = ID_NONE;
					break;
				case kAhAhAhThemeSection:
					self.selectedTheme = ID_NONE;
			}
			
		} else {
			
			// new selection, check cell...
			
			// uncheck old selection
			for (NSInteger i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
				NSIndexPath	 *path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:path];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			
			// get the file/folder name from the cell title
			UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kAhAhAhTitleTag];
			NSString *title = titleLabel.text;
			
			// store selection
			switch (indexPath.section) {
				case kAhAhAhVideoSection:
					self.selectedVideo = title;
					DebugLog(@"selected video: %@", self.selectedVideo);
					break;
				case kAhAhAhBackgroundSection:
					self.selectedBackground = title;
					DebugLog(@"selected background: %@", self.selectedBackground);
					break;
				case kAhAhAhThemeSection:
					self.selectedTheme = title;
					DebugLog(@"selected theme: %@", self.selectedTheme);
			}
		}
		
		[self savePrefs:YES];
		[tableView reloadData];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kAhAhAhThemeSection) {
		return NO;
	}
	
	if ([self isPathToLastRowInSection:indexPath]) {
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
		
		if (indexPath.section == kAhAhAhVideoSection) {
			//
			// delete video
			//
			NSString *file = self.videos[indexPath.row][@"file"];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_VIDEOS_PATH, file];
			DebugLog(@"deleting video at path: %@", path);
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			
			// if row was checked, check the default row instead
			if ([file isEqualToString:self.selectedVideo]) {
				self.selectedVideo = ID_DEFAULT;
			}
			
			[self.videos removeObjectAtIndex:indexPath.row];
			
		} else if (indexPath.section == kAhAhAhBackgroundSection) {
			//
			// delete image
			//
			NSString *file = self.backgrounds[indexPath.row][@"file"];
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, file];
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

// helpers

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
		
		// title
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 21.0f, 215.0f, 16.0f)];
		titleLabel.text = @"Import From Camera Roll";
		titleLabel.opaque = YES;
		titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
		titleLabel.textColor = LINK_COLOR;
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[cell.contentView addSubview:titleLabel];

		// icon
		CGSize size = (CGSize){ THUMBNAIL_SIZE, THUMBNAIL_SIZE };
		CGPoint origin = (CGPoint){ 16.0f, (ROW_HEIGHT - THUMBNAIL_SIZE) / 2 };
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){origin, size}];
		imageView.opaque = YES;
		imageView.contentMode = UIViewContentModeCenter;
		NSString *path = [NSString stringWithFormat:@"%@/Import.png", BUNDLE_PATH];
		UIImage *icon = [UIImage imageWithContentsOfFile:path];
		imageView.image = icon;
		[cell.contentView addSubview:imageView];
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
		subtitleLabel.font = [UIFont italicSystemFontOfSize:10.0];
		subtitleLabel.textColor = LINK_COLOR;
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
		
	// ...for Background
	} else if (indexPath.section == kAhAhAhBackgroundSection) {		
		NSDictionary *background = self.backgrounds[indexPath.row];		
		NSString *filename = background[@"file"];
		titleLabel.text = filename;
		subtitleLabel.text = background[@"size"];
		
		// get thumbnail from cache, or else load and cache it in the background...		
		UIImage *thumbnail = [self.imageCache objectForKey:filename];
		if (thumbnail) {
			imageView.image = thumbnail;			
		} else {
			[self.queue addOperationWithBlock:^{
				NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, filename];
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
		
		if ([self.selectedBackground isEqualToString:background[@"file"]]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
	// ...for Theme
	} else if (indexPath.section == kAhAhAhThemeSection) {
		NSDictionary *theme = self.themes[indexPath.row];
		NSString *folderName = theme[@"folder"];
		titleLabel.text = folderName;
		subtitleLabel.text = theme[@"size"];
		
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

- (NSMutableArray *)loadMediaAtPath:(NSString *)path {
	NSArray *keys = @[ NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLNameKey ];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
	
	NSMutableArray *files = (NSMutableArray *)[fm contentsOfDirectoryAtURL:url
									includingPropertiesForKeys:keys
													   options:NSDirectoryEnumerationSkipsHiddenFiles
														 error:nil];
	DebugLog(@"Contents of (%@): %@", url, files);
	
	if (!files) {
		DebugLog(@"No files.");
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
	DebugLog(@"Results: %@", media);
	return media;
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
			NSString *path = [NSString stringWithFormat:@"%@/%@", USER_BACKGROUNDS_PATH, filename];
			
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

@end

