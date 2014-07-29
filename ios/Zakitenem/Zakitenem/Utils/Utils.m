#import "Utils.h"

#import "NSError+Helpers.h"

void showInfoAlertView(NSString *title, NSString *message, id<UIAlertViewDelegate> delegate)
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:delegate
                      cancelButtonTitle:NSLocalizedString(@"OK", )
                      otherButtonTitles:nil] show];
}

void showErrorAlertView(NSError *error, NSString *userMessage)
{
    if (!userMessage){
        userMessage = [error userErrorMessage];
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", )
        message:userMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", )
        otherButtonTitles:nil];
    [alertView show];
}

NSString *countableValueFormat(NSUInteger value,
                               NSString *formatZero,
                               NSString *formatOne,
                               NSString *formatTwoToFour,
                               NSString *formatMany)
{
    NSInteger lastDigit = value % 10;
    NSInteger decades = value / 10;
    
    if (value == 0) {
        return formatZero;
    } else if ((lastDigit == 1) && (decades != 1)) {
        return formatOne;
    } else if ((lastDigit >= 2) && (lastDigit <= 4) && (decades != 1)) {
        return formatTwoToFour;
    } else {
        return formatMany;
    }
}

NSString *formatDateUsingDefaultFormat(NSDate *date)
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMMM yyyy"];
    return [dateFormatter stringFromDate:date];
}


NSDate *isoDateFromString(NSString *dateString)
{
    static NSString *const isoDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:isoDateFormat];
    NSDate *date = [df dateFromString:dateString];
    return date;
}

BOOL stringIsValidEmail(NSString *str)
{
    static NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    static NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";

    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    BOOL stricterFilter = YES;
    NSPredicate *emailTest =
    [NSPredicate predicateWithFormat:@"SELF MATCHES %@",
     stricterFilter ? stricterFilterString : laxString];

    return [emailTest evaluateWithObject:str];
}
