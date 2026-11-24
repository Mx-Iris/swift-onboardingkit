# OnBoardingKit 声明：实现说明

> 配套提案见 [0001-objective-c-declarations-and-swift-layer](../Evolutions/0001-objective-c-declarations-and-swift-layer.md)。
> 本文记录 `OnBoardingKitPrivateAPI.h` 里每条声明从哪来、按什么规则取舍、怎样在新系统上核对，以及 Swift 层依赖的几条框架行为。面向维护者。

## 背景与目标

OnBoardingKit 是 macOS 的私有框架，App Store、Freeform、Shortcuts 的欢迎页和 "What's New" 页，以及 Mail、Music、TV、Photos、Books 的隐私页都用它。SDK 里只有它的 `.tbd`，没有头文件。本包的 `COnBoardingKit` 模块是一份手写的头文件，`OnBoardingKit` 模块在上面加一层 Swift 便利接口。

## 关键设计决策

**声明范围以 `.tbd` 为准，成员以本机运行时为准。** 27.2 SDK 的 `OnBoardingKit.tbd` 导出 29 个类、72 个隐私标识常量，外加 `OBProcessNameForPID`、`_OBLoggingEnabled`、`_OBLoggingFacility`。类和常量全部声明；后三个是框架内部的日志与进程工具，没有调用价值，不声明。成员先从演进接口文件（`macOS-27.0.0-OnBoardingKit-ObjCEvolutionInterface.h`，覆盖 11.0 到 27.0 的 51 个版本）取，再用本机 27.2.1 的运行时逐个核对：27.2 又删了三个成员，见下文「各版本删掉的成员」。

**哪些成员不声明。** 四类：
- 实例变量与 `.cxx_destruct`；
- 下划线开头的方法；
- 对 AppKit 方法的覆写（`loadView`、`viewDidLoad`、`updateLayer`、`viewWillDraw`、`mouseUp:`、`initWithCoder:` 等），它们从父类继承就能调用，重新声明没有意义；
- 只为框架自己的布局与缓存服务的属性和方法：约束（`buttonConstraints`、`trailingConstraint`……）、计时器、缓存（`cachedBundle`、`cachedAllBundles`……）、内部搭建方法（`commonInit`、`makeButtonTray`、`setViewDefaults`、`prepareContentView`……）和按钮的内部动作方法（`donePressed:`、`morePressed:`、`viewPressed:`、`linkPressed`）。其中 `commonInit` 这类方法再调一次会重建视图，声明出来只会被误用。

**类型怎么定。** 运行时元数据只给 `id` 和不带签名的 block。类型来自三处，按可信程度排：
1. 框架自己的代码（macOS 27.2 归档 cache 反编译并对照汇编，IDA 数据库在 `/Volumes/DyldSharedCaches/macOS/27.2/OnBoardingKit.i64`）：所有 block 签名、整数参数的取值、集合的元素类型、工厂方法实际返回的类，以及下文「Swift 层依赖的行为」。
2. 同名属性与实例变量的类型（`title` 属性是 `NSString *`，`setTitle:` 的参数就是 `NSString *`）。
3. 选择子的字面意思。只靠这一条定下的声明在注释里标 `[unverified]`，目前只有 `+[OBBundle identifierWithName:]` 与 `+nameFromIdentifier:`。

**枚举是本包起的名字。** 框架只传整数，二进制里没有这些值的名字。`OBTemplateLayoutStyle`、`OBTemplateType`、`OBBulletListSpacing`、`OBDeviceType`、`OBBundleInclusionOptions` 的每个值按 27.2 上的行为命名并写明效果。它们与框架的 ABI 一致（底层类型与位宽相同），换名字不影响调用。

**可用性。** 部署目标是 macOS 14.0。没有 `API_AVAILABLE` 的成员在 14.0 上就有；标了的写明第一个有它的版本，取自演进接口文件的版本位图。唯一一个晚于 14.0 的类是 `OBPrivacyCombinedFooterComponents`（15.2）。

**Swift 名写在头文件的宏里，不写 apinotes。** 头文件是本包自己的，宏写在声明上读的人只看一处。改过的有：72 个常量去掉 `Identifier` 后缀（`.appStore`）；`OBPrivacyPresenter` 的工厂改成 `init?(splashFor:)`、`init?(unifiedAboutFor:)` 等；`OBPrivacyLinkController` 基类的构造器在 Swift 里不可用（只有工厂方法返回的 `_macOS` 子类才建视图）；拼错的 `presenterForPrivacySplashWithIdentifer:` 在 Swift 里不可用。

**`OBPrivacyPresenter` 与 `OBAnimationController` 标 `NS_SWIFT_UI_ACTOR`。** 其余 UI 类继承自 `NSView` / `NSViewController` / `NSWindowController`，本来就在主 actor 上。

## 模块结构

