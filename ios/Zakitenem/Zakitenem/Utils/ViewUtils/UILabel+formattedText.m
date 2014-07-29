
#import "UILabel+formattedText.h"
#import "NSMutableAttributedString+Attributes.h"
#import "NSString+formattedText.h"

@implementation UILabel (formattedText)

- (void)setTaggedText:(NSString *)text
{
    [self setTaggedText:text tagsAndAttributes:nil];
}

- (void)setTaggedText:(NSString *)text
       tagsAndAttributes:(NSDictionary *)tagsAttrs
{
    NSMutableString *str = text.mutableCopy;
    NSDictionary *ranges = [str removeTagsAndReturnRanges];
    [self setText:str tagsAndRanges:ranges tagsAndAttributes:tagsAttrs];
}

- (void)setText:(NSString *)text
  tagsAndRanges:(NSDictionary *)tagsRanges
{
    [self setText:text tagsAndRanges:tagsRanges tagsAndAttributes:nil];
}

- (void)setText:(NSString *)text
  tagsAndRanges:(NSDictionary *)tagsRanges
tagsAndAttributes:(NSDictionary *)tagsAttrs
{
    NSMutableAttributedString *mastr =
    [[NSMutableAttributedString alloc] initWithString:text attributes:
     @{NSFontAttributeName: self.font}];

    NSMutableArray *const tags = tagsRanges.allKeys.mutableCopy;

    // BOLD
    [tags removeObject:ftTagBold];
    NSDictionary *attrs = tagsAttrs[ftTagBold] ?: [self defaultBoldAttributes];
    [self applyString:mastr attributes:attrs ranges:tagsRanges[ftTagBold]];

    // SUP
    [tags removeObject:ftTagSup];
    attrs = tagsAttrs[ftTagSup];
    [self applySupWiselyToString:mastr attributes:attrs ranges:tagsRanges[ftTagSup]];

    // other...

    self.attributedText = [mastr copy];
}

#pragma mark - helper methods

- (NSDictionary *)defaultBoldAttributes
{
    return @{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.font.pointSize]};
}

- (NSDictionary *)defaultSupAttributesWithFont:(UIFont *)font
{
    CGFloat newSize = font.pointSize * 0.6f;
    CGFloat baseLine = font.pointSize * 0.33f;
    return @{NSFontAttributeName: [font fontWithSize:newSize],
             NSBaselineOffsetAttributeName: @(baseLine)};
}


- (void)applySupWiselyToString:(NSMutableAttributedString *)mastr
                    attributes:(NSDictionary *)attributes
                        ranges:(NSArray *)ranges
{
    __weak UILabel *weakSelf = self;
    [ranges enumerateObjectsUsingBlock:^(NSValue *vRange, NSUInteger idx, BOOL *stop) {
        const NSRange range = vRange.rangeValue;
        NSDictionary *strAttrs =
        [mastr attributesAtIndex:range.location effectiveRange:nil];
        NSMutableDictionary *attrs =
        [self defaultSupAttributesWithFont:
         strAttrs[NSFontAttributeName] ?: weakSelf.font].mutableCopy;
        [attrs addEntriesFromDictionary:attributes];
        [mastr addAttributes:attrs range:vRange.rangeValue];
    }];
}

- (void)applyString:(NSMutableAttributedString *)mastr
         attributes:(NSDictionary *)attrs
             ranges:(NSArray *)ranges
{
    [ranges enumerateObjectsUsingBlock:^(NSValue *vRange, NSUInteger idx, BOOL *stop) {
        [mastr addAttributes:attrs range:vRange.rangeValue];
    }];
}

@end
