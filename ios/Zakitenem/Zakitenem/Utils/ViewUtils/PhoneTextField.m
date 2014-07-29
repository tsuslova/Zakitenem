
#import "PhoneTextField.h"
#import <SHSPhoneComponent/SHSPhoneLibrary.h>

@interface PhoneTextField ()

@property (nonatomic, strong) SHSPhoneNumberFormatter *formatter;
@property (nonatomic, strong) SHSPhoneLogic *logicDelegate;

// SHSPhoneTextField emulation
@property (nonatomic, copy) void (^textDidChangeBlock)(UITextField *);

@end

@implementation PhoneTextField

#pragma mark - lifecycle

- (void)innerInitPhoneTextField
{
    self.formatter = [[SHSPhoneNumberFormatter alloc] init];
    [self.formatter setDefaultOutputPattern:phoneAppearanceFormat];
    self.formatter.textField = (SHSPhoneTextField *)self;

    self.logicDelegate = [[SHSPhoneLogic alloc] init];

    [super setDelegate:self.logicDelegate];
    self.keyboardType = UIKeyboardTypeNumberPad;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self innerInitPhoneTextField];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self innerInitPhoneTextField];
    return self;
}

#pragma mark - properties

- (void)setDelegate:(id<UITextFieldDelegate>)delegate
{
    self.logicDelegate.delegate = delegate;
}

- (id<UITextFieldDelegate>)delegate
{
    return self.logicDelegate.delegate;
}

- (NSString *)phone
{
    return [self.formatter digitOnlyString:self.text];
}

- (void)setPhone:(NSString *)phone
{
    [SHSPhoneLogic applyFormat:(SHSPhoneTextField *)self forText:phone];
}

@end


// number


@interface NumberTextField ()

@property (nonatomic, strong) SHSPhoneNumberFormatter *formatter;
@property (nonatomic, strong) SHSPhoneLogic *logicDelegate;

// SHSPhoneTextField emulation
@property (nonatomic, copy) void (^textDidChangeBlock)(UITextField *);

@end

@implementation NumberTextField

static NSString *const numberPattern = @"#";

static NSString *strOfPatternAndLength(NSString *p, NSInteger l)
{
    return [p stringByPaddingToLength:l withString:p startingAtIndex:0];
}

- (void)setMaxLength:(NSUInteger)maxLength
{
    _maxLength = MIN(maxLength, 256);
    [self.formatter setDefaultOutputPattern:
     strOfPatternAndLength(numberPattern, _maxLength)];
}

#pragma mark - lifecycle

- (void)innerInitPhoneTextField
{
    self.formatter = [[SHSPhoneNumberFormatter alloc] init];
    self.formatter.textField = (SHSPhoneTextField *)self;
    self.logicDelegate = [[SHSPhoneLogic alloc] init];
    [super setDelegate:self.logicDelegate];
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.maxLength = 10;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self innerInitPhoneTextField];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self innerInitPhoneTextField];
    return self;
}

#pragma mark - properties

- (void)setDelegate:(id<UITextFieldDelegate>)delegate
{
    self.logicDelegate.delegate = delegate;
}

- (id<UITextFieldDelegate>)delegate
{
    return self.logicDelegate.delegate;
}

@end

