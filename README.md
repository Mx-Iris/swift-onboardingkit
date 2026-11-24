# swift-onboardingkit

Objective-C declarations and a Swift layer for OnBoardingKit, the private macOS framework behind the welcome, "What's New" and "Data & Privacy" pages of Apple's own apps.

## Overview

App Store, Freeform and Shortcuts build their welcome and "What's New" sheets from OnBoardingKit's template view, bullet list and container view controller; Mail, Music, TV, Photos and Books show their privacy pages through it. Apple ships no headers for it, only a text stub in the SDK.

The package has two modules:

- **`COnBoardingKit`** is one Objective-C header. It declares every class the SDK's `OnBoardingKit.tbd` exports (29 classes) and the 72 privacy identifiers, with the types recovered from the framework's code: typed collections, block signatures, nullability, and enums for the integers the framework takes. Each member carries the macOS release that introduced it; the deployment target is macOS 14.
- **`OnBoardingKit`** re-exports `COnBoardingKit` and adds what Swift is missing: a result builder for the bullet list, closures in place of the container's target/action buttons, `async` presentation of privacy pages, and initializers with default arguments.

[Documentations/Internal/DeclarationSources.md](Documentations/Internal/DeclarationSources.md) says where every declaration and type comes from and which members macOS releases removed.

## Requirements

- macOS 14 or later
- Swift tools version 6.2 or later

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Mx-Iris/swift-onboardingkit.git", from: "0.1.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: [.product(name: "OnBoardingKit", package: "swift-onboardingkit")]),
]
```

Use the `COnBoardingKit` product instead if you only want the declarations, for example from an Objective-C target.

The package links `OnBoardingKit.framework` from the SDK's `PrivateFrameworks` directory through unsafe linker flags. From tools version 6.2 on, SwiftPM no longer refuses dependencies that use unsafe flags. The framework is linked weakly, so an app that links the package still launches on a system without it.

## Usage

### A "What's New" sheet

```swift
import OnBoardingKit

let templateView = OBTemplateView(title: "What's New in Atlas", systemImage: "map") {
    OBTemplatePartBulletList.Item("Offline Maps", description: "Download a region and use it without a connection.", systemImage: "arrow.down.circle")
    OBTemplatePartBulletList.Item("Shared Trips", description: "Plan a route together.", systemImage: "person.2")
    if showsBetaFeatures {
        OBTemplatePartBulletList.Item("Live Traffic", description: "Updated every minute.", systemImage: "car", status: "Beta")
    }
}

let controller = OBTemplateContainerViewController(
    templateView: templateView,
    primaryButton: .init("Continue") { controller in controller.dismiss(nil) },
    cancelButton: .init("Not Now") { controller in controller.dismiss(nil) }
)
window.contentViewController?.presentAsSheet(controller)
```

The tray holds a primary, a secondary and a cancel button. Before macOS 26 the framework draws them as a first button, a link-styled button and a second button; `button(for:)` returns the right one on either. The primary button answers Return and the cancel button Escape.

### A privacy page

```swift
if let presenter = OBPrivacyPresenter(splashFor: .appStore) {
    await presenter.presentAsSheet(on: window)
    // The sheet has ended.
}
```

`OBPrivacyPresenter(unifiedAboutFor: [.appStore, .maps])` shows the combined "About Apple & Privacy" page for several bundles. To put the privacy link with its icon under a template, use `templateView.setPrivacyLinkForBundles([.appStore])`.

### From Objective-C

```objc
@import COnBoardingKit;

OBTemplateView *templateView = [[OBTemplateView alloc] initWithTitle:@"What's New" bodyText:nil symbol:@"sparkles" contentLayoutStyle:OBTemplateLayoutStyleDefault];
OBTemplatePartBulletList *bulletList = [[OBTemplatePartBulletList alloc] initWithFrame:NSZeroRect];
[bulletList addItemWithTitle:@"Offline Maps" description:@"Use a region without a connection." symbol:@"arrow.down.circle" symbolTintColor:nil];
templateView.contentArea = bulletList;
```

## Things to know

- **This is SPI.** Nothing here is promised by Apple, and any of it can change in an OS update. macOS 27.2 removed three members that 27.0 still had.
- **The framework is linked weakly.** On a system without it the app launches and every class of it is `nil`, so creating one would crash. Check first, for example with `NSClassFromString("OBTemplateContainerViewController") != nil`, and skip the page when it is missing.
- **The tests check the header against the running system.** `swift test` reads the header and fails on any declared class, method or property accessor the running macOS does not have, so a removal shows up as a failing test rather than an unrecognized-selector crash.
- **`OBTemplateView` builds its subviews the first time it draws.** Until then `subviews` is empty and `contentArea` is not in the hierarchy. Set its properties at any time before that.
- **`layoutStyle` is read only while the template view is created.** Pass it to the initializer.
- **`OBPrivacyPresenter` needs a window.** Without `presentingWindow`, `present()` shows nothing and never calls `dismissHandler`; `presentAsSheet(on:)` takes the window as an argument for that reason.
- **The enum names are this package's.** The framework passes plain integers and its binary carries no names for them; each value is named and documented for what macOS 27.2 does with it.
- Behaviour was checked on macOS 27.2. Availability comes from the framework's runtime metadata for every release from 11.0 to 27.2.

## License

MIT. See [LICENSE](LICENSE).
