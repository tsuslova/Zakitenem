
void showInfoAlertView(NSString *title, NSString *message, id<UIAlertViewDelegate> delegate);

void showErrorAlertView(NSError *error, NSString *userMessage);

NSString *countableValueFormat(NSUInteger value,
                               NSString *formatZero,
                               NSString *formatOne,
                               NSString *formatTwoToFour,
                               NSString *formatMany);

NSString *formatDateUsingDefaultFormat(NSDate *date);

NSDate *isoDateFromString(NSString *dateString);

BOOL stringIsValidEmail(NSString *str);

