//
//  DIAssembly.swift
//  AppDI
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// DI 등록을 담당하는 Assembly 프로토콜
public protocol DIAssembly {
    /// 컨테이너에 의존성 등록
    /// - Parameter container: 등록할 DI 컨테이너
    static func register(in container: AppDIContainer)
}
