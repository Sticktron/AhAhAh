//
//  AhAhAhPrefsCustomCells.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"


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
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	// overridde the cell style because we want a detail label on the right side
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:arg2 specifier:arg3]) {
		
		// get the initial value for the label from settings...
		
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREFS_PLIST_PATH];
		NSString *selectedTheme = settings[@"Theme"] ?: nil;
		
		if (!selectedTheme) {
			// check for a selected video or background instead...
			
			NSString *selectedVideo = settings[@"VideoFile"] ?: nil;
			NSString *selectedBackground = settings[@"BackgroundFile"] ?: nil;
			
			if (!selectedVideo && !selectedBackground) {
				// nothing has been selected, so auto-select default theme
				selectedTheme = DEFAULT_THEME;
			}
		}
		
		self.detailTextLabel.text = selectedTheme ?: @"Custom Theme";
	}
	return self;
}
@end
