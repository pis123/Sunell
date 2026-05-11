//
//  ViewController.swift
//  SunellSDKDemo
//
//  Created by Sunell on 2026/3/17.
//

import UIKit
import SunellSDK

class ViewController: UIViewController {

    private var devices: [SunellDeviceModel] = []
    private var deviceListObserver: NSObjectProtocol?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tv.rowHeight = 60
        tv.tableFooterView = UIView()
        tv.dataSource = self
        tv.delegate = self
        tv.register(DeviceListCell.self, forCellReuseIdentifier: DeviceListCell.reuseIdentifier)
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupAddDeviceButton()
        setupTableView()
        deviceListObserver = NotificationCenter.default.addObserver(
            forName: DeviceManager.deviceListDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadDeviceListFromManager()
        }
        reloadDeviceListFromManager()
    }

    deinit {
        if let deviceListObserver {
            NotificationCenter.default.removeObserver(deviceListObserver)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDeviceListFromManager()
    }

    private func reloadDeviceListFromManager() {
        devices = DeviceManager.shared.allDevices()
        tableView.reloadData()
    }

    private static func displayName(for device: SunellDeviceModel) -> String {
        let name = device.deviceName
        if !name.isEmpty { return name }
        let uuid = device.deviceUUID
        if !uuid.isEmpty { return uuid }
        let sn = device.deviceSN
        if !sn.isEmpty { return sn }
        let id = device.deviceId
        if !id.isEmpty { return id }
        return TKLocalizedString("TK_DeviceUntitled")
    }

    private static func channelCount(for device: SunellDeviceModel) -> Int {
        let fromField = Int(device.chnNum)
        if fromField > 0 {
            return fromField
        }
        if let arr = device.channels as? [SunellChannelModel] {
            return arr.count
        }
        if let ns = device.channels as? NSArray {
            return ns.count
        }
        return 0
    }

    private func setupNavigationBar() {
        title = TKLocalizedString("TK_AppTitle")
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.backgroundColor = .white
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupAddDeviceButton() {
        let title = TKLocalizedString("TK_AddDevice")
        let localTitle = TKLocalizedString("TK_LocalDevice")
        let p2pTitle = TKLocalizedString("TK_P2PDevice")

        if #available(iOS 14.0, *) {
            let localAction = UIAction(title: localTitle) { [weak self] _ in
                self?.openLocalDevice()
            }
            let p2pAction = UIAction(title: p2pTitle) { [weak self] _ in
                self?.openP2PDevice()
            }
            let menu = UIMenu(children: [localAction, p2pAction])
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: title,
                image: nil,
                primaryAction: nil,
                menu: menu
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: title,
                style: .plain,
                target: self,
                action: #selector(showAddDeviceActionSheet)
            )
        }
    }

    @objc private func showAddDeviceActionSheet() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: TKLocalizedString("TK_LocalDevice"), style: .default) { [weak self] _ in
            self?.openLocalDevice()
        })
        sheet.addAction(UIAlertAction(title: TKLocalizedString("TK_P2PDevice"), style: .default) { [weak self] _ in
            self?.openP2PDevice()
        })
        sheet.addAction(UIAlertAction(title: TKLocalizedString("TK_Cancel"), style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func openLocalDevice() {
        let localDevicePage = LocalDevicePage()
        navigationController?.pushViewController(localDevicePage, animated: true)
    }

    private func openP2PDevice() {
        let p2pDevicePage = P2PDevicePage()
        navigationController?.pushViewController(p2pDevicePage, animated: true)
    }

    func TestSDK() {
        // SDK debug hook.
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceListCell.reuseIdentifier, for: indexPath) as! DeviceListCell
        let device = devices[indexPath.row]
        cell.configure(
            name: Self.displayName(for: device),
            channelCount: Self.channelCount(for: device),
            isOnline: device.status.rawValue == 1
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = devices[indexPath.row]
        let playPage = PlayPage(device: device)
        navigationController?.pushViewController(playPage, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let device = devices[indexPath.row]
        let uuid = device.deviceUUID
        // Disconnect (SDK session).
        SunellSDKEntry.disConnectDev(deviceId: device.deviceId)
        let delete = UIContextualAction(style: .destructive, title: TKLocalizedString("TK_Delete")) { _, _, done in
            if !uuid.isEmpty {
                DeviceManager.shared.removeDevice(deviceUUID: uuid)
            } else {
                DeviceManager.shared.removeDevice(device)
            }
            done(true)
        }
        
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - DeviceListCell

private final class DeviceListCell: UITableViewCell {
    static let reuseIdentifier = "DeviceListCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .label
        return l
    }()

    private let channelLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private let textStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 2
        s.alignment = .leading
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.addSubview(textStack)
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(channelLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(chevronView)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),

            chevronView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, channelCount: Int, isOnline: Bool) {
        nameLabel.text = name
        channelLabel.text = String(format: TKLocalizedString("TK_ChannelCountFormat"), channelCount)
        if isOnline {
            statusLabel.text = TKLocalizedString("TK_DeviceOnline")
            statusLabel.textColor = .systemBlue
        } else {
            statusLabel.text = TKLocalizedString("TK_DeviceOffline")
            statusLabel.textColor = .secondaryLabel
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        channelLabel.text = nil
        statusLabel.text = nil
    }
}
