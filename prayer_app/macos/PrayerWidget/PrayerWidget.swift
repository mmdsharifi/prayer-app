import WidgetKit
import SwiftUI

// MARK: - Data Models

struct PrayerTimesData: Codable {
    var title: String
    var nextPrayer: NextPrayerInfo?
    var times: [String: String]?
    var zikr: String?
    var hadith: String?
    var dateString: String?

    struct NextPrayerInfo: Codable {
        var label: String
        var time: String
        var delta: String
    }

    static var preview: PrayerTimesData {
        PrayerTimesData(
            title: "🕌 ظهر ۰۱:۲۴",
            nextPrayer: NextPrayerInfo(label: "اذان ظهر", time: "۱۲:۳۰", delta: "۰۱:۲۴"),
            times: [
                "fajr": "۰۴:۳۰",
                "sunrise": "۰۶:۰۰",
                "dhuhr": "۱۲:۳۰",
                "asr": "۱۶:۰۰",
                "maghrib": "۱۹:۱۵",
                "isha": "۲۰:۴۵"
            ],
            zikr: "سبحان الله و بحمده",
            hadith: "همانا اعمال به نیت‌ها بستگی دارند",
            dateString: "۵ شهریور ۱۴۰۵"
        )
    }
}

// MARK: - Timeline Provider

struct PrayerTimelineEntry: TimelineEntry {
    let date: Date
    let data: PrayerTimesData
}

struct PrayerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimelineEntry {
        PrayerTimelineEntry(date: Date(), data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimelineEntry) -> Void) {
        let entry = PrayerTimelineEntry(date: Date(), data: loadSavedData() ?? .preview)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimelineEntry>) -> Void) {
        let currentData = loadSavedData() ?? .preview
        let currentDate = Date()
        
        // Refresh every 15 minutes or when the app notifies WidgetKit
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let entry = PrayerTimelineEntry(date: currentDate, data: currentData)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadSavedData() -> PrayerTimesData? {
        let userDefaults = UserDefaults(suiteName: "group.com.example.prayerApp") ?? UserDefaults.standard
        guard let data = userDefaults.data(forKey: "prayer_widget_data") else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        
        let title = json["title"] as? String ?? "🕌 اذکار من"
        var nextPrayer: PrayerTimesData.NextPrayerInfo?
        if let np = json["nextPrayer"] as? [String: Any] {
            nextPrayer = PrayerTimesData.NextPrayerInfo(
                label: np["label"] as? String ?? "اذان",
                time: np["time"] as? String ?? "",
                delta: np["delta"] as? String ?? ""
            )
        }
        let times = json["times"] as? [String: String]
        let zikr = json["zikr"] as? String
        let hadith = json["hadith"] as? String
        let dateString = json["date"] as? String ?? "امروز"

        return PrayerTimesData(
            title: title,
            nextPrayer: nextPrayer,
            times: times,
            zikr: zikr,
            hadith: hadith,
            dateString: dateString
        )
    }
}

// MARK: - Views for Widget Families

