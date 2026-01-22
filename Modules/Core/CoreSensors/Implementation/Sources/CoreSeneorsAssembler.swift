//
//  CoreSeneorsAssembler.swift
//  CoreSensorsInterface
//
//  Created by 웅 on 1/22/26.
//

import Foundation
import CoreSensorsInterface

public enum CoreSeneorsAssembler: CoreSensorsAssembling {
    public static func assemble() -> any CoreSensorsInterface {
        return CoreSensorsService()
    }
}
