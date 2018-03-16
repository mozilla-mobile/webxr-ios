#import "AppState.h"

@implementation AppState

- (instancetype)copyWithZone:(NSZone *)zone
{
    AppState *copy = [AppState new];
    [copy setRecordState:[self recordState]];
    [copy setShowOptions:[self showOptions]];
    [copy setShowMode:[self showMode]];
    [copy setWebXR:[self webXR]];
    [copy setARRequest:[self aRRequest]];
    [copy setMicEnabled:[self micEnabled]];
    [copy setTrackingState:[self trackingState]];
    [copy setInterruption:[self interruption]];
    [copy setComputerVisionDataRequested:[self computerVisionDataRequested]];
    [copy setShouldRemoveAnchorsOnNextARSession: [self shouldRemoveAnchorsOnNextARSession]];
    
    return copy;
}

- (BOOL)isEqual:(id)theObject
{
    if (theObject == self)
    {
        return YES;
    }
    
    if ([self class] != [theObject class])
    {
        return NO;
    }
    
    if ([self showOptions] != [theObject showOptions])
    {
        return NO;
    }
    
    if ([self showMode] != [theObject showMode])
    {
        return NO;
    }
    
    if ([self recordState] != [theObject recordState])
    {
        return NO;
    }
    
    if ([self webXR] != [theObject webXR])
    {
        return NO;
    }
    
    if ([self micEnabled] != [theObject micEnabled])
    {
        return NO;
    }
    
    if ([self aRRequest] != [theObject aRRequest] && [[self aRRequest] isEqualToDictionary:[theObject aRRequest]] == NO)
    {
        return NO;
    }
    
    if ([self trackingState] != [theObject trackingState] && [[self trackingState] isEqualToString:[theObject trackingState]] == NO)
    {
        return NO;
    }
    
    if ([self interruption] != [theObject interruption])
    {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return [self showOptions] ^ [self showMode] ^ [self recordState] ^ [self webXR] ^ [self micEnabled] ^ [[self trackingState] hash] ^ [[self aRRequest] hash] ^ [self interruption];
}

+ (instancetype)defaultState
{
    AppState *state = [AppState new];
    
    [state setShowMode:SHOW_MODE_BY_DEFAULT];
    [state setShowOptions:SHOW_OPTIONS_BY_DEFAULT];
    [state setRecordState:RECORD_STATE_BY_DEFAULT];
    [state setMicEnabled:MICROPHONE_ENABLED_BY_DEFAULT];
    
    // trackingstate default is nil ?
    
    return state;
}

- (instancetype)updatedShowMode:(ShowMode)showMode
{
    [self setShowMode:showMode];
    return self;
}

- (instancetype)updatedShowOptions:(ShowOptions)showOptions
{
    [self setShowOptions:showOptions];
    return self;
}

- (instancetype)updatedRecordState:(RecordState)state
{
    [self setRecordState:state];
    return self;
}

- (instancetype)updatedWebXR:(BOOL)webXR
{
    [self setWebXR:webXR];
    return self;
}

- (instancetype)updatedWithARRequest:(NSDictionary *)dict
{
    [self setARRequest:dict];
    return self;
}

- (instancetype)updatedWithMicEnabled:(BOOL)enabled
{
    [self setMicEnabled:enabled];
    return self;
}

- (instancetype)updatedWithTrackingState:(NSString *)state
{
    [self setTrackingState:state];
    return self;
}

- (instancetype)updatedWithInterruption:(BOOL)interruption
{
    [self setInterruption:interruption];
    return self;
}

@end
