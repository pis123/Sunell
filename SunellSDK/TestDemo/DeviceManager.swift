//
//  DeviceManager.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import Foundation
import SunellSDK

/// In-memory device list with Application Support JSON persistence; restored on next launch.
final class DeviceManager: NSObject {

    static let shared = DeviceManager()

    private let ioQueue = DispatchQueue(label: "com.sunell.testdemo.devicemanager", qos: .utility)
    /// Serial reconnect queue (background) to avoid blocking callers.
    private static let connectQueue = DispatchQueue(label: "com.sunell.testdemo.devicemanager.connect", qos: .utility)
    private var devices: [SunellDeviceModel] = []

    /// Posted when the device list changes (object is nil).
    static let deviceListDidChangeNotification = Notification.Name("SunellDeviceListDidChange")

    private override init() {
        super.init()
        loadFromDiskSync()
        connectAllDevice()
    }

    /// Reconnect all devices: P2P uses `connectDevByP2P`, otherwise `connectDevByIP` (skipped if user or password empty).
    /// Runs on a background queue.
    func connectAllDevice() {
        let snapshot: [SunellDeviceModel] = ioQueue.sync { Array(devices) }
        Self.connectQueue.async { [weak self] in
            guard let self else { return }
            for device in snapshot {
                if device.isP2PAdd {
                    let uuid = device.deviceUUID
                    guard !uuid.isEmpty else { continue }
                    let port = Int(device.port)
                    let user = device.userName
                    let pwd = device.pwd
                    SunellSDKEntry.connectDevByP2P(uuid: uuid, port: port, user: user, pwd: pwd) { [weak self] _, deviceModel in
                        guard let self else { return }
                        
                        self.applyReconnectedStatus(deviceModel: deviceModel) { $0.deviceUUID == uuid }
                    }
                } else {
                    let user = device.userName
                    let pwd = device.pwd
                    guard !user.isEmpty, !pwd.isEmpty else { continue }
                    let ip = device.deviceIp
                    guard !ip.isEmpty, device.port > 0 else { continue }
                    let uuid = device.deviceUUID
                    let devId = device.deviceId
                    let port = Int(device.port)
                    SunellSDKEntry.connectDevByIP(ip: ip, port: port, user: user, pwd: pwd) { [weak self] _, deviceModel in
                        guard let self else { return }
                        self.applyReconnectedStatus(deviceModel: deviceModel) { d in
                            if !uuid.isEmpty { return d.deviceUUID == uuid }
                            if !devId.isEmpty { return d.deviceId == devId }
                            return d.deviceIp == ip && d.port == device.port
                        }
                    }
                }
            }
        }
    }

    /// Merge reconnect callback status into the matching device (`matches` finds the row).
    private func applyReconnectedStatus(deviceModel: SunellDeviceModel, matches: @escaping (SunellDeviceModel) -> Bool) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let idx = self.devices.firstIndex(where: matches) else { return }
            let stored = self.devices[idx]
            // deviceId may change per session; treat as session id, not immutable hardware id.
            stored.deviceId = deviceModel.deviceId;
            guard stored.status != deviceModel.status else { return }
            stored.status = deviceModel.status
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    // MARK: - Public API

    /// Snapshot of all devices (order matches persistence).
    func allDevices() -> [SunellDeviceModel] {
        ioQueue.sync { Array(devices) }
    }

