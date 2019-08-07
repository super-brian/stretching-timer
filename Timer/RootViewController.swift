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
	var prevScreenWidth: CGFloat = -2
	
	var hourLabelInitialWidth: CGFloat = -1
	var hourLabelInitialHeight: CGFloat = -1
	
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
	
	var beefInterval = 30
	
	var totalWidth: CGFloat?
	var timer: Timer?
	
	var isPaused = false
	
	var batteryLevel: String {
		
		return "\(Int(UIDevice.current.batteryLevel * 100))%"
	}
	
	// UI methods
	@IBAction func pauseButtonPressed(_ sender: UIButton) {
		
		if let label = sender.titleLabel?.text, label == "Pause" {
			// pause button pressed.
			
			isPaused = true
			
			let pauseDate = Date()
			UserDefaults.standard.set(pauseDate, forKey: "pause_date")
			
			pauseButton.setTitle("Play", for: .normal)
			
		} else {
			// play button pressed. (or viewDidLoad() called this)
			
			// move start date as much as now - pauseDate.
			if let pauseDate = UserDefaults.standard.object(forKey: "pause_date") as? Date {
				let dateDiff = Date().timeIntervalSince1970 - pauseDate.timeIntervalSince1970
				print("pauseButtonPressed(): dateDiff: \(dateDiff)")
				
				let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
				let newStartDate = startDate.addingTimeInterval(dateDiff)
				UserDefaults.standard.set(newStartDate, forKey: "start_date")
				UserDefaults.standard.removeObject(forKey: "pause_date")
			}

			isPaused = false
			
			pauseButton.setTitle("Pause", for: .normal)
		}
	}
	
	// what if... reset is pressed while paused?
	@IBAction func resetButtonPressed(_ sender: UIButton) {
		
		resetDefaults()
	}
	
	@IBAction func modeSwitchPressed(_ sender: UISwitch) {
		
		if sender.isOn {
			beefInterval = 30 * 60
			
		} else {
			beefInterval = 30
		}
		
		// need to reset all values.
		resetDefaults()
	}

	// system methods
	
	/* make the timer resume when become foreground - as if it was counting while in background.
	for this, we save 'startDate' whenever timer starts afresh. */
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("\(getTimeMS()) viewWillAppear()")
		
