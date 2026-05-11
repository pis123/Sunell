//
//  SunellSDK.swift
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//  API overview: see SunellSDKSwiftAPI.md in this folder.
//

import Foundation
import UIKit

/// 回放播放倍速（Swift 对外 API，映射底层 `SunellSpeedType`）。
public enum SunellPlaybackSpeed: Int, CaseIterable {
    /// 1×
    case x1 = 1
    /// 2×
    case x2 = 2
}
public enum SunellDeviceChannelStatus: Int,CaseIterable {
    case unkonw = 0
    case online = 1
    case offline = 2
}

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
        
        /// Chanel Status Change
        func sunellSDKChannelStatusChange(_ channelModel: SunellChannelModel)
        
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
        @objc func sunellSDKChannelStatusChangeNoti(with channelModel: SunellChannelModel) {
            target?.sunellSDKChannelStatusChange(channelModel)
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
    public static func liveStart(deviceId:String,channelId:Int,streamType:Int,isHw:Bool,caLayer:CAEAGLLayer,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.liveStart(withDevice: deviceId, channelId: Int32(channelId), streamType: Int32(streamType), isHwDec: isHw, layer: caLayer) { result in
            resultBlock(Int(result))
        }
    }
    public static func liveStop(deviceId:String,channelId:Int,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.liveStop(withDevice: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func captureImageWithDeviceId(deviceId:String,channelId:Int,path:String,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.captureImage(withDeviceId: deviceId, channelId: Int32(channelId), path: path) { result in
            resultBlock(Int(result))
        }
    };
    public static func audioSwitchWithDeviceId(deviceId:String,channelId:Int,isOpen:Bool,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.audioSwitch(withDeviceId: deviceId, channelId: Int32(channelId), isOpen: isOpen) { result in
            resultBlock(Int(result))
        }
    }
    public static func talkSwitchWithDeviceId(deviceId:String,channelId:Int,isOpen:Bool,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.talkSwitch(withDeviceId: deviceId, channelId: Int32(channelId), isOpen: isOpen) { result in
            resultBlock(Int(result))
        }
    }
    public static func qualityAdjustmentWithDeviceId(deviceId:String,channelId:Int,qualityType:Int,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.qualityAdjustment(withDeviceId: deviceId, channelId: Int32(channelId), type: Int32(qualityType)) { result in
            resultBlock(Int(result))
        }
    }
    public static func getDeviceCapacityWithDeviceId(deviceId:String,channelId:Int,resultBlock:@escaping(Int,SunellChannelModel?) -> Void){
        SunellSDKManager.getDeviceCapacity(withDeviceId: deviceId, channelId: Int32(channelId)) { result, channelModel in
            resultBlock(Int(result),channelModel ?? nil)
        }
    }
    public static func openPTZWithDeivceId(deviceId:String,channelId:Int,resultBlock:@escaping(Int) -> Void) {
        SunellSDKManager.openPTZ(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func closePTZWithDeviceId(deviceId:String,channelId:Int,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.closePTZ(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func operationPTZWithDeviceId(deviceId:String,channelId:Int,arrowType:Int,resultBlock:@escaping(Int) -> Void) {
        SunellSDKManager.operationPTZ(withDeviceId: deviceId, channelId: Int32(channelId), arrowType: Int32(arrowType)) { result in
            resultBlock(Int(result))
        }
    }
    public static func stopPTZWithDeviceId(deviceId:String,channelId:Int,resultBlock:@escaping(Int) -> Void) {
        SunellSDKManager.stopPTZ(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func getWhiteLightAbilityWithDeviceId(deviceId:String,channelId:Int,resultBlock:@escaping(Int,String?) -> Void){
        SunellSDKManager.getWhiteLightAbility(withDeviceId: deviceId, channelId: Int32(channelId)) { result, jsonStr in
            resultBlock(Int(result),jsonStr)
        }
    }
    public static func getWhiteLightSwitchParamWithDeviceId(deviceId: String, channelId: Int, resultBlock: @escaping (Int, String?) -> Void) {
        SunellSDKManager.getWhiteLightSwitchParam(withDeviceId: deviceId, channelId: Int32(channelId)) { result, jsonStr in
            resultBlock(Int(result), jsonStr)
        }
    }
    public static func setWhiteLightSwitchParamWithDeviceId(deviceId: String, channelId: Int, paramJson: String, resultBlock: @escaping (Int) -> Void) {
        SunellSDKManager.applyWhiteLightSwitchParam(withDeviceId: deviceId, channelId: Int32(channelId), paramJson: paramJson) { result in
            resultBlock(Int(result))
        }
    }
    
    public static func getAudioAlarmInfoWithDeviceId(deviceId: String, channelId: Int, resultBlock: @escaping (Int, String?) -> Void) {
        SunellSDKManager.getAudioAlarmInfo(withDeviceId: deviceId, channelId: Int32(channelId)) { result, retJsonStr in
            resultBlock(Int(result),retJsonStr)
        }
    }
    public static func playAudioAlarmWithDeviceId(deviceId: String, channelId: Int,displayId: Int, playNum: Int, resultBlock: @escaping (Int) -> Void) {
        SunellSDKManager.playAudioAlarm(withDeviceId: deviceId, channelId: Int32(channelId), displayId: Int32(displayId), playNum: Int32(playNum)) { result in
            resultBlock(Int(result))
        }
    }
    public static func playBackStartWithDeviceId(deviceId:String,channelId:Int,startTimeStr:String,streamType:Int,isHwDec:Bool,caLayer:CAEAGLLayer,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.playbackStart(withDeviceId: deviceId, channelId: Int32(channelId), startTimeStr: startTimeStr, streamType: Int32(streamType), isHwDec: isHwDec, layer: caLayer) { result in
            resultBlock(Int(result))
        }
    }
    public static func playBackStopWithDeviceId(deviceId: String, channelId: Int, resultBlock: @escaping (Int) -> Void) {
        SunellSDKManager.playBackStop(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func playBackPauseWithDeviceId(deviceId: String, channelId: Int, resultBlock: @escaping (Int) -> Void) {
        SunellSDKManager.playBackPause(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func playBackResumeWithDeviceId(deviceId: String, channelId: Int, resultBlock: @escaping (Int) -> Void) {
        SunellSDKManager.playBackResume(withDeviceId: deviceId, channelId: Int32(channelId)) { result in
            resultBlock(Int(result))
        }
    }
    public static func playBackSeekWithDeviceId(deviceId:String,channelId: Int,timeStr:String,resultBlock:@escaping(Int) -> Void){
        SunellSDKManager.playBackSeek(withDeviceId: deviceId, channelId: Int32(channelId), startTimeStr: timeStr) { result in
            resultBlock(Int(result))
        }
    }
    public static func getPlayBackOneDayRecordListWithDeviceId(deviceId:String,channelId:Int,dayStr:String,resultBlock:@escaping (Int,String) -> Void) {
        SunellSDKManager.getPlayBackOneDayRecordList(withDeviceId: deviceId, channelId: Int32(channelId), dayStr: dayStr) { result, jsonStr in
            resultBlock(Int(result),jsonStr)
        }
    }
    public static func getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId(deviceId:String,channelId:Int,startDateStr:String,endDateStr:String,resultBlock:@escaping(Int,String) -> Void){
        SunellSDKManager.getPlayBackRecordWithinACertainPeriodOfTime(withDeviceId: deviceId, channelId: Int32(channelId), startDateStr: startDateStr, endDateStr: endDateStr) { result, jsonStr in
            resultBlock(Int(result),jsonStr)
        }
    }
    public static func getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId(deviceId:String,channelId:Int,startDayStr:String,endDayStr:String,resultBlock:@escaping(Int,String) -> Void){
        SunellSDKManager.getWhichDaysWithinTheTimePeriodHavePlaybackRecords(withDeviceId: deviceId, channelId: Int32(channelId), startDayStr: startDayStr, endDayStr: endDayStr) { result, retJson in
            resultBlock(Int(result),retJson)
        }
    }
    public static func playBackSetSpeedWithDeviceId(deviceId: String, channelId: Int, speed: SunellPlaybackSpeed, resultBlock: @escaping (Int) -> Void) {
        let speedType = Self.sunellSpeedType(for: speed)
        SunellSDKManager.playBackSetSpeed(withDeviceId: deviceId, channelId: Int32(channelId), speed: speedType) { result in
            resultBlock(Int(result))
        }
    }

    private static func sunellSpeedType(for speed: SunellPlaybackSpeed) -> SunellSpeedType {
        let raw: UInt32 = speed == .x2 ? 1 : 0
        return SunellSpeedType(rawValue: raw) ?? SunellSpeedType(rawValue: 0)
    }
    
//    public static func startDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.startDeviceChannelStatusMonitoring(deviceId)
//    }
//
//    public static func stopDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.stopDeviceChannelStatusMonitoring(deviceId)
//    }
//
    public static func startDeviceChannelAlarmMonitoring(deviceId: String) {
        SunellSDKManager.startDeviceChannelStatusMonitoring(deviceId)
    }

    public static func stopDeviceChannelAlarmMonitoring(deviceId: String) {
        SunellSDKManager.stopDeviceChannelStatusMonitoring(deviceId)
    }
    public static func closeGL(){
        SunellSDKManager.closeGL()
    }
}
