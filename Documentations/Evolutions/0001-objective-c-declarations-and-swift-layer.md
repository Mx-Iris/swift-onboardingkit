# 0001 - 声明 OnBoardingKit 导出的类，并给 Swift 一层便利接口

- **状态**: Implemented
- **作者**: JH
- **创建日期**: 2026-11-23
- **最后更新**: 2026-11-23
- **所属愿景**: 无
- **关联提案**: 无
- **实现分支 / PR**: `main`（新仓库的第一个提交，只在本地，没有远端）
- **配套文档**: 实现说明 [Internal/DeclarationSources.md](../Internal/DeclarationSources.md)；面向调用方的说明在仓库根的 [README](../../README.md)
- **网页版**: 同目录同名的 `.html`

## 摘要

新建 swift-onboardingkit 包，给 macOS 私有框架 OnBoardingKit 提供两层接口。`COnBoardingKit` 是一份手写的 Objective-C 头文件：声明 27.2 SDK 的 `OnBoardingKit.tbd` 导出的全部 29 个类和 72 个隐私标识常量，成员取自 macOS 11.0 到 27.2 的运行时元数据，类型从框架代码里还原，整数参数换成本包命名的枚举，每个成员标上引入它的系统版本，部署目标 macOS 14。`OnBoardingKit` 是 Swift 层：功能列表用 result builder 写，容器的按钮用闭包代替 target/action 并自动对应新旧两套按钮，隐私页能 `await` 到关闭，模板视图有带默认参数的构造器。测试在运行时读取头文件，逐个核对声明的成员在当前系统上是否存在。

## 动机

- **Apple 自己的欢迎页和 "What's New" 页用的就是这个框架。** 在 macOS 27.2.1 上扫 `/System/Applications` 的链接表：App Store、Freeform、Shortcuts 直接引用 `OBTemplateView`、`OBTemplatePartBulletList`、`OBTemplateContainerViewController` 搭 "What's New" 页；Mail、Music、TV、Photos、Books 经 `OBPrivacyPresenter` 弹隐私页；Catalyst App 用的是同名框架 iOS 版的 `OBWelcomeController`。想在自己的 AppKit App 里做出同样外观的页面，最直接的办法就是用它。
- **SDK 里没有头文件。** 只有 `MacOSX27.2.sdk/System/Library/PrivateFrameworks/OnBoardingKit.framework/OnBoardingKit.tbd`。运行时元数据把所有对象参数记成 `id`、block 记成不带签名的 block，直接导出的头文件导入 Swift 后全是 `Any` 和 `UInt`，block 的参数也不知道。
- **框架本身很稳定，值得做成可依赖的包。** 演进接口文件（51 个版本，11.0 → 27.0）显示：1246 个成员里 848 个从 11.0 起没变过，删掉的只有 24 个，多是内部辅助方法；What's New 用到的模板、列表、容器的核心构造器从 11.0 到 27.0 一直在。
- **直接调用有几处会踩空，只有读了代码才知道。** 容器建的按钮没有 target 和 action；隐私页没有 `presentingWindow` 就什么也不显示、回调也不来；模板视图在第一次绘制前一个子视图都没有；`fade…` 的回调传 nil 会崩溃。

## 前期调研

- **导出面**（27.2 SDK 的 `.tbd`）：29 个类；72 个 `OBPrivacy…Identifier` 常量；`OBProcessNameForPID`、`_OBLoggingEnabled`、`_OBLoggingFacility`；一个 Swift 符号 `NSImage.disclosureChevronImage(expandedState:)`（其 Objective-C 入口是 `+[NSImage disclosureChevronImageWithExpandedState:]`）。没有 `allowable-clients`，任何二进制都能链接。
- **谁在用**（macOS 27.2.1，`otool -L` 与 `dyld_info -imports`）：
  - AppKit App：App Store、Freeform、Shortcuts 用模板三件套；Mail、Music、TV、Photos、Books 用隐私类。
  - Catalyst App（Journal、Clock、Find My、Home、Maps、Voice Memos、Weather）用 iOS 版 OnBoardingKit 的 `OBWelcomeController`，不在本包范围内。
  - cache 里另有约 50 个私有框架链接它，主要是账户、隐私与设置相关的 UI。
  - 另一个私有框架 `Welcome.framework`（工程名 WelcomeKit）是纯 SwiftUI 的欢迎页，27.2 上只有 GameStoreKit 链接，也不在范围内。
