//
//  DroneController.swift
//  FA2021
//
//  Created by Kevin Huang on 25.09.21.
//

import Foundation
import DJISDK

class DroneConnectionManager: NSObject, ObservableObject {
    @Published var product: DJIBaseProduct?
    @Published var aircraft: DJIAircraft?
    @Published var missionControl: DJIMissionControl?
    private var state: DroneControllerState
    
    override init() {
        self.state = .initialized
        super.init()
        
        registerSDK()
        connectProductAndAnnounce()
    }
    
    private func connectProductAndAnnounce() {
        self.state = .connecting
        Logger.getInstance().add(message: "Connecting to product")
        
        DJISDKManager.startConnectionToProduct()
        
        Logger.getInstance().add(message: "Creating connected key")
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            Logger.getInstance().add(message: "Error creating the connectedKey")
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    if newValue!.boolValue {
                        // At this point, a product is connected so we can show it.
                        
                        // UI goes on MT.
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
            DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                if let unwrappedValue = value {
                    if unwrappedValue.boolValue {
                        // UI goes on MT.
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
        }
    }
    
    private func productConnected() {
        self.state = .connected
        guard let newProduct = DJISDKManager.product() else {
            // Product is connected but DJISDKManager.product is nil -> something is wrong
            Logger.getInstance().add(message: "Status: Identifying product.")
            self.connectProductAndAnnounce()
            return
        }
        
        // Announce the product's model
        Logger.getInstance().add(message: "Status: Connected. Model: \((newProduct.model)!)")
        
        product = newProduct
        
        if product!.isKind(of: DJIAircraft.self) {
            aircraft = product as? DJIAircraft
            missionControl = DJISDKManager.missionControl()
        }
    }
    
    func isProductAvailable() -> Bool {
        return self.product != nil
    }
}

extension DroneConnectionManager: DJISDKManagerDelegate {
    private func registerSDK() {
        Logger.getInstance().add(message: "Registering SDK")
        state = .sdkRegistration
        
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        
        guard appKey != nil && appKey!.isEmpty == false else {
            Logger.getInstance().add(message: "Please enter your app key in the info.plist")
            return
        }
        DJISDKManager.registerApp(with: self)
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if (error != nil) {
            state = .error(problem: error.debugDescription)
            Logger.getInstance().add(message: "Registering SDK failed " + error.debugDescription)
        } else {
            state = .sdkRegistered
            Logger.getInstance().add(message: "Registering SDK successful")
        }
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        
    }
}

enum DroneControllerState {
    case error(problem: String)
    case initialized
    case sdkRegistration
    case sdkRegistered
    case connecting
    case connected
}
