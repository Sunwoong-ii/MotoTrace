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
    private var factories: [String: Any] = [:]
    private var scopes: [String: DIScope] = [:]
    
    public init() {}
    
    // MARK: - Register (파라미터 없는 경우)
    
    /// 의존성 등록 (파라미터 없음)
    /// - Parameters:
    ///   - type: 등록할 타입 (프로토콜 권장)
    ///   - scope: 생명주기 (.singleton 또는 .transient)
    ///   - factory: 객체 생성 클로저
    public func register<T>(
        _ type: T.Type,
        scope: DIScope = .transient,
        factory: @escaping () -> T
    ) {
        let key = String(describing: type)
        factories[key] = factory
        scopes[key] = scope
        
        // scope 변경 시 기존 singleton 제거
        if scope == .transient {
            singletons.removeValue(forKey: key)
        }
    }
    
    // MARK: - Register (파라미터 1개)
    
    /// 의존성 등록 (파라미터 1개)
    /// - Parameters:
    ///   - type: 등록할 타입
    ///   - scope: 생명주기 (파라미터가 있으면 singleton 불가, 항상 transient로 동작)
    ///   - factory: 파라미터를 받는 객체 생성 클로저
    public func register<T, P>(
        _ type: T.Type,
        scope: DIScope = .transient,
        factory: @escaping (P) -> T
    ) {
        let key = parameterizedKey(for: type, paramType: P.self)
        factories[key] = factory
        scopes[key] = scope
        
        // 파라미터가 있는 경우 singleton 캐싱 제거
        singletons.removeValue(forKey: key)
    }
    
    // MARK: - Resolve (파라미터 없는 경우)
    
    /// 의존성 해결 (파라미터 없음)
    /// - Parameter type: 해결할 타입
    /// - Returns: 등록된 객체 또는 새 객체
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        guard let factory = factories[key] as? () -> T else {
            fatalError("❌ DI Error: Type '\(type)' is not registered in AppDIContainer")
        }
        
        guard let scope = scopes[key] else {
            fatalError("❌ DI Error: Scope not found for '\(type)'")
        }
        
        switch scope {
        case .singleton:
            if let cached = singletons[key] as? T {
                return cached
            }
            let new = factory()
            singletons[key] = new
            return new
        case .transient:
            return factory()
        }
    }
    
    // MARK: - Resolve (파라미터 1개)
    
    /// 의존성 해결 (파라미터 1개)
    /// - Parameters:
    ///   - type: 해결할 타입
    ///   - param: factory에 전달할 파라미터
    /// - Returns: 생성된 객체
    public func resolve<T, P>(_ type: T.Type, with param: P) -> T {
        let key = parameterizedKey(for: type, paramType: P.self)
        
        guard let factory = factories[key] as? (P) -> T else {
            fatalError("❌ DI Error: Type '\(type)' with parameter '\(P.self)' is not registered in AppDIContainer")
        }
        
        // 파라미터가 있는 경우는 항상 새 객체 생성 (singleton 불가)
        return factory(param)
    }
    
    // MARK: - Utilities
    
    /// 등록된 의존성 제거 (테스트용)
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        factories.removeValue(forKey: key)
        scopes.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
    }
    
    /// 모든 의존성 초기화 (테스트용)
    public func reset() {
        factories.removeAll()
        scopes.removeAll()
        singletons.removeAll()
    }
    
    // MARK: - Private
    
    private func parameterizedKey<T, P>(for type: T.Type, paramType: P.Type) -> String {
        return "\(String(describing: type))_\(String(describing: paramType))"
    }
}
