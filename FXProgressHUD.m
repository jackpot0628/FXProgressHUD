//
//  FXProgressHUD.m
//
//  Created by Sam Vermette on 27.03.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/FXProgressHUD
//

#import "FXProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface FXProgressHUD ()

@property (nonatomic, readwrite) FXProgressHUDMaskType maskType;
@property (nonatomic, strong, readonly) NSTimer *fadeOutTimer;

@property (nonatomic, strong, readonly) UIWindow *overlayWindow;
@property (nonatomic, strong, readonly) UIView *hudView;
//@property (nonatomic, strong, readonly) UILabel *stringLabel;
//@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *spinnerView;
@property (nonatomic, strong, readonly) UIImageView *animationImageView;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;

- (void)showWithStatus:(NSString*)string maskType:(FXProgressHUDMaskType)hudMaskType WithAnimationImage:(BOOL)yesOrNo;
//- (void)showWithStatus:(NSString*)string maskType:(FXProgressHUDMaskType)hudMaskType networkIndicator:(BOOL)show;
- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;
- (void)positionHUD:(NSNotification*)notification;

- (void)dismiss;
- (void)dismissWithStatus:(NSString *)string showType:(FXPShowType)FXPShowType;
- (void)dismissWithStatus:(NSString *)string showType:(FXPShowType)FXPShowType afterDelay:(NSTimeInterval)seconds;

@end


@implementation FXProgressHUD

@synthesize overlayWindow, hudView, maskType, fadeOutTimer, spinnerView, visibleKeyboardHeight, animationImageView;

