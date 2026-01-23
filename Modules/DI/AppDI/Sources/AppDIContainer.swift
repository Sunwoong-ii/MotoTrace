//
//  AppDIContainer.swift
//  AppDI
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// DI 컨테이너: 의존성 등록 및 해결
public final class AppDIContainer {
    private var singletons: [String: Any] = [:]
    private var factories: [String: (scope: DIScope, factory: () -> Any)] = [:]
    
    public init() {}
    
    /// 의존성 등록
    /// - Parameters:
    ///   - type: 등록할 타입 (프로토콜 권장)
    ///   - scope: 생명주기 (.singleton 또는 .transient)
    ///   - factory: 객체 생성 클로저
    public func register<T>(
        _ type: T.Type,
        scope: DIScope = .singleton,
        factory: @escaping () -> T
    ) {
        let key = String(describing: type)
        factories[key] = (scope: scope, factory: factory)
        
        // scope 변경 시 기존 singleton 제거
        if scope == .transient {
            singletons.removeValue(forKey: key)
        }
    }
    
    /// 의존성 해결 (객체 반환)
    /// - Parameter type: 해결할 타입
    /// - Returns: 등록된 객체 또는 새 객체
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let entry = factories[key] else {
            fatalError("❌ DI Error: Type '\(type)' is not registered in AppDIContainer")
        }
        
        switch entry.scope {
        case .singleton:
            if let cached = singletons[key] as? T {
                return cached
            }
            let new = entry.factory() as! T
            singletons[key] = new
            return new
        case .transient:
            return entry.factory() as! T
        }
    }
    
    /// 등록된 의존성 제거 (테스트용)
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        factories.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
    }
    
    /// 모든 의존성 초기화 (테스트용)
    public func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}
