struct GeneratedFoundationPlanProvenance: Equatable {
    let projectID: String
    let graphVersion: Int
    let targetID: String
    let targetProfile: String
    let loweringRelease: String
    let sourceSHA256: String
}

enum GeneratedApplication {
    static let appearance = ApplicationAppearance(theme: .light)
    static let applicationKeyComponent = "reading-list"
    static let displayName = "Reading List"
    static let railsOrigin = "https://reading-list.invalid"
    static let bundleIdentifier = "invalid.firstdraft.reading-list"
    static let usesPlaceholderIdentity = true
    static let foundationPlan = GeneratedFoundationPlanProvenance(
        projectID: "01a0d534-d210-7dae-8b95-494b32694043",
        graphVersion: 1,
        targetID: "rails",
        targetProfile: "rails-sketch/2026-09",
        loweringRelease: "foundation-plan-rails/ios-application-2026-08",
        sourceSHA256: "3096a118457dd09f41ecdd482cd5788152895aeeda77bd5f3d3914a958aa904b"
    )
    static let navigation = [
        AppNavigationDefinition(
            id: "entity-index:01a0d534-d39d-7392-a0d1-604fc1c20526",
            title: "Books",
            systemImageName: "bookmark",
            selectedSystemImageName: "bookmark.fill",
            path: "/books"
        )
    ]
}
