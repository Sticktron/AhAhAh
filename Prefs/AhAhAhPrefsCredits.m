//
//  AhAhAhPrefsCredits.m
//  Preferences for Ah!Ah!Ah!
//
//  Copyright (c) 2014-2016 Sticktron. All rights reserved.
//
//

#import "Common.h"


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
	//creditView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;	
	creditView.center = CGPointMake(scrollview.center.x, creditView.center.y);
	
	scrollview.contentSize = creditView.bounds.size;
	[scrollview addSubview:creditView];
	
	[self.view addSubview:scrollview];
}

@end



