@interface NSMutableAttributedString (Attributes)

- (void)setFont:(UIFont *)font;
- (void)setFont:(UIFont *)font range:(NSRange)range;
- (void)setFontName:(NSString *)fontName size:(CGFloat)size;
- (void)setFontName:(NSString *)fontName size:(CGFloat)size range:(NSRange)range;
- (void)setFontFamily:(NSString *)fontFamily
                 size:(CGFloat)size
                 bold:(BOOL)isBold
               italic:(BOOL)isItalic;
- (void)setFontFamily:(NSString *)fontFamily
                 size:(CGFloat)size
                 bold:(BOOL)isBold
               italic:(BOOL)isItalic
                range:(NSRange)range;

- (void)setTextColor:(UIColor *)color;
- (void)setTextColor:(UIColor *)color range:(NSRange)range;
- (void)setTextIsUnderlined:(BOOL)underlined range:(NSRange)range;

@end
