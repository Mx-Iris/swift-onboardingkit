// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-onboardingkit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OnBoardingKit",
            targets: ["OnBoardingKit"]
        ),
        .library(
            name: "COnBoardingKit",
            targets: ["COnBoardingKit"]
        ),
    ],
    targets: [
        .target(
            name: "COnBoardingKit",
            linkerSettings: [
                // OnBoardingKit is a private framework; the SDK ships its text stub under PrivateFrameworks, which is
                // not on the default framework search path. From tools version 6.2 on, unsafe flags no longer stop
                // other packages from depending on this one.
                //
                // The framework is linked weakly: should a macOS release drop it, an app linking this package still
                // launches, and its classes look up as nil. Check that a class exists before using it.
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-Xlinker", "-weak_framework", "-Xlinker", "OnBoardingKit",
                ]),
            ]
        ),
        .target(
            name: "OnBoardingKit",
            dependencies: ["COnBoardingKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "COnBoardingKitTests",
            dependencies: ["COnBoardingKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "OnBoardingKitTests",
            dependencies: ["OnBoardingKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
