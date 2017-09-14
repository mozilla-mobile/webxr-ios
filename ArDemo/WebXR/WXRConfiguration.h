#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WXRARKTechType)
{
    WXRARKUser,
    WXRARKMetal,
    WXRARKSceneKit,
    WXRARKSpriteKit
};


@interface WXRConfiguration : NSObject

@property WXRARKTechType techType;

+ (instancetype)defaultConfigurtion;

@end


@interface WXRProtocol : NSObject

@end

@interface WXRMessage : NSObject

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSArray *options;

@end

@interface WXRMessageOption : NSObject

@property(copy) NSString *name;
@property(copy) NSString *value;

@end

@interface WXRMessageStrongOption : WXRMessageOption
@property(copy) NSArray *availableValues;
@end



