//
//  P2PScanResultPage.swift
//  SunellSDKDemo
//
//  Created by Sunell on 2026/3/19.
//

import UIKit
import SunellSDK
struct P2PScanResult {
    let qrCode: String
}

class P2PScanResultPage: UIViewController {

    private let rowHeight: CGFloat = 50
    private let horizontalMargin: CGFloat = 16

    private let scanResult: P2PScanResult

    private let defaultPort = 30001
    private let defaultUserName = "admin"
    private let defaultPassword = "aaa111"
    
    
    private lazy var qrCodeTextField = createTextField(placeholder: TKLocalizedString("TK_QRCodePlaceholder"))
    private lazy var portTextField: UITextField = {
        let tf = createTextField(placeholder: TKLocalizedString("TK_PortPlaceholder"))
        tf.keyboardType = .numberPad
        return tf
    }()
    private lazy var usernameTextField = createTextField(placeholder: TKLocalizedString("TK_UsernamePlaceholder"))
    private lazy var passwordTextField: UITextField = {
        let tf = createTextField(placeholder: TKLocalizedString("TK_PasswordPlaceholder"))
        // tf.isSecureTextEntry = true
        return tf
    }()

    init(scanResult: P2PScanResult) {
        self.scanResult = scanResult
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupContent()
        setupValues()
        setupDefaultValues()
    }

    private func setupDefaultValues() {
        portTextField.text = "\(defaultPort)"
        usernameTextField.text = defaultUserName
        passwordTextField.text = defaultPassword
    }

    private func setupValues() {
        qrCodeTextField.text = scanResult.qrCode
        // Port, user, password are entered manually (not prefilled).
    }

    private func setupNavigationBar() {
        title = TKLocalizedString("TK_P2PDevice")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: TKLocalizedString("TK_Save"), style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationController?.navigationBar.tintColor = .black
    }

    private func setupContent() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(createInputRow(title: TKLocalizedString("TK_QRCode"), textField: qrCodeTextField))
        stackView.addArrangedSubview(createInputRow(title: TKLocalizedString("TK_Port"), textField: portTextField))
        stackView.addArrangedSubview(createInputRow(title: TKLocalizedString("TK_Username"), textField: usernameTextField))
        stackView.addArrangedSubview(createInputRow(title: TKLocalizedString("TK_Password"), textField: passwordTextField))

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func createInputRow(title: String, textField: UITextField) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        container.addSubview(textField)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: rowHeight),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalMargin),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontalMargin),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 16),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 230)
        ])

        return container
    }

    private func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .black
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveButtonTapped() {
        guard (qrCodeTextField.text != nil) else {
            return
        }
        guard (portTextField.text != nil) else {
            return
        }
        guard (usernameTextField.text != nil) else {
            return
        }
        guard (passwordTextField.text != nil) else {
            return
        }
        showLoadingIndicator()
        SunellSDKEntry.connectDevByP2P(
            uuid: qrCodeTextField.text!,
            port: Int(portTextField.text!) ?? 0,
            user: usernameTextField.text!,
            pwd: passwordTextField.text!
        ) { [weak self] result, device in
            DispatchQueue.main.async {
                guard let self else { return }
                self.hideLoadingIndicator()
                print("handle:", device.deviceId, device.chnNum, result, Thread.current, Date())
                if result >= 1000 {
                    DeviceManager.shared.addDevice(device)
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.showConnectionFailedToast()
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingOverlay: UIView?

    private func showLoadingIndicator() {
        guard loadingOverlay == nil else { return }
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlay.isUserInteractionEnabled = true

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.hidesWhenStopped = false

        overlay.addSubview(spinner)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        spinner.startAnimating()
        loadingOverlay = overlay
        view.isUserInteractionEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
    }

    private func hideLoadingIndicator() {
        loadingOverlay?.removeFromSuperview()
        loadingOverlay = nil
        view.isUserInteractionEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = true
    }

    // MARK: - Toast

    private func showConnectionFailedToast() {
        let text = TKLocalizedString("TK_P2PConnectFailed")
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 0.15, alpha: 0.92)
        container.layer.cornerRadius = 10
        container.clipsToBounds = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0

        container.addSubview(label)
        view.addSubview(container)

        let padding: CGFloat = 14
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            container.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -56),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding)
        ])

        container.alpha = 0
        UIView.animate(withDuration: 0.2) {
            container.alpha = 1
        }

        UIView.animate(withDuration: 0.25, delay: 2.0, options: []) {
            container.alpha = 0
        } completion: { _ in
            container.removeFromSuperview()
        }
    }
}
