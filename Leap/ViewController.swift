//
//  ViewController.swift
//  Leap
//
//  Created by Kiril Savino on 12/9/16.
//  Copyright © 2016 Kiril Savino. All rights reserved.
//

import UIKit
import Lock

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
        Lock
            .classic()
            .withStyle {
                $0.title = "Leap"
                $0.primaryColor = .magenta
                $0.logo = LazyImage(name: "logo")
            }
            .withOptions {
                $0.oidcConformant = true
            }
            .onAuth { credentials in
                // Do something with credentials e.g.: save them.
                // Lock will not save these objects for you.
                // Lock will dismiss itself automatically by default.
            }
            .present(from: self)
    }


}

