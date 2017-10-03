#import "SCNNode+Show.h"

@implementation SCNNode (Show)

- (void)show:(BOOL)show
{
    if (show)
    {
        [self unhide];
    }
    else
    {
        [self hide];
    }
}

- (void)hide
{
    if ([self opacity] == 1.0)
    {
        [self runAction:[SCNAction fadeOutWithDuration:0.5]];
    }
}

- (void)unhide
{
    if ([self opacity] == 0.0)
    {
        [self runAction:[SCNAction fadeInWithDuration:0.5]];
    }
}

@end
