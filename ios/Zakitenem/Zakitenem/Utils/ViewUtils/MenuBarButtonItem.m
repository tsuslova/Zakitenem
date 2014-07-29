#import "MenuBarButtonItem.h"

@implementation MenuBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super init];
    if (self) {
        self.target = target;
        self.action = action;
        self.style = UIBarButtonItemStylePlain;
        self.tintColor = [UIColor blackColor];
        
        [self setHidden:NO];
    }
    
    return self;
}

- (void)setHidden:(BOOL)hidden
{
    //@"" is for cancelling "<Back" button appearing when menu button is hidden
    self.title = hidden ? @"" : nil;
    
    self.image = hidden ? nil : [UIImage imageNamed:@"btn_menu"];
    self.enabled = !hidden;
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (isIpad) {
        [self setHidden:UIInterfaceOrientationIsLandscape(interfaceOrientation)];
    }
}

@end
