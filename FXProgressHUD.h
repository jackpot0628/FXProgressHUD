//
//  FXProgressHUD.h
//
//  Created by Sam Vermette on 27.03.11. Remake by Raynor
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/FXProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

enum {
    FXProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    FXProgressHUDMaskTypeClear, // don't allow
    FXProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    FXProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger FXProgressHUDMaskType;

enum {
    FXPShowError,
    FXPShowSuccess,
    FXPShowDef
};

typedef NSUInteger FXPShowType;

@interface FXProgressHUD : UIView

@property (strong, nonatomic) UIImageView * imageView;
@property (strong, nonatomic) UILabel * stringLabel;

+ (void)show;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString *)status WithAnimationImage:(BOOL)yesOrNo;
+ (void)showWithStatus:(NSString *)status maskType:(FXProgressHUDMaskType)maskType WithAnimationImage:(BOOL)yesOrNo;
+ (void)showWithMaskType:(FXProgressHUDMaskType)maskType;

+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showSuccessWithStatus:(NSString *)string duration:(NSTimeInterval)duration;
+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showErrorWithStatus:(NSString *)string duration:(NSTimeInterval)duration;
+ (void)showDefWithStatus:(NSString *)string;
+ (void)showDefWithStatus:(NSString *)string duration:(NSTimeInterval)duration;

//+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

+ (void)dismiss; // simply dismiss the HUD with a fade+scale out animation
+ (void)dismissAfterDelay:(NSTimeInterval)seconds;
+ (void)dismissWithSuccess:(NSString*)successString; // also displays the success icon image
+ (void)dismissWithSuccess:(NSString*)successString afterDelay:(NSTimeInterval)seconds;
+ (void)dismissWithError:(NSString*)errorString; // also displays the error icon image
+ (void)dismissWithError:(NSString*)errorString afterDelay:(NSTimeInterval)seconds;
+ (void)dismissWithDef:(NSString *)string;
+ (void)dismissWithDef:(NSString *)string afterDelay:(NSTimeInterval)seconds;

+ (BOOL)isVisible;

@end
