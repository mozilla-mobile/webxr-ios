#ifndef ARKControllerProtocol_h
#define ARKControllerProtocol_h

#import "ARKHelper.h"
#import "OverlayHeader.h"

@protocol ARKControllerProtocol<NSObject>

- (instancetype)initWithSesion:(ARSession *)session size:(CGSize)size;
- (instancetype)init NS_UNAVAILABLE;

- (void)updateSession:(ARSession *)session;
- (void)clean;

- (UIView *)renderView;

- (NSArray *)hitTest:(CGPoint)point withType:(ARHitTestResultType)type;

- (id)currentHitTest;

- (void)setHitTestFocusPoint:(CGPoint)point;
- (void)didChangeTrackingState:(ARCamera *)camera;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;

- (matrix_float4x4)cameraProjectionTransform;

@end

#endif /* ARKControllerProtocol_h */
