//
//  Tweak.xm
//  Zetime-Goodies
//
//  Created by cbs_ghost on 2017/10/15.
//  Copyright (c) 2017 CbS Ghost. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface APPSShowTips : UIView
+ (void)hidden;
+ (void)showLoading;
+ (void)showLoadingWithMessage:(nullable NSString *)msg;
@end

@interface UIImageView (WebCache)
- (void)sd_setImageWithURL:(nullable NSURL *)url completed:(nullable id)completedBlock;
@end

@interface AppsViewController : UIViewController
@end

@interface APPSCustomPhotoViewControl : AppsViewController <WKNavigationDelegate>
- (void)wallpaperTap;

// Custom methods
- (void)webViewFailureCallback:(WKWebView *)wkWebView;

@end

%hook APPSCustomPhotoViewControl
- (void)wallpaperTap
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[@"Select wallpaper source" uppercaseString]
                                                        message:nil
                                                        preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                          handler:^(UIAlertAction *action) {
        
        // Cancel button tappped.
        //[self dismissViewControllerAnimated:YES completion:^{}];

    }]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Built-in"
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
        
        // Built-in button tapped.
        %orig;

    }]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"zetime.daap.dk" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        // zetime.daap.dk button tapped.
        [%c(APPSShowTips) showLoading];

        // Tweak webview's width on mobile device
        AppsViewController *communityWebViewController = [[[%c(AppsViewController) alloc] init] autorelease];
        NSString *webViewFixWidthJS = @"var meta = document.createElement('meta'); "
                                      @"meta.name = 'viewport'; meta.content = 'width=device-width, user-scalable=no'; "
                                      @"document.getElementsByTagName('head')[0].appendChild(meta);";
        if (self.view.bounds.size.width < 480) {
            webViewFixWidthJS = [webViewFixWidthJS stringByReplacingOccurrencesOfString:@"width=device-width" withString:@"width=480"];
        }
        WKUserScript *webViewFixWidthUserScript = [[[WKUserScript alloc] initWithSource:webViewFixWidthJS
                                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                                         forMainFrameOnly:YES] autorelease];
        WKUserContentController *communityWebViewUserContentController = [[[WKUserContentController alloc] init] autorelease];
        [communityWebViewUserContentController addUserScript:webViewFixWidthUserScript];

        // WKWebView configuration
        WKWebViewConfiguration *communityWebViewConfiguration = [[[WKWebViewConfiguration alloc] init] autorelease];
        communityWebViewConfiguration.userContentController = communityWebViewUserContentController;

        // Alloc webview
		WKWebView *communityWebView = [[[WKWebView alloc] initWithFrame:self.view.bounds
		                                                  configuration:communityWebViewConfiguration] autorelease];
		communityWebView.navigationDelegate = self;
		[communityWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://zetime.daap.dk/"]]];
        [communityWebViewController.view addSubview: communityWebView];
        communityWebViewController.title = @"zetime.daap.dk";
        
        // Go!!
        [self.navigationController pushViewController:communityWebViewController animated:YES];
    }]];

    // Present action sheet
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
	
}

%new
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
	NSURL *url = navigationResponse.response.URL;
	NSString *mimeType = navigationResponse.response.MIMEType;

    // Simple url redirecting prevention
	if (![navigationResponse.response.URL.host isEqualToString:@"zetime.daap.dk"]) {
		UIAlertController *redirectAlert = [UIAlertController alertControllerWithTitle:@"Redirection Error"
                                                              message:@"You've been redirected to an unexpected website.\n"
                                                                      @"This error message is to prevent your ZeTime app from malicious code injection."
                                                              preferredStyle:UIAlertControllerStyleAlert];

        [redirectAlert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
        
            // Go back
            [self.navigationController popViewControllerAnimated:YES];

        }]];

        // Present alert view
        [%c(APPSShowTips) hidden];
        [self.navigationController presentViewController:redirectAlert animated:YES completion:nil];

        decisionHandler(WKNavigationActionPolicyCancel);
        
	}

	if ([mimeType isEqualToString:@"image/png"]) {

        [%c(APPSShowTips) showLoadingWithMessage:@"Downloading..."];
        
        // Set watchface!!
	    UIImageView *myImageView = MSHookIvar<UIImageView *>(self, "_myImageView");
		[myImageView sd_setImageWithURL:url
                     completed:^{
                     	 [self.navigationController popViewControllerAnimated:YES];
                         [%c(APPSShowTips) hidden];
                     }];
        
		decisionHandler(WKNavigationActionPolicyCancel);

	}
	
    decisionHandler(WKNavigationActionPolicyAllow);
}

%new
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	// Set website's title
	self.navigationController.navigationBar.topItem.title = webView.title;
	[%c(APPSShowTips) hidden];
}

%new
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
	// Filter out unnecessary error
	if (error.code < 0 && error.code != NSURLErrorCancelled && error.code != NSURLErrorUserCancelledAuthentication) {
		[self webViewFailureCallback:webView];
	}
}

%new
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
	// Filter out unnecessary error
    if (error.code < 0 && error.code != NSURLErrorCancelled && error.code != NSURLErrorUserCancelledAuthentication) {
		[self webViewFailureCallback:webView];
	}
}

%new
- (void)webViewFailureCallback:(WKWebView *)wkWebView
{
	UIAlertController *failAlert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                              message:@"Unable to connect to zetime.daap.dk. :("
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    // Cancel and go back
    [failAlert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action) {
        
        [self.navigationController popViewControllerAnimated:YES];

    }]];

    // Retry (reload webpage)
    [failAlert addAction:[UIAlertAction actionWithTitle:@"Retry"
                                        style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction *action) {
        
        if (wkWebView.URL == nil) {
            [wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://zetime.daap.dk/"]]];
        } else {
        	[wkWebView reload];
        }
        
    }]];

    // Present alert view
    [%c(APPSShowTips) hidden];
    [self.navigationController presentViewController:failAlert animated:YES completion:nil];

}

%end
