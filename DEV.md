# LunarBar 的开发

也许是因为疯了，我才会在 2023 年末开发一款日历应用。我第一次发布日历应用是在十年前，这种没多少新意的产品似乎不值得投入。

但遗憾的是，截止到 [LunarBar](https://github.com/LunarBar-app/LunarBar) 发布前，我都觉得 Mac 的状态栏没有一款日历堪称完美。

最近我重新思考了这个问题，并借由 LunarBar 的开发纠正了一些十年前犯过的错误，丢掉了一些历史包袱。

## 难点在哪

实际上，开发一款农历应用，并没有很多人想象的“那么”容易，以下是一些事实：

```
阴历不等于农历，农历是“阴阳合历”，这里面的阴阳指的是月亮和太阳。

二十四节气是阳历概念，是根据太阳在黄道上的位置来确定的。

同理，清明节是阳历节日，因为它是一个节气。

还是节气，不要用公式计算。最安全的方法就是打表，把天文台数据近两百年的节气全存下来。

天干地支的繁体和简体写法完全一样，但有些错误的翻译会把“丑时”写成“醜时”，这要归咎于汉字简化把这两个字合并了。

地支、时辰、生肖，这几个概念是一一对应的。卯就是兔，辰就是龙。

说阳历 2024 年是龙年是不对的，因为春节前是还是兔年。

除夕的日期并不确定，可能是在腊月三十，或腊月廿（niàn）九。

“小年”是一个因地而异的概念，维基百科上能找到五种不同的解释。

不能断言阴历最后一个月是十二月，闰月普遍存在，两三年就会出现一次。
```

上面的每一条，都可能会变成 bug 或者用户反馈。

## 我的结论是什么

非常简单：**除非万不得已，尽可能地依赖系统行为**。每多一个计算，就会多一个出错的机会。

很多人不知道 Apple 在很多年前就已经提供了对中国日历的支持，例如：

```swift
let calendar = Calendar(identifier: .chinese)
```

这将给你一个几乎完美的 lunar calendar，用 [DateComponents](https://developer.apple.com/documentation/foundation/datecomponents) 获得 `month` 和 `day` 再映射成类似 `正月` 和 `初一` 这类字符串，工作就完成 80% 了。

事实上，上面这个 [.chinese](https://developer.apple.com/documentation/foundation/calendar/identifier/chinese) 日历与 [DateFormatter](https://developer.apple.com/documentation/foundation/dateformatter) 配合得也很好，比如：

```swift
let formatter = DateFormatter()
formatter.calendar = Calendar(identifier: .chinese)
formatter.dateStyle = .long
formatter.timeStyle = .none
```

这个 `formatter` 将在中文环境下得到类似 `2023年癸卯冬月十九` 这样的描述，所以[天干地支](https://zh-yue.wikipedia.org/wiki/%E5%B9%B2%E6%94%AF)也有了。美中不足的是其组成部分不能很好地被提取出来，导致上面提到 `month` 和 `day` 的映射仍然是必要的。

所以 LunarBar 完全没有任何这方面的“计算”，所有的“转换”都是基于 [Calendar](https://developer.apple.com/documentation/foundation/calendar), [Date](https://developer.apple.com/documentation/foundation/date), [DateComponents](https://developer.apple.com/documentation/foundation/datecomponents), [DateFormatter](https://developer.apple.com/documentation/foundation/dateformatter) 这几个核心类实现的。在最新的系统上，`DateComponents` 也提供了对[闰月](https://developer.apple.com/documentation/foundation/calendar/component/isleapmonth)的支持。

就连星期符号那一栏的“日 一 二 三 四 五 六”，也是靠[系统提供](https://developer.apple.com/documentation/foundation/calendar/2293235-weekdaysymbols)的。日历在规则之上有很多奇怪的例外，比如阳历闰年和阴历闰月，这让计算变得极其复杂。我选择完全依赖系统行为，不做任何基于经验的假设，因为它们常常是错的。甚至，就连“一周有七天”这种假设，都[不是完全正确](https://www.quora.com/Is-there-anywhere-in-the-world-where-a-7-day-week-is-not-observed)的。

## 剩下的 20% 怎么办

内置的 `Foundation.Calendar` 最大的缺陷是没有提供对[二十四节气](https://zh.wikipedia.org/wiki/%E8%8A%82%E6%B0%94)的支持，也有可能是我没有找到相关的方法。不过考虑到 Apple 原生的日历也不支持，合理怀疑就是没有。

关键是，支持二十四节气并不容易。

是的，你可以在网上找到很多种计算公式。遗憾的是，它们几乎都是错的，或者说不能 100% 正确。所以正如我所说，这个部分最安全的做法就是打表，LunarBar 内置了 200 年的天文台数据，并且压缩成了一个只有 35 KB 的[文件](https://github.com/LunarBar-app/LunarBar/blob/main/LunarBarKit/Sources/LunarCalendar/Resources/data.json)。

另外，系统行为也不总是那么符合预期。

例如 [Calendar.weekdaySymbols](https://developer.apple.com/documentation/foundation/calendar/2293235-weekdaysymbols)，它不会随着 [Calendar.firstWeekday](https://developer.apple.com/documentation/foundation/calendar/2293656-firstweekday) 的变化而变化，但 LunarBar 的日期会响应用户设置的“周首日”变化，所以需要手动去调整 `weekdaySymbols` 的顺序。

举这个例子是为了说明，LunarBar 只有像这种极端情况才会引入自己的逻辑，并且大多都有 Unit Tests 保证正确性。

## 格式化日期

你可能尝试过用 `YYYY` 来格式化年份，也听说过 `yyyy` 才是更好的实践。

可惜，日本人会告诉你这也是错的，得用 `yy` 来格式化日本日历。

但遗憾的是，最佳实践其实是 `y`，[不会吧？！](https://twitter.com/davedelong/status/1344388020661673985)

如果要加上月份，那么 `MMM y` 可以让你得到类似 `Dec 2023` 这样的字符串，看上去很棒。

那中文呢？怎么得到上述字符串的 `2023年12月` 版本？通过本地化提供两个模板？

试试 [DateFormatter.setLocalizedDateFormatFromTemplate(_:)](https://developer.apple.com/documentation/foundation/dateformatter/1417087-setlocalizeddateformatfromtempla) 吧，它会根据当前的 `Locale` 来决定输出的格式，这就是依赖系统的好处。

## 界面开发方面

我已经在 Apple 平台写了超过十年的界面，完全见证了这个平台这十几年的发展。但开发 LunarBar 我没有使用时下流行的 [SwiftUI](https://developer.apple.com/documentation/swiftui/)，而是用可以说已经“行将就木”的 [AppKit](https://developer.apple.com/documentation/appkit/) 开发了全部界面。

这完全是因为我知道自己在做什么。

LunarBar 很多 UI 细节可以说只有用心才能体会到，而这些细致入微的控制不是 macOS 上的 SwiftUI 可以提供的。我也很遗憾在 2024 年还在说这个话，但我真的不想搞一堆看上去就想吐的变通方法去完成一件简单的差事。我无意参与 SwiftUI 和 AppKit / UIKit 谁更好这种无聊的战争，因为在我看来所有的好坏都是针对场景而言的，这里我只是单纯地告诉你这个决策的原因。

话虽如此，LunarBar 仍然使用了 [Implementing Modern Collection Views
](https://developer.apple.com/documentation/uikit/views_and_controls/collection_views/implementing_modern_collection_views) 中提到的一些技巧，所以相对而言 LunarBar 的界面也是与时俱进的。

另外界面上 LunarBar 也遵循了“除非万不得已，尽可能地依赖系统行为”这个原则。没有花哨的“控件发明”，这让喜欢 Mac 原生应用的人感到安心，也让支持 [Accessibility](https://developer.apple.com/accessibility/) 变得简单。

## 沙盒困境

LunarBar 是一个极简应用，它只会提示某个日期是否有日历事件，而点击该日期会在系统日历应用打开。

首先 Calendar 支持完善的 [AppleScript](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html) 编程，可以在[官方文档](https://developer.apple.com/library/archive/documentation/AppleApplications/Conceptual/CalendarScriptingGuide/index.html) 找到各种操作 Calendar 应用的方法。

其次要在[沙盒环境](https://developer.apple.com/documentation/security/app_sandbox/)下让上述方法工作，需要这些权限：

```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.personal-information.calendars</key>
<true/>
<key>com.apple.security.temporary-exception.apple-events</key>
<array>
  <string>com.apple.iCal</string>
</array>
```

此外也需要添加 [NSCalendarsFullAccessUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nscalendarsfullaccessusagedescription) 以及获取它的流程。需要注意的是，Apple 审核常常会对 `com.apple.security.temporary-exception.apple-events` 颇有微词。

好在 LunarBar 虽然是沙盒应用，但我并不打算提供 Mac App Store 版本。

## 本地化

尽管农历应用有一半的界面元素都是中文，我在开发 LunarBar 时仍然是用英语作为默认语言，再本地化成简体中文和繁体中文。

繁体中文的转换使用了 [OpenCC](https://github.com/BYVoid/OpenCC) 外加人工校对，而在与系统翻译保持一致方面，则依靠了 [Apple Localization Terms Glossary](https://applelocalization.com) 这个网站。当然我没有完全听它的，毕竟我比 Apple 更懂中文。

技术上，使用了 2023 年刚问世的 [string catalogs](https://developer.apple.com/videos/play/wwdc2023/10155/) 来取代传统的 [strings](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html) 文件。

## 拥抱新方法

很多开发方法和十年前已经不一样了，这也是为什么我倾向于把历史包袱都丢掉，而不是一直打补丁。

十年前我还在用 Objective-C 写应用，而 LunarBar 是 100% Swift，用 [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) 处理异步，用 [Swift Packages](https://developer.apple.com/documentation/xcode/swift-packages/) 组织代码。

十年前做一个应用还需要自己画很多图标，而 LunarBar 除了桌面图标以外没有任何图片资源，应用内所有图标都是通过 [SF Symbols](https://developer.apple.com/sf-symbols/) 实现的。

十年前本地化一个应用可以用痛苦来形容，而最新的 [string catalogs](https://developer.apple.com/videos/play/wwdc2023/10155/) 拥有编译期安全、更好的格式、内置编辑器，支持多语言完全让我感到愉悦。

我很感激新方法带来的便利，尽管制作一个应用在 2024 年已经不是一件很酷的事。

## 最后

总之 LunarBar 就是这样一个即传统又现代的产品，感谢阅读，就此打住。
