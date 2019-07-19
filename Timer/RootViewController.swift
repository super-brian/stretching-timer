//
//  ViewControlleswift
//  Timer
//
//  Created by Sungil Hong on 6/15/19.
//  Copyright © 2019 WayStride. All rights reserved.
//

import UIKit
import AVFoundation

/*
1. get screen width and height.
2. adjust label height and font size.
3. show it!
*/

class RootViewController: UIViewController {
	
	var backgroundDate: Date?
	
	// screen size
	var screenWidth: CGFloat = -1
	var prevScreenWidth: CGFloat = -2
	var safeAreaWidth: CGFloat = -1
	
	// ui members
	
	@IBOutlet weak var hourLabel: UILabel!
	
	@IBOutlet weak var countLabel: UILabel!
	@IBOutlet weak var afterCountLabel: UILabel!
	@IBOutlet weak var exeLabel: UILabel!
	
	@IBOutlet weak var pauseButton: UIButton!
	
	@IBOutlet weak var batteryLabel: UILabel!
	
	
	// instance members
	var hour = 0
	var min = 0
	var sec = 0
	var alarmSec = 0
	var exe = 0
	
//	var timer: Timer?
	var totalWidth: CGFloat?
	var timer: Timer?
	
	var batteryLevel: String {
		
		return "\(Int(UIDevice.current.batteryLevel * 100))%"
	}
	
	// UI methods
	
