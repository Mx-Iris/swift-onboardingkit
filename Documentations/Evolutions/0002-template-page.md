# 0002 - 用值描述一页，由容器组装

- **状态**: Implemented
- **作者**: JH
- **创建日期**: 2026-11-24
- **最后更新**: 2026-11-25
- **所属愿景**: 无
- **关联提案**: [0001 声明 OnBoardingKit 导出的类，并给 Swift 一层便利接口](0001-objective-c-declarations-and-swift-layer.md)
- **实现分支 / PR**: 直接提交在 `main`，随 `0.2.0` 发布
- **配套文档**: 不另写 —— 用法在 README，框架行为在 [实现说明](../Internal/DeclarationSources.md)「Swift 层依赖的框架行为」
- **网页版**: 同目录同名的 `.html`

## 摘要

新增值类型 `OBTemplatePage`：一页欢迎页或 What's New 页要显示的东西（标题、正文、顶部图片、功能行）和它的版式（左右边距、功能行着色与间距、尺寸），全是数据。`OBTemplateContainerViewController(page:primaryButton:secondaryButton:cancelButton:)` 把它组装成模板视图、列表和容器控制器。调用方不再去设 `templateType`、`needsExtraWideContent`、`preferredContentSize` 这些视图和控制器的属性，也不必知道它们要在组装前还是组装后设。

## 动机

RuntimeViewer 接入本包做欢迎页与 What's New（RV 提案 `onboarding-pages`）时，页面三次「看起来不对」，每次的修法都是在视图或控制器上补设属性，而且顺序有讲究：

1. 窗口 0 × 0：要关掉模板的 `translatesAutoresizingMaskIntoConstraints`，再给容器 `preferredContentSize`（已在 0.1.1 修进容器构造器）。
2. 正文挤成约 130pt 的一列：要给模板**和它的列表**分别设 `templateType`（模板不会替列表设），而且模板的类型在第一次绘制时才读，列表的间距档位却在加行时就读。
3. 用户比较了几种版式后要求：把「组装」这部分搬进库里，封装成结构化数据，不暴露视图和控制器的属性，最后组装成控制器。

这些知识只有反编译框架才知道，留给每个调用方各自摸索不合适。用 demo 试样式时写出的 `PageStyle.makeContainer` 已经是这个形状：一个值描述页面，一个函数组装。

## 前期调研

- **框架的版式规则**（macOS 27.2 反编译，结论写在实现说明）：
  - 左右边距由模板的 `templateType` 定（`-[OBTemplateView outerContentMargins]`）：`standard` / `unspecified` 175pt，开 `needsExtraWideContent` 时 85；`privacy`、`centered` 68。
  - 只有 `centered` 把顶部图片居中（`-[OBTemplateView shouldLeadAlignIconImage]`），文字一律按自然方向排（`+[OBTemplateView templateTextAlignment]` 返回 4）。
  - 列表行宽：`centered` 344，其余按间距档位取 382 / 420（加宽 562 / 600）（`-[OBTemplatePartBulletList setBulletListSpacing:]`）。
- **Apple 自己的做法**：App Store 的 What's New 与欢迎页用 `initWithTitle:bodyText:icon:contentLayoutStyle:`（布局样式 1）建模板，模板与列表都 `setTemplateType: 3`（居中），列表行的符号用 App 的强调色。Freeform、Shortcuts 调了 `setNeedsExtraWideContent:`。都从 `otool` 反汇编加 `objc_msgSend` 存根对选择子得到。
- **先例**：Apple 用值描述界面、由框架组装的做法有 `UIContentConfiguration` 一族与 `NSHostingController(rootView:)`；本包已有的 `OBTemplateContainerViewController(templateView:primaryButton:…)` 是同一位置的构造器，新构造器与它对称。

## 提议方案

- `OBTemplatePage`（struct）：`title`、`bodyText`、`image`（`.systemImage` / `.image`）、`features`（沿用 `OBTemplatePartBulletList.Item`）、`featureTintColor`（给没设颜色的行）、`featureSpacing`（`OBBulletListSpacing`）、`layout`、`size`。两个构造器：数组版与 result builder 版，与 `OBTemplateView` 的便利构造器写法一致。
- `OBTemplatePage.Layout`：struct 加静态成员 `.standard`、`.wide`、`.centered`、`.privacy`，内部存框架的 `templateType` 与 `needsExtraWideContent`。用 struct 而不是 enum，将来加版式不破坏穷举。默认 `.centered`（App Store 的做法，配默认的 482 宽 sheet）。
- `OBTemplateContainerViewController.init(page:primaryButton:secondaryButton:cancelButton:)`：建列表（先设间距与版式再加行）、建模板（按图片种类选构造器）、交给已有的按钮构造器，再把版式设回模板与列表（已有构造器会把标准类型改成居中），最后设 `preferredContentSize = page.size`。

