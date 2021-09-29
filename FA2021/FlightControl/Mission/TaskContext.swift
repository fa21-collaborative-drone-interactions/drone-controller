//
//  TaskContext.swift
//  FA2021
//
//  Created by Kevin Huang on 26.09.21.
//

import Foundation

class TaskContext {
    private let missionScheduler: MissionScheduler
    private var currentStepIndex: Int = -1
    private var task = [Step]()
    var currentStep: Step? {
        get {
            if task.isEmpty || currentStepIndex < 0 || currentStepIndex >= task.endIndex {
                return nil
            }
            return task[currentStepIndex]
        }
    }
    private let log: Log
    
    init(log: Log, aircraftController: AircraftController) {
        self.missionScheduler = MissionScheduler(log: log, aircraftController: aircraftController)
        self.log = log
    }
    
    func runSampleTask() {
        print("start sample task")
        self.add(steps: [TakingOff(altitude: 10), Idling(duration: 8), Landing()])
        self.startTask()
        print("started sample task")
    }
    
    /**
     Adds a step to a Task that should be executed by the Aircraft. The step is appended to the end.
     
     A step can be added even when a task has already started, but new steps are only executed if the task has not completed yet.
     */
    func add(step: Step) {
        self.task.append(step)
    }
    
    /**
     Adds multiple steps to a Task that should be executed by the Aircraft. The steps are appended to the end.
     
     A step can be added even when a task has already started, but new steps are only executed if the task has not completed yet.
     */
    func add(steps: [Step]) {
        self.task.append(contentsOf: steps)
    }
    
    /**
     Sets the pointer to the first step of a Task and begins the execution of the task.
     */
    func startTask() {
        if !missionScheduler.aircraftController.isReady {
            self.log.add(message: "The aircraft is not ready yet, waiting 1s before retrying")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.startTask()
            })
            
            return
        }
        if missionScheduler.missionActive {
            self.log.add(message: "The aircraft is already executing a mission")
            return
        }
        
        log.add(message: "Starting Task")
        reset()
        executeNextStep()
    }
    
    func stopTask() {
        missionScheduler.stopAndClearMissionIfRunning()
        reset()
    }
    
    func stopAndClearTask() {
        stopTask()
        task.removeAll()
    }
    
    /**
     Resets the step pointer and marks all steps as "not done". Any steps that are currently executed will NOT be cancelled.
     Call stopTask() instead.
     */
    private func reset() {
        log.add(message: "Resetting Task Steps")
        
        currentStepIndex = -1
        for var step in task {
            step.done = false
        }
    }
    
    private func executeNextStep() {
        log.add(message: "Incrementing step counter")
        currentStepIndex += 1
        
        guard let currentStep = currentStep
        else {
            log.add(message: "No step to execute")
            return
        }
        
        log.add(message: currentStep.description)
        currentStep.execute(missionScheduler: missionScheduler)
        checkDone()
    }
    
    private func checkDone() {
        log.add(message: "Check done")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if self.currentStep == nil {
                return
            }
            
            if self.currentStep!.done {
                self.executeNextStep()
            }
            self.checkDone()
        })
    }
}