struct PrayerWidgetSmallView: View {
    let data: PrayerTimesData

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(red: 0.07, green: 0.15, blue: 0.12), Color(red: 0.04, green: 0.08, blue: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("🕌 اذکار من")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                    Spacer()
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 6, height: 6)
                }

                Spacer()

                Text("تا \(data.nextPrayer?.label ?? "اذان")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))

                Text(data.nextPrayer?.delta ?? "۰۰:۰۰")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)

                if let time = data.nextPrayer?.time, !time.isEmpty {
                    HStack(spacing: 4) {
                        Text("ساعت \(time)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
            }
            .padding(12)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

struct PrayerWidgetMediumView: View {
    let data: PrayerTimesData

    private let prayers = [
        ("fajr", "صبح", "🌅"),
        ("sunrise", "طلوع", "☀️"),
        ("dhuhr", "ظهر", "🕛"),
        ("asr", "عصر", "🌤"),
        ("maghrib", "مغرب", "🌇"),
        ("isha", "عشاء", "🌙")
    ]

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(red: 0.07, green: 0.15, blue: 0.12), Color(red: 0.04, green: 0.08, blue: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            HStack(spacing: 14) {
                // Left Column: Next Prayer Hero
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🕌 اذکار من")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                        Spacer()
                    }

                    Spacer()

                    Text("تا \(data.nextPrayer?.label ?? "اذان بعدی")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))

                    Text(data.nextPrayer?.delta ?? "۰۰:۰۰")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)

                    Text("ساعت \(data.nextPrayer?.time ?? "--:--")")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.12)))

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(Color.white.opacity(0.15))

                // Right Column: 6 Prayers Compact List
                VStack(spacing: 3) {
                    ForEach(prayers, id: \.0) { item in
                        let time = data.times?[item.0] ?? "--:--"
                        let isNext = data.nextPrayer?.label.contains(item.1) == true

                        HStack {
                            Text(item.2)
                                .font(.system(size: 10))
                            Text(item.1)
                                .font(.system(size: 11, weight: isNext ? .bold : .medium))
                                .foregroundColor(isNext ? Color(red: 0.95, green: 0.82, blue: 0.45) : .white.opacity(0.85))
                            Spacer()
                            Text(time)
                                .font(.system(size: 11, weight: isNext ? .bold : .regular, design: .monospaced))
                                .foregroundColor(isNext ? Color(red: 0.95, green: 0.82, blue: 0.45) : .white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isNext ? RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)) : nil)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

struct PrayerWidgetLargeView: View {
    let data: PrayerTimesData

    private let prayers = [
        ("fajr", "اذان صبح", "🌅"),
        ("sunrise", "طلوع آفتاب", "☀️"),
        ("dhuhr", "اذان ظهر", "🕛"),
        ("asr", "اذان عصر", "🌤"),
        ("maghrib", "اذان مغرب", "🌇"),
        ("isha", "اذان عشاء", "🌙")
    ]

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(red: 0.07, green: 0.15, blue: 0.12), Color(red: 0.04, green: 0.08, blue: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("🕌 اذکار من")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                    Spacer()
                    Text(data.dateString ?? "امروز")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Next Prayer Banner
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("تا \(data.nextPrayer?.label ?? "اذان بعدی")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text(data.nextPrayer?.delta ?? "۰۰:۰۰")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("زمان اذان")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                        Text(data.nextPrayer?.time ?? "--:--")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))

                // Times Grid (2 Columns)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(prayers, id: \.0) { item in
                        let time = data.times?[item.0] ?? "--:--"
                        let isNext = data.nextPrayer?.label == item.1

                        HStack {
                            Text(item.2)
                            Text(item.1)
                                .font(.system(size: 11, weight: isNext ? .bold : .medium))
                                .foregroundColor(isNext ? Color(red: 0.95, green: 0.82, blue: 0.45) : .white)
                            Spacer()
                            Text(time)
                                .font(.system(size: 11, weight: isNext ? .bold : .regular, design: .monospaced))
                                .foregroundColor(isNext ? Color(red: 0.95, green: 0.82, blue: 0.45) : .white.opacity(0.9))
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isNext ? Color(red: 0.95, green: 0.82, blue: 0.45).opacity(0.2) : Color.white.opacity(0.06)))
                    }
                }

                // Zikr & Hadith Footer
                if let zikr = data.zikr, !zikr.isEmpty {
                    HStack {
                        Text("📿 ذکر:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                        Text(zikr)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(14)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Main Widget Entry View

struct PrayerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PrayerTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PrayerWidgetSmallView(data: entry.data)
        case .systemMedium:
            PrayerWidgetMediumView(data: entry.data)
        case .systemLarge, .systemExtraLarge:
            PrayerWidgetLargeView(data: entry.data)
        @unknown default:
            PrayerWidgetMediumView(data: entry.data)
        }
    }
}

// MARK: - Widget Configuration

@main
struct PrayerWidget: Widget {
    let kind: String = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("اذکار من")
        .description("نمایش اوقات شرعی، شمارش معکوس اذان بعدی و اذکار روزانه.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
