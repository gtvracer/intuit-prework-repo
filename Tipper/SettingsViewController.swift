//
//  SettingsViewController.swift
//  Tipper
//
//  Created by Tom Tong on 3/5/17.
//  Copyright © 2017 Carrera. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    var tipValue = 0.15;

    // current default tip percentage
    @IBOutlet weak var lblDefaultTipPercentage: UILabel!
    
    @IBOutlet weak var sldrTipScale: UISlider!
    @IBAction func sldrActionValueChanged(_ sender: UISlider) {
        let value = Int(sender.value);
        if (value == Int(tipValue*100)) {
            return;
        }
        tipValue = Double(value) / 100.0;
        print(tipValue);
        lblDefaultTipPercentage.text = "\(value)%";
//        UserDefaults.standard.set(tipValue, forKey: "defaultTipValue");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("SettingsViewController loaded")
        // Do any additional setup after loading the view.
        loadConfig();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated);
        writeConfig();
    }
    
    //read persistent values
    func loadConfig() {
        let tipValueConfig = UserDefaults.standard.double(forKey: "defaultTipValue");
        print("SettingsViewController loadConfig - tipValueConfig:\(tipValueConfig)");
        if (tipValueConfig != 0.0) {
            tipValue = Double(tipValueConfig);
        }
        else {
            tipValue = 0.15;
        }
        let tipValueInt  = Int(tipValue.multiplied(by: 100.0));
        sldrTipScale.setValue(Float(tipValueInt), animated: true);
        lblDefaultTipPercentage.text = "\(tipValueInt)%";
    }
    
    // write to persistent storage
    func writeConfig() {
        UserDefaults.standard.set(tipValue, forKey: "defaultTipValue");
        print("writeConfig set defaultTipValue to \(tipValue)");
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("In SettingsViewController prepare()");
        print(segue);
    }
    */

}
