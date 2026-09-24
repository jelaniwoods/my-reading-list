import Foundation
import HotwireNative
import Testing
import UIKit

@testable import FoundationApp

@MainActor
struct GeneratedApplicationDefinitionTests {
    @Test
    func definesFoundationPlanNavigation() {
        let rootURL = URL(string: "https://app.example.test")!
        let entries = AppNavigation.make(rootURL: rootURL)
        let container = AppNavigationContainer(entries: entries)

        #expect(
            GeneratedApplication.navigation.map(\.id) == [
                "entity-index:01a0d534-d39d-7392-a0d1-604fc1c20526"
            ]
        )
        #expect(
            GeneratedApplication.navigation.map(\.title) == [
                "Books"
            ]
        )
        #expect(
            GeneratedApplication.navigation.map(\.systemImageName) == [
                "bookmark"
            ]
        )
        #expect(
            GeneratedApplication.navigation.map(\.selectedSystemImageName) == [
                "bookmark.fill"
            ]
        )
        #expect(
            GeneratedApplication.navigation.map(\.path) == [
                "/books"
            ]
        )
        #expect(
            entries.map(\.id) == [
                "entity-index:01a0d534-d39d-7392-a0d1-604fc1c20526"
            ]
        )
        #expect(
            entries.map(\.title) == [
                "Books"
            ]
        )
        #expect(
            entries.map(\.url.path) == [
                "/books"
            ]
        )
        #expect(entries.allSatisfy { $0.image != nil })
        #expect(entries.allSatisfy { $0.selectedImage != nil })
        #expect(container.rootViewController is UINavigationController)
        #expect(!(container.rootViewController is UITabBarController))
    }

    @Test
    func identifiesTheGeneratedApplicationAndFoundationPlan() {
        #expect(
            GeneratedApplication.appearance.interfaceStyle
                == .light
        )
        #expect(
            GeneratedApplication.applicationKeyComponent
                == "reading-list"
        )
        #expect(
            GeneratedApplication.displayName
                == "Reading List"
        )
        #expect(
            GeneratedApplication.railsOrigin
                == "https://reading-list.invalid"
        )
        #expect(
            GeneratedApplication.bundleIdentifier
                == "invalid.firstdraft.reading-list"
        )
        #expect(
            GeneratedApplication.usesPlaceholderIdentity
                == true
        )
        #expect(
            GeneratedApplication.foundationPlan.projectID
                == "01a0d534-d210-7dae-8b95-494b32694043"
        )
        #expect(
            GeneratedApplication.foundationPlan.graphVersion
                == 1
        )
        #expect(
            GeneratedApplication.foundationPlan.targetID
                == "rails"
        )
        #expect(
            GeneratedApplication.foundationPlan.targetProfile
                == "rails-sketch/2026-09"
        )
        #expect(
            GeneratedApplication.foundationPlan.loweringRelease
                == "foundation-plan-rails/ios-application-2026-08"
        )
        #expect(
            GeneratedApplication.foundationPlan.sourceSHA256
                == "3096a118457dd09f41ecdd482cd5788152895aeeda77bd5f3d3914a958aa904b"
        )
        #expect(
            Bundle.main.object(
                forInfoDictionaryKey: "FoundationPlanSHA256"
            ) as? String == GeneratedApplication.foundationPlan.sourceSHA256
        )
    }
}
