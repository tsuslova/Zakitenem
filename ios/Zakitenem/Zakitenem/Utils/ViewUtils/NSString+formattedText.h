
static NSString *const ftTagBold = @"b";
static NSString *const ftTagLink = @"a";
static NSString *const ftTagSup = @"sup";

@interface NSString (formattedText)

/*
 wraps \b string with \b <tag>...</tag>
 */
+ (NSString *)ftString:(NSString *)string wrapTag:(NSString *)tag;

- (NSString *)ftWrappedByTag:(NSString *)tag;

/*
 case insensitive isEqual
 */
- (BOOL)isEqualToStringCI:(NSString *)aString;

@end

@interface NSMutableString (formattedText)

- (void)ftWrapByTag:(NSString *)tag;

- (NSDictionary *)removeTagsAndReturnRanges;

@end
