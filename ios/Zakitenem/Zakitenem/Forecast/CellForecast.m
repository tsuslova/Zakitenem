//
//  CellForecast.m
//  Zakitenem
//
//  Created by Toto on 02.09.14.
//
//

#import "CellForecast.h"

@interface CellForecast () <UIWebViewDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIImageView *ivForecast;
@property (weak, nonatomic) IBOutlet UIScrollView *svContent;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation CellForecast

const int kActivityHidingDelay = 2;

- (void)setSpot:(GTLApiForecastMessageSpot *)spot
{
    [self.webView stopLoading];
    
    _spot = spot;
    
    NSString *html = @"<html>";
    html = [html stringByAppendingString:spot.forecast];
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
}


@end
