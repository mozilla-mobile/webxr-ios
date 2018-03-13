#import "MessageController.h"
#import <PopupDialog/PopupDialog-Swift.h>

#warning LOCALIZATION

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

- (void)clean
{
    if ([self arPopup])
    {
        [[self arPopup] dismissViewControllerAnimated:NO completion:NULL];
        
        [self setArPopup:nil];
    }
    
    if ([[self viewController] presentedViewController])
    {
        [[[self viewController] presentedViewController] dismissViewControllerAnimated:NO completion:NULL];
    }
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
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
                          ];
    
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

- (void)showMessageAboutARInterruption:(BOOL)interrupt
{
    if (interrupt && _arPopup == nil)
    {
        PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"AR Interruption Occurred"
                                                        message:@"Please wait, it would be fixed automatically"
                                                          image:nil
                                                buttonAlignment:UILayoutConstraintAxisHorizontal
                                                transitionStyle:PopupDialogTransitionStyleBounceUp
                                                 preferredWidth:200.0
                                               gestureDismissal:NO
                                                  hideStatusBar:TRUE
                                                     completion:^{}
                              ];
        
        [self setArPopup:popup];
        
        [[self viewController] presentViewController:popup animated:YES completion:nil];
        
        [self didShowMessage]();
    }
    else if (interrupt == NO && _arPopup)
    {
        [_arPopup dismissViewControllerAnimated:YES completion:NULL];
        
        [self setArPopup:nil];
        
        [self didHideMessage]();
    }
}

- (void)showMessageWithTitle:(NSString*)title message:(NSString*)message hideAfter:(NSInteger)seconds {
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:title
                                                    message:message
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleZoomIn
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
                          ];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [popup dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)showMessageAboutFailSessionWithMessage: (NSString*)message completion:(void(^)(void))completion
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"AR Session Failed"
                                                    message:message
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
    ];

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

- (void)showMessageAboutFailSessionWithCompletion:(void(^)(void))completion
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"AR Session Failed"
                                                    message:@"Tap 'Ok' to restart the session"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
                          ];
    
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

- (void)showMessageAboutMemoryWarningWithCompletion:(void(^)(void))completion
{
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Memory Issue Occurred"
                                                    message:@"There was not enough memory for the application to keep working"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
                          ];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                         {
                             [popup dismissViewControllerAnimated:YES completion:NULL];
                             
                             if (completion)
                             {
                                 completion();
                             }
                             
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
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
                          ];
    
    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"Ok" height:40 dismissOnTap:YES action:^
                         {
                             [popup dismissViewControllerAnimated:YES completion:NULL];
                             
                             [self didHideMessageByUser]();
                         }];
    
    [popup addButtons: @[ok]];
    
    [[self viewController] presentViewController:popup animated:YES completion:nil];
    
    [self didShowMessage]();
}

- (void)showSettingsPopup:(void (^)(BOOL))responseBlock {
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Open iOS Settings"
                                                    message:@"Opening iOS Settings will cause the current AR Session to be restarted when you come back"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:200.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
    ];

    DefaultButton *ok = [[DefaultButton alloc] initWithTitle:@"OK" height:40 dismissOnTap:YES action:^{
        responseBlock(true);
    }];
    ok.titleColor = UIColor.blueColor;

    DefaultButton *cancel = [[DefaultButton alloc] initWithTitle:@"Cancel" height:40 dismissOnTap:YES action:^{
        responseBlock(false);
    }];

    [popup addButtons: @[cancel, ok]];

    [[self viewController] presentViewController:popup animated:YES completion:nil];
}

- (void)showMessageAboutResetTracking:(void (^)(ResetTrackigOption))responseBlock {
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Reset tracking"
                                                    message:@"Please select one of the options below"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisVertical
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:360.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
    ];

    DefaultButton *resetTracking = [[DefaultButton alloc] initWithTitle:@"Reset tracking" height:40 dismissOnTap:YES action:^{
        responseBlock(ResetTracking);
    }];
    resetTracking.titleColor = resetTracking.tintColor;

    DefaultButton *removeExistingAnchors = [[DefaultButton alloc] initWithTitle:@"Remove existing anchors" height:40 dismissOnTap:YES action:^{
        responseBlock(RemoveExistingAnchors);
    }];
    removeExistingAnchors.titleColor = removeExistingAnchors.tintColor;

    DefaultButton *resetTrackingAndRemoveExistingAnchors = [[DefaultButton alloc] initWithTitle:@"Reset tracking and remove existing anchors" height:40 dismissOnTap:YES action:^{
        responseBlock(ResetTrackingAndRemoveExistingAnchors);
    }];
    resetTrackingAndRemoveExistingAnchors.titleColor = resetTrackingAndRemoveExistingAnchors.tintColor;

    [popup addButtons: @[resetTracking, removeExistingAnchors, resetTrackingAndRemoveExistingAnchors]];

    [[self viewController] presentViewController:popup animated:YES completion:nil];
}

- (void)showMessageAboutAccessingTheCapturedImage:(void (^)(BOOL))granted {
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:@"Video Camera Image Access"
                                                    message:@"WebXR Viewer app displays video from your camera in the background without automatically giving access to those images to the web page. This page is requesting access to images from the video camera.\n\nAllow?"
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                             preferredWidth:340.0
                                           gestureDismissal:NO
                                              hideStatusBar:TRUE
                                                 completion:^{}
    ];

    DestructiveButton *ok = [[DestructiveButton alloc] initWithTitle:@"YES" height:40 dismissOnTap:YES action:^{
        granted(true);
    }];
    ok.titleColor = UIColor.blueColor;

    DefaultButton *cancel = [[DefaultButton alloc] initWithTitle:@"NO" height:40 dismissOnTap:YES action:^{
        granted(false);
    }];

    [popup addButtons: @[cancel, ok]];

    [[self viewController] presentViewController:popup animated:YES completion:nil];
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

