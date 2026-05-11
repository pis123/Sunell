//
//  PTZKeyboardView.swift
//  TestDemo
//
//  Created by Cursor on 2026/04/25.
//

import UIKit

final class PTZKeyboardView: UIView {

    /// 仅保存 `Localizable.strings` 中的 key，展示文案由 `TKLocalizedString` 解析，新增语言只需加 `.lproj`。
    struct Item {
        let key: String
    }

    enum Direction: Int, CaseIterable {
        case up = 0
        case upRight
        case right
        case downRight
        case down
        case downLeft
        case left
        case upLeft
    }

    var onTapItem: ((String) -> Void)?
    var onClose: (() -> Void)?
    
    private let panelHeight: CGFloat = 420

    private let dimView: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        return v
    }()

    private let panelView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.masksToBounds = true
        return v
    }()

    private let dialView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        v.layer.cornerRadius = 105
        v.layer.masksToBounds = true
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("×", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        b.tintColor = .black
        return b
    }()

    private var buttons: [UIButton] = []
    private let items: [Direction: Item]

    init(items: [Direction: Item]) {
        self.items = items
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        addSubview(dimView)
        addSubview(panelView)

        dimView.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        panelView.addSubview(closeButton)
        panelView.addSubview(dialView)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            panelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: bottomAnchor),
            panelView.heightAnchor.constraint(equalToConstant: panelHeight),

            closeButton.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            dialView.centerXAnchor.constraint(equalTo: panelView.centerXAnchor),
            dialView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            dialView.widthAnchor.constraint(equalToConstant: 210),
            dialView.heightAnchor.constraint(equalToConstant: 210),
            dialView.bottomAnchor.constraint(lessThanOrEqualTo: panelView.bottomAnchor, constant: -20)
        ])

        buildButtons()
    }

    private func buildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll(keepingCapacity: true)

        for dir in Direction.allCases {
            let b = UIButton(type: .system)
            // 使用 frame 手动布局（圆周分布），避免 AutoLayout 因缺少位置约束导致按钮不显示。
            b.translatesAutoresizingMaskIntoConstraints = true
            b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            b.titleLabel?.numberOfLines = 2
            b.titleLabel?.textAlignment = .center
            b.backgroundColor = .white
            b.layer.cornerRadius = 24
            b.layer.masksToBounds = true
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.black.withAlphaComponent(0.15).cgColor
            b.setTitleColor(.black, for: .normal)
            b.tag = dir.rawValue
            b.addTarget(self, action: #selector(directionTapped(_:)), for: .touchUpInside)
            dialView.addSubview(b)
            buttons.append(b)
        }

        updateTitles()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func updateTitles() {
        for b in buttons {
            guard let dir = Direction(rawValue: b.tag) else { continue }
            let item = items[dir]
            b.setTitle(localized(item), for: .normal)
        }
    }

    private func localized(_ item: Item?) -> String {
        guard let item else { return "" }
        return TKLocalizedString(item.key)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 极坐标布局：8 个按钮刚好组成圆形（圆周上）。
        let r: CGFloat = 80
        let center = CGPoint(x: dialView.bounds.midX, y: dialView.bounds.midY)
        for b in buttons {
            guard let dir = Direction(rawValue: b.tag) else { continue }
            let angle = angleForDirection(dir)
            let x = center.x + r * cos(angle) - 24
            let y = center.y + r * sin(angle) - 24
            b.frame = CGRect(x: x, y: y, width: 48, height: 48)
        }
    }

    private func angleForDirection(_ dir: Direction) -> CGFloat {
        // iOS 坐标系 y 向下，角度顺时针更直观：上 -90°，右 0°。
        switch dir {
        case .up: return -.pi / 2
        case .upRight: return -.pi / 4
        case .right: return 0
        case .downRight: return .pi / 4
        case .down: return .pi / 2
        case .downLeft: return 3 * .pi / 4
        case .left: return .pi
        case .upLeft: return -3 * .pi / 4
        }
    }

    @objc private func directionTapped(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? ""
        onTapItem?(title)
    }

    @objc private func closeTapped() {
        onClose?()
    }

    // MARK: - Presentation

    func animateIn() {
        dimView.alpha = 0
        panelView.transform = CGAffineTransform(translationX: 0, y: panelHeight)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.panelView.transform = .identity
        }
    }

    func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
            self.dimView.alpha = 0
            self.panelView.transform = CGAffineTransform(translationX: 0, y: self.panelHeight)
        } completion: { _ in
            completion?()
        }
    }
}

