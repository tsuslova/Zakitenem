
#import "BorderedTextField.h"

@implementation BorderedTextField

- (void)setShowBorder:(BOOL)value
{
    self.layerBorderWidth = (value) ? (1.f / [UIScreen mainScreen].scale) : 0.f;
}

- (BOOL)showBorder
{
    return !!self.layerBorderWidth;
}

- (void)resetError
{
    self.hasError = NO;
}

- (void)updateBorder
{
    self.layerBorderColor = self.hasError && self.errorBorderColor ?
    self.errorBorderColor : self.borderColor;
}

- (void)innerInitBorderedTextField
{
    self.backgroundColor = [UIColor whiteColor];
    self.clipsToBounds = YES;
    self.showBorder = YES;
    self.rightView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, 4.f, 4.f}];
    self.leftViewMode = UITextFieldViewModeAlways;
    self.leftView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, 4.f, 4.f}];
    self.rightViewMode = UITextFieldViewModeAlways;
    self.layerCornerRadius = 6.f;
    self.errorBorderColor = [UIColor colorWithHEXColor:controlErrorBorderColor];
    self.borderColor = [UIColor colorWithHEXColor:controlBorderColor];

    [[RACSignal combineLatest:
      @[RACObserve(self, borderColor),
        RACObserve(self, errorBorderColor),
        RACObserve(self, hasError)]]
     subscribeNext:^(id x) {
         [self updateBorder];
    }];
    [self.rac_textSignal subscribeNext:^(id x) {
        if (self.hasError) self.hasError = NO;
    }];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    [self innerInitBorderedTextField];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder])) return nil;
    [self innerInitBorderedTextField];
    return self;
}

@end
