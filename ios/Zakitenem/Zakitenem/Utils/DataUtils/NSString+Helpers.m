
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

@end