- **成员与版本**：演进接口文件 `/Users/JH/Documents/SwiftInterfaceTests/macOS-27.0.0-OnBoardingKit-ObjCEvolutionInterface.h` 给出每个成员在 11.0–27.0 的存在位图。本机 27.2.1 的运行时（`swift-section objc dump` 与 JXA 的 `instancesRespondToSelector:`）又少了三个：`-[OBBundleManager orderedPrivacyBundlesWithPrivacyPaneBundle:]`，以及 `OBTemplatePartBulletListItem` 的两个四参数构造器。
- **类型与行为**：在 macOS 27.2 归档 cache 上用 idax 建了 `OnBoardingKit.i64`，逐个反编译并对照汇编，结论见实现说明「Swift 层依赖的框架行为」。要点：
  - 所有 block 都是 `void (^)(void)`；`fade…` 的回调不判空就调用。
  - `contentLayoutStyle` / `layoutStyle` 取 0–5，`templateType` 取 0–3，设备类型 0–9，列表间距 0–2，包含选项是 5 个位；二进制里没有这些值的名字。
  - 容器的指定构造器是 first/second/link 那个，26 起的 primary/secondary/cancel 构造器转调它，first = primary、second = cancel、link = secondary；按钮不接 target/action，也没有快捷键。
  - `OBPrivacyLinkController` 的工厂方法返回 `_macOS` 子类，基类自己的构造器得到的控制器没有视图。
  - `OBPrivacyPresenter.present` 没有窗口时只记日志返回。
- **实测**（本包测试里的探针）：`OBTemplateView` 创建后、放进未显示的窗口后、`layoutSubtreeIfNeeded` 后都没有子视图，`viewWillDraw` 之后才有；可展开行的子项在 `expanded = YES` 之后才加进 `expandableStack`。
- **Swift 侧的事实**：
  - `NSSymbolEffect` 在 27.2 SDK 里标了 `NS_REFINED_FOR_SWIFT`，Swift 代码造不出它。
  - 写成 `NS_TYPED_EXTENSIBLE_ENUM` 的常量不加 `NS_SWIFT_NAME` 时导入成 `.appStoreIdentifier`，带着 `Identifier` 后缀（`swift-synthesize-interface` 实测）。
- **先例**：同目录的 swift-skylight（SkyLight 私有框架的绑定）。它用一个 C target 放头文件，链接参数是 `.unsafeFlags(["-F/System/Library/PrivateFrameworks"])` 加 `.linkedFramework`，Swift target 再 `@_exported import`；tools 6.2 起依赖带 unsafe flags 的包不再被拒。本包照这个结构做。

## 提议方案

