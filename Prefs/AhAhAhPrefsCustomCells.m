//
//  AhAhAhPrefsCustomCells.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"


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
	
	// if I do this at init it doesn't stick :(
	[self.textLabel setTextColor:LINK_COLOR];
}
@end


//------------------------------------------------------------------------------


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

