import ActivityKit
import SwiftUI
import WidgetKit

// The Live Activity UI. Theme it from JS with the `theme` option
// (accent / icon / background), or edit the fallbacks below and this layout
// directly for full control. `context.attributes` holds static data (title,
// stageLabels, theme); `context.state` holds live data (stageIndex, statusLine).
// Add this file to the widget extension target ONLY.

// Fallbacks used when JS doesn't pass a theme.
private let defaultAccent = Color(red: 0.02, green: 0.11, blue: 0.5)
private let defaultGlyph = "circle.grid.2x2.fill"

private func accentColor(_ attributes: LiveActivityAttributes) -> Color {
  Color(hex: attributes.accentColorHex) ?? defaultAccent
}

// Defaults to a near-black card (premium look with accent details). Pass
// `theme.background` to override — e.g. set it equal to the accent for a
// full-color background instead.
private let defaultBackground = Color(red: 0.05, green: 0.05, blue: 0.07)

private func backgroundColor(_ attributes: LiveActivityAttributes) -> Color {
  Color(hex: attributes.backgroundColorHex) ?? defaultBackground
}

private func glyphName(_ attributes: LiveActivityAttributes) -> String {
  attributes.iconSystemName.isEmpty ? defaultGlyph : attributes.iconSystemName
}

extension Color {
  // Parse "#RRGGBB" / "RRGGBB" / "#RRGGBBAA". Returns nil for empty/invalid.
  init?(hex: String) {
    let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
    guard cleaned.count == 6 || cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else {
      return nil
    }
    let hasAlpha = cleaned.count == 8
    let red = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
    let green = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
    let blue = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
    let alpha = hasAlpha ? Double(value & 0xFF) / 255 : 1
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }
}

@available(iOS 16.2, *)
struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      LockScreenLiveView(context: context)
        .padding(16)
        .activityBackgroundTint(backgroundColor(context.attributes))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let total = context.attributes.stageLabels.count
      let step = context.state.stageIndex + 1
      let accent = accentColor(context.attributes)
      let glyph = glyphName(context.attributes)
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
    let glyph = glyphName(context.attributes)
    let accent = accentColor(context.attributes)
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: glyph).foregroundColor(accent)
        Text(context.attributes.title).font(.headline).foregroundColor(.white)
        Spacer()
        Text("Step \(step) of \(total)").font(.caption).foregroundColor(.white.opacity(0.7))
      }
      ProgressView(value: Double(step), total: Double(max(total, 1))).tint(accent)
      ForEach(Array(context.attributes.stageLabels.enumerated()), id: \.offset) { index, label in
        HStack(spacing: 6) {
          Image(systemName: index < context.state.stageIndex
            ? "checkmark.circle.fill"
            : (index == context.state.stageIndex ? "circle.fill" : "circle"))
            .foregroundColor(index <= context.state.stageIndex ? accent : .white.opacity(0.4))
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
