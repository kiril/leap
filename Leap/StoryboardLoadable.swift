//
//  StoryboardLoadable.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

// swiftlint:disable force_cast

protocol StoryboardLoadable {
    static var storyboardName: String { get }
    static var storyboardIdentifier: String { get }
}

extension StoryboardLoadable where Self: UIViewController {
    static var storyboardName: String {
        let fullClassName = String(describing: self)
        let storyboardName = fullClassName.replacingOccurrences(of: "ViewController", with: "")
        return storyboardName
    }

    static var storyboardIdentifier: String {
        return String(describing: self)
    }

    private static var storyboard: UIStoryboard { return UIStoryboard(name: storyboardName, bundle: nil) }

    static func loadFromStoryboard() -> Self {
        // if you're here because XCode is complaining about non-final class, make your UIViewController subclass final
        if let vc = findViewController() {
            return vc
        }
        else {
            fatalError("Couldn't find ViewController in Storyboard '\(storyboardName)' with the identifier \(storyboardIdentifier) or as the initial view controller. If the initial view controller in the storyboard is a UINavigation controller, try using `initFromStoryboardWithNavigationViewController`")
        }
    }

    static func loadFromStoryboardWithNavController() -> (UINavigationController, Self) {
        if  let navVC = storyboard.instantiateInitialViewController() as? UINavigationController,
            let vc = navVC.topViewController as? Self {
            return (navVC, vc)
        }
        else if let vc = findViewController() {
            return (UINavigationController(rootViewController: vc), vc)
        }
        else {
            fatalError("Couldn't find ViewController in Storyboard '\(storyboardName)' with the identifier \(storyboardIdentifier) or as the rootViewController of an initial UINavigationController.")
        }
    }

    private static func findViewController() -> Self? {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        if let vc = storyboard.instantiateInitialViewController() as? Self {
            return vc
        }
        else if let vc = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as? Self {
            return vc
        }
        return nil
    }
}
