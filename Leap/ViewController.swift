//
//  ViewController.swift
//  Leap
//
//  Created by Kiril Savino on 12/9/16.
//  Copyright © 2016 Kiril Savino. All rights reserved.
//

import UIKit
import Lock
import SafariServices
import CoreData

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        if let credentials = appDelegate.credentials {
            print("holy shit we're in!")
        } else {
            if appDelegate.lostCredentials {
                let logoutURL = "com.singleleap.Leap://singleleap.auth0.com/ios/com.singleleap.Leap/logout".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
                let url = "https://singleleap.auth0.com/v2/logout?returnTo=\(logoutURL)"
                let svc = SFSafariViewController(url: URL(string: url)!)
                self.present(svc, animated: true, completion: nil)

            } else {

                print("presenting login")
                Lock
                  .classic()
                  .withStyle {
                      $0.title = ""
                      $0.primaryColor = .magenta
                      $0.headerBlur = .extraLight
                      $0.logo = LazyImage(name: "Logo Small Clear")
                  }
                  .withOptions {
                      $0.oidcConformant = true
                  }
                  .onAuth { credentials in
                      print("well hey, here we are!")
                      let creds = NSEntityDescription.insertNewObject(forEntityName: "Credentials", into: appDelegate.persistentContainer.viewContext)
                      creds.setValue(credentials.accessToken, forKey: "accessToken")
                      creds.setValue(credentials.idToken, forKey: "idToken")
                      try! appDelegate.persistentContainer.viewContext.save()
                  }
                  .present(from: self)
            }
        }
    }
}
