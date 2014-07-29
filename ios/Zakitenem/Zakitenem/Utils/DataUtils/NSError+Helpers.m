#import "NSError+Helpers.h"

@implementation NSError(Helpers)

- (NSString *)userErrorMessage
{
    if ([self.domain isEqualToString:NSURLErrorDomain] &&
        (self.code == -1009 || self.code == -1005)) {
        
        return NSLocalizedString(@"NoInternetErrorMessage", );
    }
    return NSLocalizedString(@"UnknownError", );
}

@end
