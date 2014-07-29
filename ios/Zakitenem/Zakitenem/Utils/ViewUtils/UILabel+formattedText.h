
@interface UILabel (formattedText)

- (void)setTaggedText:(NSString *)text;

- (void)setTaggedText:(NSString *)text
    tagsAndAttributes:(NSDictionary *)tagsAttrs;

- (void)setText:(NSString *)text
  tagsAndRanges:(NSDictionary *)tagsRanges;

- (void)setText:(NSString *)text
  tagsAndRanges:(NSDictionary *)tagsRanges
tagsAndAttributes:(NSDictionary *)tagsAttrs;

@end