1. **包结构照 swift-skylight**：`COnBoardingKit`（Objective-C 头文件加一个空的 `.m`）与 `OnBoardingKit`（Swift），两个都是 product；macOS 14；Swift 6 语言模式。
2. **头文件声明范围**：`.tbd` 的 29 个类和 72 个常量；成员取 27.2 上存在的，不写实例变量、下划线方法、AppKit 方法的覆写，以及只服务于框架自身布局与缓存的属性和方法。
3. **类型**：按反编译结果写全 nullability、集合元素类型与 block 签名；只凭选择子字面意思定的标 `[unverified]`。
4. **枚举**：`OBTemplateLayoutStyle`、`OBTemplateType`、`OBBulletListSpacing`、`OBDeviceType`（`NS_ENUM`）与 `OBBundleInclusionOptions`（`NS_OPTIONS`）。名字由本包按行为起，并在注释里写明。
5. **可用性**：晚于 14.0 引入的成员标 `API_AVAILABLE(macos(…))`。
6. **Swift 名写在头文件的宏里**：常量去掉 `Identifier` 后缀；`OBPrivacyPresenter` 的工厂改成 `init?(splashFor:)` 一族；`OBPrivacyLinkController` 基类的构造器和拼错的工厂方法在 Swift 里不可用。
7. **Swift 层四块**：
   - 功能列表：`OBTemplatePartBulletList.Item`、`ItemBuilder`、`init(items:)` 与 `addItem(s)`。
   - 模板视图：带默认参数的构造器，以及带 `features:` builder 的构造器。
   - 容器按钮：`ButtonRole`、`Button`、`button(for:)`、`setAction(for:_:)`，以及带默认参数的构造器。
   - 隐私页：`presentAsSheet(on:) async`。
8. **测试**：一组测试在运行时读取头文件，逐个核对类、方法与属性存取器；一组测试覆盖 Swift 层。测试不把窗口放到屏幕上。

### 非目标

- 不覆盖 iOS 版 OnBoardingKit（`OBWelcomeController` 等，Catalyst App 用的那套），也不覆盖 `Welcome.framework`。
- 不声明 `OBProcessNameForPID`、`_OBLoggingEnabled`、`_OBLoggingFacility`：它们是框架内部的日志与进程工具。
- 不包装 `NSSymbolEffect` 那组接口：Swift 造不出 `NSSymbolEffect`，包装了也没法用。
- 不做 SwiftUI 包装：选定的范围是「绑定加便利接口」，SwiftUI 的 sheet 修饰符属于另一档「组装层」，没有选。
- 不在 macOS 27.2 之外的系统上实测行为；旧系统只核对成员是否存在（来自元数据）。
- 不建 GitHub 远端、不推送。

## 改动地图

| 文件 / 类型 | 动作 | 改什么 | 为什么 | 步骤 |
|---|---|---|---|---|
| `Package.swift` | 新增 | 两个 target、两个 product、两个测试 target；链接 `OnBoardingKit.framework` | 包本身 | 1 |
| `.gitignore`、`LICENSE` | 新增 | 照 swift-skylight | 仓库骨架 | 1 |
| `Sources/COnBoardingKit/COnBoardingKit.m` | 新增 | 空文件 | SwiftPM 要求 C target 至少一个源文件 | 1 |
| `Sources/COnBoardingKit/include/module.modulemap` | 新增 | `module COnBoardingKit` | 让 Swift 导入头文件 | 1 |
| `Sources/COnBoardingKit/include/OnBoardingKitPrivateAPI.h` | 新增 | 29 个类、72 个常量、3 个协议、5 个枚举、`CAPackage` / `CAStateController` 的最小声明 | 声明本身 | 2、3 |
| `Tests/COnBoardingKitTests/HeaderDeclarationParser.swift` | 新增 | 读头文件，拆出类、方法、属性与可用性 | 让核对测试不必另列一份清单 | 2 |
| `Tests/COnBoardingKitTests/DeclarationPresenceTests.swift` | 新增 | 每个声明在运行系统上存在 | 系统删掉成员时变红 | 2 |
| `Sources/OnBoardingKit/Exports.swift` | 新增 | `@_exported import COnBoardingKit` | Swift 调用方只 import 一个模块 | 4 |
| `Sources/OnBoardingKit/BulletListItem.swift` · `OBTemplatePartBulletList.Item` / `ItemImage` / `ItemBuilder` | 新增 | 行的值类型、builder、`init(items:)`、`addItem(_:)`、`addItems` | 十个 `addItem…` 合成一种写法 | 4 |
| `Sources/OnBoardingKit/TemplateView.swift` · `OBTemplateView` 扩展 | 新增 | 两个便利构造器、`bulletList` | 默认参数，功能列表一步到位 | 5 |
| `Sources/OnBoardingKit/TemplateContainerButtons.swift` · `ButtonRole` / `Button` / `ButtonActionTarget` | 新增 | 构造器、`button(for:)`、`setAction(for:_:)` | 按钮不接 target/action；新旧按钮对应 | 5 |
| `Sources/OnBoardingKit/PrivacyPresenterPresentation.swift` | 新增 | `presentAsSheet(on:) async` | 等到关闭；强制给窗口 | 5 |
| `Tests/OnBoardingKitTests/*.swift` | 新增 | 四组 Swift 层测试 | 行为清单 | 4、5 |
| `README.md` | 新增 | 英文说明 | 调用方文档 | 6 |
| `Documentations/README.md`、`Evolutions/README.md` | 新增 | 索引 | 文档规则 | 6 |
| `Documentations/Internal/DeclarationSources.md` | 新增 | 实现说明 | 维护者要知道声明从哪来、怎么核对新系统 | 6 |
| `Documentations/Evolutions/0001-objective-c-declarations-and-swift-layer.md` / `.html` | 新增 | 本提案与网页版 | 提案制 | 6 |

