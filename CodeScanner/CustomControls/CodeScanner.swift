//
//  CodeScanner.swift
//  CodeScanner
//
//  Created by John Ayres on 12/27/23.
//
//  Copyright © 2023 John Ayres. Licensed under MIT License.

import UIKit
import AVFoundation

/**
 A dead simple barcode and QR code scanning class that displays a live video feed and the encoded data of any recognized code.
 */
class CodeScanner: UIViewController {

    // MARK: - Private Properties
    
    /// The live video preview layer.
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// The capture session controlling when codes are scanned.
    private var captureSession: AVCaptureSession = {
        let createdCaptureSession = AVCaptureSession()
        createdCaptureSession.sessionPreset = .high
        return createdCaptureSession
    }()
    
    /// The code type label, displaying what type of code is scanned (i.e. QR, UPCE, etc.).
    private var codeType: UILabel = {
        let codeTypeLabel = UILabel()
        codeTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeTypeLabel.font = codeTypeLabel.font.withSize(20)
        codeTypeLabel.text = "Code Type: "
        codeTypeLabel.textColor = .white
        return codeTypeLabel
    }()
    
    /// The code data label, displaying the decoded information contained within the code.
    private var codeData: UILabel = {
        let codeDataLabel = UILabel()
        codeDataLabel.translatesAutoresizingMaskIntoConstraints = false
        codeDataLabel.font = codeDataLabel.font.withSize(20)
        codeDataLabel.text = "Data: "
        codeDataLabel.numberOfLines = 0
        codeDataLabel.textColor = .white
        return codeDataLabel
    }()
    
    /// A simple colored rectangle that indicates the recognized code.
    private var overlay: UIView = {
        let overlayView = UIView()
        overlayView.layer.borderWidth = 2.0
        overlayView.layer.borderColor = UIColor.green.cgColor
        overlayView.layer.backgroundColor = UIColor.clear.cgColor
        overlayView.alpha = 0.0
        return overlayView
    }()
    
    /// A 'reticle' that displays a simple shape within which codes are scanned.
    private var scanWindow: PartialRectangleView = {
        let scanWindowView = PartialRectangleView()
        scanWindowView.translatesAutoresizingMaskIntoConstraints = false
        scanWindowView.backgroundColor = .clear
        return scanWindowView
    }()
    
    /// A darkened area at the top of the UI with instructions.
    private var instructions: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        backgroundView.isOpaque = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        let createdInstructionLabel = UILabel()
        createdInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        createdInstructionLabel.font = createdInstructionLabel.font.withSize(20)
        createdInstructionLabel.text = "Position bar or QR code within rectangle to scan"
        createdInstructionLabel.numberOfLines = 0
        createdInstructionLabel.textColor = .white
        createdInstructionLabel.textAlignment = .center

        backgroundView.addSubview(createdInstructionLabel)
        
