
#import "BorderedTextField.h"

static const NSInteger phoneDigitsMax = 11;
static NSString *const phoneAppearanceFormat = @"+# (###) ###-##-##";

@interface PhoneTextField : BorderedTextField

@property (nonatomic, copy) NSString *phone;

@end

@interface NumberTextField : BorderedTextField

@property (nonatomic, assign) NSUInteger maxLength;

@end