	func processPauseButton() {
		
		if let t = timer {
			// pause button pressed.
			timer = nil
			t.invalidate()
			pauseButton.setTitle("Play", for: .normal)
			
			let pauseDate = Date()
			UserDefaults.standard.set(pauseDate, forKey: "pause_date")
			
		} else {
			// play button pressed. (or viewDidLoad() called this)
			
			// move start date as much as now - pauseDate.
			if let pauseDate = UserDefaults.standard.object(forKey: "pause_date") as? Date {
				let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
				let dateDiff = Date().timeIntervalSince1970 - pauseDate.timeIntervalSince1970
				let newStartDate = startDate.addingTimeInterval(dateDiff)
				UserDefaults.standard.set(newStartDate, forKey: "start_date")
			}
			
			timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
				
				self.setTimeVariables()
				self.showAndBeep()
			}
			pauseButton.setTitle("Pause", for: .normal)
		}
	}
	
	@IBAction func pauseButtonPressed(_ sender: UIButton) {
		
		processPauseButton()
	}
	
	// what if... reset is pressed while paused?
	@IBAction func resetButtonPressed(_ sender: UIButton) {
		
		// we save a new start date.
		let startDate = Date()
		UserDefaults.standard.set(startDate, forKey: "start_date")
		
		// reset execution count.
		exe = 0

		// show now.
		self.setTimeVariables()
		self.showAndBeep()
		
		// pause and play again.
		processPauseButton()
		if timer == nil {
			processPauseButton()
		}
	}
	
	// system methods
	
	/* make the timer resume when become foreground - as if it was counting while in background.
	for this, we save 'startDate' whenever timer starts afresh. */
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("\(getTimeMS()) viewWillAppear()")
		
		// get current date and save it.
		let startDate = Date()
		UserDefaults.standard.set(startDate, forKey: "start_date")
		
		// set time variables & show them.
		setTimeVariables()
		showAndBeep()
		
		// start timer that runs continuously.
		processPauseButton()
		
		// show battery percentage.
		UIDevice.current.isBatteryMonitoringEnabled = true
		batteryLabel.text = batteryLevel
	}
	
	func setTimeVariables() {
		
		// set time variables.
		let calendar = Calendar.current
		let nowDate = Date()
		
		hour = calendar.component(.hour, from: nowDate)
		min  = calendar.component(.minute, from: nowDate)
		sec  = calendar.component(.second, from: nowDate)
		
		let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
		alarmSec = Int(nowDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("\(getTimeMS()) viewWillAppear()")
	}

	@available(iOS 11.0, *)
	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		
		screenWidth = UIScreen.main.bounds.width
		let leftSafeAreaHeight = view.safeAreaInsets.left
		let rightSafeAreaHeight = view.safeAreaInsets.right

		safeAreaWidth = screenWidth - leftSafeAreaHeight - rightSafeAreaHeight
		
		print("\(getTimeMS()) viewSafeAreaInsetsDidChange(): orientation \(UIDevice.current.orientation.isLandscape ? "landscape" : "portrait") screenWidth \(screenWidth) leftSafeAreaHeight \(leftSafeAreaHeight) rightSafeAreaHeight \(rightSafeAreaHeight) safeAreaWidth \(safeAreaWidth)")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if totalWidth == nil {
			totalWidth = hourLabel.intrinsicContentSize.width
			
			print("\(getTimeMS()) viewDidLayoutSubviews(): totalWidth: \(totalWidth!)")
		}
		
		if screenWidth == -1 {
			screenWidth = UIScreen.main.bounds.width
			let leftSafeAreaHeight = view.safeAreaInsets.left
			let rightSafeAreaHeight = view.safeAreaInsets.right
			
			safeAreaWidth = screenWidth - leftSafeAreaHeight - rightSafeAreaHeight
			
			print("\(getTimeMS()) viewDidLayoutSubviews(): orientation \(UIDevice.current.orientation.isLandscape ? "landscape" : "portrait") screenWidth \(screenWidth) leftSafeAreaHeight \(leftSafeAreaHeight) rightSafeAreaHeight \(rightSafeAreaHeight) safeAreaWidth \(safeAreaWidth)")
		}
		
		if screenWidth != prevScreenWidth {
			prevScreenWidth = screenWidth
			changeFontSize()
		}
	}
	
	// monospace font: see https://stackoverflow.com/a/22620172/8963597
	func changeFontSize() {
		
		let fontSize: CGFloat = 100.0 * safeAreaWidth / totalWidth!
		
		hourLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		
		countLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		afterCountLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		exeLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		
		print("\(getTimeMS()) changeFontSize(): \(fontSize)")
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print("\(getTimeMS()) viewDidAppear()")
		
		// keep screen on.
		UIApplication.shared.isIdleTimerDisabled = true

		NotificationCenter.default.addObserver(self, selector: #selector(becomeBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(becomeForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
	}
	
	@objc func batteryLevelDidChange(_ notification: Notification) {
		
		batteryLabel.text = batteryLevel
	}
	
	@objc func becomeBackground() {
		
		print("\(getTimeMS()) becomeBackground()")

		// we save background date.
		backgroundDate = Date()

		foregroundWork = true;
	}
	
	var foregroundWork = false;
	
	@objc func becomeForeground() {
		
		print("\(getTimeMS()) becomeForeground()")
		
		// when become foreground, we calculate the time difference.
		if let bDate = backgroundDate {
			let diffSec = Date().timeIntervalSince1970 - bDate.timeIntervalSince1970
			// then apply to the startDate.
			let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
			let newDate = Date(timeIntervalSince1970: startDate.timeIntervalSince1970 + diffSec)
			UserDefaults.standard.set(newDate, forKey: "start_date")
		}
		
		foregroundWork = false;
	}
	
	func showAndBeep() {
		
		// alarm beeps every 30 seconds
		if alarmSec % 30 == 0 {
			AudioServicesPlayAlertSound(SystemSoundID(1322))
			if alarmSec % 60 != 0 {
				exe += 1
				
				// start resting cycle.
				countLabel.textColor = UIColor.white
				
			} else {
				// start exercise cycle.
				countLabel.textColor = UIColor.green
			}
		}
		
		DispatchQueue.main.async {
			
			self.showLabels()
		}
	}
	
	func showLabels() {
		
		print("\(getTimeMS()) showLabels()")
		
		guard foregroundWork == false else {
			return
		}
		
		hourLabel.text = getWith0(hour) + ":" + getWith0(min) + ":" + getWith0(sec)
		
		// show min:sec format...
		countLabel.text = String(alarmSec % 30)
		exeLabel.text = String(exe)
	}
	
	func getWith0(_ unit: Int) -> String {
		
		if unit < 10 {
			return "0\(unit)"
		} else {
			return String(unit)
		}
	}
	
	func getTimeMS(_ date: Date = Date()) -> String {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "y-MM-dd HH:mm:ss.SSS"
		let res = dateFormatter.string(from: date)
		
		return res
	}
}