        NSLayoutConstraint.activate([
            createdInstructionLabel.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 20),
            createdInstructionLabel.rightAnchor.constraint(equalTo: backgroundView.rightAnchor, constant: -20),
            createdInstructionLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: 20)
        ])
        
        return backgroundView
    }()
    
    /// A darkened area at the bottom of the UI that displays the code type and encoded information.
    private var codeInfo: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        backgroundView.isOpaque = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
                        
        return backgroundView
    }()
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // start by creating the capture device
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showAlert(withTitle: "Error", message: "Unable to create capture device")
            return
        }
        
        // a capture session needs an input and an output
        let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        let captureMetaDataOutput = AVCaptureMetadataOutput()
        
        // the capture device input is required
        guard let captureDeviceInput = captureDeviceInput else {
            showAlert(withTitle: "Error", message: "Unable to create capture device input")
            return
        }
        
        // if we can't add the input device, don't proceed
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        } else {
            showAlert(withTitle: "Error", message: "Unable to add capture device input")
            return
        }
        
        // a convenient list of all code types to be recognized
        let availableCodeTypes: [AVMetadataObject.ObjectType] = [.upce, .code39Mod43, .ean13, .ean8, .code93, .code128, .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix, .code39, .codabar, .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited, .microQR, .microPDF417]
        
        // if we can't add the output, don't proceed
        if captureSession.canAddOutput(captureMetaDataOutput) {
            captureSession.addOutput(captureMetaDataOutput)
            captureMetaDataOutput.setMetadataObjectsDelegate(self, queue: .main)
            captureMetaDataOutput.metadataObjectTypes = availableCodeTypes
        } else {
            showAlert(withTitle: "Error", message: "Unable to add capture metadata output")
            return
        }
        
        // create the preview layer and add it to the view
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.frame = view.layer.bounds
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = .portrait
        
        if let cameraPreviewLayer = cameraPreviewLayer {
            view.layer.addSublayer(cameraPreviewLayer)
        }
        
        // add the rest of the UI to the view
        codeInfo.addSubview(codeType)
        codeInfo.addSubview(codeData)
        view.addSubview(overlay)
        view.addSubview(scanWindow)
        view.addSubview(instructions)
        view.addSubview(codeInfo)
        
        // setup appropriate constraints
        NSLayoutConstraint.activate([
            instructions.topAnchor.constraint(equalTo: view.topAnchor),
            instructions.leftAnchor.constraint(equalTo: view.leftAnchor),
            instructions.rightAnchor.constraint(equalTo: view.rightAnchor),
            instructions.bottomAnchor.constraint(equalTo: scanWindow.topAnchor, constant: -150),
            scanWindow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanWindow.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanWindow.widthAnchor.constraint(equalToConstant: view.frame.width * 0.8),
            scanWindow.heightAnchor.constraint(equalTo: scanWindow.widthAnchor, constant: 1),
            codeInfo.topAnchor.constraint(equalTo: scanWindow.bottomAnchor, constant: 100),
            codeInfo.leftAnchor.constraint(equalTo: view.leftAnchor),
            codeInfo.rightAnchor.constraint(equalTo: view.rightAnchor),
            codeInfo.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            codeType.topAnchor.constraint(equalTo: codeInfo.topAnchor, constant: 20),
            codeType.leftAnchor.constraint(equalTo: codeInfo.leftAnchor, constant: 20),
            codeData.topAnchor.constraint(equalTo: codeType.bottomAnchor, constant: 10),
            codeData.leftAnchor.constraint(equalTo: codeInfo.leftAnchor, constant: 20),
            codeData.rightAnchor.constraint(equalTo: codeInfo.rightAnchor, constant: -20)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // begin capturing codes when the view appears
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // stop capturing codes when the view disappears
        stopCaptureSession()
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: - Private Methods
    
    /// Starts the capture session if it is not running. The capture session needs to be run on a background thread.
    private func startCaptureSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    /// Stops the capture session if it is running.
    private func stopCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    /// A convenience method to simplify showing error messages.
    private func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}


// MARK: - AVCaptureMetadataOutputObjectsDelegate Implementation

/**
 Implements required methods that receive recognized objects from the vision system.
 */
extension CodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        overlay.alpha = 0.0
        codeType.text = "Code Type: "
        codeData.text = "Data: "

        if let metadataObject = metadataObjects.first, let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject {
            if let recognizedObject = cameraPreviewLayer!.transformedMetadataObject(for: codeObject) {
                overlay.frame = recognizedObject.bounds
                overlay.alpha = 1.0
                overlay.layer.borderColor = UIColor.green.cgColor
                
                if scanWindow.frame.contains(recognizedObject.bounds) {
                    codeType.text = "Code Type: " + (codeObject.type.rawValue.components(separatedBy: ".").last ?? "")
                    codeData.text = "Data: " + (codeObject.stringValue ?? "")
                } else {
                    overlay.layer.borderColor = UIColor.red.cgColor
                }
            }
        }
    }
}
