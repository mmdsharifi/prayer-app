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
    registerCustomFonts()

    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    if let controller = controller {
      setupMethodChannel(messenger: controller.engine.binaryMessenger)
    }

    setupStatusBarItem()
    configureWindowAppearance()
    super.applicationDidFinishLaunching(notification)
  }

  // MARK: - Custom Font Registration (Vazirmatn)
  private func registerCustomFonts() {
    let bundle = Bundle.main
    let fontUrls: [URL] = [
      bundle.url(forResource: "Vazirmatn-Regular", withExtension: "ttf", subdirectory: "flutter_assets/assets/fonts"),
      bundle.url(forResource: "Vazirmatn-Medium", withExtension: "ttf", subdirectory: "flutter_assets/assets/fonts"),
      bundle.url(forResource: "Vazirmatn-Bold", withExtension: "ttf", subdirectory: "flutter_assets/assets/fonts"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/assets/fonts/Vazirmatn-Regular.ttf"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/assets/fonts/Vazirmatn-Medium.ttf"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/assets/fonts/Vazirmatn-Bold.ttf"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/fonts/Vazirmatn-Regular.ttf"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/fonts/Vazirmatn-Medium.ttf"),
      bundle.bundleURL.appendingPathComponent("Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/fonts/Vazirmatn-Bold.ttf")
    ].compactMap { $0 }

    for url in fontUrls {
      if FileManager.default.fileExists(atPath: url.path) {
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
      }
    }
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

  private func setupStatusBarItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem?.button {
      button.image = AppDelegate.systemSymbolImage(name: "sun.max.fill", pointSize: 13.0, weight: .medium)
      button.imagePosition = .imageLeading

      let attr = NSAttributedString(
        string: " ۰۰:۰۰",
        attributes: [
          .font: AppDelegate.vazirmatnFont(size: 13.5, weight: .bold),
          .foregroundColor: NSColor.labelColor
        ]
      )
      button.attributedTitle = attr
      button.target = self
      button.action = #selector(statusItemClicked(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
  }

  @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
    let menu = buildMenu()
    statusItem?.menu = menu
    statusItem?.button?.performClick(nil)
    DispatchQueue.main.async {
      self.statusItem?.menu = nil
    }
  }

  private func setupMethodChannel(messenger: FlutterBinaryMessenger) {
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

    DispatchQueue.main.async {
      if let button = self.statusItem?.button {
        button.image = AppDelegate.systemSymbolImage(name: sfSymbol, pointSize: 13.0, weight: .medium)
        button.imagePosition = .imageLeading

        let attr = NSAttributedString(
          string: " \(timeStr)",
          attributes: [
            .font: AppDelegate.vazirmatnFont(size: 13.5, weight: .bold),
            .foregroundColor: NSColor.labelColor
          ]
        )
        button.attributedTitle = attr
      }
    }
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

    func rtlAttr(_ string: String, font: NSFont, color: NSColor, alignment: NSTextAlignment = .right) -> NSAttributedString {
      let para = NSMutableParagraphStyle()
      para.alignment = alignment
      para.baseWritingDirection = .rightToLeft
      return NSAttributedString(string: string, attributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: para
      ])
    }

    // App Header Item (Clicking opens window)
    let headerItem = NSMenuItem(
      title: "برنامه اذکار من (اوقات شرعی)",
      action: #selector(showMainWindow),
      keyEquivalent: ""
    )
    headerItem.target = self
    headerItem.attributedTitle = rtlAttr(
      "برنامه اذکار من (اوقات شرعی)",
      font: AppDelegate.vazirmatnFont(size: 13.5, weight: .bold),
      color: NSColor.labelColor
    )
    menu.addItem(headerItem)

    if let d = dateText, !d.isEmpty {
      let dateItem = NSMenuItem(title: "\(d)", action: nil, keyEquivalent: "")
      dateItem.isEnabled = false
      dateItem.attributedTitle = rtlAttr(
        "\(d)",
        font: AppDelegate.vazirmatnFont(size: 11.5, weight: .medium),
        color: NSColor.secondaryLabelColor
      )
      menu.addItem(dateItem)
    }

    // Next Prayer Countdown Banner
    if let np = nextPrayerInfo,
       let label = np["label"] as? String,
       let delta = np["delta"] as? String,
       let time = np["time"] as? String {
      let countdownItem = NSMenuItem(
        title: "تا \(label): \(delta) (ساعت \(time))",
        action: #selector(showMainWindow),
        keyEquivalent: ""
      )
      countdownItem.target = self
      countdownItem.attributedTitle = rtlAttr(
        "تا \(label): \(delta) (ساعت \(time))",
        font: AppDelegate.vazirmatnFont(size: 12.5, weight: .bold),
        color: NSColor.systemOrange
      )
      menu.addItem(countdownItem)
    }

    menu.addItem(NSMenuItem.separator())

    // Prayer Times Section Header
    let timesHeader = NSMenuItem(title: "جدول اوقات شرعی امروز:", action: nil, keyEquivalent: "")
    timesHeader.isEnabled = false
    timesHeader.attributedTitle = rtlAttr(
      "جدول اوقات شرعی امروز:",
      font: AppDelegate.vazirmatnFont(size: 11.5, weight: .bold),
      color: NSColor.secondaryLabelColor
    )
    menu.addItem(timesHeader)

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
          frame: NSRect(x: 0, y: 0, width: 250, height: 26),
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

    // Zikr & Hadith Section (if available)
    if let z = zikrText, !z.isEmpty {
      menu.addItem(NSMenuItem.separator())
      let zikrItem = NSMenuItem(title: "📿 ذکر: \(z)", action: #selector(showMainWindow), keyEquivalent: "")
      zikrItem.target = self
      zikrItem.attributedTitle = rtlAttr(
        "📿 ذکر: \(z)",
        font: AppDelegate.vazirmatnFont(size: 12.0, weight: .medium),
        color: NSColor.labelColor
      )
      menu.addItem(zikrItem)
    }

    if let h = hadithText, !h.isEmpty {
      let shortHadith = h.count > 50 ? String(h.prefix(47)) + "..." : h
      let hadithItem = NSMenuItem(title: "📜 حدیث: \(shortHadith)", action: #selector(showMainWindow), keyEquivalent: "")
      hadithItem.target = self
      hadithItem.toolTip = h
      hadithItem.attributedTitle = rtlAttr(
        "📜 حدیث: \(shortHadith)",
        font: AppDelegate.vazirmatnFont(size: 12.0, weight: .medium),
        color: NSColor.labelColor
      )
      menu.addItem(hadithItem)
    }

    menu.addItem(NSMenuItem.separator())

    // Window Controls
    let isWinVisible = mainFlutterWindow?.isVisible == true && NSApp.isActive
    let toggleItem = NSMenuItem(
      title: isWinVisible ? "مخفی کردن پنجره" : "نمایش پنجره اصلی برنامه",
      action: #selector(toggleMainWindow),
      keyEquivalent: "o"
    )
    toggleItem.target = self
    toggleItem.attributedTitle = rtlAttr(
      isWinVisible ? "مخفی کردن پنجره" : "نمایش پنجره اصلی برنامه",
      font: AppDelegate.vazirmatnFont(size: 12.0, weight: .regular),
      color: NSColor.labelColor
    )
    menu.addItem(toggleItem)

    let widgetModeItem = NSMenuItem(
      title: isWidgetMode ? "✓ حالت ویجت شناور رومیزی" : "حالت ویجت شناور رومیزی",
      action: #selector(toggleWidgetMode),
      keyEquivalent: "w"
    )
    widgetModeItem.target = self
    widgetModeItem.attributedTitle = rtlAttr(
      isWidgetMode ? "✓ حالت ویجت شناور رومیزی" : "حالت ویجت شناور رومیزی",
      font: AppDelegate.vazirmatnFont(size: 12.0, weight: .regular),
      color: NSColor.labelColor
    )
    menu.addItem(widgetModeItem)

    let pinItem = NSMenuItem(
      title: isAlwaysOnTop ? "✓ شناور ماندن در بالا" : "همیشه در بالاترین لایه (Pin)",
      action: #selector(toggleAlwaysOnTop),
      keyEquivalent: "p"
    )
    pinItem.target = self
    pinItem.attributedTitle = rtlAttr(
      isAlwaysOnTop ? "✓ شناور ماندن در بالا" : "همیشه در بالاترین لایه (Pin)",
      font: AppDelegate.vazirmatnFont(size: 12.0, weight: .regular),
      color: NSColor.labelColor
    )
    menu.addItem(pinItem)

    menu.addItem(NSMenuItem.separator())

    // Quit Item
    let quitItem = NSMenuItem(
      title: "خروج از اذکار من",
      action: #selector(quitApp),
      keyEquivalent: "q"
    )
    quitItem.target = self
    quitItem.attributedTitle = rtlAttr(
      "خروج از اذکار من",
      font: AppDelegate.vazirmatnFont(size: 12.0, weight: .regular),
      color: NSColor.systemRed
    )
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

// MARK: - Custom RTL Prayer Row View for macOS Menu (Vector SF Symbols)
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
      ? AppDelegate.vazirmatnFont(size: 13.0, weight: .bold)
      : AppDelegate.vazirmatnFont(size: 12.5, weight: .medium)

    // 1. Right side: SF Symbol vector icon + Prayer Name (RTL)
    let iconSize: CGFloat = 14.0
    let iconX = bounds.width - 24.0
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

    // Name text next to icon
    let rightText = isNext ? "\(name)  ●" : name
    let rightPara = NSMutableParagraphStyle()
    rightPara.alignment = .right
    rightPara.baseWritingDirection = .rightToLeft

    let rightAttr: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: textColor,
      .paragraphStyle: rightPara
    ]
    let textWidth = iconX - 8.0 - 70.0
    let rightRect = NSRect(x: 70, y: (bounds.height - 18) / 2, width: textWidth, height: 18)
    (rightText as NSString).draw(in: rightRect, withAttributes: rightAttr)

    // 2. Left side: Prayer Time in Persian digits (Left-aligned)
    let leftPara = NSMutableParagraphStyle()
    leftPara.alignment = .left
    let leftAttr: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: isHighlighted ? .white : (isNext ? NSColor.systemGreen : (isDark ? NSColor(white: 0.90, alpha: 1.0) : NSColor(white: 0.20, alpha: 1.0))),
      .paragraphStyle: leftPara
    ]
    let leftRect = NSRect(x: 12, y: (bounds.height - 18) / 2, width: 60, height: 18)
    (time as NSString).draw(in: leftRect, withAttributes: leftAttr)
  }
}