## 架构图

模块与依赖：

```text
+ swift-onboardingkit/
+ ├── COnBoardingKit                       (Objective-C, header only)
+ │   └── OnBoardingKitPrivateAPI.h
+ │       ├── 29 classes from OnBoardingKit.tbd
+ │       ├── OBPrivacyIdentifier + 72 constants
+ │       ├── OBTemplateLayoutStyle, OBTemplateType, OBBulletListSpacing, OBDeviceType, OBBundleInclusionOptions
+ │       └── links -F/System/Library/PrivateFrameworks -framework OnBoardingKit
+ └── OnBoardingKit                        (Swift, @_exported import COnBoardingKit)
+     ├── OBTemplatePartBulletList.Item / ItemBuilder / init(items:) / addItem(_:)
+     ├── OBTemplateView.init(title:bodyText:systemImage:layoutStyle:contentArea:)
+     ├── OBTemplateView.init(title:bodyText:systemImage:layoutStyle:features:)
+     ├── OBTemplateContainerViewController.ButtonRole / Button / button(for:) / setAction(for:_:)
+     └── OBPrivacyPresenter.presentAsSheet(on:) async

  OnBoardingKit.framework (system, private)
  ├── OBTemplateView ── contentArea ──> OBTemplatePartBulletList ──> OBTemplatePartBulletListItem
  ├── OBTemplateContainerViewController ──> OBTemplateView + button tray
  └── OBPrivacyPresenter ──> OBPrivacySplashController / OBPrivacyCombinedController (sheet)
```

一次 "What's New" 页的调用链：

```text
OBTemplateView(title:systemImage:features:)
├── OBTemplatePartBulletList(items:)
│   └── addItem(_:)  ──> -addItemWithTitle:description:symbol:symbolTintColor:status:
│                        or -addExpandableItemWithTitle:…:sublistItems:  (only with subitems)
└── -initWithTitle:bodyText:symbol:contentLayoutStyle:  then  contentArea = bulletList

OBTemplateContainerViewController(templateView:primaryButton:secondaryButton:cancelButton:)
├── -initWithTemplateView:firstButtonTitle:secondButtonTitle:linkButtonTitle:   (every macOS)
└── setAction(for:_:) per role
    ├── button(for:)  macOS 26+: primaryButton / secondaryButton / cancelButton
    │                 earlier:   firstButton   / linkButton      / secondButton
    └── ButtonActionTarget (associated with the button) ──> action(controller)

presentAsSheet(on:)  ──> presentingWindow = window; dismissHandler = resume; -present
                         sheet ends ──> dismissHandler ──> previous handler, continuation resumes
```

