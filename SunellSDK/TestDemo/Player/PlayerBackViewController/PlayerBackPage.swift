//
//  PlayerBackPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK

/// 回放页：与 `LivePlayerPage` 相同的横向分页预览，滑动切换通道并播放对应通道录像。
final class PlayerBackPage: UIViewController {

    private var device: SunellDeviceModel
    private var currentChannel: Int = 1

    /// 与设备协议一致：`yyyy-MM-dd HH:mm:ss`（见 `sdks_dev_pb_start` 说明）。默认当天 0 点，后续可接录像时间轴传入。
    private let playbackStartTimeStr: String

    private lazy var playAreaView: PlayerView = {
        let v = PlayerView(frame: .zero, device: device)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private let bottomPlaceholderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    /// 默认显示「暂停」；按下进入暂停后为选中态，文案为「继续播放」。
    private lazy var playbackPauseResumeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        Self.applyPlaybackPauseResumeTitles(to: b)
        b.isSelected = false
        b.addTarget(self, action: #selector(playbackPauseResumeTapped), for: .touchUpInside)
        return b
    }()

    private lazy var playbackSpeedButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitle(TKLocalizedString("TK_PlaybackSpeed"), for: .normal)
        b.addTarget(self, action: #selector(playbackSpeedButtonTapped), for: .touchUpInside)
        return b
    }()

    private let playbackControlsStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 28
        s.distribution = .fill
        return s
    }()

    private var playbackSpeed: SunellPlaybackSpeed = .x1

    private weak var playbackSpeedPickerDimView: UIView?
    private weak var playbackSpeedPickerCardView: UIView?
    private weak var playbackSpeedPickerButton1x: UIButton?
    private weak var playbackSpeedPickerButton2x: UIButton?