```
Sources/
├── COnBoardingKit/
│   ├── COnBoardingKit.m                    # Empty: SwiftPM needs one source file in a C-family target
│   └── include/
│       ├── module.modulemap
│       └── OnBoardingKitPrivateAPI.h       # Every declaration, enums and privacy identifiers included
└── OnBoardingKit/
    ├── Exports.swift                       # @_exported import COnBoardingKit
    ├── BulletListItem.swift                # Item value, ItemBuilder result builder, addItem(_:)
    ├── TemplateView.swift                  # Convenience initializers with defaults and a features builder
    ├── TemplateContainerButtons.swift      # ButtonRole, Button, closures in place of target/action
    ├── TemplateContainerSizing.swift       # sheetSize(forParentWindowSize:), the framework's sheet size
    └── PrivacyPresenterPresentation.swift  # presentAsSheet(on:) async
Tests/
├── COnBoardingKitTests/                    # Reads the header and checks it against the running system
└── OnBoardingKitTests/                     # The Swift layer
```

## Swift 层依赖的框架行为

都在 macOS 27.2 上从反编译确认，地址属于 27.2 归档 cache 的构建。

- **容器的按钮没有 target、action 和快捷键。** `OBTemplateContainerViewController` 用 `buttonWithTitle:target:nil action:nil` 建按钮，也不设 `keyEquivalent`；框架自己的隐私页是自己接 `donePressed:` 和 `\r` 的。所以 `setAction(for:_:)` 替按钮接上闭包，并给主按钮设 Return、取消按钮设 Escape。
- **新旧两套按钮的对应。** 指定构造器是 `initWithFirstButtonTitle:secondButtonTitle:linkButtonTitle:`（`0x1C3887B28`），其余三个都汇入它；26 起的 `initWithPrimary…` 只是换了参数顺序转调。对应关系是 first = primary、second = cancel、link = secondary。Swift 层因此在所有系统上都用 first/second/link 构造器，取按钮时按系统版本选 `primaryButton` 或 `firstButton`。26 之前 link 按钮是 `OBTemplatePartLinkButton`，画成链接。
- **空标题的按钮会隐藏。** secondary 和 cancel 的标题为 nil 时代入空串，空串标题的按钮被隐藏。primary 的标题不做 nil 处理，所以头文件把它标成非空。
- **按钮在构造器里就建好了**，不等 `loadView`（测试里不加载视图也取得到按钮）。
- **`OBPrivacyPresenter.present` 必须有 `presentingWindow`。** 没有窗口时只记一条日志就返回，`dismissHandler` 也不会被调用；有窗口时一律以 sheet 弹出，sheet 结束时先 `endSheet:`，再调 `dismissHandler`。`presentAsSheet(on:)` 因此要求传窗口，并靠 `dismissHandler` 恢复等待。
- **`OBTemplateView` 在第一次绘制前才搭子视图。** 创建、放进窗口、`layoutSubtreeIfNeeded`、窗口 `displayIfNeeded`（窗口没显示时）都不会触发；只有 `viewWillDraw` 会。测试里直接调 `viewWillDraw()` 代替第一次绘制，不必把窗口放到屏幕上。
- **模板视图会把容器钉成 0 × 0。** `OBTemplateView` 的构造器给它零尺寸，`translatesAutoresizingMaskIntoConstraints` 保持默认的 `true`；`-[OBTemplateContainerViewController setTemplateView:]` 又用 `_completelyFillWithView:` 以约束把它贴满模板区。于是 AppKit 按零尺寸生成 `width == 0`、`height == 0` 两条必需约束，容器、用它建的窗口和 sheet 都被压成 0 × 0，什么尺寸约束都顶不过（2026-11-24 在 RuntimeViewer 里撞到，用 `constraintsAffectingLayout(for:)` 查出）。Swift 便利构造器因此先关掉这个开关再交给容器。
- **容器自己不定尺寸。** `-[OBTemplateContainerViewController loadView]` 用 `NSZeroRect` 建视图，只约束按钮栏的高度（63），宽度没有任何约束；模板第一次绘制前也没有子视图撑开它。只关开关不给尺寸，窗口约 300 宽、0 高。框架自己的隐私页窗口 `OBPrivacyWindow` 覆写 `setFrame:display:`，把尺寸强制成 `+[OBStyle sheetSizeForParentWindowSize:]`：宽 482，高取父窗口高度的 88%、限制在 546 到 600 之间，父窗口尺寸为零时 546。15.5 与 27.2 的这组数相同。`OBStyle` 不在 `.tbd` 里，所以 `sheetSize(forParentWindowSize:)` 照抄公式，便利构造器把无父窗口的尺寸设为 `preferredContentSize`（AppKit 换成两条优先级 501 的约束，窗口与 sheet 都按它开）。
- **模板的左右边距按类型定。** `-[OBTemplateView outerContentMargins]`：`standard` 与 `unspecified` 每边 175pt（开 `needsExtraWideContent` 或 `needsExtraWideContentAreaOnly` 时 85），`privacy` 与 `centered` 每边 68。构造器给的是 `standard`，放进 482 宽的 sheet，标题只剩 136pt 宽（2026-11-24 在 RuntimeViewer 里撞到）。列表的行宽另由 `-[OBTemplatePartBulletList setBulletListSpacing:]` 定：`centered` 固定 344，其余按间距档位取 382 / 420（加宽 562 / 600）；`privacy` 的 382 比 sheet 留下的 346 还宽，它的上边距也按窗口高度的 12% 算，是隐私页的版式。`-[OBTemplateView setTemplateType:]` 只存值、不传给列表，类型在第一次绘制（`layoutSubviews`）时才读。Swift 容器便利构造器因此把仍是 `standard` / `unspecified` 的模板与它的列表改成 `centered`，调用方另选的类型不动。
- **`layoutStyle` 只在创建时读一次。** setter 只存值，`commonInit` 才读，所以 Swift 便利构造器把它作为构造参数。
- **可展开行的子项在展开时才加进 `expandableStack`**，之前存在内部的 `cells` 里；`addExpandableItem…` 收到空数组时只记错误日志、什么都不加，所以 `addItem(_:)` 只在有子项时才走这条路。
- **`fadeTitle/BodyToAlpha:duration:completionHandler:` 的回调不判空就调用**（`0x1C388213C`），传 nil 会崩溃，所以头文件把它标成非空。
- **`symbolEffects` 与 `symbolEffectOptions` 按下标配对**，options 比 effects 短会越界。`NSSymbolEffect` 在 Swift 里被 Apple 藏起来了（`NS_REFINED_FOR_SWIFT`），Swift 调用方造不出它，所以这组接口没有 Swift 包装。

