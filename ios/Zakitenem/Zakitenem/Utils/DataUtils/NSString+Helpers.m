
#import "NSString+Helpers.h"

@implementation NSString(Helpers)

+ (NSString *)descriptionOfRequest:(NSURLRequest *)request response:(id)response
    error:(NSError *)error
{
    NSString *requestParameters =
    [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]
     stringByReplacingOccurrencesOfString:@"&" withString:@", "];
    
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"\n    Request: %@ %@", request.HTTPMethod, [request.URL absoluteString]];
    [result appendFormat:@"\n    Parameters: %@", requestParameters];
    [result appendFormat:@"\n    Response: %@", response];
    if (error) [result appendFormat:@"\n    Error: %@", error];
    
    return [result copy];
}

- (BOOL)isValidEmail
{
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    return
    [[NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex] evaluateWithObject:self];
}


@end
