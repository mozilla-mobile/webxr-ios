#import "MessageController.h"
#import <PopupDialog/PopupDialog-Swift.h>

#warning DESIGN, LOCALIZATION

@interface MessageController ()
@property(nonatomic, weak) UIViewController *viewController;
@property(nonatomic, weak) PopupDialog *arPopup;
@end

@implementation MessageController

- (void)dealloc
{
    DDLogDebug(@"MessageController dealloc");
}

- (instancetype)initWithViewController:(UIViewController *)vc
{
    self = [super init];
    
    if (self)
    {
        [self setViewController:vc];
        
        [self setupAppearance];
    }
    
    return self;
}

- (BOOL)arMessageShowing
{
    return [self arPopup] != nil;
}

- (void)showMessageAboutWebError:(NSError *)error withCompletion:(void(^)(BOOL reload))reloadCompletion;
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Can not open the page"
                                                    message:@"Please check the URL and try again"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                           gestureDismissal:NO
                                                 completion:^{ }];
    
    DestructiveButton *cancel = [[DestructiveButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                                 {
                                     reloadCompletion(NO);
                                     
                                     [self didHideMessageByUser]();
                                 }];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Reload" height:40 dismissOnTap:YES action:^
                         {
                             reloadCompletion(YES);
                             
                             [self didHideMessageByUser]();
                         }];
    
    [popup addButtons: @[cancel, ok]];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    [self didShowMessage]();
}

- (void)showMessageAboutARInteruption:(BOOL)interupt
{
    if (interupt && _arPopup == nil)
    {
        PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"AR Interruption Occurred"
                                                        message:@"Please wait, it would be fixed automatically"
                                                          image:nil
                                                buttonAlignment:UILayoutConstraintAxisHorizontal
                                                transitionStyle:PopupDialogTransitionStyleBounceUp
                                               gestureDismissal:NO
                                                     completion:^{ }];
        
        [self setArPopup:popup];
        
        [[self viewController] presentViewController:popup animated:YES completion:nil];
        
        [self didShowMessage]();
    }
    else if (interupt == NO && _arPopup)
    {
        [_arPopup dismissViewControllerAnimated:YES completion:NULL];
        
        [self setArPopup:nil];
        
        [self didHideMessage]();
    }
}

- (void)showMessageAboutFailSessionWithCompletion:(void(^)(void))completion
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"ARSession Failed"
                                                    message:@"Tap 'Ok' to restart the session"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                           gestureDismissal:NO
                                                 completion:^{ }];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                         {
                             [popup dismissViewControllerAnimated:YES completion:NULL];
                             
                             [self didHideMessageByUser]();
                             
                             completion();
                         }];
    
    [popup addButtons: @[ok]];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    [self didShowMessage]();
    
}

- (void)showMessageAboutMemoryWarning
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Memory Issue Occurred"
                                                    message:@"There was not enough memory for the application to keep working. Webpage was reloaded"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                           gestureDismissal:NO
                                                 completion:^{ }];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                         {
                             [popup dismissViewControllerAnimated:YES completion:NULL];
                             
                             [self didHideMessageByUser]();
                         }];
    
    [popup addButtons: @[ok]];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    [self didShowMessage]();
}

- (void)showMessageAboutConnectionRequired
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Internet connection is not available now"
                                                    message:@"Application will be started automatically when connection become available"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                           gestureDismissal:NO
                                                 completion:^{ }];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                         {
                             [popup dismissViewControllerAnimated:YES completion:NULL];
                             
                             [self didHideMessageByUser]();
                         }];
    
    [popup addButtons: @[ok]];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    [self didShowMessage]();
}

#pragma mark private

- (void)setupAppearance
{
    [PopupDialogDefaultView appearance].backgroundColor = [UIColor clearColor];
    [PopupDialogDefaultView appearance].titleFont = [UIFont fontWithName:@"Myriad Pro Regular" size:14];
    [PopupDialogDefaultView appearance].titleColor = [UIColor blackColor];
    [PopupDialogDefaultView appearance].messageFont = [UIFont fontWithName:@"Myriad Pro Regular" size:12];
    [PopupDialogDefaultView appearance].messageColor = [UIColor grayColor];

    [PopupDialogOverlayView appearance].color = [UIColor colorWithWhite:0 alpha:0.5];
    [PopupDialogOverlayView appearance].blurRadius = 10;
    [PopupDialogOverlayView appearance].blurEnabled = YES;
    [PopupDialogOverlayView appearance].liveBlur = NO;
    [PopupDialogOverlayView appearance].opacity = .5;
    
    [DefaultButton appearance].titleFont = [UIFont fontWithName:@"Myriad Pro Regular" size:14];
    [DefaultButton appearance].titleColor = [UIColor grayColor];
    [DefaultButton appearance].buttonColor = [UIColor clearColor];
    [DefaultButton appearance].separatorColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    [CancelButton appearance].titleColor = [UIColor grayColor];
    [DestructiveButton appearance].titleColor = [UIColor redColor];
}

@end
