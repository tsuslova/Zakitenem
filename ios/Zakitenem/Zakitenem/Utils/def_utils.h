/* Define utils */
#ifndef NDEBUG
#   define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __func__, __LINE__, ##__VA_ARGS__)
#else
#   define DLOG(...)
#endif


#define ANALYTICS 1


#define API_LOGS 1

#ifdef API_LOGS
#   define API_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __func__, __LINE__, ##__VA_ARGS__)
#else
#   define API_LOG(...)
#endif


#define COLOR_RGBA(R, G, B, A) [UIColor colorWithRed:(float)(R)/255\
    green:(float)(G)/255\
    blue:(float)(B)/255\
    alpha:(float)(A)/255]

#define COLOR_RGB(R, G, B) COLOR_RGBA(R, G, B, 255)

#define COLOR_GREY(Y) COLOR_RGB(Y, Y, Y)


#define ERROR_WITH_CODE(_code_) ERROR_WITH_CODE_AND_INFO(_code_, nil)

#define ERROR_WITH_CODE_AND_INFO(_code_, _info_) [NSError \
errorWithDomain:[NSString stringWithFormat:@"com.%@.%@", \
[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey], \
NSStringFromClass([self class])] \
code:_code_ \
userInfo:_info_]


#define WeakselfDefine() __weak typeof(self) weakSelf = self;

#define STR_FROM_CLASS(_x_) NSStringFromClass([_x_ class])

#define STR_FROM_INT(_x_) [NSString stringWithFormat:@"%d", (_x_)]

#define STR_FROM_BOOL(_x_) (_x_) ? @"1" : @"0"

#define strFormat(__format__, ...) [NSString stringWithFormat:__format__, ##__VA_ARGS__]

#define METHOD_IMPLEMENTED(instance, selector) [NSException \
raise:[NSString stringWithFormat:@"%@ method implementation exeption", \
NSStringFromClass([instance class])] \
format:@"Method %@ should be implemented", NSStringFromSelector(selector)];


#define IS_WIDESCREEN ([[UIScreen mainScreen] bounds].size.height == 568)


#define IOS_MIN_VERSION(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define isIpad ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone)