    /// Add or replace device with the same `deviceUUID`.
    func addDevice(_ device: SunellDeviceModel) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let uuid = device.deviceUUID
            if let idx = self.devices.firstIndex(where: { ($0.deviceUUID) == uuid && !uuid.isEmpty }) {
                self.devices[idx] = device
            } else {
                self.devices.append(device)
            }
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// Remove by device UUID.
    func removeDevice(deviceUUID: String) {
        let key = deviceUUID
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.devices.removeAll { ($0.deviceUUID) == key }
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// Remove by matching UUID.
    func removeDevice(_ device: SunellDeviceModel) {
        removeDevice(deviceUUID: device.deviceUUID)
    }

    /// Clear list and persist.
    func removeAllDevices() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.devices.removeAll()
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// Reload from disk (usually unnecessary; loaded at init).
    func reloadFromDisk() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.loadFromDiskSync()
            self.postChangeOnMain()
        }
    }

    // MARK: - Sandbox paths

    private var cacheDirectoryURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("SunellDeviceCache", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var devicesFileURL: URL {
        cacheDirectoryURL.appendingPathComponent("devices.json", isDirectory: false)
    }

    // MARK: - Persistence

    private struct DevicesFileDTO: Codable {
        var devices: [DeviceCacheDTO]
    }

    private struct DeviceCacheDTO: Codable {
        var deviceUUID: String
        var deviceName: String
        /// Legacy JSON without this field decodes as nil; restored as empty string.
        var userName: String?
        var pwd: String?
        var deviceStyle: String
        var deviceIp: String
        var deviceMac: String
        var productModel: String
        var deviceSN: String
        var swInfo: String
        var hwInfo: String
        var deviceId: String
        var devType: Int
        var port: Int
        var chnNum: Int
        var status: Int
        /// Legacy `devices.json` without this field decodes as nil; restored as false.
        var isP2PAdd: Bool?
        var channels: [ChannelCacheDTO]
    }

    private struct ChannelCacheDTO: Codable {
        var channelId: Int
        var deviceId: String
        var status: Int
        var channleName: String
    }

    private func loadFromDiskSync() {
        let url = devicesFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            devices = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(DevicesFileDTO.self, from: data)
            devices = decoded.devices.map { Self.model(from: $0) }
        } catch {
            devices = []
        }
    }

    private func saveToDiskSync() {
        let dto = DevicesFileDTO(devices: devices.map { Self.dto(from: $0) })
        do {
            let data = try JSONEncoder().encode(dto)
            try data.write(to: devicesFileURL, options: [.atomic])
        } catch {
            // Keep in-memory data if write fails.
        }
    }

    private func postChangeOnMain() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.deviceListDidChangeNotification, object: nil)
        }
    }

    // MARK: - Model <-> DTO

    private static func sunellDeviceStatus(fromPersisted raw: Int) -> SunellDeviceStatus {
        if raw == 1 {
            return SunellDeviceStatus_online
        }
        switch raw {
        case SunellDeviceStatus_unknown.rawValue: return SunellDeviceStatus_unknown
        case SunellDeviceStatus_online.rawValue: return SunellDeviceStatus_online
        case SunellDeviceStatus_offline.rawValue: return SunellDeviceStatus_offline
        default: return SunellDeviceStatus_unknown
        }
    }

    private static func dto(from model: SunellDeviceModel) -> DeviceCacheDTO {
        let chs: [ChannelCacheDTO] = channelModels(from: model.channels as Any?).map { ch in
            ChannelCacheDTO(
                channelId: Int(ch.channelId),
                deviceId: ch.deviceId,
                status: ch.status.rawValue,
                channleName: ch.channleName
            )
        }
        return DeviceCacheDTO(
            deviceUUID: model.deviceUUID,
            deviceName: model.deviceName,
            userName: model.userName,
            pwd: model.pwd,
            deviceStyle: model.deviceStyle,
            deviceIp: model.deviceIp,
            deviceMac: model.deviceMac,
            productModel: model.productModel,
            deviceSN: model.deviceSN,
            swInfo: model.swInfo,
            hwInfo: model.hwInfo,
            deviceId: model.deviceId,
            devType: Int(model.devType),
            port: Int(model.port),
            chnNum: Int(model.chnNum),
            status: model.status.rawValue,
            isP2PAdd: model.isP2PAdd,
            channels: chs
        )
    }

    private static func channelModels(from raw: Any?) -> [SunellChannelModel] {
        if let list = raw as? [SunellChannelModel] {
            return list
        }
        if let array = raw as? NSArray {
            var out: [SunellChannelModel] = []
            out.reserveCapacity(array.count)
            for case let ch as SunellChannelModel in array {
                out.append(ch)
            }
            return out
        }
        return []
    }

    private static func model(from dto: DeviceCacheDTO) -> SunellDeviceModel {
        let m = SunellDeviceModel()
        m.deviceUUID = dto.deviceUUID
        m.deviceName = dto.deviceName
        m.userName = dto.userName ?? ""
        m.pwd = dto.pwd ?? ""
        m.deviceStyle = dto.deviceStyle
        m.deviceIp = dto.deviceIp
        m.deviceMac = dto.deviceMac
        m.productModel = dto.productModel
        m.deviceSN = dto.deviceSN
        m.swInfo = dto.swInfo
        m.hwInfo = dto.hwInfo
        m.deviceId = dto.deviceId
        m.devType = Int32(dto.devType)
        m.port = Int32(dto.port)
        m.chnNum = Int32(dto.chnNum)
        // Restored devices start offline; SDK callbacks refresh real status.
        m.status = SunellDeviceStatus_unknown
        m.isP2PAdd = dto.isP2PAdd ?? false
        let channels: [SunellChannelModel] = dto.channels.map { c in
            let ch = SunellChannelModel()
            ch.channelId = Int32(c.channelId)
            ch.deviceId = c.deviceId
            ch.status = Self.sunellDeviceStatus(fromPersisted: c.status)
            ch.channleName = c.channleName
            return ch
        }
        m.channels = channels
        return m
    }
}