### 非目标

- 不包装 `layoutStyle`（headline、顶部内容区、动画）、隐私链接、返回按钮：这次的页面用不到，需要时用 `init(templateView:…)` 自己建。
- 不改已有的 `init(templateView:…)`，也不删它。
- 不做 SwiftUI 包装。

## 改动地图

| 文件 / 类型 | 动作 | 改什么 | 为什么 | 步骤 |
|---|---|---|---|---|
| `Sources/OnBoardingKit/TemplatePage.swift` · `OBTemplatePage`、`Image`、`Layout` | 新增 | 页面的值、两种构造器、四种版式 | 页面写成数据 | 1 |
| 同上 · `OBTemplateContainerViewController.init(page:…)` | 新增 | 由页面组装模板、列表、控制器 | 组装的顺序与补设留在库里 | 1 |
| 同上 · `OBTemplatePartBulletList` 的 `fileprivate` 扩展 | 新增 | 按页面建列表、套用版式 | 列表要在加行前设好间距与版式 | 1 |
| `Tests/OnBoardingKitTests/TemplatePageTests.swift` | 新增 | 文字、功能行、四种版式、尺寸、窗口尺寸与模板铺满 | 行为清单 | 1 |
| `README.md` | 修改 | 用法以页面值为主，原写法挪到「Building the template yourself」，加版式表 | 公开用法 | 2 |
| `Documentations/Internal/DeclarationSources.md` | 修改 | 文件树加一行；记「组装后要设回版式、间距在加行前设」 | 维护者会踩 | 2 |
| `Documentations/Evolutions/0002-template-page.md`（与 `.html`）、`README.md` | 新增 / 修改 | 本提案与索引 | 留档 | 2 |

## 架构图

```text
OnBoardingKit (Swift layer)
  + OBTemplatePage                         title, bodyText, image, features,
      + Image   (.systemImage / .image)    featureTintColor, featureSpacing,
      + Layout  (.standard .wide           layout, size
                 .centered .privacy)
  OBTemplateContainerViewController
    + init(page:primaryButton:secondaryButton:cancelButton:)
    │   ├─ OBTemplatePartBulletList   spacing + layout first, then rows
    │   ├─ OBTemplateView             by image kind
    │   ├─ init(templateView:primaryButton:…)   (existing: constraints, centered, sheet size)
    │   ├─ layout again on template and list
    │   └─ preferredContentSize = page.size
    init(templateView:primaryButton:secondaryButton:cancelButton:)   (unchanged)
```

## 详细设计

```swift
public struct OBTemplatePage {
    public enum Image {
        case systemImage(String)
        case image(NSImage)
    }

    public struct Layout: Hashable, Sendable {
        public static let standard: Layout   // 175-point margins, image leads
        public static let wide: Layout       // 85-point margins, image leads
        public static let centered: Layout   // 68-point margins, image centered, rows 344 wide
        public static let privacy: Layout    // 68-point margins, content in an inner scroll view
    }

    public var title: String
    public var bodyText: String?
    public var image: Image?
    public var features: [OBTemplatePartBulletList.Item]
    public var featureTintColor: NSColor?
    public var featureSpacing: OBBulletListSpacing
    public var layout: Layout
    public var size: NSSize

    public init(title: String, bodyText: String? = nil, image: Image? = nil,
                features: [OBTemplatePartBulletList.Item] = [], featureTintColor: NSColor? = nil,
                featureSpacing: OBBulletListSpacing = .default, layout: Layout = .centered,
                size: NSSize = OBTemplateContainerViewController.sheetSize())

    public init(title: String, bodyText: String? = nil, image: Image? = nil,
                featureTintColor: NSColor? = nil, featureSpacing: OBBulletListSpacing = .default,
                layout: Layout = .centered, size: NSSize = OBTemplateContainerViewController.sheetSize(),
                @OBTemplatePartBulletList.ItemBuilder features: () -> [OBTemplatePartBulletList.Item])
}

extension OBTemplateContainerViewController {
    public convenience init(page: OBTemplatePage, primaryButton: Button,
                            secondaryButton: Button? = nil, cancelButton: Button? = nil)
}
```