- (void)dealloc {
	self.fadeOutTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (FXProgressHUD*)sharedView {
    static dispatch_once_t once;
    static FXProgressHUD *sharedView;
    dispatch_once(&once, ^ { sharedView = [[FXProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return sharedView;
}


//+ (void)setStatus:(NSString *)string {
//	[[FXProgressHUD sharedView] setStatus:string];
//}

#pragma mark - Show Methods

+ (void)show {
    [[FXProgressHUD sharedView] showWithStatus:nil maskType:FXProgressHUDMaskTypeNone WithAnimationImage:YES];
}

+ (void)showWithStatus:(NSString *)status {
    [[FXProgressHUD sharedView] showWithStatus:status maskType:FXProgressHUDMaskTypeNone WithAnimationImage:NO];
}

+ (void)showWithStatus:(NSString *)status WithAnimationImage:(BOOL)yesOrNo
{
    [[FXProgressHUD sharedView] showWithStatus:status maskType:FXProgressHUDMaskTypeNone WithAnimationImage:yesOrNo];
}

+ (void)showWithStatus:(NSString *)status maskType:(FXProgressHUDMaskType)maskType WithAnimationImage:(BOOL)yesOrNo
{
    [[FXProgressHUD sharedView] showWithStatus:status maskType:maskType WithAnimationImage:yesOrNo];
}

+ (void)showWithMaskType:(FXProgressHUDMaskType)maskType {
    [[FXProgressHUD sharedView] showWithStatus:nil maskType:maskType WithAnimationImage:YES];
}


+ (void)showSuccessWithStatus:(NSString *)string {
    [FXProgressHUD showSuccessWithStatus:string duration:1];
}

+ (void)showSuccessWithStatus:(NSString *)string duration:(NSTimeInterval)duration {
    [FXProgressHUD show];
    [FXProgressHUD dismissWithSuccess:string afterDelay:duration];
}

+ (void)showErrorWithStatus:(NSString *)string {
    [FXProgressHUD showErrorWithStatus:string duration:1];
}

+ (void)showErrorWithStatus:(NSString *)string duration:(NSTimeInterval)duration {
    [FXProgressHUD show];
    [FXProgressHUD dismissWithError:string afterDelay:duration];
}

+ (void)showDefWithStatus:(NSString *)string {
    [FXProgressHUD showDefWithStatus:string duration:1];
}

+ (void)showDefWithStatus:(NSString *)string duration:(NSTimeInterval)duration {
    [FXProgressHUD showWithStatus:string WithAnimationImage:NO];
    [FXProgressHUD dismissAfterDelay:duration];
}


#pragma mark - Dismiss Methods

+ (void)dismiss {
	[[FXProgressHUD sharedView] dismiss];
}

+ (void)dismissAfterDelay:(NSTimeInterval)seconds {
    [NSTimer scheduledTimerWithTimeInterval:seconds target:[FXProgressHUD sharedView] selector:@selector(dismiss) userInfo:nil repeats:NO];
}

+ (void)dismissWithSuccess:(NSString*)successString {
	[[FXProgressHUD sharedView] dismissWithStatus:successString showType:FXPShowSuccess];
}

+ (void)dismissWithSuccess:(NSString *)successString afterDelay:(NSTimeInterval)seconds {
    [[FXProgressHUD sharedView] dismissWithStatus:successString showType:FXPShowSuccess afterDelay:seconds];
}

+ (void)dismissWithError:(NSString*)errorString {
	[[FXProgressHUD sharedView] dismissWithStatus:errorString showType:FXPShowError];
}

+ (void)dismissWithError:(NSString *)errorString afterDelay:(NSTimeInterval)seconds {
    [[FXProgressHUD sharedView] dismissWithStatus:errorString showType:FXPShowError afterDelay:seconds];
}

+ (void)dismissWithDef:(NSString *)string {
    [[FXProgressHUD sharedView] dismissWithStatus:string showType:FXPShowDef];
}

+ (void)dismissWithDef:(NSString *)string afterDelay:(NSTimeInterval)seconds {
    [[FXProgressHUD sharedView] dismissWithStatus:string showType:FXPShowDef afterDelay:seconds];
}


#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.maskType = FXProgressHUDMaskTypeClear; // 显示模式
    }
	
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    switch (self.maskType) {
            
        case FXProgressHUDMaskTypeBlack: {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
            
        case FXProgressHUDMaskTypeGradient: {
            
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f}; 
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
            float radius = MIN(self.bounds.size.width , self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
            break;
        }
    }
}

- (void)setStatus:(NSString *)string {
	
    CGFloat hudWidth = 120;
    CGFloat hudHeight = 100;
    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    CGRect labelRect = CGRectZero;
    
    self.hudView.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
    
    if([string length])
    {
        CGSize stringSize = [string sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(200, 300)];
        stringWidth = stringSize.width;
        stringHeight = stringSize.height;
        hudHeight = 60+stringHeight;
        
        if(stringWidth > hudWidth)
            hudWidth = ceil(stringWidth/2)*2;
        
        if(hudHeight > 120) {
            labelRect = CGRectMake(12, hudHeight - stringHeight - 10, hudWidth, stringHeight);
            hudWidth+=24;
        } else {
            hudWidth+=24;
            labelRect = CGRectMake(0, hudHeight - stringHeight - 10, hudWidth, stringHeight);
        }
        
        self.hudView.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
        
        self.imageView.center = CGPointMake(hudWidth / 2, hudHeight / 2 - self.imageView.frame.size.height / 2);
        
        self.animationImageView.center = CGPointMake(hudWidth / 2, hudHeight / 2 - self.animationImageView.frame.size.height / 2);
    }
    else
    {
        self.imageView.center = CGPointMake(hudWidth / 2, hudHeight / 2 - self.imageView.frame.size.height / 2);
        
        self.animationImageView.center = CGPointMake(hudWidth / 2, hudHeight / 2);
    }
    
    [self.stringLabel setFrame:labelRect];
    
    if (self.imageView.hidden == YES && self.animationImageView.hidden == YES)
    {
        [self.stringLabel setCenter:CGPointMake(hudWidth/2, hudHeight / 2)];
    }
    
    [self.stringLabel setText:string];
//    NSLog(@"StringLabelFrame: - %@ - ",NSStringFromCGRect(self.stringLabel.frame));

}

- (void)setFadeOutTimer:(NSTimer *)newTimer {
    
    if(fadeOutTimer)
        [fadeOutTimer invalidate], fadeOutTimer = nil;
    
    if(newTimer)
        fadeOutTimer = newTimer;
}


- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification 
                                               object:nil];  
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}


- (void)positionHUD:(NSNotification*)notification {
    
    CGFloat keyboardHeight;
    double animationDuration = 0.0;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [[keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [[keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            if(UIInterfaceOrientationIsPortrait(orientation))
                keyboardHeight = keyboardFrame.size.height;
            else
                keyboardHeight = keyboardFrame.size.width;
        } else
            keyboardHeight = 0;
    } else {
        keyboardHeight = self.visibleKeyboardHeight;
    }
    
    CGRect orientationFrame = [UIScreen mainScreen].bounds;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        float temp = orientationFrame.size.width;
        orientationFrame.size.width = orientationFrame.size.height;
        orientationFrame.size.height = temp;
        
        temp = statusBarFrame.size.width;
        statusBarFrame.size.width = statusBarFrame.size.height;
        statusBarFrame.size.height = temp;
    }
    
    CGFloat activeHeight = orientationFrame.size.height;
    
    if(keyboardHeight > 0)
        activeHeight += statusBarFrame.size.height*2;
    
    activeHeight -= keyboardHeight;
    CGFloat posY = floor(activeHeight*0.45);
    CGFloat posX = orientationFrame.size.width/2;
    
    CGPoint newCenter;
    CGFloat rotateAngle;
    
    switch (orientation) { 
        case UIInterfaceOrientationPortraitUpsideDown:
            rotateAngle = M_PI; 
            newCenter = CGPointMake(posX, orientationFrame.size.height-posY);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotateAngle = -M_PI/2.0f;
            newCenter = CGPointMake(posY, posX);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotateAngle = M_PI/2.0f;
            newCenter = CGPointMake(orientationFrame.size.height-posY, posX);
            break;
        default: // as UIInterfaceOrientationPortrait
            rotateAngle = 0.0;
            newCenter = CGPointMake(posX, posY);
            break;
    } 
    
    if(notification) {
        [UIView animateWithDuration:animationDuration
                              delay:0 
                            options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
                         } completion:NULL];
    } 
    
    else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
    }
    
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.hudView.transform = CGAffineTransformMakeRotation(angle); 
    self.hudView.center = newCenter;
}

#pragma mark - Master show/dismiss methods

- (void)showWithStatus:(NSString*)string maskType:(FXProgressHUDMaskType)hudMaskType WithAnimationImage:(BOOL)yesOrNo
{
    [self.imageView setHidden:YES];
    if (yesOrNo == YES)
    {
        [self.animationImageView setHidden:NO];
        [self.animationImageView startAnimating];
        [self.hudView setBackgroundColor:[UIColor clearColor]];
        [self.stringLabel setTextColor:[UIColor whiteColor]];
    }
    else
    {
        [self.animationImageView setHidden:YES];
        [self.animationImageView stopAnimating];
        [self.hudView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
        [self.stringLabel setTextColor:CUSTOM_ORANGE_COLOR_HIGHLIGHTED];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{ 
        if(!self.superview)
        {
            [self.overlayWindow addSubview:self];
        }
        
        self.fadeOutTimer = nil;
        
        self.maskType = hudMaskType;
        
        if(self.maskType != FXProgressHUDMaskTypeNone)
        {
            self.overlayWindow.userInteractionEnabled = YES;
        }
        else
        {
            self.overlayWindow.userInteractionEnabled = NO;
        }
        
        [self.overlayWindow makeKeyAndVisible];
        [self positionHUD:nil];
        
//        [self.spinnerView stopAnimating];
        [self setStatus:string];

        
        if(self.alpha != 1)
        {
            [self registerNotifications];
            self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.1, 1.1);
            
            [UIView animateWithDuration:0.15
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.1, 1/1.1);
                                 self.alpha = 1;
                             }
                             completion:NULL];
        }
        

        
        [self setNeedsDisplay];
    });
}


