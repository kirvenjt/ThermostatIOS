
//
//  thermostatViewController.swift
//  SimpleThermostat
//
//  Created by Tucker Kirven on 3/25/15.
//  Copyright (c) 2015 Tucker Kirven. All rights reserved.
//

import Foundation
import UIKit

class thermostatViewController: UIViewController {

    // allows View controller to access shared schedule and communication interface
    var appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    //holds weekly schedule to be accessed by view and updated by the users actions
    var sched: schedule?

    //keeps touches from causing unwanted actions while in the settings popup
    var touchMask = false
    
    //navigation buttons
    @IBOutlet weak var scheduleButton: UIButton!
    @IBOutlet weak var thermostatButton: UIButton!
    
    //HVAC Displays
    var heatingCoolingViewStrip = UIView()
    var heatingCoolingLabel = UILabel()
    
    var homeTempBigView = UIView()
    var homeTempLabel = UILabel()
    var currentTempLabel = UILabel()
    
    var statusViewStrip = UIView()
    var statusLabel = UILabel()
    
    //Current set status displays and controls
    var setPointBigView = UIView()
    var setPointLabel = UILabel()
    var setToLabel = UILabel()
    var minusButton = UIButton()
    var plusButton = UIButton()
    
    // settings popup items
    var greyOut = UIView()
    var settingsBigView = UIView()
    var settingHouseTempLabel = UILabel()
    var minusButtonHouseTemp = UIButton()
    var plusButtonHouseTemp = UIButton()
    var settingsLabel = UILabel()
    
    @IBOutlet weak var settingsButton: UIButton!
    
    //set Point adjuster
    func plusClick(sender: UIButton!)
    {
        sched!.increaseSetPoint()
        sched!.setSetPointTemporary()
        appDelegate.connection!.sendSchedule()
        
        updateView()
    }
    
    //set Point adjuster
    func minusClick(sender: UIButton!)
    {
        sched!.decreaseSetPoint()
        sched!.setSetPointTemporary()
        appDelegate.connection!.sendSchedule()
        
        updateView()
    }
    
    //demo settings - temp adjuster
    func plusClickSettings(sender: UIButton!)
    {
        sched!.setTemp(sched!.currentHomeTemp + 1)
       
        
        updateView()
    }
    
    //demo settings - temp adjuster
    func minusClickSettings(sender: UIButton!)
    {
         sched!.setTemp(sched!.currentHomeTemp - 1)
       updateView()
    }
    
