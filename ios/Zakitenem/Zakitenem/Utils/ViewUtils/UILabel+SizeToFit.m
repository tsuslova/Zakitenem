#import "UILabel+SizeToFit.h"
#import "UIView+maoDimensions.h"

@implementation UILabel (SizeToFit)

- (void)sizeToFitWidth
{
    CGSize fitSize = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, self.height)];
    self.width = fitSize.width;
}

- (void)sizeToFitHeight
{
    [self sizeToFitMaxHeight:CGFLOAT_MAX];
}

- (void)sizeToFitMaxHeight:(CGFloat)maxHeight
{
    CGSize fitSize = [self sizeThatFits:CGSizeMake(self.width, maxHeight)];
    self.height = fitSize.height;
}

@end
