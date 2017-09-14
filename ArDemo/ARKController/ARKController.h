#import <Foundation/Foundation.h>
#import "ARKHelper.h"
#import "OverlayHeader.h"

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

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidInterupt didInterupt;
@property(copy) DidFailSession didFailSession;
@property(copy) DidChangeTrackingState didChangeTrackingState;

- (instancetype)initWithType:(ARKType)type;
- (UIView *)arkView;

- (void)viewWillTransitionToSize:(CGSize)size;

- (void)startSessionWithRequest:(NSDictionary *)request
                       showMode:(ShowMode)mode
                    showOptions:(ShowOptions)options;
- (void)stopSession;

- (NSDictionary *)arkData;

- (NSDictionary *)anchorsData;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;

- (NSArray *)hitTestNormPoint:(CGPoint)point types:(NSUInteger)type;
- (BOOL)addAnchor:(NSString *)name transform:(NSArray *)transform;

- (void)removeAnchors:(NSArray *)anchorNames;

@end