- (void)dismissWithStatus:(NSString*)string showType:(FXPShowType)FXPShowType {
	[self dismissWithStatus:string showType:FXPShowType afterDelay:1.0];
}


- (void)dismissWithStatus:(NSString *)string showType:(FXPShowType)FXPShowType afterDelay:(NSTimeInterval)seconds {
    
//    [self.imageView setHidden:YES];
    
    [self.animationImageView stopAnimating];
    [self.animationImageView setHidden:YES];
    [self.hudView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
    [self.stringLabel setTextColor:CUSTOM_ORANGE_COLOR_HIGHLIGHTED];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        switch (FXPShowType)
        {
            case FXPShowError:
            {
                self.imageView.image = [UIImage imageNamed:@"FXProgressHUD.bundle/error.png"];
                [self.imageView setHidden:NO];
            }
                break;
            case FXPShowSuccess:
            {
                self.imageView.image = [UIImage imageNamed:@"FXProgressHUD.bundle/success.png"];
                [self.imageView setHidden:NO];
            }
                break;
            case FXPShowDef:
            {
                [self.imageView setHidden:YES];
            }
                break;
            default:
                break;
        }
        
        [self setStatus:string];
//        [self.spinnerView stopAnimating];
        
        self.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismiss {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{	
                             self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 0.6, 0.6);
                             self.alpha = 0;
                         }
                         completion:^(BOOL finished){ 
                             if(self.alpha == 0) {
                                 [[NSNotificationCenter defaultCenter] removeObserver:self];
                                 [hudView removeFromSuperview];
                                 hudView = nil;
                                 
                                 // Make sure to remove the overlay window from the list of windows
                                 // before trying to find the key window in that same list
                                 NSMutableArray *windows = [[NSMutableArray alloc] initWithArray:[UIApplication sharedApplication].windows];
                                 [windows removeObject:overlayWindow];
                                 overlayWindow = nil;
                                 
                                 [windows enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIWindow *window, NSUInteger idx, BOOL *stop) {
                                   if([window isKindOfClass:[UIWindow class]] && window.windowLevel == UIWindowLevelNormal) {
                                     [window makeKeyWindow];
                                     *stop = YES;
                                   }
                                 }];
                                 
                                 // uncomment to make sure UIWindow is gone from app.windows
                                 //NSLog(@"%@", [UIApplication sharedApplication].windows);
                                 //NSLog(@"keyWindow = %@", [UIApplication sharedApplication].keyWindow);
                                 
                             }
                         }];
    });
    
    
    
}

