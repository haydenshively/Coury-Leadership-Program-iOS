//
//  AppDelegate.swift
//  Coury Leadership Program
//
//  Created by Hayden Shively on 2/8/19.
//  Copyright © 2019 USC Marshall School of Business. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("Application did launch")
        engageFirebase()
        AppDelegate.signIn(allowingInteraction: false)
        
        engagePushNotifications(application)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleAsFirebase(url, with: options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        CLPProfile.shared.stopFetching()
        Feed.shared.stopFetching()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        CLPProfile.shared.stopFetching()
        Feed.shared.stopFetching()
        
        //        CLPProfile.shared.flushDataToServer()// TODO
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        CLPProfile.shared.startFetching()
        Feed.shared.startFetching()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        CLPProfile.shared.startFetching()
        Feed.shared.startFetching()
        
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        CLPProfile.shared.stopFetching()
        Feed.shared.stopFetching()
        
        //        CLPProfile.shared.flushDataToServer()// TODO
    }
}


extension AppDelegate: GIDSignInDelegate {

    // sign in
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser?, withError error: Error!) {
        if let error = error {
            print("AppDelegate.sign did fail. Error: \(error.localizedDescription)")
            CLPProfile.shared.isSigningIn = false
            return
        }

        guard let authentication = user?.authentication else {
            print("AppDelegate.sign did fail. Authentication was nil even after signing in with Google")
            CLPProfile.shared.isSigningIn = false
            return
        }

        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("AppDelegate.sign did fail. Auth.auth().signIn callback had error: \(error.localizedDescription)")
                CLPProfile.shared.isSigningIn = false
                return
            }
            
            CLPProfile.shared.isSigningIn = false
            
            // if this is the first sign in, we'll have local strengths and values but nothing in the database:
            if (CLPProfile.shared.basicInformation.strengths.count == 5 && CLPProfile.shared.basicInformation.values.count == 5) {
                CLPProfile.shared.basicInformation.startUploading()
            }
            
            CLPProfile.shared.startFetching()
            Feed.shared.startFetching()
        }
    }

    // sign out
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //        CLPProfile.shared.flushDataToServer()// TODO

        do {try Auth.auth().signOut()}
        catch {print(error)}
    }

    //MARK: - convenience functions
    func engageFirebase() {
        FirebaseApp.configure()
        print("Configured FirebaseApp")
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
    }

    func handleAsFirebase(_ url: URL, with options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
//        let sourceApp = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
        return GIDSignIn.sharedInstance().handle(url/*, sourceApplication: sourceApp, annotation: [:]*/)
    }

    public static func signIn(allowingInteraction: Bool = true) {
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        if allowingInteraction {
            CLPProfile.shared.isSigningIn = true
            GIDSignIn.sharedInstance().signIn()
        }
    }

    public static func signOut() {
        GIDSignIn.sharedInstance()?.signOut()
        GIDSignIn.sharedInstance()?.disconnect()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        print(userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        print(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }

    //MARK: - convenience functions
    func engagePushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {_,_ in }
        application.registerForRemoteNotifications()

        Messaging.messaging().delegate = self
    }
}
