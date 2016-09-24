//
//  AhAhAhPrefsCustom.m
//  Preferences for Ah!Ah!Ah!
//
//  Custom cells and UI style overrides.
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "../Common.h"
#import "Prefs.h"


/* Logo Cell */

@interface AhAhAhLogoCell : PSTableCell
@property (nonatomic, strong) UIImageView *logoView;
@end

@implementation AhAhAhLogoCell
- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:@"LogoCell"
					  specifier:specifier];
	
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		
		NSString *path = [NSString stringWithFormat:@"%@/Logo.png", BUNDLE_PATH];
		UIImage *logo = [UIImage imageWithContentsOfFile:path];
		UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
		logoView.center = self.contentView.center;
		logoView.contentMode = UIViewContentModeCenter;
		logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		[self.contentView addSubview:logoView];
	}
	return self;
}
- (CGFloat)preferredHeightForWidth:(CGFloat)height {
	return 100.0f;
}
@end


//------------------------------------------------------------------------------


/* Tinted Switch Cell */

@interface AhAhAhSwitchCell : PSSwitchTableCell
@end

@implementation AhAhAhSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:TINT_COLOR];
	}
	return self;
}
@end


//------------------------------------------------------------------------------


/* Tinted Button Cell */

@interface AhAhAhButtonCell : PSTableCell
@end

@implementation AhAhAhButtonCell
- (void)layoutSubviews {
	[super layoutSubviews];
	[self.textLabel setTextColor:LINK_COLOR];
}
@end


//------------------------------------------------------------------------------


/* Tinter Slider Cell */
@interface AhAhAhSliderCell : PSSliderTableCell
@end

@implementation AhAhAhSliderCell
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	if (self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3]) {
		UISlider *slider = (UISlider *)self.control;
		
		//slider.thumbTintColor = PINK;
		slider.minimumTrackTintColor = TINT_COLOR;
		//slider.maximumTrackTintColor = PURPLE;
		
		// UIControlEventValueChanged isn't firing continuously, so I'm using TouchDragInside instead
		[slider addTarget:self.specifier.target action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchDragInside];
	}
	return self;
}
@end


//------------------------------------------------------------------------------


/* Add value label to Theme Controller Link Cell */

@interface AhAhAhThemeLinkCell : PSTableCell
@end

@implementation AhAhAhThemeLinkCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	
	// overridde the cell style because we want a detail label on the right side ...
	
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier specifier:specifier]) {
		HBLogDebug(@"getting value for detail label...");
		
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		NSString *selectedTheme = settings[@"Theme"] ?: nil;
		HBLogDebug(@"selected theme is: %@", selectedTheme);
		
		if (!selectedTheme) {
			HBLogDebug(@"no selected theme, is there a custom selection instead?");
			
			NSString *selectedVideo = settings[@"VideoFile"] ?: nil;
			NSString *selectedImage = settings[@"ImageFile"] ?: nil;
			HBLogDebug(@"selectedVideo = %@", selectedVideo);
			HBLogDebug(@"selectedImage = %@", selectedImage);
			
			if (!(selectedVideo || selectedImage)) {
				HBLogDebug(@"no setting yet, setting to default theme: %@", DEFAULT_THEME);
				selectedTheme = DEFAULT_THEME;
			}
		}
		
		self.detailTextLabel.text = selectedTheme ?: @"Custom";
	}
	return self;
}
@end


//------------------------------------------------------------------------------


/* Tinted List Items Controller */

@interface AhAhAhListItemsController : PSListItemsController
@end

@implementation AhAhAhListItemsController
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// tint checkmarks
	[[self table] setTintColor:TINT_COLOR];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// tint navbar
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = TINT_COLOR;
	} else {
		self.navigationController.navigationBar.tintColor = TINT_COLOR;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	// un-tint navbar
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = nil;
	} else {
		self.navigationController.navigationBar.tintColor = nil;
	}
	
	[super viewWillDisappear:animated];
}

@end