## 详细设计

头文件里的枚举（节选）：

```objc
typedef NS_ENUM(NSInteger, OBTemplateLayoutStyle) {
    OBTemplateLayoutStyleDefault = 0,
    OBTemplateLayoutStyleLargeContent = 1,
    OBTemplateLayoutStyleHeadline = 2,
    OBTemplateLayoutStyleTopContentWithBackground = 3,
    OBTemplateLayoutStyleAnimation = 4,
    OBTemplateLayoutStyleTopContent = 5,
};
typedef NS_ENUM(NSUInteger, OBTemplateType) { OBTemplateTypeUnspecified, OBTemplateTypePrivacy, OBTemplateTypeStandard, OBTemplateTypeCentered };
typedef NS_ENUM(NSInteger, OBBulletListSpacing) { OBBulletListSpacingDefault, OBBulletListSpacingLarge, OBBulletListSpacingCompact };
typedef NS_ENUM(NSUInteger, OBDeviceType) { OBDeviceTypeCurrent, OBDeviceTypeIPhone, /* … */ OBDeviceTypeHomeAccessory };
typedef NS_OPTIONS(NSUInteger, OBBundleInclusionOptions) { /* 1 << 0 … 1 << 4 */ };
```

隐私页的 Swift 名：

```objc
+ (nullable instancetype)presenterForPrivacySplashWithIdentifier:(OBPrivacyIdentifier)identifier NS_SWIFT_NAME(init(splashFor:));
+ (nullable instancetype)presenterForPrivacyUnifiedAboutWithIdentifiers:(NSArray<OBPrivacyIdentifier> *)identifiers NS_SWIFT_NAME(init(unifiedAboutFor:));
extern OBPrivacyIdentifier const OBPrivacyAppStoreIdentifier NS_SWIFT_NAME(appStore);
```

Swift 层：

```swift
extension OBTemplatePartBulletList {
    public enum ItemImage: Sendable { case systemImage(String), image(NSImage) }
    public struct Item: Sendable {
        public var title: String?
        public var description: String?
        public var image: ItemImage?
        public var tintColor: NSColor?
        public var status: String?
        public var subitems: [Item]
        public init(_ title: String? = nil, description: String? = nil, systemImage: String, tintColor: NSColor? = nil, status: String? = nil, @ItemBuilder subitems: () -> [Item] = { [] })
        public init(_ title: String? = nil, description: String? = nil, image: NSImage, tintColor: NSColor? = nil, status: String? = nil, @ItemBuilder subitems: () -> [Item] = { [] })
        public init(_ title: String? = nil, description: String? = nil, status: String? = nil, @ItemBuilder subitems: () -> [Item] = { [] })
    }
    @resultBuilder public enum ItemBuilder { /* buildExpression, buildBlock, buildOptional, buildEither, buildArray, buildLimitedAvailability */ }
    public convenience init(@ItemBuilder items: () -> [Item])
    public func addItem(_ item: Item)
    public func addItems(_ items: [Item])
    public func addItems(@ItemBuilder _ items: () -> [Item])
}

extension OBTemplateView {
    public convenience init(title: String, bodyText: String? = nil, systemImage: String? = nil, layoutStyle: OBTemplateLayoutStyle = .default, contentArea: NSView? = nil)
    public convenience init(title: String, bodyText: String? = nil, systemImage: String? = nil, layoutStyle: OBTemplateLayoutStyle = .default, @OBTemplatePartBulletList.ItemBuilder features: () -> [OBTemplatePartBulletList.Item])
    public var bulletList: OBTemplatePartBulletList? { get }
}

extension OBTemplateContainerViewController {
    public enum ButtonRole: Sendable { case primary, secondary, cancel }
    public struct Button {
        public var title: String
        public var action: @MainActor (OBTemplateContainerViewController) -> Void
        public init(_ title: String, action: @escaping @MainActor (OBTemplateContainerViewController) -> Void)
    }
    public convenience init(templateView: OBTemplateView, primaryButton: Button, secondaryButton: Button? = nil, cancelButton: Button? = nil)
    public func button(for role: ButtonRole) -> NSButton?
    public func setAction(for role: ButtonRole, _ action: @escaping @MainActor (OBTemplateContainerViewController) -> Void)
}

extension OBPrivacyPresenter {
    public func presentAsSheet(on window: NSWindow) async
}
```

