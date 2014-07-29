
@interface BorderedTextField : UITextField

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *errorBorderColor;
@property (nonatomic, assign) BOOL hasError;
@property (nonatomic, assign) BOOL showBorder;

- (void)resetError; //equals to hasError = NO;

@end
