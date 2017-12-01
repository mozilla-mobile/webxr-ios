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
typedef void (^DidChangeTrackingState)(NSString *);
typedef void (^DidUpdateAnchors)(NSDictionary *);


@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidInterupt didInterupt;
@property(copy) DidFailSession didFailSession;
@property(copy) DidChangeTrackingState didChangeTrackingState;
@property(copy) DidUpdateAnchors didAddPlanes;
@property(copy) DidUpdateAnchors didRemovePlanes;
@property(copy) DidUpdateAnchors didUpdateAnchors;


- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;
- (UIView *)arkView;

- (void)viewWillTransitionToSize:(CGSize)size rotation:(CGFloat)rotation;
- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;
    
- (void)startSessionWithAppState:(AppState *)state;
- (void)stopSession;

- (NSDictionary *)arkData;
- (NSDictionary *)hitTest:(NSDictionary *)dict;
- (NSDictionary *)addAnchor:(NSDictionary *)dict;
- (NSDictionary *)removeAnchor:(NSDictionary *)dict;
- (NSDictionary *)updateAnchor:(NSDictionary *)dict;
- (NSDictionary *)startHoldAnchor:(NSDictionary *)dict;
- (NSDictionary *)stopHoldAnchor:(NSDictionary *)dict;
- (NSArray *)currentPlanesArray;
- (NSString *)trackingState;

@end

