//  CoreSensorsFactory.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//
import CoreSensorsInterface

public enum CoreSensorsFactory {
    public static func create() -> CoreSensorsInterface {
        CoreSensorsService()
    }
}
