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
	
	// static members
	
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
	
	// instance members
	var hour = 0
	var min = 0
	var sec = 0
	var alarmSec = 0
	var exe = 0
	
//	var timer: Timer?
	var totalWidth: CGFloat?
	var timer: Timer?
	
	// UI methods
	
	func processPauseButton() {
		
		if let t = timer {
			timer = nil
			t.invalidate()
			pauseButton.setTitle("Play", for: .normal)
			
		} else {
			timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
				
				self.updateCounting()
			}
			pauseButton.setTitle("Pause", for: .normal)
		}
	}
	
	@IBAction func pauseButtonPressed(_ sender: UIButton) {
		
		processPauseButton()
	}
	
	@IBAction func resetButtonPressed(_ sender: UIButton) {
		
		if let t = timer {
			// was playing
			timer = nil
			t.invalidate()
			
		}
		
		processPauseButton()

		exe = 0
		becomeForeground()
	}
	
	// system methods
	
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
		
		becomeForeground()
		showLabels()

		processPauseButton()

		NotificationCenter.default.addObserver(self, selector: #selector(becomeForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
	}
	
	@objc func becomeForeground() {
		
		let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
		hour = now.hour!
		min = now.minute!
		sec = now.second! - 1
		
		// alarm starts after 5 seconds.
		alarmSec = -5

		// start resting cycle.
		countLabel.textColor = UIColor.white

		// in order to correct hou
		updateCounting()
	}
	
	@objc func updateCounting() {
		
		sec += 1
		if sec == 60 {
			sec = 0
			min += 1
		}
		if min == 60 {
			min = 0
			hour += 1
		}
		if hour > 12 {
			hour -= 12
		}
		
		alarmSec += 1
		
		// alarm beeps every 30 minutes.
		if alarmSec % (30 * 60) == 0 {
			AudioServicesPlayAlertSound(SystemSoundID(1322))
			if alarmSec % (60 * 60) != 0 {
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
	
	func getWith0(_ unit: Int) -> String {
		
		if unit < 10 {
			return "0\(unit)"
		} else {
			return String(unit)
		}
	}
	
	func showLabels() {
		
		hourLabel.text = getWith0(hour) + ":" + getWith0(min) + ":" + getWith0(sec)
		
		// show min:sec format...
		let secs = alarmSec % (30 * 60)
		let min = Int(secs / 60)
		let sec = secs - min * 60
		countLabel.text = "\(min):\(sec)"
		exeLabel.text = String(exe)
	}
	
	func getTimeMS(_ date: Date = Date()) -> String {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "y-MM-dd HH:mm:ss.SSS"
		let res = dateFormatter.string(from: date)
		
		return res
	}
}

