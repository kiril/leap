//
//  EventRepresentation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


class EventRepresentation: Representation {
    var title: String {
        return self.data["title"] as? String ?? ""
    }

    var startTime: String {
        get {
            return self.data["start_time"] as? String ?? ""
        }
    }

    var timeRange: String {
        get {
            return self.data["time_range"] as? String ?? ""
        }
    }

    var location: String {
        return self.data["location"] as? String ?? ""
    }
}
