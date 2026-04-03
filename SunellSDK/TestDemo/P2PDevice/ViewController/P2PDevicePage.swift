//
//  P2PDevicePage.swift
//  SunellSDKDemo
//
//  Created by Sunell on 2026/3/19.
//

import UIKit
import AVFoundation

class P2PDevicePage: UIViewController {
    // B011003AU2747C253 30001 admin   1nner!Range
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = true

    private let scanAreaSize: CGFloat = 260

    private lazy var scanAreaView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var topOverlay: UIView = createOverlayView()
    private lazy var bottomOverlay: UIView = createOverlayView()
    private lazy var leftOverlay: UIView = createOverlayView()
    private lazy var rightOverlay: UIView = createOverlayView()

    private func createOverlayView() -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private lazy var scanLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupScanArea()
        setupResultLabel()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
        }
        isScanning = true
        if scanAreaView.bounds.width > 0 {
            scanLineView.layer.removeAllAnimations()
            startScanLineAnimation()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        if scanAreaView.bounds.width > 0, scanLineView.layer.animation(forKey: "scanLine") == nil {
            startScanLineAnimation()
        }
    }

    private func setupNavigationBar() {
        title = TKLocalizedString("TK_QRCode")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: TKLocalizedString("TK_Save"), style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationController?.navigationBar.tintColor = .black
    }

    private func setupScanArea() {
        view.addSubview(topOverlay)
        view.addSubview(bottomOverlay)
        view.addSubview(leftOverlay)
        view.addSubview(rightOverlay)
        view.addSubview(scanAreaView)
        scanAreaView.addSubview(scanLineView)
        view.bringSubviewToFront(scanAreaView)

        NSLayoutConstraint.activate([
            scanAreaView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            scanAreaView.widthAnchor.constraint(equalToConstant: scanAreaSize),
            scanAreaView.heightAnchor.constraint(equalToConstant: scanAreaSize)
        ])

        NSLayoutConstraint.activate([
            topOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            topOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlay.bottomAnchor.constraint(equalTo: scanAreaView.topAnchor),

            bottomOverlay.topAnchor.constraint(equalTo: scanAreaView.bottomAnchor),
            bottomOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            leftOverlay.topAnchor.constraint(equalTo: scanAreaView.topAnchor),
            leftOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftOverlay.trailingAnchor.constraint(equalTo: scanAreaView.leadingAnchor),
            leftOverlay.bottomAnchor.constraint(equalTo: scanAreaView.bottomAnchor),

            rightOverlay.topAnchor.constraint(equalTo: scanAreaView.topAnchor),
            rightOverlay.leadingAnchor.constraint(equalTo: scanAreaView.trailingAnchor),
            rightOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightOverlay.bottomAnchor.constraint(equalTo: scanAreaView.bottomAnchor)
        ])
    }

    private func layoutScanLine() {
        let lineHeight: CGFloat = 2
        scanLineView.frame = CGRect(x: 0, y: 0, width: scanAreaSize, height: lineHeight)
    }

    private func startScanLineAnimation() {
        scanLineView.layer.removeAllAnimations()
        layoutScanLine()
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = 1
        animation.toValue = scanAreaSize - 1
        animation.duration = 2.0
        animation.repeatCount = .infinity
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        scanLineView.layer.add(animation, forKey: "scanLine")
    }

    private func setupResultLabel() {
        view.addSubview(resultLabel)
        resultLabel.text = TKLocalizedString("TK_ScanQRCodeHint")
        view.bringSubviewToFront(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: scanAreaView.bottomAnchor, constant: 24),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startCameraSession()
                    } else {
                        self?.resultLabel.text = TKLocalizedString("TK_CameraPermissionDenied")
                    }
                }
            }
        default:
            resultLabel.text = TKLocalizedString("TK_CameraPermissionDenied")
        }
    }

    private func startCameraSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice),
              session.canAddInput(input) else {
            DispatchQueue.main.async { [weak self] in
                self?.resultLabel.text = TKLocalizedString("TK_CameraNotAvailable")
            }
            return
        }

        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preview, at: 0)

        captureSession = session
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func showScanResult(_ string: String) {
        guard isScanning else { return }
        isScanning = false
        captureSession?.stopRunning()
        resultLabel.text = string

        let scanResult = P2PScanResult(qrCode: string)
        let resultPage = P2PScanResultPage(scanResult: scanResult)
        navigationController?.pushViewController(resultPage, animated: true)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveButtonTapped() {
        // Save action: reserved.
    }
}

extension P2PDevicePage: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue else { return }
        showScanResult(stringValue)
    }
}