- **`Item` 的三个构造器按图片来源分**（SF Symbol、自己的图片、无图），与 SwiftUI `Label` 的 `systemImage:` / `image:` 一致；有子项就成为可展开行，没有就是普通行。`addItem(_:)` 按「有无标题 × 图片来源」选对应的 Objective-C 方法，可展开行只在子项非空时才走 `addExpandableItem…`（框架收到空数组时什么都不加）。
- **按钮的闭包收控制器作参数**：关闭 sheet 时不必捕获控制器，避免「控制器 → 按钮 → target → 闭包 → 控制器」的循环。target 以关联对象挂在按钮上，因为 `NSControl.target` 是弱引用。
- **`presentAsSheet(on:)`** 暂时替换 `dismissHandler`，sheet 结束时把原来的放回去、调用它，再恢复 `await`。

## 替代方案考量

- **运行时查找（`NSClassFromString` / OpenSoftLinking）代替链接。** 否：`.tbd` 导出了全部 29 个类，链接器看得到，直接链接能得到编译期的类型检查；swift-skylight 也是直接链接。
- **改名写进 apinotes。** 否：头文件是本包自己的，宏写在声明上读一处就够；apinotes 是给不便改的老头文件用的。swift-skylight 用的是 apinotes，那是它的历史做法。
- **一个 `OBTemplateView` 构造器包下四种来源（符号、图片、动画、大内容区），用 `TopImage` 枚举区分。** 否：动画那条构造器自己决定 `layoutStyle`，合进去会让 `layoutStyle` 参数在一种情况下被悄悄忽略；只合并参数形状一致的那条（符号 + 布局样式），其余保留 Objective-C 导入的原样。
- **最低系统 macOS 26，只包新按钮。** 否：用户选了 14，和 AppKitPlus、swift-skylight 一致；反编译证实旧构造器在 26 起照样能用，Swift 层只需在取按钮时分版本。
- **`present() async` 与同步的 `present()` 同名重载。** 否：在 async 上下文里同名会让原来的同步调用被换成 async 版本；而且等待的是「关闭」而不是「显示」，`presentAsSheet(on:)` 照 `NSViewController.presentAsSheet(_:)` 起名，并把必需的窗口放进参数。
- **按钮闭包写成 `() -> Void`，和 SwiftUI `Button` 一样。** 否：最常见的动作是关掉 sheet，`() -> Void` 逼调用方捕获控制器，形成循环引用。
- **Swift 模块另起名（如 `OnBoardingKitSwift`）。** 否：框架自身虽也有 Swift 模块名 `OnBoardingKit`，但它只有一个私有类和一个 `NSImage` 扩展，本包不定义同名符号；照 swift-skylight 用框架名。

## 影响

### 源码兼容性（source compatibility）

纯新增：新仓库，没有既有调用方。

### ABI 兼容性（条件项）

不适用 —— 本库以 SPM 源码分发，使用方每次重新编译。对系统框架的 ABI：声明与框架的选择子、参数位宽一致，换成枚举不改变调用约定。

### 下游影响

本仓库之外暂无依赖方。将来 AppKitPlus 或别的 App 若用它做欢迎页，只需加 SPM 依赖。

### 文档与示例

README（英文）、实现说明、本提案及网页版。没有示例 App：sheet 必须上屏才能看，示例留到有需要时再加。

## API 演进与废弃策略