//		hourLabel.adjustsFontSizeToFitWidth = true
//		hourLabel.minimumScaleFactor = 10 / UIFont.labelFontSize
		
		// initialize and show first time.
		resetDefaults()
		
		// start timer
		startTimer()
		
		// show battery percentage.
		UIDevice.current.isBatteryMonitoringEnabled = true
		batteryLabel.text = batteryLevel
	}
	
	// from viewDidLoad(), resetButtonPressed()
	func resetDefaults() {
		
		// we save a new start date.
		UserDefaults.standard.set(Date(), forKey: "start_date")
		UserDefaults.standard.removeObject(forKey: "pause_date")
		
		// reset execution count.
		exe = 0
		
		// show now.
		self.setTimeAndShow()
		self.setAlarmSecAndBeepShow()
	}
	
	func setTimeAndShow() {
		
		// set time variables.
		let calendar = Calendar.current
		let nowDate = Date()
		
		hour = calendar.component(.hour, from: nowDate)
		min  = calendar.component(.minute, from: nowDate)
		sec  = calendar.component(.second, from: nowDate)
		
		DispatchQueue.main.async {
			
			self.showTime()
		}
	}
	
	func showTime() {
		
		guard isInBackground == false else {
			return
		}
		
		hourLabel.text = getWith0(hour) + ":" + getWith0(min) + ":" + getWith0(sec)
	}
	
	func setAlarmSecAndBeepShow() {
		
		let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
		alarmSec = Int(Date().timeIntervalSince1970 - startDate.timeIntervalSince1970)
		
		// alarm beeps every beefInterval seconds
		if alarmSec % beefInterval == 0 {
			AudioServicesPlayAlertSound(SystemSoundID(1322))
			if alarmSec % (beefInterval * 2) != 0 {
				exe += 1
				
				// start resting cycle.
				countLabel.textColor = UIColor.white
				
			} else {
				// start exercise cycle.
				countLabel.textColor = UIColor.green
			}
		}
		
		DispatchQueue.main.async {
			
			self.showAlarmSec()
		}
	}
	
	func showAlarmSec() {
		
		guard isInBackground == false else {
			return
		}
		
		// show min:sec format...
		countLabel.text = String(alarmSec % beefInterval)
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
	
	func startTimer() {
		
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
			
			self.setTimeAndShow()
			if self.isPaused == false {
				self.setAlarmSecAndBeepShow()
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("\(getTimeMS()) viewWillAppear()")
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let screenWidth = UIScreen.main.bounds.width
		
		// avoid being called multiple times when orientation changes.
		if screenWidth != prevScreenWidth {
			// save new value to previous variable.
			prevScreenWidth = screenWidth
			let leftSafeAreaWidth = view.safeAreaInsets.left
			let rightSafeAreaWidth = view.safeAreaInsets.right
			let safeAreaWidth = screenWidth - leftSafeAreaWidth - rightSafeAreaWidth
			
			print("\(getTimeMS()) viewDidLayoutSubviews(): orientation \(UIDevice.current.orientation.isLandscape ? "landscape" : "portrait") screenWidth \(screenWidth) leftSafeAreaWidth \(leftSafeAreaWidth) rightSafeAreaWidth \(rightSafeAreaWidth) safeAreaWidth \(safeAreaWidth)")

			let screenHeight = UIScreen.main.bounds.height
			let topSafeAreaHeight = view.safeAreaInsets.top
			let bottomSafeAreaHeight = view.safeAreaInsets.bottom
			let safeAreaHeight = screenHeight - topSafeAreaHeight - bottomSafeAreaHeight

			print("\(getTimeMS()) viewDidLayoutSubviews(): screenHeight \(screenHeight) topSafeAreaHeight \(topSafeAreaHeight) bottomSafeAreaHeight \(bottomSafeAreaHeight) safeAreaHeight \(safeAreaHeight)")

			// get values only one time since opening this app.
			if hourLabelInitialWidth < 0 {
				hourLabelInitialWidth = hourLabel.intrinsicContentSize.width
				hourLabelInitialHeight = hourLabel.intrinsicContentSize.height
				print("\(getTimeMS()) viewDidLayoutSubviews(): hourLabelInitialWidth: \(hourLabelInitialWidth)")
			}
			
			// we need to get the right font size considering width and height.
			// get font size based on width.
			var fontSize: CGFloat = 50.0 * safeAreaWidth / hourLabelInitialWidth
			// get height using this font size.
			let totalHeight: CGFloat = hourLabelInitialHeight / 50.0 * fontSize * 2 + 60
			// if this height is bigger than screen height,adjust font size again.
			if totalHeight > safeAreaHeight {
				// need to decrease font size.
				fontSize = 50 / hourLabelInitialHeight * (safeAreaHeight - 60) / 2
			}
			
			// monospace font: see https://stackoverflow.com/a/22620172/8963597
			hourLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
			
			// same size to row 2 labels.
			countLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
			afterCountLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
			exeLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
			
			print("\(getTimeMS()) viewDidLayoutSubviews(): new font size: \(fontSize)")
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print("\(getTimeMS()) viewDidAppear()")
		
		// keep screen on.
		UIApplication.shared.isIdleTimerDisabled = true

		// background
		NotificationCenter.default.addObserver(self, selector: #selector(becomeBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		
		// foreground
		NotificationCenter.default.addObserver(self, selector: #selector(becomeForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		
		// battery level
		NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
	}
	
	@objc func batteryLevelDidChange(_ notification: Notification) {
		
		batteryLabel.text = batteryLevel
	}
	
	@objc func becomeBackground() {
		
		isInBackground = true;

		// we save background date.
		backgroundDate = Date()

	}
	
	var isInBackground = false;
	
	@objc func becomeForeground() {
		
		// when become foreground, we adjust start_date.
		if let bDate = backgroundDate {
			let dateDiff = Date().timeIntervalSince1970 - bDate.timeIntervalSince1970
			print("becomeForeground(): dateDiff: \(dateDiff)")
			
			// then adjust startDate
			let startDate = UserDefaults.standard.object(forKey: "start_date") as! Date
			let newStartDate = startDate.addingTimeInterval(dateDiff)
			UserDefaults.standard.set(newStartDate, forKey: "start_date")
			backgroundDate = nil
			
			// also adjust pauseDate
			if let pauseDate = UserDefaults.standard.object(forKey: "pause_date") as? Date {
				let newPauseDate = pauseDate.addingTimeInterval(dateDiff)
				UserDefaults.standard.set(newPauseDate, forKey: "pause_date")
			}
		}
		
		isInBackground = false;
	}
}

