#import "UIView+NibLoading.h"


@implementation UIView (NibLoading)

+ (id)loadFromNibNamed:(NSString *)nibName
{
    NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
    for (id nibObject in nibObjects) {
        if ([nibObject isKindOfClass:[self class]]) {
            return nibObject;
        }
    }
    return nil;
}

+ (id)loadFromNib
{
    return [self loadFromNibNamed:NSStringFromClass([self class])];
}

@end
