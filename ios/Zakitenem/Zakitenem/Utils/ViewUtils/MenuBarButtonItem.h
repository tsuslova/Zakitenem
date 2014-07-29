#import <UIKit/UIKit.h>

@interface MenuBarButtonItem : UIBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end
