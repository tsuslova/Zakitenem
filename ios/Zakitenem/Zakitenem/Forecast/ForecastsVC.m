//
//  ForecastsVC.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "ForecastsVC.h"
#import "UserManager.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "GTLApiUserMessageUser.h"
#import "GTLApiForecastMessageSpot.h"
#import "GTLApiForecastMessageSpotList.h"


@interface ForecastsVC () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ForecastsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadForecasts];
}

#pragma mark - Data loading

- (void)loadForecasts
{
    [self lock];
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    GTLApiUserMessageSession *session = [[UserManager sharedManager] currentUser].session;
    GTLQueryApi *query = [GTLQueryApi queryForUserForecastsWithObject:session];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
        GTLApiForecastMessageSpotList *obj, NSError *error){
        [self unlock];
        DLOG(@"%@", obj);
        [self showSpotsForecast:obj.spots];
    }];
}

- (void)showSpotsForecast:(NSArray*)spotsList
{
    NSString *html = @"<html>";
    for (GTLApiForecastMessageSpot *spot in spotsList){
        html = [html stringByAppendingString:spot.forecast];
    }
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
