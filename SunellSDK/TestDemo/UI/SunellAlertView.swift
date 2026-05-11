//
//  SunellAlertView.swift
//  TestDemo
//
//  Created by Sunell on 2026/4/24.
//

import UIKit

final class SunellAlertView: UIView {

    typealias Action = () -> Void

    // MARK: - Public

    @discardableResult
    static func show(
        title: String,
        message: String,
        confirmTitle: String = TKLocalizedString("TK_Confirm"),
        cancelTitle: String = TKLocalizedString("TK_Cancel"),
        onConfirm: Action? = nil,
        onCancel: Action? = nil
    ) -> SunellAlertView? {
        guard let window = Self.currentKeyWindow() else { return nil }
        let alert = SunellAlertView(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        window.addSubview(alert)
        NSLayoutConstraint.activate([
            alert.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            alert.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            alert.topAnchor.constraint(equalTo: window.topAnchor),
            alert.bottomAnchor.constraint(equalTo: window.bottomAnchor),
        ])
        alert.presentAnimated()
        return alert
    }

    // MARK: - Private

    private let onConfirm: Action?
    private let onCancel: Action?

    private let dimView: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return v
    }()

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor.black.withAlphaComponent(0.78)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        return b
    }()

    private let buttonSeparator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        return v
    }()

    private let horizontalSeparator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        return v
    }()

    private init(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String,
        onConfirm: Action?,
        onCancel: Action?
    ) {
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        messageLabel.text = message
        confirmButton.setTitle(confirmTitle, for: .normal)
        cancelButton.setTitle(cancelTitle, for: .normal)

        dimView.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        addSubview(dimView)
        addSubview(containerView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(horizontalSeparator)
        containerView.addSubview(cancelButton)
        containerView.addSubview(buttonSeparator)
        containerView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            horizontalSeparator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            horizontalSeparator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            horizontalSeparator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            cancelButton.topAnchor.constraint(equalTo: horizontalSeparator.bottomAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            buttonSeparator.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor),
            buttonSeparator.topAnchor.constraint(equalTo: horizontalSeparator.bottomAnchor),
            buttonSeparator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buttonSeparator.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            confirmButton.topAnchor.constraint(equalTo: horizontalSeparator.bottomAnchor),
            confirmButton.leadingAnchor.constraint(equalTo: buttonSeparator.trailingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            confirmButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            confirmButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func presentAnimated() {
        dimView.alpha = 0
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            self.dimView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    private func dismissAnimated(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
            self.dimView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        } completion: { _ in
            self.removeFromSuperview()
            completion()
        }
    }

    @objc private func confirmTapped() {
        dismissAnimated { [onConfirm] in onConfirm?() }
    }

    @objc private func cancelTapped() {
        dismissAnimated { [onCancel] in onCancel?() }
    }

    private static func currentKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

