
#import "UIViewController+dismissSelf.h"

@implementation UIViewController (dismissSelf)

- (IBAction)dismissSelf
{
    [self dismissSelfAnimated:YES];
}

- (void)dismissSelfAnimated:(BOOL)animated
{
    [self dismissSelfAnimated:animated completion:nil];
}

- (void)dismissSelfAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.navigationController) {
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationController dismissSelfAnimated:animated completion:completion];
            return;
        }
        [self.navigationController popViewControllerAnimated:animated];
        return;
    }
    [self dismissViewControllerAnimated:animated completion:completion];
}

@end
