//
//  ViewController.swift
//  CodeScanner
//
//  Created by John Ayres on 5/3/21.
//
//  Copyright © 2023 John Ayres. Licensed under MIT License.

import UIKit
//import Vision
import AVFoundation

/**
 The primary view controller for the application.
 */
class ViewController: UIViewController {
    
    // MARK: - Action Handlers
    
    /// Handler for the "Get Started!" button.
    @IBAction func getStartedButtonTouched(_ sender: Any) {
        displayCodeScanner()
    }
    
    
    // MARK: - Private Methods
    
    /// Displays the scanning interface
    private func displayCodeScanner() {
        // warn if running in the simulator
        #if targetEnvironment(simulator)

        print("This does not work in the simulator, you must run this on a physical device.")

        #else

        // Here we're checking for authorization to access the camera. This is segregated from the CodeScanner class as it should not be responsible for
        // checking permissions (it should only be scanning for codes). In a production app, this section would be in its own class, possibly a convenience
        // wrapper over the CodeScanner so that callers wouldn't need to perform the authorization check first.
        
        // If the user has not fully authorized use of the camera, we provide a link to the Settings where the user can turn this on.
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            proceedWithScannerDisplay()

        case .denied:
            let alert = UIAlertController(title: "Access Denied", message: "This app is unable to access the camera. Please turn on camera access in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }))

            present(alert, animated: true)

        case .restricted:
            let alert = UIAlertController(title: "Access Restricted", message: "This app is unable to access the camera. Please turn on camera access in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }))

            present(alert, animated: true)

        default:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self?.proceedWithScannerDisplay()
                    }
                }
            }
        }

        #endif
    }
    
    
    // MARK: - Private Methods
    
    /// Displays the barcode scanner view.
    private func proceedWithScannerDisplay() {
        let scanner = CodeScanner()
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: false)
    }
}
