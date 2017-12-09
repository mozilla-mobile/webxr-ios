#import <Foundation/Foundation.h>
#import "ARKHelper.h"
#import "AppState.h"

typedef NS_ENUM(NSUInteger, ARKType)
{
    ARKMetal,
    ARKSceneKit
};

@class ARKController;
typedef void (^DidUpdate)(ARKController *);
typedef void (^DidFailSession)(NSError *);
typedef void (^DidInterupt)(BOOL);
typedef void (^DidChangeTrackingState)(NSString *state);
typedef void (^DidAddPlaneAnchors)(void);
typedef void (^DidRemovePlaneAnchors)(void);

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidInterupt didInterupt;
@property(copy) DidFailSession didFailSession;
@property(copy) DidChangeTrackingState didChangeTrackingState;
@property(copy) DidAddPlaneAnchors didAddPlaneAnchors;
@property(copy) DidRemovePlaneAnchors didRemovePlaneAnchors;

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;
- (UIView *)arkView;

- (void)viewWillTransitionToSize:(CGSize)size;

- (void)startSessionWithAppState:(AppState *)state;

- (void)stopSession;

- (NSDictionary *)arkData;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;

- (NSArray *)hitTestNormPoint:(CGPoint)point types:(NSUInteger)type;
- (BOOL)addAnchor:(NSString *)name transform:(NSArray *)transform;

- (void)removeAnchors:(NSArray *)anchorNames;

- (NSArray *)currentPlanesArray;

- (NSString *)trackingState;
@end