- 系统删掉某个成员时：`DeclarationPresenceTests` 变红；在头文件里给它标 `API_OBSOLETED`（若仍要支持旧系统）或删除。
- 本包自己的 Swift API 改名时保留旧名，标 `@available(*, deprecated, renamed:)`。
- 还没有发布版本号；第一次打 tag 时从 0.1.0 起。

## 落地步骤

1. **骨架** —— `Package.swift`、`.gitignore`、`LICENSE`、空 `.m`、modulemap
   - 行为：`swift build` 成功，链接得到 `OnBoardingKit.framework`。
2. **头文件主体与核对测试** —— 头文件、`HeaderDeclarationParser`、`DeclarationPresenceTests`
   - 行为：`Every declared class exists`
   - 行为：`Every declared method and property accessor exists`
   - 行为：加回 27.2 已删的 `makeDivider` 时测试失败
3. **按反编译结果补类型、枚举与 Swift 名** —— 头文件
   - 行为：`swift-synthesize-interface` 无警告，常量导入为 `.appStore`，工厂导入为 `init?(splashFor:)`
4. **功能列表 builder** —— `BulletListItem.swift`、`BulletListBuilderTests`
   - 行为：`Rows are added in the order the builder lists them`
   - 行为：`Conditions and loops in the builder add exactly the rows they produce`
   - 行为：`A row with a status shows it under the description`
   - 行为：`A row with sub-items becomes an expandable row holding them`
   - 行为：`addItems appends after the rows already there`
5. **模板视图、容器按钮、隐私页** —— 三个 Swift 文件与对应测试
   - 行为：`The convenience initializer sets the title, body text, symbol and layout style`
   - 行为：`The feature builder makes a bullet list the content area`
   - 行为：`A What's New page assembles into a container whose view hierarchy holds the bullet list`
   - 行为：`Each role's button carries its title and calls its action with the controller`
   - 行为：`The primary button answers Return and the cancel button Escape`
   - 行为：`A later setAction replaces the earlier one`
   - 行为：`The action does not keep the controller alive`
   - 行为：`presentAsSheet sets the window, presents once and returns after the sheet ends`
   - 行为：`The dismiss handler set before is called and put back`
   - 行为：`The factories find the system's privacy pages`
   - 行为：`Privacy identifiers name the system's privacy bundles`
6. **文档** —— README、实现说明、索引、本提案与网页版

**收尾判断**：
- 配套文档：写了实现说明（声明来源、取舍规则、Swift 层依赖的框架行为，都是代码里看不出来的）；调用方契约写在 README 的 Things to know 和头文件注释里，不另写使用指南。
- 新术语：没有项目特有的术语，不建术语表。

## 决策日志

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-11-23 | Created as Draft | 用户想在自己的 App 里用系统 What's New 页同款的框架，要求新建包、声明 `.tbd` 导出的全部类并提供 Swift 便利接口 |
| 2026-11-23 | 范围：绑定加便利接口 | 用户在「只做薄绑定 / 绑定加便利接口 / 再加 What's New 组装层与 SwiftUI」中选了中间一档 |
| 2026-11-23 | 部署目标 macOS 14 | 用户选定，与 AppKitPlus、swift-skylight 一致；26 起的新按钮接口标可用性，Swift 层按系统版本取按钮 |
| 2026-11-23 | 只声明 27.2 上存在的成员 | 本机运行时核对发现 27.2 删了三个 27.0 还有的成员；加一组运行时读取头文件的核对测试防止再漂移 |
| 2026-11-23 | 枚举名由本包起 | 二进制里没有这些整数的名字，按 27.2 的行为命名并写明 |
| 2026-11-23 | In Progress | 代码、测试与文档已在本地完成，全部测试通过，尚未提交 |
| 2026-11-23 | Implemented | 用户选择只在本地提交：代码、测试与文档作为新仓库的第一个提交进入 `main`，编号 0001；不建远端 |