- 每次组装都新建视图与控制器，页面值可以反复用、随时改。
- 没有功能行时不建列表（`contentArea` 为 nil）。
- `.image(_:)` 走 `initWithTitle:bodyText:icon:contentLayoutStyle:`，图片按调用方给的 `size` 显示；App Store 的 App 图标是 128pt。

## 替代方案考量

- **版式用 enum**：穷举方便，但版式会增加（比如只加宽内容区的 `needsExtraWideContentAreaOnly`），加一个 case 就破坏调用方的 `switch`。按 Apple 的做法用 struct 加静态成员。
- **直接暴露 `templateType` 与 `needsExtraWideContent` 两个字段**：等于把框架的组合规则交给调用方，`.standard` 加 `needsExtraWideContent` 才是 85pt 这种知识又得各自去查。用具名版式。
- **把按钮也放进页面值**：按钮带闭包，和「描述页面」不是一类数据；与已有构造器对称、按钮作参数更顺手。
- **页面值自己提供 `makeViewController()`**：Apple 由值建控制器的先例多是控制器的构造器（`NSHostingController(rootView:)`），本包也已有 `init(templateView:…)`，所以用构造器。

## 影响

### 源码兼容性（source compatibility）

纯新增。已有的 `init(templateView:…)`、`sheetSize(forParentWindowSize:)` 不变。

### ABI 兼容性（条件项）

不适用 —— 本库以 SPM 源码分发，使用方每次重新编译。

### 下游影响

RuntimeViewer 的 `RuntimeViewerAppUI`（`OnboardingPage+TemplateContainer.swift`）可以改成把自己的页面数据映射成 `OBTemplatePage` 再组装，删掉手设的 `templateType` 与 `preferredContentSize`；需要本包发布包含它的版本后再抬下限。

### 文档与示例

README 的用法改为以页面值为主，原写法保留在「Building the template yourself」；实现说明补文件树与组装顺序。

## API 演进与废弃策略

不废弃任何 API。新增公开类型，发布时按 semver 升次版本号（`0.2.0`）。

## 落地步骤

1. ✅ **页面值与组装** —— 改动地图前四行
   - 行为：The template shows the page's title, body text and symbol
   - 行为：The bullet list has a row for each feature, in order
   - 行为：A page without features has no bullet list
   - 行为：Each layout reaches the template and its bullet list
   - 行为：The controller asks for the page's size
   - 行为：A window made from the page is the page's size, and the template fills it
2. ✅ **文档** —— 改动地图后三行
3. ✅ **发布** —— 打 `0.2.0`，RuntimeViewer 改用它

## 决策日志

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-11-24 | Created as In Progress | RuntimeViewer 的引导页三次因视图、控制器属性没设对而难看。用户用 demo 比较样式后，要求把 demo 里组装页面的那部分搬进本库：封装成结构化数据，不暴露视图与控制器的属性，最后组装成控制器。按用户的直接要求实现，提案随实现一起写。 |
| 2026-11-24 | 第 1、2 步完成 | Ultra 上 36 个测试全过；去掉组装后设回版式的几行时，版式那组测试变红（已有的按钮构造器会把标准类型改成居中）。demo 已改为走 `OBTemplatePage`。默认版式暂定 `.centered`（App Store 的做法），等用户在 demo 里调过再定。 |
| 2026-11-24 | Implemented，发布 0.2.0 | 用户选定 App Store 的样式（居中版式、功能行用强调色、What's New 不放顶部图片），默认版式维持 `.centered`。连同尚未单独发布的「标准类型改成居中」（原计划 0.1.2）一起打 `0.2.0`：新增公开类型，按 semver 升次版本号。RuntimeViewer 随即改用页面值。配套文档：不另写，用法在 README、组装顺序在实现说明。新术语：无。 |
| 2026-11-25 | 修正默认行距，发布 0.2.1 | 0.2.0 的 `featureSpacing` 默认 `.default`（0）并写回列表，盖掉了框架给新列表的 `large`，每行图标成了 0 × 0，RuntimeViewer 的 What's New 上符号压在标题上。改为 `.default` 不写回列表，独立行与子行按 `.large` 建、子行跟随列表的档位，复现测试修复前先红。`OBTemplatePartBulletListItem(item:)` 加了带默认值的 `spacing:`，源码兼容，按 semver 发补丁版本。原因记在实现说明。 |
