//
//  SunellImageViewPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/4/24.
//

import UIKit

final class SunellImageViewPage: UIViewController {

    private let imageFilePath: String
    private var remainingRetries = 10

    private let imageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = UIColor.black.withAlphaComponent(0.55)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()

    init(imageFilePath: String) {
        self.imageFilePath = imageFilePath
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Image"

        view.addSubview(imageView)
        view.addSubview(hintLabel)

        let w = UIScreen.main.bounds.width
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: w * 3 / 4),

            hintLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        hintLabel.text = imageFilePath
        loadImageWithRetry()
    }

    private func loadImageWithRetry() {
        if let img = UIImage(contentsOfFile: imageFilePath) {
            imageView.image = img
            return
        }

        // 文件可能还在写入中：先检查是否存在及大小，方便定位问题。
        let attrs = (try? FileManager.default.attributesOfItem(atPath: imageFilePath)) ?? [:]
        let exists = FileManager.default.fileExists(atPath: imageFilePath)
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        hintLabel.text = "The picture is temporarily unreadable（exists=\(exists), size=\(size) bytes）\n\(imageFilePath)"

        guard remainingRetries > 0 else { return }
        remainingRetries -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.loadImageWithRetry()
        }
    }
}
