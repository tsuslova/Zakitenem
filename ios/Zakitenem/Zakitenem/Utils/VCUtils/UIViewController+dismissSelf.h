
@interface UIViewController (dismissSelf)

// priority:
// 1. if it's the only one VC in navigation stack -> dismiss navigation controller as modal
// 2. pop self from navigation stack
// 3. dismiss self as modal
- (void)dismissSelfAnimated:(BOOL)animated completion:(void (^)(void))completion;

// calls previous method with completion=nil
- (void)dismissSelfAnimated:(BOOL)animated;

// calls previous method with animated=YES
- (IBAction)dismissSelf;

@end
