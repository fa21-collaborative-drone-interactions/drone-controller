//
//  DroneController.swift
//  FA2021
//
//  Created by Kevin Huang on 25.09.21.
//

import Foundation
import DJISDK
import Combine

class AircraftController: ObservableObject {
    private var droneConnection: DroneConnectionManager
    @Published private(set) var state: DroneState
    
    private var droneConnectionCancellable: AnyCancellable?
    
    /**
     The current location of the aircraft as a coordinate. `nil` if the location is invalid.
     
     [DJI SDK Documentation](https://developer.dji.com/api-reference/ios-api/Components/FlightController/DJIFlightController_DJIFlightControllerCurrentState.html#djiflightcontroller_djiflightcontrollercurrentstate_aircraftlocation_inline)
     */
    var aircraftPosition: CLLocationCoordinate2D? {
        get {
            guard let key = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)
            else {
                Logger.getInstance().add(message: "Cannot retrieve current location: Missing Controller Key")
                return nil
            }
            
            let value = DJISDKManager.keyManager()?.getValueFor(key)
            guard let location = value?.value as? CLLocation else {
                Logger.getInstance().add(message: "Cannot retrieve current location")
                return nil
            }
            
            return location.coordinate
        }
    }
    
    /**
     Relative altitude of the aircraft relative to take off location, measured by the barometer, in meters.
     
     [DJI SDK Documentation](https://developer.dji.com/api-reference/ios-api/Components/FlightController/DJIFlightController_DJIFlightControllerCurrentState.html#djiflightcontroller_djiflightcontrollercurrentstate_altitude_inline)
     */
    var aircraftAltitude: Double? {
        get {
            guard let key = DJIFlightControllerKey(param: DJIFlightControllerParamAltitudeInMeters)
            else {
                Logger.getInstance().add(message: "Cannot retrieve current altitude: Missing Controller Key")
                return nil
            }
            
            let value = DJISDKManager.keyManager()?.getValueFor(key)
            guard let altitude = value?.value as? Double else {
                Logger.getInstance().add(message: "Cannot retrieve current altitude")
                return nil
            }
            
            return altitude
        }
    }
    
    /**
     GPS signal levels, which are used to measure the signal quality.

     [DJI SDK Documentation](https://developer.dji.com/api-reference/ios-api/Components/FlightController/DJIFlightController_DJIFlightControllerCurrentState.html#djiflightcontroller_djigpssignalstatus_inline)
     */
    var gpsSignalLevel: DJIGPSSignalLevel? {
        get {
            guard let key = DJIFlightControllerKey(param: DJIFlightControllerParamGPSSignalStatus)
            else {
                Logger.getInstance().add(message: "Cannot retrieve current GPS Signal Level: Missing Controller Key")
                return nil
            }
            
            let value = DJISDKManager.keyManager()?.getValueFor(key)
            guard let gpsSignalLevel = value?.value as? DJIGPSSignalLevel else {
                Logger.getInstance().add(message: "Cannot retrieve current GPS Signal Level")
                return nil
            }
            
            return gpsSignalLevel
        }
    }
    
    var isReady: Bool {
        get {
            return droneConnection.aircraft != nil
        }
    }
    
    init(droneConnection: DroneConnectionManager) {
        self.state = .onGround
        self.droneConnection = droneConnection
    }
    
    func takeOff(completion: @escaping () -> Void) {
        droneConnection.aircraft?.flightController?.startTakeoff {_ in
            Logger.getInstance().add(message: "Take off command sent")
            self.state = .inAir
            completion()
        }
    }
    
    func land() {
        droneConnection.aircraft?.flightController?.startLanding {_ in
            Logger.getInstance().add(message: "Landing command sent")
            self.state = .onGround
        }
    }
}

enum DroneState {
    case inAir
    case onGround
}
