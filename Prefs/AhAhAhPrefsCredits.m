//
//  AhAhAhPrefsCredits.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"
#import <version.h>


/* Credits Controller */

@interface AhAhAhPrefsCreditsController : PSViewController
@end


@implementation AhAhAhPrefsCreditsController

- (instancetype)init {
	if ((self = [super init])) {
		[self setTitle:@"Credits"];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	scrollview.backgroundColor = UIColor.whiteColor;
    scrollview.showsVerticalScrollIndicator = YES;
    scrollview.scrollEnabled = YES;
    scrollview.userInteractionEnabled = YES;
	
	UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Credits.png", BUNDLE_PATH]];
	UIImageView *creditView = [[UIImageView alloc] initWithImage:image];
	creditView.center = CGPointMake(scrollview.center.x, creditView.center.y);
	
	scrollview.contentSize = creditView.bounds.size;
	[scrollview addSubview:creditView];
	
	[self.view addSubview:scrollview];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = TINT_COLOR;
	} else {
		self.navigationController.navigationBar.tintColor = TINT_COLOR;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		self.navigationController.navigationController.navigationBar.tintColor = nil;
	} else {
		self.navigationController.navigationBar.tintColor = nil;
	}
	
	[super viewWillDisappear:animated];
}

@end
