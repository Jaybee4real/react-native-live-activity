import ActivityKit
import Foundation

// SHARED CONTRACT — add this one file to BOTH targets (app + widget extension).
// The JS bridge (app target) starts/updates the activity; the widget extension
// renders it. Do not rename the type or its fields — the native module in
// @novacraft-engineering/react-native-live-activity references them by name.
struct LiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var stageIndex: Int
    var statusLine: String
  }

  var title: String
  var stageLabels: [String]

  // Theme — set from JS at start(). Empty strings mean "use the widget default".
  var accentColorHex: String = ""
  var iconSystemName: String = ""
  var backgroundColorHex: String = ""
}
