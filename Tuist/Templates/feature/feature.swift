import ProjectDescription

let nameAttribute = Template.Attribute.required("name")

let template = Template(
    description: "Feature 모듈 생성 (Interface + Implementation + Demo)",
    attributes: [nameAttribute],
    items: [
        // Project.swift
        .file(
            path: "Modules/Feature/\(nameAttribute)/Project.swift",
            templatePath: "Project.stencil"
        ),
        // Interface
        .file(
            path: "Modules/Feature/\(nameAttribute)/Interface/Sources/\(nameAttribute)Assembling.swift",
            templatePath: "Assembling.stencil"
        ),
        .file(
            path: "Modules/Feature/\(nameAttribute)/Interface/Sources/\(nameAttribute)State.swift",
            templatePath: "State.stencil"
        ),
        .file(
            path: "Modules/Feature/\(nameAttribute)/Interface/Sources/\(nameAttribute)Intent.swift",
            templatePath: "Intent.stencil"
        ),
        // Implementation
        .file(
            path: "Modules/Feature/\(nameAttribute)/Implementation/Sources/DI/\(nameAttribute)FeatureBuilder.swift",
            templatePath: "FeatureBuilder.stencil"
        ),
        .file(
            path: "Modules/Feature/\(nameAttribute)/Implementation/Sources/Store/\(nameAttribute)Store.swift",
            templatePath: "Store.stencil"
        ),
        .file(
            path: "Modules/Feature/\(nameAttribute)/Implementation/Sources/View/\(nameAttribute)View.swift",
            templatePath: "View.stencil"
        ),
        // Demo
        .file(
            path: "Modules/Feature/\(nameAttribute)/Demo/Sources/\(nameAttribute)DemoApp.swift",
            templatePath: "DemoApp.stencil"
        ),
    ]
)
