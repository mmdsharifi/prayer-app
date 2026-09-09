import Cocoa
import FlutterMacOS
import WidgetKit
import CoreText

@main
class AppDelegate: FlutterAppDelegate {
  private var statusItem: NSStatusItem?
  private var methodChannel: FlutterMethodChannel?
  private var isAlwaysOnTop: Bool = false
  private var isWidgetMode: Bool = false
  private var originalFrame: NSRect?

  // Stored state for dynamic menu rebuilding & widget sync
  private var currentTitle: String = "🕌 ۰۰:۰۰"
  private var nextPrayerInfo: [String: Any]?
  private var todayTimes: [String: String]?
  private var zikrText: String?
  private var hadithText: String?

  private var dateText: String?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    registerCustomFonts()

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      setupMethodChannel(messenger: controller.engine.binaryMessenger)
    }

    setupStatusBarItem()
    configureWindowAppearance()
  }

  // MARK: - Custom Font Registration (Estedad & Vazirmatn)
  private func registerCustomFonts() {
    let bundle = Bundle.main
    var fontUrls: [URL] = []

    let fontFiles = [
      "Estedad-Regular.ttf", "Estedad-Medium.ttf", "Estedad-SemiBold.ttf", "Estedad-Bold.ttf",
      "Estedad-FD-Regular.ttf", "Estedad-FD-Bold.ttf",
      "Vazirmatn-Regular.ttf", "Vazirmatn-Medium.ttf", "Vazirmatn-Bold.ttf"
    ]

    for file in fontFiles {
      let base = (file as NSString).deletingPathExtension
      let ext = (file as NSString).pathExtension
      if let url = bundle.url(forResource: base, withExtension: ext, subdirectory: "flutter_assets/assets/fonts") {
        fontUrls.append(url)
      }
      let candidatePaths = [
        bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/assets/fonts/\(file)"),
        bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/fonts/\(file)"),
        bundle.bundleURL.appendingPathComponent("Contents/Resources/flutter_assets/assets/fonts/\(file)"),
        URL(fileURLWithPath: "/Users/user/Library/Fonts/\(file)")
      ]
      for p in candidatePaths {
        if FileManager.default.fileExists(atPath: p.path) {
          fontUrls.append(p)
        }
      }
    }

    for url in fontUrls {
      var error: Unmanaged<CFError>?
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }
  }

  static func estedadFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    let fontName: String
    if weight == .bold || weight == .heavy || weight == .black {
      fontName = "Estedad-Bold"
    } else if weight == .semibold {
      fontName = "Estedad-SemiBold"
    } else if weight == .medium {
      fontName = "Estedad-Medium"
    } else {
      fontName = "Estedad-Regular"
    }
    if let customFont = NSFont(name: fontName, size: size) {
      return customFont
    }
    if let baseFont = NSFont(name: "Estedad", size: size) {
      return baseFont
    }
    return vazirmatnFont(size: size, weight: weight)
  }

  static func vazirmatnFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    let fontName: String
    if weight == .bold || weight == .heavy || weight == .black {
      fontName = "Vazirmatn-Bold"
    } else if weight == .medium || weight == .semibold {
      fontName = "Vazirmatn-Medium"
    } else {
      fontName = "Vazirmatn-Regular"
    }
    if let customFont = NSFont(name: fontName, size: size) {
      return customFont
    }
    if let baseFont = NSFont(name: "Vazirmatn", size: size) {
      return baseFont
    }
    return NSFont.systemFont(ofSize: size, weight: weight)
  }

  static func systemSymbolImage(name: String, pointSize: CGFloat = 13.0, weight: NSFont.Weight = .medium) -> NSImage? {
    if #available(macOS 11.0, *) {
      let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
      let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config)
      img?.isTemplate = true
      return img
    }
    return nil
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep running in the menu bar when the window is closed
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func configureWindowAppearance() {
    guard let window = mainFlutterWindow else { return }
    window.isMovableByWindowBackground = true
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.insert(.fullSizeContentView)
    window.minSize = NSSize(width: 320, height: 380)
  }

  // MARK: - Status Bar Setup

  @discardableResult
  func getOrCreateStatusItem() -> NSStatusItem {
    if let existing = self.statusItem {
      return existing
    }
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.isVisible = true
    item.autosaveName = "PrayerAppStatusItem"
    self.statusItem = item
    return item
  }

  func setupStatusBarItem() {
    DispatchQueue.main.async {
      let item = self.getOrCreateStatusItem()
      if let button = item.button {
        let img = AppDelegate.systemSymbolImage(name: "sun.max.fill", pointSize: 14.0, weight: .semibold)
        button.image = img
        button.imagePosition = (img != nil) ? .imageLeading : .noImage
        button.title = (img != nil) ? " ۰۰:۰۰" : "🕌 ۰۰:۰۰"
        button.font = AppDelegate.estedadFont(size: 13.0, weight: .bold)
      }
      item.menu = self.buildMenu()
    }
  }

  func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "prayer_app/menubar",
      binaryMessenger: messenger
    )

    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "updateMenuBar":
        if let args = call.arguments as? [String: Any] {
          self.handleUpdateMenuBar(args: args)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a Map", details: nil))
        }

      case "showWindow":
        self.showMainWindow()
        result(true)

      case "hideWindow":
        self.hideMainWindow()
        result(true)

      case "toggleWindow":
        self.toggleMainWindow()
        result(true)

      case "togglePopover":
        self.togglePopoverWindow()
        result(true)

      case "setAlwaysOnTop":
        if let isTop = call.arguments as? Bool {
          self.setAlwaysOnTop(isTop)
          result(true)
        } else {
          result(false)
        }

      case "setWidgetMode":
        if let isWidget = call.arguments as? Bool {
          self.setWidgetMode(isWidget)
          result(true)
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleUpdateMenuBar(args: [String: Any]) {
    let sfSymbol = (args["sfSymbol"] as? String) ?? "sun.max.fill"
    let timeStr = (args["remainingTime"] as? String) ?? (args["title"] as? String) ?? "۰۰:۰۰"

    self.currentTitle = timeStr

    if let np = args["nextPrayer"] as? [String: Any] {
      self.nextPrayerInfo = np
    }
    if let times = args["times"] as? [String: String] {
      self.todayTimes = times
    }
    if let zikr = args["zikr"] as? String {
      self.zikrText = zikr
    }
    if let hadith = args["hadith"] as? String {
      self.hadithText = hadith
    }
    if let date = args["date"] as? String {
      self.dateText = date
    }

    DispatchQueue.main.async {
      let item = self.getOrCreateStatusItem()
      if let button = item.button {
        let img = AppDelegate.systemSymbolImage(name: sfSymbol, pointSize: 14.0, weight: .semibold)
        button.image = img
        button.imagePosition = (img != nil) ? .imageLeading : .noImage
        button.title = (img != nil) ? " \(timeStr)" : "🕌 \(timeStr)"
        button.font = AppDelegate.estedadFont(size: 13.0, weight: .bold)
      }
      item.menu = self.buildMenu()
    }

    // Sync to Shared UserDefaults for macOS WidgetKit
    if let data = try? JSONSerialization.data(withJSONObject: args, options: []) {
      UserDefaults(suiteName: "group.com.example.prayerApp")?.set(data, forKey: "prayer_widget_data")
      UserDefaults.standard.set(data, forKey: "prayer_widget_data")
    }
    if #available(macOS 11.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  @discardableResult
  private func buildMenu() -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false

    // 1. App Header (Title, Date, Countdown)
    var countdownStr: String? = nil
    if let np = nextPrayerInfo,
       let label = np["label"] as? String,
       let delta = np["delta"] as? String,
       let time = np["time"] as? String {
      countdownStr = "تا \(label): \(delta) (ساعت \(time))"
    }

    var headerHeight: CGFloat = 34.0
    if dateText != nil && !dateText!.isEmpty { headerHeight += 22.0 }
    if countdownStr != nil { headerHeight += 26.0 }

    let headerItem = NSMenuItem()
    let headerView = PrayerMenuHeaderView(
      frame: NSRect(x: 0, y: 0, width: 330, height: headerHeight),
      title: "برنامه اذکار من (اوقات شرعی)",
      dateText: dateText,
      countdownText: countdownStr,
      target: self,
      action: #selector(showMainWindow)
    )
    headerItem.view = headerView
    menu.addItem(headerItem)

    menu.addItem(NSMenuItem.separator())

    // 2. Prayer Times Section Header
    let timesHeaderItem = NSMenuItem()
    let timesHeaderView = PrayerSectionHeaderView(
      frame: NSRect(x: 0, y: 0, width: 330, height: 22),
      title: "جدول اوقات شرعی امروز:"
    )
    timesHeaderItem.view = timesHeaderView
    menu.addItem(timesHeaderItem)

    let prayerOrder: [(key: String, name: String, sfSymbol: String)] = [
      ("fajr", "اذان صبح", "sunrise.fill"),
      ("sunrise", "طلوع آفتاب", "sun.max.fill"),
      ("dhuhr", "اذان ظهر", "sun.max"),
      ("asr", "اذان عصر", "cloud.sun.fill"),
      ("maghrib", "اذان مغرب", "sunset.fill"),
      ("isha", "اذان عشاء", "moon.stars.fill")
    ]

    let activePrayer = nextPrayerInfo?["label"] as? String

    if let times = todayTimes {
      for p in prayerOrder {
        let timeStr = times[p.key] ?? "--:--"
        let isNext = (activePrayer == p.name)

        let item = NSMenuItem()
        let rowView = PrayerRowMenuItemView(
          frame: NSRect(x: 0, y: 0, width: 330, height: 28),
          sfSymbol: p.sfSymbol,
          name: p.name,
          time: timeStr,
          isNext: isNext,
          target: self,
          action: #selector(showMainWindow)
        )
        item.view = rowView
        menu.addItem(item)
      }
    }

    // 3. Zikr & Hadith Section (if available)
    if (zikrText != nil && !zikrText!.isEmpty) || (hadithText != nil && !hadithText!.isEmpty) {
      menu.addItem(NSMenuItem.separator())

      if let z = zikrText, !z.isEmpty {
        let zikrItem = NSMenuItem()
        let zikrView = PrayerTextRowMenuItemView(
          frame: NSRect(x: 0, y: 0, width: 330, height: 26),
          text: "📿 ذکر: \(z)",
          target: self,
          action: #selector(showMainWindow)
        )
        zikrItem.view = zikrView
        menu.addItem(zikrItem)
      }

      if let h = hadithText, !h.isEmpty {
        let shortHadith = h.count > 45 ? String(h.prefix(42)) + "..." : h
        let hadithItem = NSMenuItem()
        let hadithView = PrayerTextRowMenuItemView(
          frame: NSRect(x: 0, y: 0, width: 330, height: 26),
          text: "📜 حدیث: \(shortHadith)",
          fullText: h,
          target: self,
          action: #selector(showMainWindow)
        )
        hadithItem.view = hadithView
        menu.addItem(hadithItem)
      }
    }

    menu.addItem(NSMenuItem.separator())

    // 4. Window Controls
    let isWinVisible = mainFlutterWindow?.isVisible == true && NSApp.isActive
    let toggleItem = NSMenuItem(
      title: isWinVisible ? "مخفی کردن پنجره" : "نمایش پنجره اصلی برنامه",
      action: #selector(toggleMainWindow),
      keyEquivalent: "o"
    )
    toggleItem.keyEquivalentModifierMask = [.command]
    toggleItem.target = self
    let toggleView = PrayerActionMenuItemView(
      frame: NSRect(x: 0, y: 0, width: 330, height: 26),
      title: isWinVisible ? "مخفی کردن پنجره" : "نمایش پنجره اصلی برنامه",
      shortcut: "⌘ O",
      target: self,
      action: #selector(toggleMainWindow)
    )
    toggleItem.view = toggleView
    menu.addItem(toggleItem)

    let widgetModeItem = NSMenuItem(
      title: isWidgetMode ? "✓ حالت ویجت شناور رومیزی" : "حالت ویجت شناور رومیزی",
      action: #selector(toggleWidgetMode),
      keyEquivalent: "w"
    )
    widgetModeItem.keyEquivalentModifierMask = [.command]
    widgetModeItem.target = self
    let widgetView = PrayerActionMenuItemView(
      frame: NSRect(x: 0, y: 0, width: 330, height: 26),
      title: isWidgetMode ? "✓ حالت ویجت شناور رومیزی" : "حالت ویجت شناور رومیزی",
      shortcut: "⌘ W",
      target: self,
      action: #selector(toggleWidgetMode)
    )
    widgetModeItem.view = widgetView
    menu.addItem(widgetModeItem)

    let pinItem = NSMenuItem(
      title: isAlwaysOnTop ? "✓ شناور ماندن در بالا" : "همیشه در بالاترین لایه (Pin)",
      action: #selector(toggleAlwaysOnTop),
      keyEquivalent: "p"
    )
    pinItem.keyEquivalentModifierMask = [.command]
    pinItem.target = self
    let pinView = PrayerActionMenuItemView(
      frame: NSRect(x: 0, y: 0, width: 330, height: 26),
      title: isAlwaysOnTop ? "✓ شناور ماندن در بالا" : "همیشه در بالاترین لایه (Pin)",
      shortcut: "⌘ P",
      target: self,
      action: #selector(toggleAlwaysOnTop)
    )
    pinItem.view = pinView
    menu.addItem(pinItem)

    menu.addItem(NSMenuItem.separator())

    // 5. Quit Item
    let quitItem = NSMenuItem(
      title: "خروج از اذکار من",
      action: #selector(quitApp),
      keyEquivalent: "q"
    )
    quitItem.keyEquivalentModifierMask = [.command]
    quitItem.target = self
    let quitView = PrayerActionMenuItemView(
      frame: NSRect(x: 0, y: 0, width: 330, height: 26),
      title: "خروج از اذکار من",
      shortcut: "⌘ Q",
      isDestructive: true,
      target: self,
      action: #selector(quitApp)
    )
    quitItem.view = quitView
    menu.addItem(quitItem)

    return menu
  }

  // MARK: - Actions

  @objc private func togglePopoverWindow() {
    guard let window = mainFlutterWindow else { return }
    if window.isVisible && window.isKeyWindow {
      hideMainWindow()
    } else {
      showAnchoredToStatusBar()
    }
  }

  private func showAnchoredToStatusBar() {
    guard let window = mainFlutterWindow,
          let button = statusItem?.button,
          let buttonWindow = button.window else {
      showMainWindow()
      return
    }

    let buttonRect = buttonWindow.convertToScreen(button.frame)
    let windowSize = window.frame.size

    // Position directly under status bar button
    var targetX = buttonRect.midX - (windowSize.width / 2)
    let targetY = buttonRect.minY - windowSize.height - 4

    if let screen = button.window?.screen ?? NSScreen.main {
      let screenFrame = screen.visibleFrame
      if targetX + windowSize.width > screenFrame.maxX {
        targetX = screenFrame.maxX - windowSize.width - 8
      }
      if targetX < screenFrame.minX {
        targetX = screenFrame.minX + 8
      }
    }

    window.setFrameOrigin(NSPoint(x: targetX, y: targetY))
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.orderFrontRegardless()
  }

  @objc private func showMainWindow() {
    guard let window = mainFlutterWindow else { return }
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.orderFrontRegardless()
  }

  @objc private func hideMainWindow() {
    guard let window = mainFlutterWindow else { return }
    window.orderOut(nil)
  }

  @objc private func toggleMainWindow() {
    guard let window = mainFlutterWindow else { return }
    if window.isVisible && NSApp.isActive {
      hideMainWindow()
    } else {
      showMainWindow()
    }
  }

  @objc private func toggleAlwaysOnTop() {
    setAlwaysOnTop(!isAlwaysOnTop)
  }

  private func setAlwaysOnTop(_ top: Bool) {
    isAlwaysOnTop = top
    guard let window = mainFlutterWindow else { return }
    window.level = top ? .floating : .normal
  }

  @objc private func toggleWidgetMode() {
    setWidgetMode(!isWidgetMode)
  }

  private func setWidgetMode(_ enable: Bool) {
    guard let window = mainFlutterWindow else { return }
    isWidgetMode = enable
    if enable {
      originalFrame = window.frame
      window.level = .floating
      isAlwaysOnTop = true
      var frame = window.frame
      frame.size = NSSize(width: 380, height: 520)
      window.setFrame(frame, display: true, animate: true)
    } else {
      isAlwaysOnTop = false
      window.level = .normal
      if let orig = originalFrame {
        window.setFrame(orig, display: true, animate: true)
      }
    }
    showMainWindow()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}

// MARK: - Custom RTL Menu Views (Estedad Font)

/// Header card showing app title, Jalali date, and next prayer countdown banner
class PrayerMenuHeaderView: NSView {
  let title: String
  let dateText: String?
  let countdownText: String?
  weak var target: AnyObject?
  let action: Selector?

  private var isHighlighted: Bool = false
  private var trackingArea: NSTrackingArea?

  init(frame: NSRect, title: String, dateText: String?, countdownText: String?, target: AnyObject?, action: Selector?) {
    self.title = title
    self.dateText = dateText
    self.countdownText = countdownText
    self.target = target
    self.action = action
    super.init(frame: frame)
    self.autoresizingMask = [.width]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let ta = trackingArea { removeTrackingArea(ta) }
    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  override func mouseEntered(with event: NSEvent) {
    isHighlighted = true
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHighlighted = false
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    if bounds.contains(convert(event.locationInWindow, from: nil)) {
      if let menu = enclosingMenuItem?.menu {
        menu.cancelTracking()
      }
      if let action = action, let target = target {
        _ = target.perform(action, with: self)
      }
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let insetRect = bounds.insetBy(dx: 5, dy: 2)
    if isHighlighted {
      NSColor.selectedContentBackgroundColor.withAlphaComponent(0.18).setFill()
      let path = NSBezierPath(roundedRect: insetRect, xRadius: 6, yRadius: 6)
      path.fill()
    }

    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let titleColor = isDark ? NSColor.white : NSColor(white: 0.10, alpha: 1.0)
    let subColor = isDark ? NSColor(white: 0.65, alpha: 1.0) : NSColor(white: 0.45, alpha: 1.0)

    let rightMargin: CGFloat = 14.0
    let leftMargin: CGFloat = 14.0
    let contentWidth = bounds.width - rightMargin - leftMargin

    let rightPara = NSMutableParagraphStyle()
    rightPara.alignment = .right
    rightPara.baseWritingDirection = .rightToLeft

    var currentY = bounds.height - 24.0

    // Title
    let titleAttr: [NSAttributedString.Key: Any] = [
      .font: AppDelegate.estedadFont(size: 13.5, weight: .bold),
      .foregroundColor: titleColor,
      .paragraphStyle: rightPara
    ]
    let titleRect = NSRect(x: leftMargin, y: currentY, width: contentWidth, height: 20)
    (title as NSString).draw(in: titleRect, withAttributes: titleAttr)

    // Date
    if let d = dateText, !d.isEmpty {
      currentY -= 20.0
      let dateAttr: [NSAttributedString.Key: Any] = [
        .font: AppDelegate.estedadFont(size: 11.5, weight: .medium),
        .foregroundColor: subColor,
        .paragraphStyle: rightPara
      ]
      let dateRect = NSRect(x: leftMargin, y: currentY, width: contentWidth, height: 18)
      (d as NSString).draw(in: dateRect, withAttributes: dateAttr)
    }

    // Countdown
    if let cd = countdownText, !cd.isEmpty {
      currentY -= 24.0
      let cdAttr: [NSAttributedString.Key: Any] = [
        .font: AppDelegate.estedadFont(size: 12.0, weight: .bold),
        .foregroundColor: NSColor.systemOrange,
        .paragraphStyle: rightPara
      ]
      let cdRect = NSRect(x: leftMargin, y: currentY, width: contentWidth, height: 18)
      (cd as NSString).draw(in: cdRect, withAttributes: cdAttr)
    }
  }
}

/// Section title (e.g. "جدول اوقات شرعی امروز:")
class PrayerSectionHeaderView: NSView {
  let title: String

  init(frame: NSRect, title: String) {
    self.title = title
    super.init(frame: frame)
    self.autoresizingMask = [.width]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    let rightPara = NSMutableParagraphStyle()
    rightPara.alignment = .right
    rightPara.baseWritingDirection = .rightToLeft

    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let color = isDark ? NSColor(white: 0.65, alpha: 1.0) : NSColor(white: 0.45, alpha: 1.0)

    let attr: [NSAttributedString.Key: Any] = [
      .font: AppDelegate.estedadFont(size: 11.5, weight: .bold),
      .foregroundColor: color,
      .paragraphStyle: rightPara
    ]
    let rect = NSRect(x: 14, y: (bounds.height - 18) / 2, width: bounds.width - 28, height: 18)
    (title as NSString).draw(in: rect, withAttributes: attr)
  }
}

/// Prayer row item: SF Symbol icon + Name on right, Time in Persian digits on left, with active badge & hover highlight
class PrayerRowMenuItemView: NSView {
  let sfSymbol: String
  let name: String
  let time: String
  let isNext: Bool
  weak var target: AnyObject?
  let action: Selector?

  private var isHighlighted: Bool = false
  private var trackingArea: NSTrackingArea?

  init(frame: NSRect, sfSymbol: String, name: String, time: String, isNext: Bool, target: AnyObject?, action: Selector?) {
    self.sfSymbol = sfSymbol
    self.name = name
    self.time = time
    self.isNext = isNext
    self.target = target
    self.action = action
    super.init(frame: frame)
    self.autoresizingMask = [.width]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let ta = trackingArea {
      removeTrackingArea(ta)
    }
    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  override func mouseEntered(with event: NSEvent) {
    isHighlighted = true
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHighlighted = false
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    if bounds.contains(convert(event.locationInWindow, from: nil)) {
      if let menu = enclosingMenuItem?.menu {
        menu.cancelTracking()
      }
      if let action = action, let target = target {
        _ = target.perform(action, with: self)
      }
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let insetRect = bounds.insetBy(dx: 5, dy: 1.5)

    if isHighlighted {
      NSColor.selectedContentBackgroundColor.setFill()
      let path = NSBezierPath(roundedRect: insetRect, xRadius: 5, yRadius: 5)
      path.fill()
    } else if isNext {
      let greenBg = NSColor.systemGreen.withAlphaComponent(0.18)
      greenBg.setFill()
      let path = NSBezierPath(roundedRect: insetRect, xRadius: 5, yRadius: 5)
      path.fill()
      let greenBorder = NSColor.systemGreen.withAlphaComponent(0.50)
      greenBorder.setStroke()
      path.lineWidth = 1.0
      path.stroke()
    }

    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let textColor: NSColor
    if isHighlighted {
      textColor = .white
    } else if isNext {
      textColor = NSColor.systemGreen
    } else {
      textColor = isDark ? NSColor(white: 0.95, alpha: 1.0) : NSColor(white: 0.15, alpha: 1.0)
    }

    let font: NSFont = isNext
      ? AppDelegate.estedadFont(size: 13.0, weight: .bold)
      : AppDelegate.estedadFont(size: 12.5, weight: .medium)

    // 1. Right side: SF Symbol vector icon + Prayer Name (RTL)
    let iconSize: CGFloat = 14.0
    let rightMargin: CGFloat = 14.0
    let iconX = bounds.width - rightMargin - iconSize
    let iconY = (bounds.height - iconSize) / 2.0

    if let symbolImg = AppDelegate.systemSymbolImage(name: sfSymbol, pointSize: 12.5, weight: isNext ? .bold : .medium) {
      if let tinted = symbolImg.copy() as? NSImage {
        tinted.lockFocus()
        textColor.set()
        NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: NSRect(x: iconX, y: iconY, width: iconSize, height: iconSize))
      }
    }

    // Name text next to icon (right-aligned)
    let rightText = isNext ? "\(name)  ●" : name
    let rightPara = NSMutableParagraphStyle()
    rightPara.alignment = .right
    rightPara.baseWritingDirection = .rightToLeft

    let rightAttr: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: textColor,
      .paragraphStyle: rightPara
    ]
    let leftMargin: CGFloat = 14.0
    let timeWidth: CGFloat = 65.0
    let textWidth = iconX - 8.0 - (leftMargin + timeWidth)
    let rightRect = NSRect(x: leftMargin + timeWidth, y: (bounds.height - 18) / 2, width: textWidth, height: 18)
    (rightText as NSString).draw(in: rightRect, withAttributes: rightAttr)

    // 2. Left side: Prayer Time in Persian digits (Left-aligned)
    let leftPara = NSMutableParagraphStyle()
    leftPara.alignment = .left
    let leftAttr: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: isHighlighted ? .white : (isNext ? NSColor.systemGreen : (isDark ? NSColor(white: 0.90, alpha: 1.0) : NSColor(white: 0.20, alpha: 1.0))),
      .paragraphStyle: leftPara
    ]
    let leftRect = NSRect(x: leftMargin, y: (bounds.height - 18) / 2, width: timeWidth, height: 18)
    (time as NSString).draw(in: leftRect, withAttributes: leftAttr)
  }
}

/// Text row item for Zikr and Hadith (right-aligned, Estedad font, hover highlight, click handling)
class PrayerTextRowMenuItemView: NSView {
  let text: String
  weak var target: AnyObject?
  let action: Selector?

  private var isHighlighted: Bool = false
  private var trackingArea: NSTrackingArea?

  init(frame: NSRect, text: String, fullText: String? = nil, target: AnyObject?, action: Selector?) {
    self.text = text
    self.target = target
    self.action = action
    super.init(frame: frame)
    self.autoresizingMask = [.width]
    if let ft = fullText {
      self.toolTip = ft
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let ta = trackingArea { removeTrackingArea(ta) }
    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  override func mouseEntered(with event: NSEvent) {
    isHighlighted = true
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHighlighted = false
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    if bounds.contains(convert(event.locationInWindow, from: nil)) {
      if let menu = enclosingMenuItem?.menu {
        menu.cancelTracking()
      }
      if let action = action, let target = target {
        _ = target.perform(action, with: self)
      }
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let insetRect = bounds.insetBy(dx: 5, dy: 1.5)
    if isHighlighted {
      NSColor.selectedContentBackgroundColor.setFill()
      let path = NSBezierPath(roundedRect: insetRect, xRadius: 5, yRadius: 5)
      path.fill()
    }

    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let textColor: NSColor = isHighlighted ? .white : (isDark ? NSColor(white: 0.92, alpha: 1.0) : NSColor(white: 0.18, alpha: 1.0))

    let para = NSMutableParagraphStyle()
    para.alignment = .right
    para.baseWritingDirection = .rightToLeft
    para.lineBreakMode = .byTruncatingTail

    let attr: [NSAttributedString.Key: Any] = [
      .font: AppDelegate.estedadFont(size: 12.0, weight: .medium),
      .foregroundColor: textColor,
      .paragraphStyle: para
    ]

    let rect = NSRect(x: 14, y: (bounds.height - 18) / 2, width: bounds.width - 28, height: 18)
    (text as NSString).draw(in: rect, withAttributes: attr)
  }
}

/// Action item with title right-aligned and keyboard shortcut left-aligned, Estedad font, and hover highlight
class PrayerActionMenuItemView: NSView {
  let title: String
  let shortcut: String
  let isDestructive: Bool
  weak var target: AnyObject?
  let action: Selector?

  private var isHighlighted: Bool = false
  private var trackingArea: NSTrackingArea?

  init(frame: NSRect, title: String, shortcut: String, isDestructive: Bool = false, target: AnyObject?, action: Selector?) {
    self.title = title
    self.shortcut = shortcut
    self.isDestructive = isDestructive
    self.target = target
    self.action = action
    super.init(frame: frame)
    self.autoresizingMask = [.width]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let ta = trackingArea { removeTrackingArea(ta) }
    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  override func mouseEntered(with event: NSEvent) {
    isHighlighted = true
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHighlighted = false
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    if bounds.contains(convert(event.locationInWindow, from: nil)) {
      if let menu = enclosingMenuItem?.menu {
        menu.cancelTracking()
      }
      if let action = action, let target = target {
        _ = target.perform(action, with: self)
      }
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let insetRect = bounds.insetBy(dx: 5, dy: 1.5)
    if isHighlighted {
      NSColor.selectedContentBackgroundColor.setFill()
      let path = NSBezierPath(roundedRect: insetRect, xRadius: 5, yRadius: 5)
      path.fill()
    }

    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let titleColor: NSColor
    if isHighlighted {
      titleColor = .white
    } else if isDestructive {
      titleColor = NSColor.systemRed
    } else {
      titleColor = isDark ? NSColor(white: 0.92, alpha: 1.0) : NSColor(white: 0.18, alpha: 1.0)
    }

    let shortcutColor: NSColor = isHighlighted ? .white : (isDark ? NSColor(white: 0.65, alpha: 1.0) : NSColor(white: 0.50, alpha: 1.0))

    // 1. Right side: Title (right-aligned)
    let rightPara = NSMutableParagraphStyle()
    rightPara.alignment = .right
    rightPara.baseWritingDirection = .rightToLeft

    let rightAttr: [NSAttributedString.Key: Any] = [
      .font: AppDelegate.estedadFont(size: 12.0, weight: .regular),
      .foregroundColor: titleColor,
      .paragraphStyle: rightPara
    ]

    let rightMargin: CGFloat = 14.0
    let leftMargin: CGFloat = 14.0
    let shortcutWidth: CGFloat = 45.0
    let titleWidth = bounds.width - rightMargin - (leftMargin + shortcutWidth)
    let titleRect = NSRect(x: leftMargin + shortcutWidth, y: (bounds.height - 18) / 2, width: titleWidth, height: 18)
    (title as NSString).draw(in: titleRect, withAttributes: rightAttr)

    // 2. Left side: Shortcut (left-aligned)
    if !shortcut.isEmpty {
      let leftPara = NSMutableParagraphStyle()
      leftPara.alignment = .left

      let leftAttr: [NSAttributedString.Key: Any] = [
        .font: AppDelegate.estedadFont(size: 11.5, weight: .medium),
        .foregroundColor: shortcutColor,
        .paragraphStyle: leftPara
      ]
      let shortcutRect = NSRect(x: leftMargin, y: (bounds.height - 18) / 2, width: shortcutWidth, height: 18)
      (shortcut as NSString).draw(in: shortcutRect, withAttributes: leftAttr)
    }
  }
}

