//
//  DIScope.swift
//  AppDI
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// 의존성 객체의 생명주기 정의
public enum DIScope {
    /// 싱글톤: 첫 resolve 시 생성 후 재사용
    case singleton
    /// 일시적: resolve 호출 시마다 새 객체 생성
    case transient
}