    private let recordQuerySectionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemGroupedBackground
        v.layer.cornerRadius = 8
        return v
    }()

    private let recordQueryTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.lineBreakMode = .byTruncatingTail
        l.text = TKLocalizedString("TK_PlaybackRecordOneDayTitle")
        return l
    }()

    private let recordQueryDateLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        l.textColor = .label
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private lazy var recordQueryPickDateButton: UIButton = Self.makeCompactRecordQueryButton(title: TKLocalizedString("TK_SelectDate"))

    private lazy var recordQueryExecuteButton: UIButton = Self.makeCompactRecordQueryButton(title: TKLocalizedString("TK_Query"))

    /// 当前选中日（本地日历 00:00），与标签 `yyyy-MM-dd` 一致。
    private var recordQuerySelectedCalendarDay: Date = Calendar.current.startOfDay(for: Date())

    private let periodQuerySectionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemGroupedBackground
        v.layer.cornerRadius = 8
        return v
    }()

    private let periodQueryTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.lineBreakMode = .byTruncatingTail
        l.text = TKLocalizedString("TK_PlaybackRecordPeriodTitle")
        return l
    }()

    private lazy var periodStartTimeButton: UIButton = Self.makePeriodDateTimeButton()
    private lazy var periodEndTimeButton: UIButton = Self.makePeriodDateTimeButton()
    private lazy var periodRangeQueryButton: UIButton = Self.makeCompactRecordQueryButton(title: TKLocalizedString("TK_Query"))

    private let periodTimesStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .fill
        s.distribution = .fillEqually
        return s
    }()

    private var periodQueryStartDate: Date = Calendar.current.startOfDay(for: Date())
    private var periodQueryEndDate: Date = {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: start) ?? start
    }()

    /// 查询日期范围内「哪些天有录像」：界面仅展示 `yyyy-MM-dd`，请求时扩展为当日起止时刻以兼容接口。
    private let daysWithPlaybackSectionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemGroupedBackground
        v.layer.cornerRadius = 8
        return v
    }()

    private let daysWithPlaybackTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.lineBreakMode = .byTruncatingTail
        l.text = TKLocalizedString("TK_PlaybackRecordDaysWithDataTitle")
        return l
    }()

    private lazy var daysRangeStartDayButton: UIButton = Self.makePeriodDateTimeButton()
    private lazy var daysRangeEndDayButton: UIButton = Self.makePeriodDateTimeButton()
    private lazy var daysRangeQueryButton: UIButton = Self.makeCompactRecordQueryButton(title: TKLocalizedString("TK_Query"))

    private let daysRangeDatesStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .fill
        s.distribution = .fillEqually
        return s
    }()

    private var daysRangeStartCalendarDay: Date = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: -7, to: today) ?? today
    }()

    private var daysRangeEndCalendarDay: Date = Calendar.current.startOfDay(for: Date())

    private let playbackSeekSectionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemGroupedBackground
        v.layer.cornerRadius = 8
        return v
    }()

    private lazy var playbackSeekTimeButton: UIButton = Self.makePeriodDateTimeButton()
    private lazy var playbackSeekExecuteButton: UIButton = Self.makeCompactRecordQueryButton(title: TKLocalizedString("TK_PlaybackSeek"))

    /// 跳转目标时刻，展示与请求均为 `yyyy-MM-dd HH:mm:ss`。
    private var playbackSeekTargetDate: Date = Date()

    private let pageIndicatorContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.isUserInteractionEnabled = false
        return v
    }()

    private let pageIndicatorLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.text = "0/0"
        return l
    }()

    private var didStartPlayback = false
    private var deferredPlaybackBootstrapWorkItem: DispatchWorkItem?
    private var playbackPreviewTornDown = false
    private var suspendedForSceneLifecycle = false
    private var reconnectStatusObserver: NSObjectProtocol?
    private var scenePauseObserver: NSObjectProtocol?
    private var sceneResumeObserver: NSObjectProtocol?

    init(device: SunellDeviceModel, playbackStartTimeStr: String? = nil) {
        self.device = device
        self.playbackStartTimeStr = playbackStartTimeStr ?? Self.defaultPlaybackStartTimeString()
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

        view.addSubview(playAreaView)
        view.addSubview(bottomPlaceholderView)
        bottomPlaceholderView.addSubview(hintLabel)
        playbackControlsStack.addArrangedSubview(playbackPauseResumeButton)
        playbackControlsStack.addArrangedSubview(playbackSpeedButton)
        bottomPlaceholderView.addSubview(playbackControlsStack)
        bottomPlaceholderView.addSubview(recordQuerySectionContainer)
        recordQuerySectionContainer.addSubview(recordQueryTitleLabel)
        recordQuerySectionContainer.addSubview(recordQueryDateLabel)
        recordQuerySectionContainer.addSubview(recordQueryPickDateButton)
        recordQuerySectionContainer.addSubview(recordQueryExecuteButton)
        recordQueryDateLabel.text = Self.recordQueryDayFormatter.string(from: recordQuerySelectedCalendarDay)
        recordQueryPickDateButton.addTarget(self, action: #selector(recordQueryPickDateTapped), for: .touchUpInside)
        recordQueryExecuteButton.addTarget(self, action: #selector(recordQueryExecuteTapped), for: .touchUpInside)

        bottomPlaceholderView.addSubview(periodQuerySectionContainer)
        periodQuerySectionContainer.addSubview(periodQueryTitleLabel)
        periodTimesStack.addArrangedSubview(periodStartTimeButton)
        periodTimesStack.addArrangedSubview(periodEndTimeButton)
        periodQuerySectionContainer.addSubview(periodTimesStack)
        periodQuerySectionContainer.addSubview(periodRangeQueryButton)
        updatePeriodQueryDateTimeButtonTitles()
        periodStartTimeButton.addTarget(self, action: #selector(periodStartTimeTapped), for: .touchUpInside)
        periodEndTimeButton.addTarget(self, action: #selector(periodEndTimeTapped), for: .touchUpInside)
        periodRangeQueryButton.addTarget(self, action: #selector(periodRangeQueryExecuteTapped), for: .touchUpInside)

        bottomPlaceholderView.addSubview(daysWithPlaybackSectionContainer)
        daysWithPlaybackSectionContainer.addSubview(daysWithPlaybackTitleLabel)
        daysRangeDatesStack.addArrangedSubview(daysRangeStartDayButton)
        daysRangeDatesStack.addArrangedSubview(daysRangeEndDayButton)
        daysWithPlaybackSectionContainer.addSubview(daysRangeDatesStack)
        daysWithPlaybackSectionContainer.addSubview(daysRangeQueryButton)
        updateDaysWithPlaybackRangeButtonTitles()
        daysRangeStartDayButton.addTarget(self, action: #selector(daysRangeStartDayTapped), for: .touchUpInside)
        daysRangeEndDayButton.addTarget(self, action: #selector(daysRangeEndDayTapped), for: .touchUpInside)
        daysRangeQueryButton.addTarget(self, action: #selector(daysWithPlaybackRangeQueryTapped), for: .touchUpInside)

        bottomPlaceholderView.addSubview(playbackSeekSectionContainer)
        playbackSeekSectionContainer.addSubview(playbackSeekTimeButton)
        playbackSeekSectionContainer.addSubview(playbackSeekExecuteButton)
        if let parsed = Self.playbackAPIDateTimeFormatter.date(from: playbackStartTimeStr) {
            playbackSeekTargetDate = parsed
        }
        updatePlaybackSeekTimeButtonTitle()
        playbackSeekTimeButton.addTarget(self, action: #selector(playbackSeekTimeTapped), for: .touchUpInside)
        playbackSeekExecuteButton.addTarget(self, action: #selector(playbackSeekExecuteTapped), for: .touchUpInside)

        playAreaView.bgScrollView.delegate = self
        playAreaView.addSubview(pageIndicatorContainer)
        pageIndicatorContainer.addSubview(pageIndicatorLabel)

        let playHeight = UIScreen.main.bounds.width * (3.0 / 4.0)
        hintLabel.text = playbackStartTimeStr

        NSLayoutConstraint.activate([
            playAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playAreaView.heightAnchor.constraint(equalToConstant: playHeight),

            bottomPlaceholderView.topAnchor.constraint(equalTo: playAreaView.bottomAnchor),
            bottomPlaceholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPlaceholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPlaceholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hintLabel.topAnchor.constraint(equalTo: bottomPlaceholderView.safeAreaLayoutGuide.topAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -20),

            playbackControlsStack.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            playbackControlsStack.centerXAnchor.constraint(equalTo: bottomPlaceholderView.centerXAnchor),

            recordQuerySectionContainer.topAnchor.constraint(equalTo: playbackControlsStack.bottomAnchor, constant: 16),
            recordQuerySectionContainer.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            recordQuerySectionContainer.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),
            recordQuerySectionContainer.heightAnchor.constraint(equalToConstant: 70),

            recordQueryTitleLabel.topAnchor.constraint(equalTo: recordQuerySectionContainer.topAnchor, constant: 8),
            recordQueryTitleLabel.leadingAnchor.constraint(equalTo: recordQuerySectionContainer.leadingAnchor, constant: 12),
            recordQueryTitleLabel.trailingAnchor.constraint(equalTo: recordQuerySectionContainer.trailingAnchor, constant: -12),

            recordQueryDateLabel.topAnchor.constraint(greaterThanOrEqualTo: recordQueryTitleLabel.bottomAnchor, constant: 4),

            recordQueryDateLabel.leadingAnchor.constraint(equalTo: recordQuerySectionContainer.leadingAnchor, constant: 12),
            recordQueryDateLabel.bottomAnchor.constraint(equalTo: recordQuerySectionContainer.bottomAnchor, constant: -10),

            recordQueryExecuteButton.trailingAnchor.constraint(equalTo: recordQuerySectionContainer.trailingAnchor, constant: -12),
            recordQueryExecuteButton.centerYAnchor.constraint(equalTo: recordQueryDateLabel.centerYAnchor),

            recordQueryPickDateButton.trailingAnchor.constraint(equalTo: recordQueryExecuteButton.leadingAnchor, constant: -20),
            recordQueryPickDateButton.centerYAnchor.constraint(equalTo: recordQueryDateLabel.centerYAnchor),

            recordQueryDateLabel.trailingAnchor.constraint(lessThanOrEqualTo: recordQueryPickDateButton.leadingAnchor, constant: -8),

            periodQuerySectionContainer.topAnchor.constraint(equalTo: recordQuerySectionContainer.bottomAnchor, constant: 12),
            periodQuerySectionContainer.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            periodQuerySectionContainer.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),
            periodQuerySectionContainer.heightAnchor.constraint(equalToConstant: 100),

            periodQueryTitleLabel.topAnchor.constraint(equalTo: periodQuerySectionContainer.topAnchor, constant: 6),
            periodQueryTitleLabel.leadingAnchor.constraint(equalTo: periodQuerySectionContainer.leadingAnchor, constant: 12),
            periodQueryTitleLabel.trailingAnchor.constraint(equalTo: periodQuerySectionContainer.trailingAnchor, constant: -12),

            periodTimesStack.topAnchor.constraint(equalTo: periodQueryTitleLabel.bottomAnchor, constant: 4),
            periodTimesStack.leadingAnchor.constraint(equalTo: periodQuerySectionContainer.leadingAnchor, constant: 12),
            periodTimesStack.bottomAnchor.constraint(lessThanOrEqualTo: periodQuerySectionContainer.bottomAnchor, constant: -8),

            periodRangeQueryButton.trailingAnchor.constraint(equalTo: periodQuerySectionContainer.trailingAnchor, constant: -12),
            periodRangeQueryButton.centerYAnchor.constraint(equalTo: periodTimesStack.centerYAnchor),

            periodTimesStack.trailingAnchor.constraint(lessThanOrEqualTo: periodRangeQueryButton.leadingAnchor, constant: -10),

            daysWithPlaybackSectionContainer.topAnchor.constraint(equalTo: periodQuerySectionContainer.bottomAnchor, constant: 12),
            daysWithPlaybackSectionContainer.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            daysWithPlaybackSectionContainer.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),
            daysWithPlaybackSectionContainer.heightAnchor.constraint(equalToConstant: 100),

            daysWithPlaybackTitleLabel.topAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.topAnchor, constant: 6),
            daysWithPlaybackTitleLabel.leadingAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.leadingAnchor, constant: 12),
            daysWithPlaybackTitleLabel.trailingAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.trailingAnchor, constant: -12),

            daysRangeDatesStack.topAnchor.constraint(equalTo: daysWithPlaybackTitleLabel.bottomAnchor, constant: 4),
            daysRangeDatesStack.leadingAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.leadingAnchor, constant: 12),
            daysRangeDatesStack.bottomAnchor.constraint(lessThanOrEqualTo: daysWithPlaybackSectionContainer.bottomAnchor, constant: -8),

            daysRangeQueryButton.trailingAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.trailingAnchor, constant: -12),
            daysRangeQueryButton.centerYAnchor.constraint(equalTo: daysRangeDatesStack.centerYAnchor),

            daysRangeDatesStack.trailingAnchor.constraint(lessThanOrEqualTo: daysRangeQueryButton.leadingAnchor, constant: -10),

            playbackSeekSectionContainer.topAnchor.constraint(equalTo: daysWithPlaybackSectionContainer.bottomAnchor, constant: 12),
            playbackSeekSectionContainer.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            playbackSeekSectionContainer.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),
            playbackSeekSectionContainer.heightAnchor.constraint(equalToConstant: 50),

            playbackSeekTimeButton.leadingAnchor.constraint(equalTo: playbackSeekSectionContainer.leadingAnchor, constant: 12),
            playbackSeekTimeButton.centerYAnchor.constraint(equalTo: playbackSeekSectionContainer.centerYAnchor),
            playbackSeekTimeButton.trailingAnchor.constraint(lessThanOrEqualTo: playbackSeekExecuteButton.leadingAnchor, constant: -10),

            playbackSeekExecuteButton.trailingAnchor.constraint(equalTo: playbackSeekSectionContainer.trailingAnchor, constant: -12),
            playbackSeekExecuteButton.centerYAnchor.constraint(equalTo: playbackSeekSectionContainer.centerYAnchor),

            pageIndicatorContainer.centerXAnchor.constraint(equalTo: playAreaView.centerXAnchor),
            pageIndicatorContainer.bottomAnchor.constraint(equalTo: playAreaView.bottomAnchor, constant: -12),

            pageIndicatorLabel.topAnchor.constraint(equalTo: pageIndicatorContainer.topAnchor, constant: 6),
            pageIndicatorLabel.leadingAnchor.constraint(equalTo: pageIndicatorContainer.leadingAnchor, constant: 12),
            pageIndicatorLabel.bottomAnchor.constraint(equalTo: pageIndicatorContainer.bottomAnchor, constant: -6),
            pageIndicatorLabel.trailingAnchor.constraint(equalTo: pageIndicatorContainer.trailingAnchor, constant: -12)
        ])

        playAreaView.accessibilityIdentifier = device.deviceId
        playAreaView.bringSubviewToFront(pageIndicatorContainer)
        updatePageIndicator()
        updatePlaybackPauseResumeControlAvailability()

        reconnectStatusObserver = NotificationCenter.default.addObserver(
            forName: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleAutoReconnectStatusNotification(note)
        }

        scenePauseObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneWillResignActivePauseVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pausePlaybackForSceneResignActive()
        }
        sceneResumeObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneDidBecomeActiveResumeVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumePlaybackAfterSceneBecomeActive()
        }
        
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissPlaybackSpeedPickerIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current

        let calendar = Calendar.current
        let now = Date()
        let todayZero = calendar.startOfDay(for: now)
        let yesterdayZero = calendar.date(byAdding: .day, value: -1, to: todayZero)!
        let tomorrowZero = calendar.date(byAdding: .day, value: 1, to: todayZero)!

        let preDayStr = formatter.string(from: yesterdayZero)
        let tomorrowStr = formatter.string(from: tomorrowZero)
        requestPlaybackRecordListForPeriod(startDateStr: preDayStr, endDateStr: tomorrowStr)
    }

    private func requestPlaybackRecordListForPeriod(startDateStr: String, endDateStr: String) {
        SunellSDKEntry.getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId(
            deviceId: device.deviceId,
            channelId: currentChannel,
            startDateStr: startDateStr,
            endDateStr: endDateStr
        ) { result, jsonStr in
            print("时间段回放记录:", "result=\(result)", jsonStr)
        }
    }

    /// `startDayStr` / `endDayStr` 须为 `yyyy-MM-dd`（与 `sdks_dev_pb_date_list` 一致）。
    private func requestWhichDaysHavePlaybackInRange(startDayStr: String, endDayStr: String) {
        SunellSDKEntry.getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId(
            deviceId: device.deviceId,
            channelId: currentChannel,
            startDayStr: startDayStr,
            endDayStr: endDayStr
        ) { result, jsonStr in
            print("哪些天有回放记录:", "result=\(result)", jsonStr)
        }
    }

    private func requestPlaybackRecordListForCalendarDay(dayStr: String) {
        SunellSDKEntry.getPlayBackOneDayRecordListWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, dayStr: dayStr) { result, jsonStr in
            // 回放记录: {"data":[{"is_alarm":false,"s_time":"2026-05-07 00:00:00","e_time":"2026-05-07 11:54:00"}]}
            print("单日回放记录:", "result=\(result)", jsonStr)
        }
    }

    @objc private func recordQueryPickDateTapped() {
        let picker = PlaybackRecordDayPickerViewController()
        picker.initialCalendarDay = recordQuerySelectedCalendarDay
        picker.onConfirmedCalendarDay = { [weak self] day in
            guard let self else { return }
            self.recordQuerySelectedCalendarDay = day
            self.recordQueryDateLabel.text = Self.recordQueryDayFormatter.string(from: day)
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(nav, animated: true)
    }

    @objc private func recordQueryExecuteTapped() {
        guard let raw = recordQueryDateLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines), raw.count == 10 else { return }
        requestPlaybackRecordListForCalendarDay(dayStr: raw)
    }

    private func updatePeriodQueryDateTimeButtonTitles() {
        periodStartTimeButton.setTitle(Self.playbackAPIDateTimeFormatter.string(from: periodQueryStartDate), for: .normal)
        periodEndTimeButton.setTitle(Self.playbackAPIDateTimeFormatter.string(from: periodQueryEndDate), for: .normal)
    }

    @objc private func periodStartTimeTapped() {
        presentPeriodDateTimePicker(editingStart: true)
    }

    @objc private func periodEndTimeTapped() {
        presentPeriodDateTimePicker(editingStart: false)
    }

    private func presentPeriodDateTimePicker(editingStart: Bool) {
        let picker = PlaybackRecordDateTimePickerViewController()
        picker.initialDate = editingStart ? periodQueryStartDate : periodQueryEndDate
        picker.navigationTitleText = TKLocalizedString(editingStart ? "TK_SelectStartDateTime" : "TK_SelectEndDateTime")
        picker.onConfirmedDate = { [weak self] date in
            guard let self else { return }
            if editingStart {
                self.periodQueryStartDate = date
            } else {
                self.periodQueryEndDate = date
            }
            self.updatePeriodQueryDateTimeButtonTitles()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(nav, animated: true)
    }

    @objc private func periodRangeQueryExecuteTapped() {
        guard periodQueryStartDate < periodQueryEndDate else {
            print("period query: start time must be before end time")
            return
        }
        let startStr = Self.playbackAPIDateTimeFormatter.string(from: periodQueryStartDate)
        let endStr = Self.playbackAPIDateTimeFormatter.string(from: periodQueryEndDate)
        requestPlaybackRecordListForPeriod(startDateStr: startStr, endDateStr: endStr)
    }

    private func updateDaysWithPlaybackRangeButtonTitles() {
        let startDay = Calendar.current.startOfDay(for: daysRangeStartCalendarDay)
        let endDay = Calendar.current.startOfDay(for: daysRangeEndCalendarDay)
        daysRangeStartDayButton.setTitle(Self.recordQueryDayFormatter.string(from: startDay), for: .normal)
        daysRangeEndDayButton.setTitle(Self.recordQueryDayFormatter.string(from: endDay), for: .normal)
    }

    @objc private func daysRangeStartDayTapped() {
        presentDaysRangeDayPicker(editingStart: true)
    }

    @objc private func daysRangeEndDayTapped() {
        presentDaysRangeDayPicker(editingStart: false)
    }

    private func presentDaysRangeDayPicker(editingStart: Bool) {
        let picker = PlaybackRecordDayPickerViewController()
        picker.initialCalendarDay = editingStart ? daysRangeStartCalendarDay : daysRangeEndCalendarDay
        picker.navigationTitleOverride = TKLocalizedString(editingStart ? "TK_SelectStartDate" : "TK_SelectEndDate")
        picker.onConfirmedCalendarDay = { [weak self] day in
            guard let self else { return }
            let d = Calendar.current.startOfDay(for: day)
            if editingStart {
                self.daysRangeStartCalendarDay = d
            } else {
                self.daysRangeEndCalendarDay = d
            }
            self.updateDaysWithPlaybackRangeButtonTitles()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(nav, animated: true)
    }

    @objc private func daysWithPlaybackRangeQueryTapped() {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: daysRangeStartCalendarDay)
        let endDay = cal.startOfDay(for: daysRangeEndCalendarDay)
        guard startDay <= endDay else {
            print("days-with-playback query: start date must be on or before end date")
            return
        }
        let startStr = Self.recordQueryDayFormatter.string(from: startDay)
        let endStr = Self.recordQueryDayFormatter.string(from: endDay)
        requestWhichDaysHavePlaybackInRange(startDayStr: startStr, endDayStr: endStr)
    }

    private func updatePlaybackSeekTimeButtonTitle() {
        playbackSeekTimeButton.setTitle(Self.playbackAPIDateTimeFormatter.string(from: playbackSeekTargetDate), for: .normal)
    }

    @objc private func playbackSeekTimeTapped() {
        let picker = PlaybackRecordDateTimePickerViewController()
        picker.initialDate = playbackSeekTargetDate
        picker.navigationTitleText = TKLocalizedString("TK_SelectSeekDateTime")
        picker.onConfirmedDate = { [weak self] date in
            guard let self else { return }
            self.playbackSeekTargetDate = date
            self.updatePlaybackSeekTimeButtonTitle()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(nav, animated: true)
    }

    @objc private func playbackSeekExecuteTapped() {
        guard didStartPlayback, !playbackPreviewTornDown, !suspendedForSceneLifecycle else { return }
        let timeStr = Self.playbackAPIDateTimeFormatter.string(from: playbackSeekTargetDate)
        playbackSeekExecuteButton.isEnabled = false
        let ch = currentChannel
        let devId = device.deviceId
        SunellSDKEntry.playBackSeekWithDeviceId(deviceId: devId, channelId: ch, timeStr: timeStr) { [weak self] ret in
            guard let self else { return }
            if ret != 0 {
                print("playback seek failed ret=\(ret)")
            }
            self.updatePlaybackPauseResumeControlAvailability()
        }
    }

    private func pausePlaybackForSceneResignActive() {
        guard view.window != nil, didStartPlayback else { return }
        dismissPlaybackSpeedPickerIfNeeded()
        suspendedForSceneLifecycle = true
        resetPlaybackPauseResumeUIDefaults()
        SunellSDKEntry.playBackStopWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { _ in
            SunellSDKEntry.closeGL()
        }
        updatePlaybackPauseResumeControlAvailability()
    }

    private func resumePlaybackAfterSceneBecomeActive() {
        guard view.window != nil, suspendedForSceneLifecycle else { return }
        suspendedForSceneLifecycle = false
        let page = playAreaView.currentPageIndex()
        startPlayback(onPage: page)
    }

    private func cancelPendingDeferredPlaybackBootstrap() {
        deferredPlaybackBootstrapWorkItem?.cancel()
        deferredPlaybackBootstrapWorkItem = nil
    }

    private func tearDownPlaybackPreviewIfNeeded(completion: (() -> Void)? = nil) {
        dismissPlaybackSpeedPickerIfNeeded()
        cancelPendingDeferredPlaybackBootstrap()
        let finish: () -> Void = {
            guard let completion else { return }
            if Thread.isMainThread {
                completion()
            } else {
                DispatchQueue.main.async(execute: completion)
            }
        }

        guard !playbackPreviewTornDown else {
            finish()
            return
        }
        guard didStartPlayback else {
            finish()
            return
        }
        playbackPreviewTornDown = true
        suspendedForSceneLifecycle = false
        resetPlaybackPauseResumeUIDefaults()
        updatePlaybackPauseResumeControlAvailability()
        playAreaView.bgScrollView.delegate = nil
        SunellSDKEntry.playBackStopWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { _ in
            SunellSDKEntry.closeGL()
            finish()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let leavingStack = isMovingFromParent || isBeingDismissed
            || (navigationController?.isBeingDismissed == true)
        if leavingStack {
            tearDownPlaybackPreviewIfNeeded()
        }
    }

    deinit {
        cancelPendingDeferredPlaybackBootstrap()
        tearDownPlaybackPreviewIfNeeded()
        if let reconnectStatusObserver {
            NotificationCenter.default.removeObserver(reconnectStatusObserver)
        }
        if let scenePauseObserver {
            NotificationCenter.default.removeObserver(scenePauseObserver)
        }
        if let sceneResumeObserver {
            NotificationCenter.default.removeObserver(sceneResumeObserver)
        }
    }

    private func handleAutoReconnectStatusNotification(_ note: Notification) {
        guard let info = note.userInfo,
              let deviceId = info["deviceId"] as? String,
              deviceId == device.deviceId
        else { return }

        let status = info["status"] as? Int
        if status == 1, didStartPlayback, !playbackPreviewTornDown {
            let page = playAreaView.currentPageIndex()
            startPlayback(onPage: page)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updatePageIndicator()

        guard !didStartPlayback else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        scheduleDeferredPlaybackBootstrapFromLayoutIfNeeded()
    }

    private func scheduleDeferredPlaybackBootstrapFromLayoutIfNeeded() {
        guard !didStartPlayback else { return }
        deferredPlaybackBootstrapWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.deferredPlaybackBootstrapWorkItem = nil
            self.performDeferredPlaybackBootstrapFromLayout()
        }
        deferredPlaybackBootstrapWorkItem = work
        DispatchQueue.main.async(execute: work)
    }

    private func performDeferredPlaybackBootstrapFromLayout() {
        guard !didStartPlayback else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        syncPlayAreaCellsWithDevice()

        let expectedCells = expectedPlayCellCount()
        guard expectedCells > 0, !playAreaView.cellArray.isEmpty else { return }

        let lastPageIndex = max(0, playAreaView.cellArray.count - 1)
        let page = min(max(0, playAreaView.currentPageIndex()), lastPageIndex)
        currentChannel = channelIdForCellIndex(page)
        didStartPlayback = true

        startPlayback(onPage: page)
        updatePageIndicator()
    }

    private func expectedPlayCellCount() -> Int {
        let raw = max(0, Int(device.chnNum))
        if raw == 0 {
            return 1
        }
        return raw
    }

    private func syncPlayAreaCellsWithDevice() {
        let expected = expectedPlayCellCount()
        guard expected > 0 else { return }

        if playAreaView.device !== device {
            playAreaView.device = device
            return
        }
        if playAreaView.cellArray.count != expected {
            playAreaView.reloadChannelCellsFromDevice()
        }
    }

    private func updatePageIndicator() {
        var total = playAreaView.cellArray.count
        if total == 0, Int(device.chnNum) == 0 {
            total = 1
        }
        guard total > 0 else {
            pageIndicatorLabel.text = "0/0"
            pageIndicatorContainer.isHidden = true
            return
        }
        pageIndicatorContainer.isHidden = false
        let idx = playAreaView.currentPageIndex()
        let current = min(max(0, idx), total - 1) + 1
        pageIndicatorLabel.text = "\(current)/\(total)"
    }

    private func channelIdForCellIndex(_ index: Int) -> Int {
        if Int(device.chnNum) == 0 {
            return 1
        }
        if let list = device.channels as? [SunellChannelModel], index >= 0, index < list.count {
            return Int(list[index].channelId)
        }
        if let arr = device.channels as? NSArray, index >= 0, index < arr.count {
            if let ch = arr.object(at: index) as? SunellChannelModel {
                return Int(ch.channelId)
            }
        }
        return index + 1
    }

    private func startPlayback(onPage page: Int) {
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        resetPlaybackPauseResumeUIDefaults()
        playbackSpeed = .x1
        refreshPlaybackSpeedPickerHighlights()
        updatePlaybackPauseResumeControlAvailability()

        let chId = channelIdForCellIndex(page)
        let cell = playAreaView.cellArray[page]
        currentChannel = chId
        SunellSDKEntry.playBackStartWithDeviceId(
            deviceId: device.deviceId,
            channelId: chId,
            startTimeStr: playbackStartTimeStr,
            streamType: 2,
            isHwDec: false,
            caLayer: cell.glLayer
        ) { [weak self] ret in
            guard let self else { return }
            if ret >= 0 {
                print("playback start success ch=\(chId)")
                self.syncPlaybackSpeedToDevice(speed: .x1)
            } else {
                print("playback start error ch=\(chId) ret=\(ret)")
            }
            self.updatePlaybackPauseResumeControlAvailability()
        }
    }

    private static func applyPlaybackPauseResumeTitles(to button: UIButton) {
        button.setTitle(TKLocalizedString("TK_PlaybackPause"), for: .normal)
        button.setTitle(TKLocalizedString("TK_PlaybackResume"), for: .selected)
    }

    private func resetPlaybackPauseResumeUIDefaults() {
        playbackPauseResumeButton.isSelected = false
    }

    private func updatePlaybackPauseResumeControlAvailability() {
        let controlsActive = didStartPlayback && !playbackPreviewTornDown && !suspendedForSceneLifecycle
        playbackPauseResumeButton.isEnabled = controlsActive
        playbackSpeedButton.isEnabled = controlsActive
        playbackSeekExecuteButton.isEnabled = controlsActive
        Self.applyPlaybackPauseResumeTitles(to: playbackPauseResumeButton)
    }

    @objc private func playbackPauseResumeTapped() {
        guard didStartPlayback, !playbackPreviewTornDown, !suspendedForSceneLifecycle else { return }
        let wantResume = playbackPauseResumeButton.isSelected
        playbackPauseResumeButton.isEnabled = false
        let ch = currentChannel
        let devId = device.deviceId
        if wantResume {
            SunellSDKEntry.playBackResumeWithDeviceId(deviceId: devId, channelId: ch) { [weak self] ret in
                guard let self else { return }
                self.playbackPauseResumeButton.isEnabled = true
                if ret == 0 {
                    self.playbackPauseResumeButton.isSelected = false
                } else {
                    print("playback resume failed ret=\(ret)")
                }
                self.updatePlaybackPauseResumeControlAvailability()
            }
        } else {
            SunellSDKEntry.playBackPauseWithDeviceId(deviceId: devId, channelId: ch) { [weak self] ret in
                guard let self else { return }
                self.playbackPauseResumeButton.isEnabled = true
                if ret == 0 {
                    self.playbackPauseResumeButton.isSelected = true
                } else {
                    print("playback pause failed ret=\(ret)")
                }
                self.updatePlaybackPauseResumeControlAvailability()
            }
        }
    }

    @objc private func playbackSpeedButtonTapped() {
        guard didStartPlayback, !playbackPreviewTornDown, !suspendedForSceneLifecycle else { return }
        if playbackSpeedPickerDimView != nil {
            dismissPlaybackSpeedPickerIfNeeded()
        } else {
            presentPlaybackSpeedPicker()
        }
    }

    private func presentPlaybackSpeedPicker() {
        guard playbackSpeedPickerDimView == nil else { return }

        let dim = UIView()
        dim.translatesAutoresizingMaskIntoConstraints = false
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dim.accessibilityIdentifier = "playbackSpeedPickerDim"

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.text = TKLocalizedString("TK_PlaybackSpeedTitle")

        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        row.alignment = .fill

        let b1 = Self.makePlaybackSpeedOptionButton(titleKey: "TK_PlaybackSpeed1x", tag: 1)
        let b2 = Self.makePlaybackSpeedOptionButton(titleKey: "TK_PlaybackSpeed2x", tag: 2)
        b1.addTarget(self, action: #selector(playbackSpeedOptionTapped(_:)), for: .touchUpInside)
        b2.addTarget(self, action: #selector(playbackSpeedOptionTapped(_:)), for: .touchUpInside)
        row.addArrangedSubview(b1)
        row.addArrangedSubview(b2)

        playbackSpeedPickerButton1x = b1
        playbackSpeedPickerButton2x = b2

        dim.addSubview(card)
        card.addSubview(titleLabel)
        card.addSubview(row)
        view.addSubview(dim)

        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            card.centerXAnchor.constraint(equalTo: dim.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: dim.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: dim.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(lessThanOrEqualTo: dim.trailingAnchor, constant: -32),
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 260),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            row.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            b1.heightAnchor.constraint(equalToConstant: 44)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(playbackSpeedPickerDimTapped(_:)))
        tap.cancelsTouchesInView = false
        dim.addGestureRecognizer(tap)

        playbackSpeedPickerDimView = dim
        playbackSpeedPickerCardView = card
        refreshPlaybackSpeedPickerHighlights()
    }

    @objc private func playbackSpeedPickerDimTapped(_ gr: UITapGestureRecognizer) {
        guard let dim = playbackSpeedPickerDimView, let card = playbackSpeedPickerCardView else { return }
        let p = gr.location(in: dim)
        if card.frame.contains(p) { return }
        dismissPlaybackSpeedPickerIfNeeded()
    }

    private func dismissPlaybackSpeedPickerIfNeeded() {
        playbackSpeedPickerDimView?.removeFromSuperview()
        playbackSpeedPickerDimView = nil
        playbackSpeedPickerCardView = nil
        playbackSpeedPickerButton1x = nil
        playbackSpeedPickerButton2x = nil
    }

    @objc private func playbackSpeedOptionTapped(_ sender: UIButton) {
        guard let speed = SunellPlaybackSpeed(rawValue: sender.tag) else { return }
        requestPlaybackSpeedChange(speed: speed)
    }

    private func requestPlaybackSpeedChange(speed: SunellPlaybackSpeed) {
        guard didStartPlayback, !playbackPreviewTornDown, !suspendedForSceneLifecycle else { return }
        if speed == playbackSpeed {
            refreshPlaybackSpeedPickerHighlights()
            return
        }
        let previous = playbackSpeed
        let devId = device.deviceId
        let ch = currentChannel
        SunellSDKEntry.playBackSetSpeedWithDeviceId(deviceId: devId, channelId: ch, speed: speed) { [weak self] ret in
            guard let self else { return }
            if ret == 0 {
                self.playbackSpeed = speed
            } else {
                print("playback set speed failed ret=\(ret) wanted=\(speed.rawValue)×")
                self.playbackSpeed = previous
            }
            self.refreshPlaybackSpeedPickerHighlights()
        }
    }

    /// 起播后同步设备倍速（默认 1×）。
    private func syncPlaybackSpeedToDevice(speed: SunellPlaybackSpeed) {
        SunellSDKEntry.playBackSetSpeedWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, speed: speed) { [weak self] ret in
            if ret != 0 {
                print("playback sync speed failed ret=\(ret) speed=\(speed.rawValue)×")
            }
            self?.refreshPlaybackSpeedPickerHighlights()
        }
    }

    private func refreshPlaybackSpeedPickerHighlights() {
        guard let b1 = playbackSpeedPickerButton1x, let b2 = playbackSpeedPickerButton2x else { return }
        Self.applyPlaybackSpeedOptionHighlight(selectedSpeed: playbackSpeed, button1x: b1, button2x: b2)
    }

    private static func makePlaybackSpeedOptionButton(titleKey: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.tag = tag
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitle(TKLocalizedString(titleKey), for: .normal)
        b.layer.cornerRadius = 10
        b.layer.masksToBounds = true
        return b
    }

    private static func applyPlaybackSpeedOptionHighlight(selectedSpeed: SunellPlaybackSpeed, button1x: UIButton, button2x: UIButton) {
        let sel = UIColor.systemBlue
        let selTitle = UIColor.white
        let normalBg = UIColor.tertiarySystemFill
        let normalTitle = UIColor.label

        let oneSelected = selectedSpeed == .x1
        button1x.backgroundColor = oneSelected ? sel : normalBg
        button1x.setTitleColor(oneSelected ? selTitle : normalTitle, for: .normal)

        let twoSelected = selectedSpeed == .x2
        button2x.backgroundColor = twoSelected ? sel : normalBg
        button2x.setTitleColor(twoSelected ? selTitle : normalTitle, for: .normal)
    }

    private func switchPlaybackToVisiblePageIfNeeded() {
        let page = playAreaView.currentPageIndex()
        updatePageIndicator()
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        let chId = channelIdForCellIndex(page)
        if chId == currentChannel { return }

        SunellSDKEntry.playBackStopWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] ret in
            guard let self else { return }
            if ret == 0 {
                self.startPlayback(onPage: page)
            } else {
                print("playback stop error ret=\(ret)")
            }
        }
    }

    @objc private func backTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        tearDownPlaybackPreviewIfNeeded { [weak self] in
            guard let self else { return }
            guard self.navigationController?.topViewController === self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    /// 默认从当天 00:00:00 起播；无录像时可改为传入具体片段起点。
    private static func defaultPlaybackStartTimeString() -> String {
        let start = Calendar.current.startOfDay(for: Date())
        return playbackAPIDateTimeFormatter.string(from: start)
    }

    /// 与设备协议一致：`yyyy-MM-dd HH:mm:ss`
    private static let playbackAPIDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private static func makeCompactRecordQueryButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.setTitle(title, for: .normal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        return b
    }

    private static func makePeriodDateTimeButton() -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.titleLabel?.minimumScaleFactor = 0.65
        b.titleLabel?.lineBreakMode = .byTruncatingTail
        b.titleLabel?.numberOfLines = 1
        b.contentHorizontalAlignment = .leading
        return b
    }

    /// 单日查询接口 `dayStr` 要求长度为 10（`yyyy-MM-dd`）。
    private static let recordQueryDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - 时间段回放 — 日期时间选择弹层

private final class PlaybackRecordDateTimePickerViewController: UIViewController {

    var initialDate = Date()
    var navigationTitleText = ""
    var onConfirmedDate: ((Date) -> Void)?

    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.translatesAutoresizingMaskIntoConstraints = false
        p.datePickerMode = .dateAndTime
        p.calendar = Calendar.current
        p.locale = Locale.current
        p.minuteInterval = 1
        return p
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        datePicker.date = initialDate

        navigationItem.title = navigationTitleText
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: TKLocalizedString("TK_Close"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TKLocalizedString("TK_Confirm"),
            style: .done,
            target: self,
            action: #selector(confirmTapped)
        )

        view.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        onConfirmedDate?(datePicker.date)
        dismiss(animated: true)
    }
}

