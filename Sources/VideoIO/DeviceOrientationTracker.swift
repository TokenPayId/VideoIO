//
//  File.swift
//  
//
//  Created by Yu Ao on 2019/12/27.
//

import Foundation

#if canImport(CoreMotion) && canImport(UIKit)
import CoreMotion
import UIKit
import AVFoundation

public protocol DeviceOrientationTrackerDelegate: class {
    func deviceOrientationUpdated(tracker: DeviceOrientationTracker, orientation: UIDeviceOrientation)
}

@available(macOS, unavailable)
public class DeviceOrientationTracker {
    
    private let motionManager = CMMotionManager()
    
    private let queue: OperationQueue
    
    // Access in `queue`.
    private var _deviceOrientation: UIDeviceOrientation = .unknown
    
    // Access in main queue.
    public var deviceOrientation: UIDeviceOrientation = .unknown
    
    public weak var delegate: DeviceOrientationTrackerDelegate?
    
    public init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        motionManager.accelerometerUpdateInterval = 0.33
        motionManager.deviceMotionUpdateInterval = 0.33
        motionManager.gyroUpdateInterval = 0.33
        motionManager.magnetometerUpdateInterval = 0.33
    }
    
    private func handle(motionData: CMDeviceMotion) {
        let acceleration = motionData.gravity
        let xx = -acceleration.x
        let yy = acceleration.y
        let z = acceleration.z
        let angle = atan2(yy, xx)
        var deviceOrientation = _deviceOrientation
        let absoluteZ = fabs(z)
        
        if deviceOrientation == .faceUp || deviceOrientation == .faceDown {
            if absoluteZ < 0.845 {
                if angle < -2.6 {
                    deviceOrientation = .landscapeRight
                } else if angle > -2.05 && angle < -1.1 {
                    deviceOrientation = .portrait
                } else if angle > -0.48 && angle < 0.48 {
                    deviceOrientation = .landscapeLeft
                } else if angle > 1.08 && angle < 2.08 {
                    deviceOrientation = .portraitUpsideDown
                }
            } else if z < 0 {
                deviceOrientation = .faceUp
            } else if z > 0 {
                deviceOrientation = .faceDown
            }
        } else {
            if z > 0.875 {
                deviceOrientation = .faceDown
            } else if z < -0.875 {
                deviceOrientation = .faceUp
            } else {
                switch deviceOrientation {
                case .landscapeLeft:
                    if angle < -1.07 {
                        deviceOrientation = .portrait
                    }
                    if angle > 1.08 {
                        deviceOrientation = .portraitUpsideDown
                    }
                case .landscapeRight:
                    if angle < 0 && angle > -2.05 {
                        deviceOrientation = .portrait
                    }
                    if angle > 0 && angle < 2.05 {
                        deviceOrientation = .portraitUpsideDown
                    }
                case .portraitUpsideDown:
                    if angle > 2.66 {
                        deviceOrientation = .landscapeRight
                    }
                    if angle < 0.48 {
                        deviceOrientation = .landscapeLeft
                    }
                case .portrait:
                    if angle > -0.47 {
                        deviceOrientation = .landscapeLeft
                    }
                    if angle < -2.64 {
                        deviceOrientation = .landscapeRight
                    }
                default:
                    if angle > -0.47 {
                        deviceOrientation = .landscapeLeft
                    }
                    if angle < -2.64 {
                        deviceOrientation = .landscapeRight
                    }
                }
            }
        }
        
        if _deviceOrientation != deviceOrientation {
            _deviceOrientation = deviceOrientation
            DispatchQueue.main.async {
                self.deviceOrientation = deviceOrientation
                self.delegate?.deviceOrientationUpdated(tracker: self, orientation: deviceOrientation)
            }
        }
    }
    
    public func start() {
        guard motionManager.isDeviceMotionAvailable else {
            assertionFailure()
            return
        }
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (motionData, error) in
            guard let strongSelf = self, let motionData = motionData else {
                return
            }
            strongSelf.handle(motionData: motionData)
        }
        queue.addOperation { [weak self] in
            guard let strongSelf = self, let motionData = strongSelf.motionManager.deviceMotion else {
                return
            }
            strongSelf.handle(motionData: motionData)
        }
    }
    
    public func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}

#endif