#pragma mark - Utilities

+ (BOOL)isVisible {
    return ([FXProgressHUD sharedView].alpha > 0.5);
}


#pragma mark - Getters

- (UIWindow *)overlayWindow {
    if(!overlayWindow) {
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = NO;
    }
    return overlayWindow;
}

- (UIView *)hudView {
    if(!hudView) {
        hudView = [[UIView alloc] initWithFrame:CGRectZero];
        hudView.layer.cornerRadius = 5.0;
//        hudView.backgroundColor = [UIColor clearColor];
		hudView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        hudView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
        
        hudView.layer.shadowColor = [UIColor blackColor].CGColor;
        hudView.layer.shadowOffset = CGSizeMake(0, 0);
        hudView.layer.shadowOpacity = 0.8;
        
        self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 28, 28)];
        [self.imageView setHidden:YES];
        [hudView addSubview:self.imageView];
        
        self.stringLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        self.stringLabel.textColor = CUSTOM_ORANGE_COLOR_HIGHLIGHTED;
		self.stringLabel.backgroundColor = [UIColor clearColor];
		self.stringLabel.adjustsFontSizeToFitWidth = YES;
        
        self.stringLabel.textAlignment = NSTextAlignmentCenter;
        
		self.stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.stringLabel.font = [UIFont systemFontOfSize:15.0];
        self.stringLabel.numberOfLines = 0;
        [hudView addSubview:self.stringLabel];

    }
    [self addSubview:hudView];
    
    return hudView;
}

//- (UILabel *)stringLabel {
//    if (stringLabel == nil) {
//        stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//		stringLabel.textColor = CUSTOM_ORANGE_COLOR_HIGHLIGHTED;
//		stringLabel.backgroundColor = [UIColor clearColor];
//		stringLabel.adjustsFontSizeToFitWidth = YES;
//    
//        stringLabel.textAlignment = NSTextAlignmentCenter;
//        
//		stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
//		stringLabel.font = [UIFont systemFontOfSize:15.0];
////		stringLabel.shadowColor = [UIColor blackColor];
////		stringLabel.shadowOffset = CGSizeMake(0, 0);
//        stringLabel.numberOfLines = 0;
//    }
//    
//    if(!stringLabel.superview)
//    {
//        [self.hudView addSubview:stringLabel];
//    }
//    
//    return stringLabel;
//}

/**
 *	@brief	自定义动画效果
 *
 *	@return UIImageView
 */
- (UIImageView *)animationImageView

{
    if (animationImageView == nil)
    {
        animationImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
        animationImageView.animationImages = [NSArray arrayWithObjects:
                                              [UIImage imageNamed:@"bus_loading_1.png"],
                                              [UIImage imageNamed:@"bus_loading_2.png"],
                                              [UIImage imageNamed:@"bus_loading_3.png"],
                                              [UIImage imageNamed:@"bus_loading_4.png"],
                                              [UIImage imageNamed:@"bus_loading_5.png"],
                                              [UIImage imageNamed:@"bus_loading_6.png"],
                                              [UIImage imageNamed:@"bus_loading_7.png"],
                                              [UIImage imageNamed:@"bus_loading_8.png"],nil];
        animationImageView.animationDuration = 1.1;
        animationImageView.animationRepeatCount = 0;
        [animationImageView setHidden:YES];
    }
    
    if (!animationImageView.superview)
    {
        [self.hudView addSubview:animationImageView];
    }
    
    return animationImageView;
}


- (UIActivityIndicatorView *)spinnerView {
    if (spinnerView == nil) {
        spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		spinnerView.hidesWhenStopped = YES;
		spinnerView.bounds = CGRectMake(0, 0, 45, 45);
    }
    
    if(!spinnerView.superview)
        [self.hudView addSubview:spinnerView];
    
    return spinnerView;
}

- (CGFloat)visibleKeyboardHeight {
        
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }

    // Locate UIKeyboard.  
    UIView *foundKeyboard = nil;
    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews]) {
        
        // iOS 4 sticks the UIKeyboard inside a UIPeripheralHostView.
        if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
            possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
        }                                                                                
        
        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
            foundKeyboard = possibleKeyboard;
            break;
        }
    }
        
    if(foundKeyboard && foundKeyboard.bounds.size.height > 100)
        return foundKeyboard.bounds.size.height;
    
    return 0;
}

@end
