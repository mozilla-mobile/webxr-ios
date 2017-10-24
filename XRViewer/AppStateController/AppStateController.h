#import <UIKit/UIKit.h>
#import "AppState.h"

typedef void (^ASValueChangedAction)(NSUInteger);
typedef void (^ASBoolChangedAction)(BOOL);
typedef void (^ASAppChangedAction)(Application);
typedef void (^ASOnRequestAction)(NSDictionary *);
typedef void (^ASURLAction)(NSString *);

@interface AppStateController : NSObject

@property(nonatomic, copy) AppState *state;

@property(nonatomic, copy) ASValueChangedAction onModeUpdate;
@property(nonatomic, copy) ASValueChangedAction onOptionsUpdate;
@property(nonatomic, copy) ASValueChangedAction onRecordUpdate;

@property(nonatomic, copy) ASAppChangedAction  onAppUpdate;
@property(nonatomic, copy) ASBoolChangedAction onMicUpdate;
@property(nonatomic, copy) ASBoolChangedAction onDebug;
@property(nonatomic, copy) ASBoolChangedAction onInterruption;

@property(nonatomic, copy) ASOnRequestAction onRequestUpdate;

@property(nonatomic, copy) ASURLAction onMemoryWarning;
@property(nonatomic, copy) ASURLAction onEnterForeground;
@property(nonatomic, copy) ASURLAction onReachable;

- (instancetype)initWithState:(AppState *)state;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;
- (void)setRecordState:(RecordState)state;
- (void)setApplication:(Application)app;
- (void)setARRequest:(NSDictionary *)dict;
- (void)setARInterruption:(BOOL)interruption;

- (void)invertMic;
- (void)invertShowMode;
- (void)invertDebugMode;

- (BOOL)shouldShowURLBar;
- (BOOL)shouldSendARKData;

- (BOOL)isRecording;

- (BOOL)wasMemoryWarning;

// rf ?
- (void)saveOnMessageShowMode;
- (void)applyOnMessageShowMode;

- (void)saveDidReceiveMemoryWarningOnURL:(NSString *)url;
- (void)applyOnDidReceiveMemoryAction;

- (void)saveMoveToBackgroundOnURL:(NSString *)url;
- (void)applyOnEnterForegroundAction;

- (void)saveNotReachableOnURL:(NSString *)url;
- (void)applyOnReachableAction;

@end
