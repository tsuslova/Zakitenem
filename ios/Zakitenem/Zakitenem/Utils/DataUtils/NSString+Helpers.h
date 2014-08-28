
@interface NSString(Helpers)
+ (NSString *)descriptionOfRequest:(NSURLRequest *)request response:(id)response
    error:(NSError *)error;
- (BOOL)isValidEmail;

@end