## 各版本删掉的成员

演进接口文件的位图加本机运行时核对：

| 成员 | 存在的版本 |
|---|---|
| `-[OBBundleManager orderedPrivacyBundlesWithPrivacyPaneBundle:]` | 11.0–27.0，27.2 删除 |
| `-[OBTemplatePartBulletListItem initWithTitle:description:image:imageTintColor:]` | 11.0–27.0，27.2 删除 |
| `-[OBTemplatePartBulletListItem initWithTitle:description:symbol:symbolTintColor:]` | 11.0–27.0，27.2 删除 |
| `-[OBTemplateContainerViewController makeDivider]` | 11.0–26.7，27.0 删除 |
| `-[OBTemplateContainerViewController setFirstButton:]`、`setSecondButton:`、`setLinkButton:` | 11.0–15.8，26.0 删除 |

列表项剩下的构造器都带 `spacing:` 与 `showsBackground:`，`OBTemplatePartBulletList` 的 `addItem…` 方法一个没少。

## 验证

- `Tests/COnBoardingKitTests/DeclarationPresenceTests.swift`：测试时读取头文件（`HeaderDeclarationParser`），对每个类查 `NSClassFromString`，对每个方法和属性的 getter / setter 查 `instancesRespondToSelector:` 或类方法的 `respondsToSelector:`；`API_AVAILABLE` 高于运行系统的跳过。加回一个 27.2 已删的方法（`makeDivider`）时它变红，已实测。
- `Tests/OnBoardingKitTests/`：列表 builder 的行数、顺序、条件与循环、状态行、可展开行；容器按钮的标题、闭包、快捷键、替换动作、不持有控制器；`presentAsSheet(on:)` 设窗口、只调一次 `present`、关闭后返回并恢复原来的 `dismissHandler`（用一个立即结束 sheet 的子类代替真 sheet）；模板视图的便利构造器、功能列表、在容器里的层级；容器的尺寸公式，以及用便利构造器建的窗口和 sheet 是 sheet 尺寸、模板铺满（窗口与 sheet 都不放上屏幕）；标准类型改成居中、另选的类型保留、正文宽度超过 sheet 的六成；隐私标识对得上系统的隐私包。
- 所有视图都在屏幕外创建，测试不弹窗口。

### 系统更新后怎样核对

1. 跑 `swift test`。`DeclarationPresenceTests` 报出的就是新系统删掉的成员：删掉对应声明，或者给它标 `API_OBSOLETED`。
2. 新增的成员要靠导出新系统的接口来发现：`swift-section objc dump --uses-system-dyld-shared-cache -p /System/Library/PrivateFrameworks/OnBoardingKit.framework/Versions/A/OnBoardingKit`，和头文件比对。
3. 新的 `.tbd` 导出类：`awk '/objc-classes:/ {inside=1} inside {print} inside && /\]/ {exit}' "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks/OnBoardingKit.framework/OnBoardingKit.tbd"`。

## 已知降级

- 枚举值的名字是本包起的；Apple 以后若在别处公开这些概念，名字可能对不上。
- 只在 macOS 27.2 上核对过行为。可用性来自运行时元数据，14.0 到 27.0 上声明的成员都存在，但行为（比如按钮隐藏、模板何时搭视图）没有在旧系统上实测。
- `NSSymbolEffect` 那组接口在 Swift 里能看到，但 Swift 调用方造不出 `NSSymbolEffect` 对象。

## 延伸阅读

- 提案：[0001-objective-c-declarations-and-swift-layer](../Evolutions/0001-objective-c-declarations-and-swift-layer.md)
- 调用方的说明：仓库根的 [README](../../README.md)
