//
//  ForecastsVC.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "ForecastsVC.h"
#import "UserManager.h"

@interface ForecastsVC () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ForecastsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *html = @"<html>";
    NSString *forecastPath = [[NSBundle mainBundle] pathForResource:@"Neokom" ofType:@"html"];
    
    NSError *error;
    NSString *forecastHTML = [NSString stringWithContentsOfFile:forecastPath encoding:NSUTF8StringEncoding error:&error];
    if (error){
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    html = [html stringByAppendingString:forecastHTML];
    html = [html stringByAppendingString:@"</html>"];
    
    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - IBActions
- (IBAction)logout:(id)sender
{
    [[UserManager sharedManager] logout];
}

- (IBAction)reload:(id)sender
{
    DLOG(@"%@",self.webView.request);
    [self.webView stopLoading];
    [self.webView reload];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLOG(@"%@",request.URL.absoluteString);
    return YES;
}

@end
