#import "AppState.h"

@implementation AppState

- (instancetype)copyWithZone:(NSZone *)zone
{
    AppState *copy = [AppState new];
    [copy setShowOptions:[self showOptions]];
    [copy setShowMode:[self showMode]];
    [copy setWebXR:[self webXR]];
    [copy setARRequest:[self aRRequest]];
    [copy setComputerVisionFrameRequested:[self computerVisionFrameRequested]];
    [copy setShouldRemoveAnchorsOnNextARSession: [self shouldRemoveAnchorsOnNextARSession]];
    [copy setSendComputerVisionData:[self sendComputerVisionData]];
    [copy setShouldShowLiteModePopup:[self shouldShowLiteModePopup]];
    [copy setShouldShowSessionStartedPopup: [self shouldShowSessionStartedPopup]];
    [copy setNumberOfTimesSendNativeTimeWasCalled: [self numberOfTimesSendNativeTimeWasCalled]];
    [copy setUserGrantedSendingComputerVisionData: [self userGrantedSendingComputerVisionData]];
    [copy setAskedComputerVisionData: [self askedComputerVisionData]];
    [copy setUserGrantedSendingWorldStateData: [self userGrantedSendingWorldStateData]];
    [copy setAskedWorldStateData: [self askedWorldStateData]];

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
    
    if ([self webXR] != [theObject webXR])
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

    if ([self computerVisionFrameRequested] != [theObject computerVisionFrameRequested])
    {
        return NO;
    }

    if ([self shouldRemoveAnchorsOnNextARSession] != [theObject shouldRemoveAnchorsOnNextARSession])
    {
        return NO;
    }

    if ([self sendComputerVisionData] != [theObject sendComputerVisionData])
    {
        return NO;
    }
    
    if ([self shouldShowLiteModePopup] != [theObject shouldShowLiteModePopup]) {
        return NO;
    }
    
    if ([self shouldShowSessionStartedPopup] != [theObject shouldShowSessionStartedPopup]) {
        return NO;
    }
    
    if ([self numberOfTimesSendNativeTimeWasCalled] != [theObject numberOfTimesSendNativeTimeWasCalled]) {
        return NO;
    }

    if ([self userGrantedSendingComputerVisionData] != [theObject userGrantedSendingComputerVisionData]) {
        return NO;
    }

    if ([self askedComputerVisionData] != [theObject askedComputerVisionData]) {
        return NO;
    }

    if ([self userGrantedSendingWorldStateData] != [theObject userGrantedSendingWorldStateData]) {
        return NO;
    }
    
    if ([self askedWorldStateData] != [theObject askedWorldStateData]) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return [self showOptions] ^ [self showMode] ^ [self webXR] ^ [[self trackingState] hash] ^ [[self aRRequest] hash];
}

+ (instancetype)defaultState
{
    AppState *state = [AppState new];
    
    [state setShowMode:SHOW_MODE_BY_DEFAULT];
    [state setShowOptions:SHOW_OPTIONS_BY_DEFAULT];
    [state setShouldShowLiteModePopup:YES];
    [state setShouldShowSessionStartedPopup:POPUP_ENABLED_BY_DEFAULT];
    [state setNumberOfTimesSendNativeTimeWasCalled:0];
    [state setUserGrantedSendingComputerVisionData:USER_GRANTED_SENDING_COMPUTER_VISION_DATA_BY_DEFAULT];
    [state setUserGrantedSendingWorldStateData:SendWorldSensingDataAuthorizationStateDenied];
    [state setAskedComputerVisionData:NO];
    [state setAskedWorldStateData:NO];

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

@end
