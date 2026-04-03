//
//  SunellSDK.swift
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//  API overview: see SunellSDKSwiftAPI.md in this folder.
//

import Foundation
import UIKit

@objc(SunellSDK)
@objcMembers


public class SunellSDKEntry: NSObject {

    // MARK: - Delegate bridging (ObjC -> Swift)

    /// Swift-side delegate; receives bridged `SunellSDKManagerDelegate` callbacks.
    public protocol Delegate: AnyObject {
        /// Device online/offline or error state changed.
        func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel,_ type: Int32)
        /// SDK started automatic reconnect after an abnormal disconnect.
        func sunellSDKStartAutoReconnect(_ deviceModel:SunellDeviceModel)
        /// Automatic reconnect finished.
        func sunellSDKEndAutoReconnect(_ deviceModel:SunellDeviceModel,_ isSuccess: Bool)
        /// Alarm payload from device.
        func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String)
        /// Video pipeline / operation feedback.
        func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int)
        
    }

    /// Legacy alias for adopters that already use `SunellSDKDelegate`.
    public typealias SunellSDKDelegate = Delegate

    private final class DelegateBridge: NSObject, SunellSDKManagerDelegate {
        weak var target: Delegate?

        @objc func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel,type: Int32) {
            target?.sunellSDKDeviceErrorStatus(deviceModel,type)
        }
        @objc func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel) {
            target?.sunellSDKStartAutoReconnect(deviceModel)
        }
        @objc func sunellSDKEndtAutoReconnect(_ deviceModel: SunellDeviceModel, isSuccess: Bool) {
            target?.sunellSDKEndAutoReconnect(deviceModel, isSuccess)
        }
        /// Signature must match Objective-C exactly (`NSDictionary *` etc.), or ObjC will not dispatch.
        @objc func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String) {
            target?.sunellSDKAlarmInfo(deviceModel, alarmInfo: alarmInfo)
        }

        @objc func sunellSDKVideoOperation(_ deviceId: String, channelId: Int32, eventId: Int32, msg: String, playModel: Int32) {
            target?.sunellSDKVideoOperation(
                deviceId,
                channelId: Int(channelId),
                eventId: Int(eventId),
                msg: msg,
                playModel: Int(playModel)
            )
        }
    }

    /// Strong bridge object so callbacks survive (`SunellSDKManager.delegate` is weak).
    private static let delegateBridge = DelegateBridge()

    /// Preferred: `SunellSDKEntry.delegate = ...` (static) or `SunellSDKEntry.shared.delegate = ...` (instance).
    public static weak var delegate: Delegate? {
        didSet {
            delegateBridge.target = delegate
            SunellSDKManager.shared().delegate = delegateBridge
        }
    }

    /// Instance-style access: `SunellSDKEntry.shared.delegate = ...`
    public var delegate: Delegate? {
        get { Self.delegate }
        set { Self.delegate = newValue }
    }

    public static let shared = SunellSDKEntry()

    private override init() { super.init() }
    
    public static func connectDevByP2P(uuid:String,port:Int,user:String,pwd:String,resultBlock:@escaping(Int,SunellDeviceModel) -> Void){
        SunellSDKManager.connectDev(byP2P: uuid, port: Int32(port), user: user, pwd: pwd) { handle,device in
             resultBlock(Int(handle),device)
        }
    }
    public static func connectDevByIP(ip:String,port:Int,user:String,pwd:String,resultBlock:@escaping(Int,SunellDeviceModel) -> Void){
        SunellSDKManager.connectDev(byIP: ip, port: Int32(port), user: user, pwd: pwd) { handle, device in
            resultBlock(Int(handle),device)
        }
    }
    public static func disConnectDev(deviceId:String) -> Void {
        SunellSDKManager.disConnectDev(byDeviceId: deviceId)
    }
    /**
     * - channelId: defaults to 1; for NVR use the target channel id.
     * - streamType: 1 = HD, 2 = sub stream.
     * - isHw: enable hardware decoding when supported.
     */
    public static func liveStart(deviceId:String,channelId:Int,streamType:Int,isHw:Bool,caLayer:CAEAGLLayer,resultBlcok:@escaping(Int) -> Void){
        SunellSDKManager.liveStart(withDevice: deviceId, channelId: Int32(channelId), streamType: Int32(streamType), isHwDec: isHw, layer: caLayer) { result in
            resultBlcok(Int(result))
        }
    }
    public static func liveStop(deviceId:String,channelId:Int,resultBlcok:@escaping(Int) -> Void){
        SunellSDKManager.liveStop(withDevice: deviceId, channelId: Int32(channelId)) { result in
            resultBlcok(Int(result))
        }
    }

//    public static func startDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.startDeviceChannelStatusMonitoring(deviceId)
//    }
//
//    public static func stopDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.stopDeviceChannelStatusMonitoring(deviceId)
//    }
//
//    public static func startDeviceChannelAlarmMonitoring(deviceId: String) {
//        SunellSDKManager.startDeviceChannelAlarmMonitoring(deviceId)
//    }
//
//    public static func stopDeviceChannelAlarmMonitoring(deviceId: String) {
//        SunellSDKManager.stopDeviceChannelAlarmMonitoring(deviceId)
//    }
    public static func closeGL(){
        SunellSDKManager.closeGL()
    }
}
