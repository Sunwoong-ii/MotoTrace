//
//  Target+Templates.swift
//  Config
//
//  Created by 웅 on 1/20/26.
//

import ProjectDescription

public extension ProjectDescription.TargetDependency {
    static func makeDependency(name: ModuleName) -> Self {
        return .project(target: name.rawValue, path: .relativeToRoot(name.path))
    }
    
    static func makeInterfaceDependency(name: ModuleName) -> Self {
        return .project(target: name.rawValue + "Interface", path: .relativeToRoot(name.path))
    }
}
