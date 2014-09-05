//
//  CellForecast.m
//  Zakitenem
//
//  Created by Toto on 02.09.14.
//
//

#import "CellForecast.h"
#import "GTLApiForecastMessageSpot+Wrapper.h"

@import CoreImage;

@interface CellForecast () <UIWebViewDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIImageView *ivForecast;
@property (weak, nonatomic) IBOutlet UIScrollView *svContent;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIImageView *ivTitleBG;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

@property (strong, nonatomic) GTLApiForecastMessageSpot *spot;

@end

@implementation CellForecast

const int kActivityHidingDelay = 2;

- (void)showSpot:(GTLApiForecastMessageSpot *)spot cached:(BOOL)cached
{
    self.svContent.scrollsToTop = NO;
    self.webView.scrollView.scrollsToTop = NO;
    self.spot = spot;
    
    self.lblTitle.text = spot.name;
    
    UIImage *image = [spot forecastImage];
    if (image){
        DLOG(@"Show cache image");
        self.ivForecast.image = image;
        self.svContent.contentSize = CGSizeMake(self.ivForecast.width, self.ivForecast.height);
    }
    //If we don't have cache yet or if we should reload cache - load the forecast
    if (!cached || !image){
        [self loadForecastHTML];
    }
}

- (void)loadForecastHTML
{
    DLOG(@"");
    [self.webView stopLoading];
    self.webView.hidden = NO;
    
    NSString *html = @"<html>";
    html = [html stringByAppendingString:self.spot.forecast];
    html = [html stringByAppendingString:@"</html>"];
    
    [self.activityIndicator startAnimating];
    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLOG(@"%@",request.URL.absoluteString);
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLOG(@"%@",[error localizedDescription]);
//    [self unlock];
    [self.activityIndicator performSelector:@selector(stopAnimating) withObject:nil afterDelay:kActivityHidingDelay];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLOG(@"");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLOG(@"");
    [self.activityIndicator performSelector:@selector(stopAnimating) withObject:nil afterDelay:kActivityHidingDelay];
    self.svContent.contentSize = CGSizeMake(self.webView.width, self.svContent.height);
    
    [self performSelector:@selector(takeWebViewScreenshot:) withObject:webView afterDelay:2];
}

- (void)takeWebViewScreenshot:(UIWebView *)webView
{
    UIGraphicsBeginImageContextWithOptions(webView.scrollView.bounds.size, NO, 0.0f);
    [webView.scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (![self checkIfImage:viewImage]){
        DLOG(@"no underlying data");
        [self performSelector:@selector(takeWebViewScreenshot:) withObject:webView afterDelay:2];
    } else {
        [self.spot setForecastImage:viewImage];
        self.ivForecast.image = viewImage;
        self.ivForecast.hidden = NO;
        self.webView.hidden = YES;
    }
    
    //TODO: may be it's more optimal to create a one-pixel image before?
//    CIImage *image = viewImage.CIImage;
//    CGRect imageRect = (CGRect){CGPointZero,viewImage.size};
//    image = [CIFilter filterWithName:@"CIAreaMaximumAlpha" keysAndValues:kCIInputImageKey, image, @"inputExtent", [NSValue valueWithCGRect:imageRect], nil].outputImage;
//    CGImageRef img = [myContext createCGImage:image fromRect:[image extent]];
//    [self checkIfImage:image];
    
}

- (BOOL)checkIfImage:(UIImage *)someImage
{
    CGImageRef image = someImage.CGImage;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    GLubyte * imageData = malloc(width * height * 4);
    int bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    int bitsPerComponent = 8;
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, height, bitsPerComponent,
        bytesPerRow, CGImageGetColorSpace(image),
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextSetBlendMode(imageContext, kCGBlendModeCopy);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
    CGContextRelease(imageContext);
    
    int byteIndex = 0;
    
    BOOL imageExist = NO;
    for ( ; byteIndex < width*height*4; byteIndex += 4) {
        CGFloat red = ((GLubyte *)imageData)[byteIndex]/255.0f;
        CGFloat green = ((GLubyte *)imageData)[byteIndex + 1]/255.0f;
        CGFloat blue = ((GLubyte *)imageData)[byteIndex + 2]/255.0f;
        CGFloat alpha = ((GLubyte *)imageData)[byteIndex + 3]/255.0f;
        if (red != 0 || green != 0 || blue != 0 || alpha != 0){
            imageExist = YES;
            break;
        }
    }
    
    return imageExist;
}


#pragma mark - UIScrollViewDelegate

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView
{
    return NO;
}
@end
