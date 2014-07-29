#import "NSMutableAttributedString+Attributes.h"
#import <CoreText/CoreText.h>


@implementation NSMutableAttributedString (Attributes)

- (void)setFont:(UIFont *)font
{
    [self setFont:font range:NSMakeRange(0, self.length)];
}

- (void)setFont:(UIFont *)font range:(NSRange)range
{
    NSDictionary *attr = @{NSFontAttributeName: font};
    [self setAttributes:attr range:range];
}

- (void)setFontName:(NSString *)fontName size:(CGFloat)size
{
    [self setFontName:fontName size:size range:NSMakeRange(0, self.length)];
}

- (void)setFontName:(NSString *)fontName size:(CGFloat)size range:(NSRange)range
{
    UIFont *font = [UIFont fontWithName:fontName size:size];
    [self setFont:font range:range];
}

- (void)setFontFamily:(NSString *)fontFamily
                 size:(CGFloat)size
                 bold:(BOOL)isBold
               italic:(BOOL)isItalic
{
    [self setFontFamily:fontFamily
                   size:size
                   bold:isBold
                 italic:isItalic
                  range:NSMakeRange(0, self.length)];
}

- (void)setFontFamily:(NSString *)fontName
                 size:(CGFloat)size
                 bold:(BOOL)isBold
               italic:(BOOL)isItalic
                range:(NSRange)range
{
    BOOL isLight = NO;
    // TODO: cheat, replace.
    if ([fontName rangeOfString:@"-Light" options:NSCaseInsensitiveSearch].length) {
        isLight = YES;
        if (isBold) {
            fontName = [fontName stringByReplacingOccurrencesOfString:@"-Light"
                                   withString:@""
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, fontName.length)];
        }
    }
    
    CTFontSymbolicTraits traits = 
    isBold&&!isLight ? kCTFontBoldTrait : 0 | isItalic ? kCTFontItalicTrait : 0;
    
    // convert full name to postscript name for CTFontCreateWithName()
    UIFont *font = [UIFont fontWithName:fontName size:size];
    fontName = (__bridge NSString *)(CTFontCopyPostScriptName((__bridge CTFontRef)(font)));
    
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, size, NULL);
    CFRelease((__bridge CFStringRef)fontName);
    if (traits) {
        CTFontRef tmpFont = CTFontCreateCopyWithSymbolicTraits(fontRef, size, NULL, traits, traits);
        CFRelease(fontRef);
        fontRef = tmpFont;
    }

    CFStringRef name = CTFontCopyPostScriptName(fontRef);
    UIFont *resultFont = [UIFont fontWithName:(__bridge NSString *)name size:size];
    CFRelease(name);
    [self setFont:resultFont range:range];

    CFRelease(fontRef);
}

- (void)setTextColor:(UIColor *)color
{
    [self setTextColor:color range:NSMakeRange(0, self.length)];
}

- (void)setTextColor:(UIColor *)color range:(NSRange)range
{
    NSDictionary *attr = @{NSForegroundColorAttributeName: color};
    [self addAttributes:attr range:range];
}

- (void)setTextIsUnderlined:(BOOL)underlined range:(NSRange)range
{
    int style = underlined ? NSUnderlineStyleNone : NSUnderlineStyleSingle;
    NSDictionary *attr = @{NSUnderlineStyleAttributeName: @(style)};
    [self addAttributes:attr range:range];
}

@end