// MARK: - 单日回放 — 年月日选择弹层

private final class PlaybackRecordDayPickerViewController: UIViewController {

    /// 弹出时展示的初始日期（通常为当前已选某日 00:00）。
    var initialCalendarDay = Date()

    /// 非空时用作导航标题（如「选择开始日期」）；否则为 `TK_SelectDate`。
    var navigationTitleOverride: String?

    /// 用户点击确认后回调（已为当日 00:00 的开始时刻）。
    var onConfirmedCalendarDay: ((Date) -> Void)?

    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.translatesAutoresizingMaskIntoConstraints = false
        p.datePickerMode = .date
        p.calendar = Calendar.current
        p.locale = Locale.current
        return p
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .compact
        }

        datePicker.date = Calendar.current.startOfDay(for: initialCalendarDay)

        navigationItem.title = navigationTitleOverride ?? TKLocalizedString("TK_SelectDate")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: TKLocalizedString("TK_Close"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TKLocalizedString("TK_Confirm"),
            style: .done,
            target: self,
            action: #selector(confirmTapped)
        )

        view.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        let cal = Calendar.current
        let d = cal.startOfDay(for: datePicker.date)
        onConfirmedCalendarDay?(d)
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension PlayerBackPage: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageIndicator()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        switchPlaybackToVisiblePageIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            switchPlaybackToVisiblePageIfNeeded()
        }
    }
}
