#import "UIViewController+Lock.h"

@implementation UIViewController (Lock)

static const NSInteger kLockViewTag = 300;

- (void)lock
{
    UIView *lockView = [self.view viewWithTag:kLockViewTag];
    
    if (lockView == nil) {
        lockView = [[UIView alloc] initWithFrame:self.view.bounds];
        lockView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;
        lockView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        lockView.tag = kLockViewTag;
        
        UIActivityIndicatorView *indicator =
            [[UIActivityIndicatorView alloc]
             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        [lockView addSubview:indicator];
        indicator.center = lockView.center;
        indicator.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin;
        
        [indicator startAnimating];
        
        [self.view addSubview:lockView];
    }
    
    [self.view bringSubviewToFront:lockView];
    lockView.hidden = false;
}

- (void)unlock
{
    UIView *lockView = [self.view viewWithTag:kLockViewTag];
    if (lockView) {
        lockView.hidden = YES;
    }
}

- (void)setNavitaionButtonEnabled:(BOOL)enabled
{
    self.navigationItem.backBarButtonItem.enabled = enabled;
    self.navigationItem.leftBarButtonItem.enabled = enabled;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

- (void)lockNavigationButtons
{
    [self setNavitaionButtonEnabled:NO];
}

- (void)unlockNavigationButtons
{
    [self setNavitaionButtonEnabled:YES];
}

@end
