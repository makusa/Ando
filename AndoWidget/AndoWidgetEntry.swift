//  AndoWidgetEntry.swift — Timeline entry and providers shared by the widgets
import WidgetKit
import Foundation
import AppIntents

struct AndoEntry: TimelineEntry {
    let date: Date
    let data: AndoWidgetData
    var content: WidgetContentType = .netWorth
}

// Static provider — used by the Accessory and Room widgets (no configuration).
struct AndoProvider: TimelineProvider {
    func placeholder(in context: Context) -> AndoEntry {
        AndoEntry(date: .now, data: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (AndoEntry) -> Void) {
        completion(AndoEntry(date: .now, data: .load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AndoEntry>) -> Void) {
        let entry    = AndoEntry(date: .now, data: .load())
        let nextDate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextDate)))
    }
}

// Configurable provider — used by the Balance widget (content selector intent).
struct AndoConfigProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AndoEntry {
        AndoEntry(date: .now, data: .placeholder, content: .netWorth)
    }
    func snapshot(for configuration: SelectContentIntent, in context: Context) async -> AndoEntry {
        AndoEntry(date: .now, data: .load(), content: configuration.content)
    }
    func timeline(for configuration: SelectContentIntent, in context: Context) async -> Timeline<AndoEntry> {
        let entry    = AndoEntry(date: .now, data: .load(), content: configuration.content)
        let nextDate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextDate))
    }
}
