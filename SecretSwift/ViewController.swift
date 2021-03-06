//
//  ViewController.swift
//  SecretSwift
//
//  Created by Paul Richardson on 17/06/2021.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

	@IBOutlet var secret: UITextView!
	var doneButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Nothing to see here"

		doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))

		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
	}

	@IBAction func authenticateTapped(_ sender: Any) {
		let context = LAContext()
		var error: NSError?
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Identify yourself!") { [weak self] success, authenticationError in
				DispatchQueue.main.async {
					if success {
						self?.unlockSecretMessage()
					} else {
						if let error = authenticationError {
							switch error._code {
							case LAError.Code.userCancel.rawValue:
								break
							default:
								let ac = UIAlertController(title: "Authentication failed", message: "Your identity could not be verified: please try again.", preferredStyle: .alert)
								ac.addAction(UIAlertAction(title: "OK", style: .default))
								self?.present(ac, animated: true)
							}
						}
					}
				}
			}
		} else {
			authenticateWithPassword()
		}
	}

	func authenticateWithPassword() {
		let passwordKey = "SecretPassword"
		if let password = KeychainWrapper.standard.string(forKey: passwordKey) {
			let ac = UIAlertController(title: "Authenticate with password", message: "Please enter your password.", preferredStyle: .alert)
			ac.addTextField()
			ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] action in
				if let answer = ac.textFields?[0].text, answer == password {
					self?.unlockSecretMessage()
				} else {
					// TODO: authentication failed
				}
			})
			present(ac, animated: true)
		} else {
			// TODO: Enable Biometry or use a password?
			// if use a password
			let ac = UIAlertController(title: "Authenticate with password", message: "Please enter a new password.", preferredStyle: .alert)
			ac.addTextField()
			ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] action in
				if let password = ac.textFields?[0].text, !password.isEmpty {
					KeychainWrapper.standard.set(password, forKey: passwordKey)
					self?.unlockSecretMessage()
				} else {
					// TODO: no password provided
				}
			})
			present(ac, animated: true)
			// else enable biometry
		}
	}

	@objc func adjustForKeyboard(notification: Notification) {
		guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

		let keyboardScreenEndFrame = keyboardValue.cgRectValue
		let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

		if notification.name == UIResponder.keyboardWillHideNotification {
			secret.contentInset = .zero
		} else {
			secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
		}
		secret.scrollIndicatorInsets = secret.contentInset

		let selectedRange = secret.selectedRange
		secret.scrollRangeToVisible(selectedRange)
	}

	func unlockSecretMessage() {
		secret.isHidden = false
		navigationItem.setRightBarButton(doneButton, animated: true)
		title = "Secret Stuff"
		secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
	}

	@objc func saveSecretMessage() {
		guard secret.isHidden == false else { return }

		KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
		secret.resignFirstResponder()
		secret.isHidden = true
		navigationItem.setRightBarButton(nil, animated: true)
		title = "Nothing to see here"
	}
}

