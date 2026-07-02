//
//  AppDelegate+CULPlugin.m
//
//  Created by Nikolay Demyankov on 15.09.15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Cordova/CDVAppDelegate.h>
#import <Cordova/CDVViewController.h>
#import "CULPlugin.h"

/**
 *  Plugin name in config.xml
 */
static NSString *const PLUGIN_NAME = @"UniversalLinks";

@interface CDVAppDelegate (CULPlugin)
- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler;
@end

@implementation CDVAppDelegate (CULPlugin)

/**
 * Cordova iOS 8 moves to UIScene and deprecates CDVAppDelegate.window and CDVAppDelegate.viewController.
 * For backwards compatibility, try to locate a CDVViewController from the scene/window hierarchy if needed.
 */
- (CDVViewController *)cul_currentCordovaViewController {
    if ([self respondsToSelector:@selector(viewController)] && self.viewController != nil) {
        return (CDVViewController *)self.viewController;
    }

    // iOS 13+ multi-scene support: find a key window's root view controller.
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in scenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (!window.isKeyWindow) {
                    continue;
                }
                UIViewController *root = window.rootViewController;
                if ([root isKindOfClass:[CDVViewController class]]) {
                    return (CDVViewController *)root;
                }
                // common embedding: Cordova is inside a navigation controller
                if ([root isKindOfClass:[UINavigationController class]]) {
                    UIViewController *top = ((UINavigationController *)root).topViewController;
                    if ([top isKindOfClass:[CDVViewController class]]) {
                        return (CDVViewController *)top;
                    }
                }
            }
        }
    }

    return nil;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    // ignore activities that are not for Universal Links
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] || userActivity.webpageURL == nil) {
        return NO;
    }
    
    // get instance of the plugin and let it handle the userActivity object
    CDVViewController *cordovaVC = [self cul_currentCordovaViewController];
    if (cordovaVC == nil) {
        return NO;
    }

    CULPlugin *plugin = [cordovaVC getCommandInstance:PLUGIN_NAME];
    if (plugin == nil) {
        return NO;
    }
    
    return [plugin handleUserActivity:userActivity];
}

@end
