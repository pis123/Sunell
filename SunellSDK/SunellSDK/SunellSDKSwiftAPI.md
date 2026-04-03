# SunellSDK Swift API Reference

This document describes the Swift-facing API in `SunellSDK.swift` (`SunellSDKEntry`). The module bridges Objective-C types (`SunellSDKManager`, `SunellDeviceModel`) for use from Swift.

**Requirements:** iOS 13+, import `SunellSDK` (or the umbrella module name exposed by your integration).

---

## Overview

| Type | Role |
|------|------|
| `SunellSDKEntry` | Main entry point: static methods for connect/disconnect/live, plus delegate bridging. |
| `SunellSDKEntry.Delegate` | Swift protocol mirroring `SunellSDKManagerDelegate` callbacks. |
| `SunellSDKDelegate` | Typealias for `Delegate` (legacy naming). |

Use **`SunellSDKEntry.delegate`** (static or via `SunellSDKEntry.shared.delegate`) to receive device lifecycle, alarm, and video events.

---

## Delegate

```swift
public protocol Delegate: AnyObject {
    func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel, _ type: Int32)
    func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel)
    func sunellSDKEndAutoReconnect(_ deviceModel: SunellDeviceModel, _ isSuccess: Bool)
    func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String)
    func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int)
}
```

| Callback | When |
|----------|------|
| `sunellSDKDeviceErrorStatus` | Device error/offline notification; `type` follows native SDK disconnect reasons. |
| `sunellSDKStartAutoReconnect` | SDK begins automatic reconnect after an abnormal disconnect. |
| `sunellSDKEndAutoReconnect` | Automatic reconnect finished; `isSuccess` indicates outcome. |
| `sunellSDKAlarmInfo` | Alarm string from device. |
| `sunellSDKVideoOperation` | Video pipeline events (operation feedback). |

**Note:** The internal `DelegateBridge` keeps a strong reference so that `SunellSDKManager.delegate` (weak) still receives events when you assign `SunellSDKEntry.delegate`.

---

## Connection

### `connectDevByP2P(uuid:port:user:pwd:resultBlock:)`

Connects via P2P/NAT mapping using device UUID.

- **Parameters**
  - `uuid`: Device UUID / serial used for P2P resolution.
  - `port`: Port for map/relay (see native P2P flow).
  - `user`, `pwd`: Credentials.
  - `resultBlock`: `(Int, SunellDeviceModel)` — first value is handle/result code (see `SunellSDKManager` docs: typically `>= 1000` success; `-507` / `-508` user/password errors).

### `connectDevByIP(ip:port:user:pwd:resultBlock:)`

Connects directly by IPv4/hostname and port.

- **Parameters**
  - `ip`, `port`, `user`, `pwd`: Same semantics as native `connectDevByIP`.
  - `resultBlock`: Same as P2P.

### `disConnectDev(deviceId:)`

Disconnects the session associated with `deviceId` (the identifier used in your app/SDK cache).

---

## Live preview

### `liveStart(deviceId:channelId:streamType:isHw:caLayer:resultBlcok:)`

Starts live preview on an `CAEAGLLayer`.

| Parameter | Description |
|-----------|-------------|
| `deviceId` | Device id string used when connecting (matches cached model). |
| `channelId` | Default `1` for single-channel devices; for NVR use the target channel id. |
| `streamType` | `1` = high (HD), `2` = sub (smooth). |
| `isHw` | Enable hardware-accelerated decode when supported. |
| `caLayer` | Target `CAEAGLLayer` for rendering. |
| `resultBlcok` | `Int` result from native API; **≥ 0** typically means stream id / success per native contract. |

### `liveStop(deviceId:channelId:resultBlcok:)`

Stops the live session for the given device and channel.

### `closeGL()`

Stops all GL/video consumers across connected devices (global cleanup).

---

## Threading

- Callbacks from `SunellSDKManager` are bridged to your `Delegate` on the appropriate queues as implemented in Objective-C (often main queue for UI-related delegate methods).
- `resultBlock` closures in static methods follow the underlying manager behavior.

---

## Objective-C parity

For full parameter semantics and error codes, see `SunellSDKManager.h` and the bundled headers in `SunellSDK.xcframework`. Swift names use `SunellSDKEntry` to avoid clashing with the module name `SunellSDK`.

---

## Version notes (binary)

When integrating via **Swift Package Manager** with a **binary** `SunellSDK.xcframework`, ensure the slice matches your run destination (device vs simulator). See distribution notes in the repository for simulator architecture support.

## Vendor C headers

Files such as `sdk_def.h` / `sdks.h` under `SunellBaseSDK` may still contain legacy comments or non-UTF8 text from the native SDK. The Swift API surface documented here refers to **`SunellSDK.swift`** and the public Objective-C headers shipped with the framework.