    //shows demo settings pop up
    @IBAction func settingsClick(sender: AnyObject) {
        settingsShow()
    }
    
    
    override func viewDidLoad() {
       super.viewDidLoad()
        appDelegate.currVC = self
        sched = appDelegate.sched
        self.view.backgroundColor = JTKColors().backgroundColor
        
        scheduleButton.backgroundColor = JTKColors().orangeDark
        thermostatButton.backgroundColor = JTKColors().orangeLight
        
        settingsButton.setImage(UIImage(named: "settings18"), forState: .Normal)
        
        bigViewsSetup()     //programmatic autolayout setup for views containing HVAC and schedule info
        hometempInternals() //current home temp and HVAC status view internals setup
        setPointInternals() //set point and schedule status view internals setup
        settingsSetup()     // demo settings view setup
        settingsHide()      // hides settings view
        
        sched?.updateCurrent() // updates with most recent HVAC and schedule info
        updateView()
        
        //continuosly updates thermosat view bases on the thermostat temp and schedule
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            while true {
                sleep(1)
                self.sched?.updateCurrent()
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateView()
                }
            }
        }
        
        //Background thread to keep wall device time synced
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            while true {
                self.appDelegate.connection!.setTime(self.sched!.getTime())
                sleep(500)
            }
        }
    }
    
    //sets up View for Demo Settings
    func settingsSetup(){
         var constStrings = Array<String>()
        
        constStrings.append("H:|[settingsBigView]-50-|")
        constStrings.append("V:|-400-[settingsBigView]|")
        constStrings.append("H:|[greyOut]|")
        constStrings.append("V:|[greyOut]|")
        constStrings.append("H:|[settingsLabel]|")
        constStrings.append("V:|[settingsLabel]")
        constStrings.append("H:|[houseTempLabelSetting][minusButtonHouseTemp]-5-|")
        constStrings.append("H:|[settingsHouseTempLabel][plusButtonHouseTemp]-5-|")
        constStrings.append("V:|-12-[plusButtonHouseTemp][minusButtonHouseTemp]-5-|")
        constStrings.append("V:|-10-[settingsHouseTempLabel][houseTempLabelSetting]|")
        
        var justTempLabel = UILabel()
        var views1 = ["settingsBigView":settingsBigView,
            "greyOut":greyOut,]
        var views2 = [
            "settingsLabel":settingsLabel,
            "houseTempLabelSetting":justTempLabel,
            "settingsHouseTempLabel":settingHouseTempLabel,
            "minusButtonHouseTemp":minusButtonHouseTemp,
            "plusButtonHouseTemp":plusButtonHouseTemp]
        var views3 = ["settingsBigView":settingsBigView,
            "settingsLabel":settingsLabel,
            "greyOut":greyOut,
            "houseTempLabelSetting":justTempLabel,
            "settingsHouseTempLabel":settingHouseTempLabel,
            "minusButtonHouseTemp":minusButtonHouseTemp,
            "plusButtonHouseTemp":plusButtonHouseTemp]
        
        for view1 in views1{
            view1.1.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(view1.1)
        }
        for view1 in views2{
            view1.1.setTranslatesAutoresizingMaskIntoConstraints(false)
            settingsBigView.addSubview(view1.1)
        }
        view.insertSubview(settingsBigView, aboveSubview: greyOut)
        
        settingHouseTempLabel.text = String(appDelegate.sched!.currentHomeTemp)
        settingHouseTempLabel.font = UIFont(name: settingHouseTempLabel.font.fontName, size: 70)
        settingHouseTempLabel.textAlignment = NSTextAlignment.Center
        
        justTempLabel.text = "Home temp"
        justTempLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        justTempLabel.textAlignment = NSTextAlignment.Center
        settingsBigView.backgroundColor = JTKColors().orangeDark
        greyOut.backgroundColor = JTKColors().darkerGrey
        greyOut.alpha = 0.8
        settingsLabel.text = "Demo Settings"
        
        for constraint in Range(start: 0, end: constStrings.count){
            let constraintArr:Array = NSLayoutConstraint.constraintsWithVisualFormat(constStrings[constraint],
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: views3)
            
            view.addConstraints(constraintArr)
        }
        
        plusButtonHouseTemp.setImage(UIImage(named: "PlusImage"), forState: .Normal)
        plusButtonHouseTemp.addTarget(self, action: "plusClickSettings:", forControlEvents: UIControlEvents.TouchUpInside)
        minusButtonHouseTemp.setImage(UIImage(named: "MinusImage"), forState: .Normal)
        minusButtonHouseTemp.addTarget(self, action: "minusClickSettings:", forControlEvents: UIControlEvents.TouchUpInside)
        plusButtonHouseTemp.setImage(UIImage(named: "PlusImageGrey"), forState: .Highlighted)
        minusButtonHouseTemp.setImage(UIImage(named: "MinusImageGrey"), forState: .Highlighted)
        plusButtonHouseTemp.layer.cornerRadius = 3
        plusButtonHouseTemp.layer.borderWidth = 1
        minusButtonHouseTemp.layer.cornerRadius = 3
        minusButtonHouseTemp.layer.borderWidth = 1
        
        var pmHeight = NSLayoutConstraint(item: plusButtonHouseTemp, attribute: .Height, relatedBy: .Equal, toItem:minusButtonHouseTemp, attribute: .Height, multiplier: 1, constant: 0.0)
        var pWidth = NSLayoutConstraint(item: plusButtonHouseTemp, attribute: .Width, relatedBy: .Equal, toItem:plusButtonHouseTemp, attribute: .Height, multiplier: 1, constant: 0.0)
        var mWidth = NSLayoutConstraint(item: minusButtonHouseTemp, attribute: .Width, relatedBy: .Equal, toItem:plusButtonHouseTemp, attribute: .Width, multiplier: 1, constant: 0.0)
        
        settingsBigView.addConstraint(pmHeight)
        settingsBigView.addConstraint(mWidth)
        settingsBigView.addConstraint(pWidth)
        
    }
    
    func bigViewsSetup(){
        var constStrings = Array<String>()
        
        constStrings.append("H:|[HCViewStrip]|")
        constStrings.append("H:|-16-[homeTempBV]-16-|")
        constStrings.append("V:|-115-[HCViewStrip]-(-10)-[homeTempBV]-50-[statusViewStrip]")
        constStrings.append("H:|[statusViewStrip]|")
        constStrings.append("H:|-16-[setPointBV]-16-|")
        constStrings.append("V:[statusViewStrip]-(-10)-[setPointBV]-50-|")

        
        var views = ["homeTempBV":homeTempBigView,
                    "HCViewStrip":heatingCoolingViewStrip,
                    "statusViewStrip":statusViewStrip,
                    "setPointBV":setPointBigView,
                    "HCLabel":heatingCoolingLabel,
                    "statusLabel":statusLabel]
        
        homeTempBigView.layer.borderWidth = 2
        setPointBigView.layer.borderWidth = 2
        
        for view1 in views{
            view1.1.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(view1.1)
        }
        view.insertSubview(homeTempBigView, belowSubview: heatingCoolingViewStrip)
        view.insertSubview(setPointBigView, belowSubview: statusViewStrip)
        
        for constraint in Range(start: 0, end: constStrings.count){
            let constraintArr:Array = NSLayoutConstraint.constraintsWithVisualFormat(constStrings[constraint],
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: views)
            
            view.addConstraints(constraintArr)
        }
        
        var homeTempBVHeight = NSLayoutConstraint(item: homeTempBigView, attribute: .Height, relatedBy: .Equal, toItem:setPointBigView, attribute: .Height, multiplier: 1, constant: 10)

        view.addConstraint(homeTempBVHeight)

        heatingCoolingViewStrip.addSubview(heatingCoolingLabel)
        heatingCoolingViewStrip.layer.cornerRadius = 20
        heatingCoolingLabel.text = "Currently: Heating"
        heatingCoolingLabel.textAlignment = NSTextAlignment.Center
        homeTempBigView.layer.cornerRadius = 10
        
        heatingCoolingLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        heatingCoolingViewStrip.backgroundColor = JTKColors().orangeLight
        
        let constraintV:Array = NSLayoutConstraint.constraintsWithVisualFormat("V:|[HCLabel]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: views)
        let constraintH:Array = NSLayoutConstraint.constraintsWithVisualFormat("H:|[HCLabel]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: views)
        heatingCoolingViewStrip.addConstraints(constraintV)
        heatingCoolingViewStrip.addConstraints(constraintH)
        
        
        statusViewStrip.addSubview(statusLabel)
        statusLabel.text = "Home"
        statusLabel.textAlignment = NSTextAlignment.Center
        
        statusLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        statusViewStrip.backgroundColor = JTKColors().softGreen
        statusViewStrip.layer.cornerRadius = 20
        setPointBigView.layer.cornerRadius = 10
        
        let constraintSPV:Array = NSLayoutConstraint.constraintsWithVisualFormat("V:|[statusLabel]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: views)
        let constraintSPH:Array = NSLayoutConstraint.constraintsWithVisualFormat("H:|[statusLabel]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: views)
        statusViewStrip.addConstraints(constraintSPV)
        statusViewStrip.addConstraints(constraintSPH)
    }
    
    //sets up the internal elements in the home temperature view
    func hometempInternals() {
        var constStrings = Array<String>()
        
        constStrings.append("H:|-15-[homeTempLabel]|")
        constStrings.append("H:|[homeTemp]|")
        constStrings.append("V:|-10-[homeTempLabel][homeTemp]|")

        var homeTemp = UILabel()
        homeTemp.text = "Inside Temperature"
        homeTemp.textAlignment = NSTextAlignment.Center
        homeTempLabel.textAlignment = NSTextAlignment.Center
        
        
        var views = ["homeTemp":homeTemp,
            "homeTempLabel":homeTempLabel]
        
        for view1 in views{
            view1.1.setTranslatesAutoresizingMaskIntoConstraints(false)

        }
        homeTemp.setContentHuggingPriority(1000, forAxis: .Vertical)
        
        homeTempLabel.text = String(sched!.currentHomeTemp) + "°"
        
        homeTempLabel.font = UIFont(name: homeTempLabel.font.fontName, size: 90)
        homeTempBigView.addSubview(homeTemp)
        homeTempBigView.addSubview(homeTempLabel)
        
        for constraint in Range(start: 0, end: constStrings.count){
            let constraintArr:Array = NSLayoutConstraint.constraintsWithVisualFormat(constStrings[constraint],
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: views)
            
            homeTempBigView.addConstraints(constraintArr)
        }
    }
    
    //sets up internals of setpoint view
    // setpoint, plus/minus buttons
    func setPointInternals() {
        var constStrings = Array<String>()
    
        constStrings.append("H:|[setPointLabel][minusButton]-5-|")
        constStrings.append("H:|[setToLabel][plusButton]-5-|")
        constStrings.append("V:|-12-[plusButton][minusButton]-5-|")
        constStrings.append("V:|-10-[setToLabel][setPointLabel]|")
        
        
        var views = ["setPointLabel":setPointLabel,
            "setToLabel":setToLabel,
            "plusButton":plusButton,
            "minusButton":minusButton]
        
        for view1 in views{
            view1.1.setTranslatesAutoresizingMaskIntoConstraints(false)
            setPointBigView.addSubview(view1.1)

        }
        
        for constraint in Range(start: 0, end: constStrings.count){
            let constraintArr:Array = NSLayoutConstraint.constraintsWithVisualFormat(constStrings[constraint],
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: views)
            
            setPointBigView.addConstraints(constraintArr)
        }
        
        setPointLabel.text = "Set to"
        setPointLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        setPointLabel.textAlignment = NSTextAlignment.Center
        setToLabel.text = "68°"
        setToLabel.textAlignment = NSTextAlignment.Center
        setToLabel.font = UIFont(name: setToLabel.font.fontName, size: 80)
        setToLabel.adjustsFontSizeToFitWidth = true
        
        
        plusButton.setImage(UIImage(named: "PlusImage"), forState: .Normal)
        plusButton.addTarget(self, action: "plusClick:", forControlEvents: UIControlEvents.TouchUpInside)
        minusButton.setImage(UIImage(named: "MinusImage"), forState: .Normal)
        minusButton.addTarget(self, action: "minusClick:", forControlEvents: UIControlEvents.TouchUpInside)
        plusButton.setImage(UIImage(named: "PlusImageGrey"), forState: .Highlighted)
        minusButton.setImage(UIImage(named: "MinusImageGrey"), forState: .Highlighted)
        plusButton.layer.cornerRadius = 3
        plusButton.layer.borderWidth = 1
        minusButton.layer.cornerRadius = 3
        minusButton.layer.borderWidth = 1
        
        var pmHeight = NSLayoutConstraint(item: plusButton, attribute: .Height, relatedBy: .Equal, toItem:minusButton, attribute: .Height, multiplier: 1, constant: 0.0)
        var pWidth = NSLayoutConstraint(item: plusButton, attribute: .Width, relatedBy: .Equal, toItem:plusButton, attribute: .Height, multiplier: 1, constant: 0.0)
        var mWidth = NSLayoutConstraint(item: minusButton, attribute: .Width, relatedBy: .Equal, toItem:plusButton, attribute: .Width, multiplier: 1, constant: 0.0)
        
        setPointBigView.addConstraint(pmHeight)
        setPointBigView.addConstraint(mWidth)
        setPointBigView.addConstraint(pWidth)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //updates view with current values including home temp, HVAC status, setPoint, and home/away status
    func updateView(){
        sched!.updateCurrent()
        homeTempLabel.text = String(sched!.currentHomeTemp) + "°"
        setToLabel.text = String(sched!.currentSegment["setPoint"] as Int) + "°"
        settingHouseTempLabel.text = String(sched!.currentHomeTemp) + "°"

        var hvac = sched!.currentHVACStatus
        heatingCoolingLabel.text = hvac

        if(hvac == "Heating"){
            heatingCoolingViewStrip.backgroundColor = JTKColors().heatingOrange
        }else if ( hvac == "Cooling"){
            heatingCoolingViewStrip.backgroundColor = JTKColors().coolingBlue
        }else{
            heatingCoolingViewStrip.backgroundColor = JTKColors().lightGrey
        }
        var status =  sched!.currentSegment["status"] as String
        statusLabel.text = status
        
        if(status == "Home"){
            statusViewStrip.backgroundColor = JTKColors().softGreen
        }else{
            statusViewStrip.backgroundColor = JTKColors().lightGrey
        }
        
    }
    
    //when Demo settings popup is open touching outside of the settings view 
    // hides it
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent){
        if touchMask{
            for touch:AnyObject in touches{
                if !settingsBigView.frame.contains(touch.locationInView(view))
                {
                    settingsHide()
                }
            }
        }
    }
    
    //hide demo settings
    func settingsHide(){
        greyOut.hidden = true
        settingsBigView.hidden = true
        touchMask = false
    }
    
    //show demo settings
    func settingsShow(){
        greyOut.hidden = false
        settingsBigView.hidden = false
        touchMask = true
    }
}



