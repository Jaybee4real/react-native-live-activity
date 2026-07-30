import ActivityKit
import SwiftUI
import WidgetKit

// The Live Activity UI. This is YOURS to theme — colors, icons, and layout.
// Everything reads from `context.attributes` (static: title, stageLabels) and
// `context.state` (live: stageIndex, statusLine). Add this file to the widget
// extension target ONLY.

// Brand accent — change to your color.
private let accent = Color(red: 0.02, green: 0.11, blue: 0.5)
private let glyph = "circle.grid.2x2.fill"

@available(iOS 16.2, *)
struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      LockScreenLiveView(context: context)
        .padding(16)
        .activityBackgroundTint(accent)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let total = context.attributes.stageLabels.count
      let step = context.state.stageIndex + 1
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: glyph).foregroundColor(accent)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(step)/\(total)").font(.caption).foregroundColor(.secondary)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            Text(context.attributes.title).font(.caption).bold()
            ProgressView(value: Double(step), total: Double(max(total, 1))).tint(accent)
            Text(context.state.statusLine).font(.caption2).foregroundColor(.secondary)
          }
        }
      } compactLeading: {
        Image(systemName: glyph).foregroundColor(accent)
      } compactTrailing: {
        Text("\(step)/\(total)").font(.caption2)
      } minimal: {
        Image(systemName: glyph).foregroundColor(accent)
      }
    }
  }
}

@available(iOS 16.2, *)
struct LockScreenLiveView: View {
  let context: ActivityViewContext<LiveActivityAttributes>

  var body: some View {
    let total = context.attributes.stageLabels.count
    let step = context.state.stageIndex + 1
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: glyph).foregroundColor(.white)
        Text(context.attributes.title).font(.headline).foregroundColor(.white)
        Spacer()
        Text("Step \(step) of \(total)").font(.caption).foregroundColor(.white.opacity(0.7))
      }
      ProgressView(value: Double(step), total: Double(max(total, 1))).tint(.white)
      ForEach(Array(context.attributes.stageLabels.enumerated()), id: \.offset) { index, label in
        HStack(spacing: 6) {
          Image(systemName: index < context.state.stageIndex
            ? "checkmark.circle.fill"
            : (index == context.state.stageIndex ? "circle.fill" : "circle"))
            .foregroundColor(index <= context.state.stageIndex ? .white : .white.opacity(0.4))
            .font(.caption2)
          Text(label)
            .font(.caption)
            .foregroundColor(index <= context.state.stageIndex ? .white : .white.opacity(0.5))
        }
      }
      if !context.state.statusLine.isEmpty {
        Text(context.state.statusLine).font(.caption2).foregroundColor(.white.opacity(0.85))
      }
    }
  }
}

@available(iOS 16.2, *)
@main
struct LiveActivityBundle: WidgetBundle {
  var body: some Widget {
    LiveActivityWidget()
  }
}
