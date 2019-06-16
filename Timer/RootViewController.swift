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
	@IBOutlet weak var afterHourLabel: UILabel!
	
	@IBOutlet weak var minLabel: UILabel!
	@IBOutlet weak var afterMinLabel: UILabel!
	
	@IBOutlet weak var secLabel: UILabel!
	
	@IBOutlet weak var countLabel: UILabel!
	@IBOutlet weak var exeLabel: UILabel!
	
	// instance members
	var hour = 0
	var min = 0
	var sec = 0
	var alarmSec = 0
	var exe = 0
	
//	var timer: Timer?
	var totalWidth: CGFloat?
	
	// system methods
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("\(getTimeMS()) viewWillAppear()")
	}

	
	@available(iOS 11.0, *)
	override func viewSafeAreaInsetsDidChange() {
		
		screenWidth = UIScreen.main.bounds.width
		let leftSafeAreaHeight = view.safeAreaInsets.left
		let rightSafeAreaHeight = view.safeAreaInsets.right

		safeAreaWidth = screenWidth - leftSafeAreaHeight - rightSafeAreaHeight
		
		print("\(getTimeMS()) viewSafeAreaInsetsDidChange(): orientation \(UIDevice.current.orientation.isLandscape ? "landscape" : "portrait") screenWidth \(screenWidth) leftSafeAreaHeight \(leftSafeAreaHeight) rightSafeAreaHeight \(rightSafeAreaHeight) safeAreaWidth \(safeAreaWidth)")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if totalWidth == nil {
			totalWidth = hourLabel.intrinsicContentSize.width +
				afterHourLabel.intrinsicContentSize.width +
				minLabel.intrinsicContentSize.width +
				afterMinLabel.intrinsicContentSize.width +
				secLabel.intrinsicContentSize.width
			
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
		afterHourLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		minLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		afterMinLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		secLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		
		countLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		exeLabel.font = UIFont(name: "Menlo-Bold", size: fontSize)
		
		print("\(getTimeMS()) changeFontSize(): \(fontSize)")
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print("\(getTimeMS()) viewDidAppear()")
		
		becomeForeground()
		showLabels()

		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
			
			self.updateCounting()
		}

		NotificationCenter.default.addObserver(self, selector: #selector(becomeForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
	}
	
	@objc func becomeForeground() {
		
		let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
		hour = now.hour!
		min = now.minute!
		sec = now.second! - 1
		
		// alarm starts after 5 seconds.
		alarmSec = -5

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
		
		// alarm beeps every 30 seconds.
		if alarmSec % 30 == 0 {
			AudioServicesPlayAlertSound(SystemSoundID(1322))
			if alarmSec % 60 != 0 {
				exe += 1
			}
		}
		
		DispatchQueue.main.async {
			
			self.showLabels()
		}
	}
	
	func showLabels() {
		
		if hour < 10 {
			hourLabel.text = "0\(hour)"
		} else {
			hourLabel.text = String(hour)
		}
		
		if min < 10 {
			minLabel.text = "0\(min)"
		} else {
			minLabel.text = String(min)
		}
		
		if sec < 10 {
			secLabel.text = "0\(sec)"
			
		} else {
			secLabel.text = String(sec)
		}
		
		countLabel.text = String(alarmSec % 30)
		exeLabel.text = String(exe)
	}
	
	func getTimeMS(_ date: Date = Date()) -> String {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "y-MM-dd HH:mm:ss.SSS"
		let res = dateFormatter.string(from: date)
		
		return res
	}
}

