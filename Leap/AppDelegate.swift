//
//  AppDelegate.swift
//  Leap
//
//  Created by Kiril Savino on 12/9/16.
//  Copyright © 2016 Kiril Savino. All rights reserved.
//

import UIKit
import CoreData
import Lock
import RealmSwift
import EventKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lostCredentials: Bool = false
    var credentials: NSManagedObject?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let attemptSync = true
        if attemptSync {
            attemptCalendarSync()
        }

        setupDefaultAppearance()

        return true
    }

    private func attemptCalendarSync() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted:Bool, error:Error?) in
            if accessGranted {
                let realm = Realm.user()
                let calendars = eventStore.legacyCalendars()
                for calendar in calendars {
                    try! realm.write {
                        realm.add(calendar)
                    }
                    eventStore.syncPastEvents(forCalendar: calendar)
                }

                let context = self.persistentContainer.viewContext
                let credentialFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Credentials")

                do {
                    let credentials = try context.fetch(credentialFetch) as! [NSManagedObject]
                    if !credentials.isEmpty {
                        self.credentials = credentials[0]
                    }
                } catch {
                    print("Failed to get credentials \(error)")
                }
            }
        }
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // com.singleleap.leap://singleleap.auth0.com/ios/com.singleleap.Leap/callback?code=lEVGl5AJl0K1a9yS&state=oCFr3Esan6AeRS136liSH3YerF1zoxwlKNtea2i6OD4
        print("URL request: \(url)")

        if url.absoluteString.range(of: "auth0.com") != nil {
            let context = self.persistentContainer.viewContext

            let credentialFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Credentials")

            do {
                let credentials = try context.fetch(credentialFetch) as! [NSManagedObject]

                switch credentials.count {
                case 0:
                    self.lostCredentials = true
                    return Lock.resumeAuth(url, options: options)

                case 1:
                    self.lostCredentials = false
                    self.credentials = credentials[0]
                    if url.absoluteString.range(of: "auth0.com") != nil {
                        return Lock.resumeAuth(url, options: options)
                    }
                    return true

                default:
                    self.lostCredentials = false
                    self.credentials = credentials[0]
                    if url.absoluteString.range(of: "auth0.com") != nil {
                        return Lock.resumeAuth(url, options: options)
                    }
                    fatalError("Can't have multiple credential sets")
                }
            } catch {
                print("Error finding credentials \(error)")
                self.lostCredentials = true
                return Lock.resumeAuth(url, options: options)
            }
        }

        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    private func setupDefaultAppearance() {
        UISegmentedControl.appearance().tintColor = UIColor.projectDarkerGray

        let attributes = [NSForegroundColorAttributeName: UIColor.projectDarkerGray]
        UISegmentedControl.appearance().setTitleTextAttributes(attributes, for: .normal)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Leap")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
