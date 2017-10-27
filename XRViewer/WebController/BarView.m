#import "BarView.h"
#import "OverlayHeader.h"

@interface URLTextField : UITextField
@end

@interface BarView () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet URLTextField *urlField;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *forwardBtn;
@property (nonatomic, weak) UIButton *reloadBtn;
@property (nonatomic, weak) UIButton *cancelBtn;
@property (nonatomic, weak) UIActivityIndicatorView *ai;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightConstraint;
@end

@implementation URLTextField

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, 0, URL_FIELD_HEIGHT, URL_FIELD_HEIGHT);
}

@end


@implementation BarView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
}

- (NSString *)urlFieldText
{
    return [[self urlField] text];
}

- (void)startLoading:(NSString *)url
{
    [[self ai] startAnimating];
    [[self cancelBtn] setHidden:NO];
    [[self reloadBtn] setHidden:YES];
    [[self urlField] setText:url];
}

- (void)finishLoading:(NSString *)url
{
    [[self ai] stopAnimating];
    [[self cancelBtn] setHidden:YES];
    [[self reloadBtn] setHidden:NO];
}

- (void)setBackEnabled:(BOOL)enabled
{
    [[self backBtn] setEnabled:enabled];
}

- (void)setForwardEnabled:(BOOL)enabled
{
    [[self forwardBtn] setEnabled:enabled];
}

- (void)layout
{
    [self setupBarConstraint];
    
    [self layoutIfNeeded];
}

- (void)setup
{
    [[self backBtn] setImage:[UIImage imageNamed:@"back"] forState:UIControlStateDisabled];
    [[self forwardBtn] setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateDisabled];
    [[self backBtn] setEnabled:NO];
    [[self forwardBtn] setEnabled:NO];
    
    [[self urlField] setDelegate:self];
    
    UIActivityIndicatorView *i = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [[self urlField] setLeftView:i];
    [[self urlField] setLeftViewMode:UITextFieldViewModeUnlessEditing];
    [i hidesWhenStopped];
    [self setAi:i];
    
    [[self urlField] setClearButtonMode:UITextFieldViewModeWhileEditing];
    [[self urlField] setReturnKeyType:UIReturnKeyGo];
    [[self urlField] setKeyboardType:UIKeyboardTypeURL];
    [[self urlField] setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    [[self urlField] setTextContentType:UITextContentTypeURL];
    [[self urlField] setPlaceholder:@"Search or enter website name"];
    [[[self urlField] layer] setCornerRadius:URL_FIELD_HEIGHT / 4];
    [[self urlField] setTextAlignment:NSTextAlignmentCenter];
    
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [reloadButton setImage:[UIImage imageNamed:@"reload"] forState:UIControlStateNormal];
    [reloadButton addTarget:self action:@selector(reloadAction:) forControlEvents:UIControlEventTouchDown];
    [reloadButton setFrame:CGRectMake(0, 0, URL_FIELD_HEIGHT, URL_FIELD_HEIGHT)];
    [reloadButton setHidden:NO];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchDown];
    [cancelButton setFrame:CGRectMake(0, 0, URL_FIELD_HEIGHT, URL_FIELD_HEIGHT)];
    [cancelButton setHidden:YES];
    
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, URL_FIELD_HEIGHT, URL_FIELD_HEIGHT)];
    [rightView addSubview:reloadButton];
    [rightView addSubview:cancelButton];
    [self setCancelBtn:cancelButton];
    [self setReloadBtn:reloadButton];
    
    [[self urlField] setRightView:rightView];
    [[self urlField] setRightViewMode:UITextFieldViewModeUnlessEditing];
    
    [self setupBarConstraint];
}

- (void)setupBarConstraint
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    BOOL isntIpad = [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad;
    
    [[self rightConstraint] setConstant:(isPortrait && isntIpad ? 27.5 : 127.5)];
}

- (IBAction)backAction:(id)sender
{
    DDLogDebug(@"backAction");
    
    [[self urlField] resignFirstResponder];
    
    if ([self backActionBlock])
    {
        [self backActionBlock](self);
    }
}

- (IBAction)forwardAction:(id)sender
{
    DDLogDebug(@"forwardAction");
    
    [[self urlField] resignFirstResponder];
    
    if ([self forwardActionBlock])
    {
        [self forwardActionBlock](self);
    }
}

- (IBAction)reloadAction:(id)sender
{
    DDLogDebug(@"reloadAction");
    
    [[self urlField] resignFirstResponder];
    
    if ([self reloadActionBlock])
    {
        [self reloadActionBlock](self);
    }
}

- (IBAction)cancelAction:(id)sender
{
    DDLogDebug(@"cancelAction");
    
    [[self urlField] resignFirstResponder];
    
    if ([self cancelActionBlock])
    {
        [self cancelActionBlock](self);
    }
}

#pragma mark UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if ([self goActionBlock])
    {
        [self goActionBlock]([textField text]);
    }
    
    return YES;
}

#pragma mark UIView

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event
{
    CGFloat minXPos = CGRectGetMaxX([[self backBtn] frame]);
    CGFloat maxXPos = CGRectGetMinX([[self forwardBtn] frame]);
    
    CGFloat increaseValue = (maxXPos - minXPos) / 2;
    
    CGRect icreasedBackRect = CGRectMake([[self backBtn] frame].origin.x - increaseValue,
                                         [[self backBtn] frame].origin.y - increaseValue,
                                         [[self backBtn] frame].size.width + increaseValue * 2,
                                         [[self backBtn] frame].size.height + increaseValue * 2);
    
    CGRect icreasedForwardRect = CGRectMake([[self forwardBtn] frame].origin.x - increaseValue,
                                            [[self forwardBtn] frame].origin.y - increaseValue,
                                            [[self forwardBtn] frame].size.width + increaseValue * 2,
                                            [[self forwardBtn] frame].size.height + increaseValue * 2);
    
    if (CGRectContainsPoint(icreasedBackRect, point))
    {
        return [self backBtn];
    }
    
    if (CGRectContainsPoint(icreasedForwardRect, point))
    {
        return [self forwardBtn];
    }
    
    return [super hitTest:point withEvent:event];
}

@end

