//
//  AudioAlarmFileListViewController.swift
//  TestDemo
//
//  以表格展示 `audio_file_list`：左 id、中 name（多行）、右 display_num；行点击留作后续业务。
//

import UIKit

protocol AudioAlarmFileListViewControllerDelegate: AnyObject {
    /// 用户选中一条报警音频条目（`audio_file_id` 等由 `LivePlayerPage` 传给 SDK）。
    func audioAlarmFileList(_ controller: AudioAlarmFileListViewController, didSelect file: AudioAlarmFileItem)
}

final class AudioAlarmFileListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let items: [AudioAlarmFileItem]
    private let tableView = UITableView(frame: .zero, style: .plain)
    weak var delegate: AudioAlarmFileListViewControllerDelegate?

    /// - Parameters:
    ///   - items: 已解析的 `audio_file_list`。
    ///   - delegate: 选中行后回调（通常为 `LivePlayerPage`）。
    init(items: [AudioAlarmFileItem], delegate: AudioAlarmFileListViewControllerDelegate?) {
        self.items = items
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = TKLocalizedString("TK_PlayAlarm")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        tableView.register(AudioAlarmFileTableViewCell.self, forCellReuseIdentifier: AudioAlarmFileTableViewCell.reuseId)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AudioAlarmFileTableViewCell.reuseId, for: indexPath) as! AudioAlarmFileTableViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let file = items[indexPath.row]
        delegate?.audioAlarmFileList(self, didSelect: file)
    }
}

// MARK: - Cell

private final class AudioAlarmFileTableViewCell: UITableViewCell {

    static let reuseId = "AudioAlarmFileTableViewCell"

    private let idLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        l.textColor = .secondaryLabel
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .label
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let displayNumLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        l.textColor = .label
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.addSubview(idLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(displayNumLabel)

        NSLayoutConstraint.activate([
            idLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            idLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            idLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),

            nameLabel.leadingAnchor.constraint(equalTo: idLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            displayNumLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 12),
            displayNumLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            displayNumLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            displayNumLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: AudioAlarmFileItem) {
        idLabel.text = "\(item.audioFileId)"
        nameLabel.text = item.audioFileName
        displayNumLabel.text = "\(item.audioDisplayNum)"
    }
}
