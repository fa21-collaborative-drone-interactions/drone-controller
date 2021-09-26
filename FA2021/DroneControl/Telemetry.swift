//
//  Telemetry.swift
//  FA2021
//
//  Created by FA21 on 26.09.21.
//

import Foundation
import RxSwift

class Telemetry {
    let api: CoatyAPI
    
    init(api: CoatyAPI){
        
        self.api = api
        
        // sending mock data currently
        _ = Observable
             .timer(RxTimeInterval.seconds(0),
                    period: RxTimeInterval.seconds(1),
                    scheduler: MainScheduler.instance)
            .subscribe(onNext: { (i: Int) in
                self.api.postLiveData(data: """
                    {
                        "position":{
                            "latitude":\(46.74588+0.0005*sin(Float(i)/5)),
                            "longitude":\(11.35683+0.0005*cos(Float(i)/5)),
                            "altitude":\(26+(i%50))
                        },
                        "speed":5,
                        "batteryLevel":\(100-((i/4)%100)),
                        "tasks":[
                            {
                                "task_id":"123",
                                "status": "claimed"
                            },
                            {
                                "task_id":"321",
                                "status": "finished"
                            }
                        ],
                        "drone_id": "123"
                    }
                """)
             })
    }
}

