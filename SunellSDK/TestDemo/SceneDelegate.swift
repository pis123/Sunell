//
//  SceneDelegate.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/23.
//

import UIKit
import SunellSDK
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        SunellSDKEntry.delegate = self
   
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        NotificationCenter.default.post(name: .sunellSceneDidBecomeActiveResumeVideo, object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        // 进入 inactive/即将后台时先停 GPU 预览，避免 kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted
        NotificationCenter.default.post(name: .sunellSceneWillResignActivePauseVideo, object: nil)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
     

}

extension SceneDelegate: SunellSDKEntry.Delegate {
    func sunellSDKChannelStatusChange(_ channelModel: SunellChannelModel) {
        print("device Id:\(channelModel.deviceId),channelId:\(channelModel.channelId),channelName:\(channelModel.channleName),status:\(channelModel.status)")
    }
    
    func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel, _ type: Int32) {
        print(deviceModel.deviceId,type)
        print("SceneDelegate sunellSDKDeviceErrorStatus:",type)
    }
    
    func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel) {
        print(deviceModel.status)
        // Update sandbox and current device online state.
        print("SceneDelegate sunellSDKStartAutoReconnect:",deviceModel.status)
        // Device went offline; reconnect in progress.
        DeviceManager.shared.addDevice(deviceModel)
        NotificationCenter.default.post(
            name: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            userInfo: [
                "deviceId": deviceModel.deviceId,
                "status": deviceModel.status
            ]
        )
    }
    
    func sunellSDKEndAutoReconnect(_ deviceModel: SunellDeviceModel, _ isSuccess: Bool) {
        print(deviceModel.deviceId,isSuccess)
        // Update sandbox and current device online state.
        print(deviceModel.status)
        print("SceneDelegate sunellSDKEndAutoReconnect:",deviceModel.status)
        if(isSuccess){
            // Back online.
            DeviceManager.shared.addDevice(deviceModel)
            NotificationCenter.default.post(
                name: .sunellDeviceAutoReconnectStatusDidChange,
                object: nil,
                userInfo: [
                    "deviceId": deviceModel.deviceId,
                    "status": deviceModel.status,
                ]
            )
        }
        
    }
    
    func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String) {
        // Not implemented.
    }
    
    func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int) {
        var dict = [String: Any]()
        dict["deviceId"] = deviceId;
        dict["channelId"] = channelId;
        dict["eventId"] = eventId;
        dict["playModel"] = playModel;
        dict["msg"] = msg;
        NotificationCenter.default.post(name: Notification.Name("sunellSDKVideoOperation"), object: dict)
    }
    
  
    
    
    
}

extension Notification.Name {
    /// Auto-reconnect phase updates: `userInfo` may include `phase` (`start` / `end`), `deviceId`, `status`, and on `end` optionally `success`.
    static let sunellDeviceAutoReconnectStatusDidChange = Notification.Name("sunellDeviceAutoReconnectStatusDidChange")
    /// Scene 将离开前台（来电遮罩、切后台前兆）：应停止预览/GPU。
    static let sunellSceneWillResignActivePauseVideo = Notification.Name("sunellSceneWillResignActivePauseVideo")
    /// Scene 已回到 active：可恢复预览。
    static let sunellSceneDidBecomeActiveResumeVideo = Notification.Name("sunellSceneDidBecomeActiveResumeVideo")
}
