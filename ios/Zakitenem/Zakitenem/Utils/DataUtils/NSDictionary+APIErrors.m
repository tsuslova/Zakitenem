#import "NSDictionary+APIErrors.h"


static NSString *const errorKey = @"error";
static NSString *const userMessageKey = @"user-message";
static NSString *const messageKey = @"message";

@implementation NSDictionary(APIErrors)

- (NSString *)userErrorMessage
{
    NSDictionary *error = self[errorKey];
    if (error){
        NSString *message = error[userMessageKey];
        if (!message){
            DLOG(@"No user message found");
            message = error[messageKey];
        }
        return message;
    }
    return nil;
}

@end
