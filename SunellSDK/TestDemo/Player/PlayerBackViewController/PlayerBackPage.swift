//
//  PlayerBackPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK

/// Playback placeholder; connect playback APIs later.
final class PlayerBackPage: UIViewController {

    private let device: SunellDeviceModel

    init(device: SunellDeviceModel) {
        self.device = device
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = TKLocalizedString("TK_Playback")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .black
        view.accessibilityIdentifier = device.deviceId
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
