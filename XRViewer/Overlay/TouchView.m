#import "TouchView.h"
#import "LayerView.h"

@interface TouchView()

@property (nonatomic, copy) HotAction cameraAction;
@property (nonatomic, copy) HotAction micAction;
@property (nonatomic, copy) HotAction showAction;
@property (nonatomic, copy) HotAction debugAction;

@property (nonatomic) CGRect cameraRect;
@property (nonatomic) CGRect micRect;
@property (nonatomic) CGRect showRect;
@property (nonatomic) CGRect debugRect;

@property BOOL cameraEvent;
@property BOOL micEvent;
@property BOOL showEvent;
@property BOOL debugEvent;

@property(nonatomic, strong) NSDate *startTouchDate;
@property(nonatomic, strong) NSTimer *touchTimer;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;
@property(nonatomic) RecordState recordState;

#define MAX_INCREASE_ZONE_SIZE 10
@property(nonatomic) CGFloat increaseHotZoneValue;

@end


@implementation TouchView

- (instancetype)initWithFrame:(CGRect)frame
                 cameraAction:(HotAction)cameraAction
                    micAction:(HotAction)micAction
                   showAction:(HotAction)showAction
                  debugAction:(HotAction)debugAction
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setCameraAction:cameraAction];
        [self setMicAction:micAction];
        [self setShowAction:showAction];
        [self setDebugAction:debugAction];
    }
    
    return self;
}

- (void)setCameraRect:(CGRect)cameraRect
              micRect:(CGRect)micRect
             showRect:(CGRect)showRect
            debugRect:(CGRect)debugRect
{
    [self setCameraRect:cameraRect];
    [self setMicRect:micRect];
    [self setShowRect:showRect];
    [self setDebugRect:debugRect];
    
    [self updateIncreaseHotZoneValue];
}

- (void)setProcessTouches:(BOOL)process
{
    [(LayerView *)[self superview] setProcessTouchInSubview:process];
}

- (BOOL)pointInside:(CGPoint)point
          withEvent:(UIEvent *)event
{
    if ([(LayerView *)[self superview] processTouchInSubview] == NO)
    {
        return NO;
    }
    
    if ([self showMode] == ShowNothing)
    {
        return NO;
    }
    
    if (([self showMode] >= ShowMulti) && ([self showOptions] & Capture) && CGRectContainsPoint([self increasedRect:[self cameraRect]], point))
    {
        [self setCameraEvent:YES];
        return YES;
    }
    else
    {
        if (([self showMode] >= ShowMulti) && ([self showOptions] & Mic) && CGRectContainsPoint([self increasedRect:[self micRect]], point))
        {
            [self setMicEvent:YES];
            [self setCameraEvent:NO];
            return YES;
        }
        /*
         This functionality is not needed anymore, since we are showing/hiding the debug buttons when swipping down/up
         
        if (CGRectContainsPoint([self increasedRect:[self showRect]], point))
        {
            if (([self recordState] == RecordStateRecording) || ([self recordState] == RecordStateRecordingWithMicrophone))
            {
                return NO;
            }
            
            [self setShowEvent:YES];
            [self setCameraEvent:NO];
            return YES;
        }
        if (([self showMode] >= ShowMulti) && ([self showOptions] & Debug) && CGRectContainsPoint([self debugRect], point))
        {
            [self setDebugEvent:YES];
            [self setCameraEvent:NO];
            return YES;
        }
         */
    }
    
    return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self cameraEvent])
    {
        [self setStartTouchDate:[NSDate date]];
        
        __weak typeof(self) blockSelf = self;
        
        [self setTouchTimer:[NSTimer scheduledTimerWithTimeInterval:RECORD_LONG_TAP_DURATION repeats:NO
                                                              block:^(NSTimer * _Nonnull timer)
                             {
                                 [blockSelf cameraAction](YES);
                                 [blockSelf setCameraEvent:NO];
                                 [timer invalidate];
                                 [blockSelf setTouchTimer:nil];
                             }]];
    }
    else if ([self micEvent])
    {
        [self micAction](YES);
        [self setMicEvent:NO];
    }
    else if ([self showEvent])
    {
        [self showAction](YES);
        [self setShowEvent:NO];
    }
    else if ([self debugEvent])
    {
        [self debugAction](YES);
        [self setDebugEvent:NO];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self touchTimer])
    {
        [self cameraAction](NO);
        [self setCameraEvent:NO];
        
        [[self touchTimer] invalidate];
        [self setTouchTimer:nil];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self touchTimer])
    {
        [self cameraAction](NO);
        [self setCameraEvent:NO];
        
        [[self touchTimer] invalidate];
        [self setTouchTimer:nil];
    }
}

- (void)updateIncreaseHotZoneValue
{
    CGFloat bottomYMin = CGRectGetMinY([self showRect]);
    CGFloat topYMax = CGRectGetMaxY([self cameraRect]);
    
    CGFloat increase = fminf(MAX_INCREASE_ZONE_SIZE, fabs(bottomYMin - topYMax) / 2);
    
    [self setIncreaseHotZoneValue:increase];
}

- (CGRect)increasedRect:(CGRect)rect
{
    return CGRectMake(rect.origin.x - [self increaseHotZoneValue],
                      rect.origin.y - [self increaseHotZoneValue],
                      rect.size.width + [self increaseHotZoneValue] * 2,
                      rect.size.height + [self increaseHotZoneValue] * 2);
}

@end

