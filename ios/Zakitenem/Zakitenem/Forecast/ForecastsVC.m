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
    NSURL *url = [NSURL URLWithString:@"http://windguru.cz"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - IBActions
- (IBAction)logout:(id)sender
{
    [[UserManager sharedManager] logout];
}

@end
