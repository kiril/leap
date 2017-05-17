//
//  TimeRangeObserver.swift
//  Leap
//
//  Created by Chris Ricca on 5/16/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

protocol TimeRangeObserverDelegate: class {
    func didObserveTimePerspectiveChange(on observer: TimeRangeObserver)
    func didObserveMinuteChangeWhenCurrent(on observer: TimeRangeObserver)
}

/*
 *  This class is designed to be used to 1) fire a block of code `currentRangeUpdateBlock` 1 / minute
 *  if the range is current (to update display) and to fire a method to inform a delegate if the time perspective has
 *  changed for the time range.
 *
 */

class TimeRangeObserver {
    let range: TimeRange
    weak var delegate: TimeRangeObserverDelegate?

    init(range: TimeRange) {
        self.range = range

        ensureCurrentUpdates()
    }

    private var currentTimer: Timer?
    private var lastPerspective: TimePerspective!

    private func ensureCurrentUpdates() {
        // this should be called once per event configuration
        let perspective = range.timePerspective
        guard perspective != .past else {
            cancelCurrentEventTimer()
            return
        }

        lastPerspective = perspective

        setupCurrentDisplayTimer()
    }

    private func nextRoundMinute() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.era,.year,.month,.day,.hour,.minute], from: now)
        components.setValue(components.minute! + 1, for: .minute)
        return calendar.date(from: components)!
    }

    private func setupCurrentDisplayTimer() {
        guard currentTimer == nil else { return }

        currentTimer = Timer(fire: nextRoundMinute(), interval: 60, repeats: true) { [weak self] timer in
            guard   let _self = self else {
                timer.invalidate()
                return
            }

            let perspective = _self.range.timePerspective

            if _self.lastPerspective != perspective {
                _self.delegate?.didObserveTimePerspectiveChange(on: _self)
            }
            if perspective == .current {
                _self.delegate?.didObserveMinuteChangeWhenCurrent(on: _self)
            }

            _self.ensureCurrentUpdates()
        }

        let runLoop = RunLoop.current
        runLoop.add(currentTimer!, forMode: .defaultRunLoopMode)
    }

    private func cancelCurrentEventTimer() {
        currentTimer?.invalidate()
        currentTimer = nil
    }
}
