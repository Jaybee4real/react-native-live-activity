import ActivityKit
import Foundation
import React

@objc(RNLiveActivity)
class RNLiveActivity: NSObject {

  @objc static func requiresMainQueueSetup() -> Bool { false }

  private static var activities: [String: Any] = [:]

  @objc(start:resolver:rejecter:)
  func start(_ options: NSDictionary,
             resolver resolve: @escaping RCTPromiseResolveBlock,
             rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else {
      reject("unsupported", "Live Activities require iOS 16.2+", nil); return
    }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      reject("disabled", "Live Activities are disabled in Settings", nil); return
    }
    let id = options["id"] as? String ?? "live"
    let title = options["title"] as? String ?? ""
    let stages = options["stages"] as? [String] ?? []
    let stageIndex = options["currentStage"] as? Int ?? 0
    let statusLine = options["statusLine"] as? String ?? ""
    let accentColorHex = options["accentColorHex"] as? String ?? ""
    let iconSystemName = options["iconSystemName"] as? String ?? ""
    let backgroundColorHex = options["backgroundColorHex"] as? String ?? ""

    let attributes = LiveActivityAttributes(
      title: title,
      stageLabels: stages,
      accentColorHex: accentColorHex,
      iconSystemName: iconSystemName,
      backgroundColorHex: backgroundColorHex
    )
    let state = LiveActivityAttributes.ContentState(stageIndex: stageIndex, statusLine: statusLine)
    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil)
      )
      RNLiveActivity.activities[id] = activity
      resolve(activity.id)
    } catch {
      reject("start_failed", error.localizedDescription, error)
    }
  }

  @objc(update:resolver:rejecter:)
  func update(_ options: NSDictionary,
              resolver resolve: @escaping RCTPromiseResolveBlock,
              rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { resolve(nil); return }
    let id = options["id"] as? String ?? "live"
    let stageIndex = options["currentStage"] as? Int ?? 0
    let statusLine = options["statusLine"] as? String ?? ""
    let state = LiveActivityAttributes.ContentState(stageIndex: stageIndex, statusLine: statusLine)

    // Prefer the tracked handle; fall back to any live activity of this type so
    // a cold-started process (push-driven update) can still target it.
    let tracked = RNLiveActivity.activities[id] as? Activity<LiveActivityAttributes>
    let activity = tracked ?? Activity<LiveActivityAttributes>.activities.first { $0.id == id }
      ?? Activity<LiveActivityAttributes>.activities.first
    guard let activity = activity else { resolve(nil); return }
    RNLiveActivity.activities[id] = activity
    Task {
      await activity.update(.init(state: state, staleDate: nil))
      resolve(nil)
    }
  }

  @objc(end:resolver:rejecter:)
  func end(_ options: NSDictionary,
           resolver resolve: @escaping RCTPromiseResolveBlock,
           rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { resolve(nil); return }
    let id = options["id"] as? String ?? "live"
    let tracked = RNLiveActivity.activities[id] as? Activity<LiveActivityAttributes>
    let activity = tracked ?? Activity<LiveActivityAttributes>.activities.first { $0.id == id }
    guard let activity = activity else { resolve(nil); return }
    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
      RNLiveActivity.activities[id] = nil
      resolve(nil)
    }
  }
}
