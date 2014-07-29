
#import "NSString+formattedText.h"

@implementation NSString (formattedText)

+ (NSString *)ftString:(NSString *)str wrapTag:(NSString *)tag
{
    return [str ftWrappedByTag:tag];
}

- (NSString *)ftWrappedByTag:(NSString *)tag
{
    if (!tag.length) return nil;
    return [NSString stringWithFormat:@"<%1$@>%2$@</%1$@>", tag, self];
}

- (BOOL)isEqualToStringCI:(NSString *)aString
{
    return [[self lowercaseString] isEqualToString:[aString lowercaseString]];
}

@end

@implementation NSMutableString (formattedText)

static NSCharacterSet *beginTagTrimmingCharacterSet = nil;

static NSString *const beginTagRegexPattern = @"<\\w+>";
static NSString *const endTagRegexPatternFormat = @"</%@>";

+ (void)load
{
    beginTagTrimmingCharacterSet =
    [NSCharacterSet characterSetWithCharactersInString:@"<> "];
}

- (void)ftWrapByTag:(NSString *)tag
{
    if (!tag.length) return;
    [self insertString:[NSString stringWithFormat:@"<%@>", tag] atIndex:0];
    [self appendString:[NSString stringWithFormat:@"</%@>", tag]];
}

- (NSDictionary *)removeTagsAndReturnRanges
{
    NSRegularExpression *const beginTagRegex =
    [NSRegularExpression
     regularExpressionWithPattern:beginTagRegexPattern
     options:NSRegularExpressionCaseInsensitive
     error:nil];

    NSMutableArray *const ranges = [NSMutableArray array];
    NSMutableArray *const tags = [NSMutableArray array];
    NSInteger beginPosition = 0;
    while (YES) {
        NSRange beginRange =
        [beginTagRegex
         rangeOfFirstMatchInString:self
         options:0
         range:(NSRange){beginPosition, self.length - beginPosition}];

        if (beginRange.location == NSNotFound || !beginRange.length) {
            break;
        }
        if (beginRange.length < 3) continue;

        NSString *const tagName =
        [[[self substringWithRange:beginRange]
          stringByTrimmingCharactersInSet:beginTagTrimmingCharacterSet]
         lowercaseString];

        {
            NSInteger endPosition = beginRange.location + beginRange.length;
            NSRegularExpression *const endTagRegex =
            [NSRegularExpression
             regularExpressionWithPattern:
             [NSString stringWithFormat:endTagRegexPatternFormat, tagName]
             options:NSRegularExpressionCaseInsensitive
             error:nil];

            NSRange endRange =
            [endTagRegex
             rangeOfFirstMatchInString:self
             options:0
             range:(NSRange){endPosition, self.length - endPosition}];

            if (endRange.location == NSNotFound || endRange.length < 3) {
                continue;
            }
            NSRange finalTagContentRange =
            (NSRange){beginRange.location, endRange.location - endPosition};

            //correcting all previously found ranges
            for (NSInteger i = ranges.count - 1; i >= 0; --i) {
                NSRange tempRange = [ranges[i] rangeValue];
                if (tempRange.location >= endRange.location + endRange.length) {
                    tempRange.location -= (endRange.length + beginRange.length);
                    ranges[i] = [NSValue valueWithRange:tempRange];
                    continue;
                }
                BOOL needsReplacing = NO;;
                if (tempRange.location + tempRange.length >= endRange.location + endRange.length) {
                    tempRange.length -= endRange.length;
                    needsReplacing = YES;
                }
                if ((tempRange.location <= beginRange.location) &&
                    (tempRange.location + tempRange.length > endPosition)) {
                    tempRange.length -= beginRange.length;
                    needsReplacing = YES;
                }
                if (tempRange.location >= endPosition) {
                    tempRange.location -= beginRange.length;
                    needsReplacing = YES;
                }
                if (!needsReplacing) continue;
                ranges[i] = [NSValue valueWithRange:tempRange];
            }

            //removing tags
            [self replaceCharactersInRange:endRange
                                withString:[NSString string]];
            [self replaceCharactersInRange:beginRange
                                withString:[NSString string]];
            //add new range and tagName
            [ranges addObject:[NSValue valueWithRange:finalTagContentRange]];
            [tags addObject:tagName];
        }
    }
    if (!ranges.count) return nil;
    NSMutableDictionary *tagsRanges = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < ranges.count; ++i) {
        NSString *tag = tags[i];
        NSMutableArray *dranges = tagsRanges[tag];
        if (!dranges) {
            dranges = [NSMutableArray array];
            tagsRanges[tag] = dranges;
        }
        [dranges addObject:ranges[i]];
    }
    return tagsRanges.copy;
}

@end
