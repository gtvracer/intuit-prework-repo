//
//  ViewController.swift
//  Tipper
//
//  Created by Tom Tong on 3/5/17.
//  Copyright © 2017 Carrera. All rights reserved.
//

import UIKit

// globalize the formatter, as it is used everywhere
let formatter = NumberFormatter();

extension String {
    
    // formatting text for currency textField with locality in mind
    func currencyInputFormatting() -> String {
        
        var number: NSNumber!
        var amountWithPrefix = self
        
//        print("input is \(amountWithPrefix)");
        // check to see if we have a '.' naturally or not
        let zero = NSNumber(value: Double(0));
        let charset = CharacterSet(charactersIn: ".");
        if formatter.string(from: zero)!.rangeOfCharacter(from: charset) == nil { // not period naturally
            let result = amountWithPrefix.range(of: ".",
                                    options: NSString.CompareOptions.literal,
                                    range: amountWithPrefix.startIndex..<amountWithPrefix.endIndex,
                                    locale: nil);
            if let range = result {
                // Start of range of found string.
                let start = range.lowerBound
                //strip out decimal value
                
                amountWithPrefix = amountWithPrefix[amountWithPrefix.startIndex..<start];
                print("after stripping out the decimal value: \(amountWithPrefix)");
            }
        }
        
//        print("amountWithPrefix used is \(amountWithPrefix)");
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, amountWithPrefix.characters.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue;
        
        // check to see if we have a '.' naturally or not
        if formatter.string(from: zero)!.rangeOfCharacter(from: charset) != nil {
            number = NSNumber(value: (double / 100)); // divide by 100 if we have a period
        }
        else {
            number = NSNumber(value: double); // no period, use as is
        }
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        let formatted = formatter.string(from: number)!
//        print("formatted: \(formatted) from \(number)");
        
        return formatted;
    }
    
    // get bill amount as float, regardless of locality
    func asFloat() -> Float {
        let str = self;
        let symbol = Locale.current.currencySymbol!;
        
        var temp = str.replacingOccurrences(of: symbol, with: "");
        temp = temp.replacingOccurrences(of:",", with: "");
        return (temp as NSString).floatValue
    }
}

class TipViewController: UIViewController {
    var tipValue = 0.15;
    var billAmountString : String = "";

    // this is the display for the slider
    @IBOutlet weak var lblTipPercentage: UILabel!
    // this is is the bill text field
    @IBOutlet weak var txtBillAmount: UITextField!
    // this is the tip dollar amount
    @IBOutlet weak var lslTipTotal: UILabel!
    // this is the sum of tip and bill
    @IBOutlet weak var lblMealTotal: UILabel!
    // view container with per person values
    @IBOutlet weak var viewPerPerson: UIView!
    // these are per person owed values
    @IBOutlet weak var lblPerPerson1: UILabel!
    @IBOutlet weak var lblPerPerson2: UILabel!
    @IBOutlet weak var lblPerPerson3: UILabel!
    @IBOutlet weak var lblPerPerson4: UILabel!
    @IBOutlet weak var lblPerPerson5: UILabel!
    // this is the slider for tipping
    @IBOutlet weak var sldrTipScale: UISlider!
    // when value changes in slider
    @IBAction func sldrActionValueChanged(_ sender: UISlider) {
        let value = Int(sender.value);
        if (value == Int(tipValue*100)) {
            return;
        }
        tipValue = Double(value) / 100.0;
        lblTipPercentage.text = "\(value)%";
        updateValues();
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        formatter.locale = Locale.current; // Change this to another locale if you want to force a specific locale, otherwise this is redundant as the current locale is the default already
        formatter.numberStyle = .currency;
        
        txtBillAmount.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged);
        loadConfig();
        
        displayTipAndTotal();
        viewPerPerson.isHidden = true;
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        writeConfig();
        print("viewWillDisappear");
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        loadConfig();
        updateValues();
    }
    
    // signals if Home if pressed to save current values to persistent storage
    func appMovedToBackground() {
        writeConfig();
        print("appMovedToBackground");
    }
    
    // read persistent values
    func loadConfig() {
        let tipValueConfig = UserDefaults.standard.double(forKey: "defaultTipValue");
        print("ViewController loadConfig - tipValueConfig:\(tipValueConfig)");
        if (tipValueConfig != 0.0) {
            tipValue = Double(tipValueConfig);
        }
        else {
            tipValue = 0.15; // set to default if UserDefaults is not found for this
        }
        let tipValueInt  = Int(tipValue.multiplied(by: 100.0));
        sldrTipScale.setValue(Float(tipValueInt), animated: true);
        let bill = UserDefaults.standard.object(forKey: "billAmount") as? Float ?? Float(0);
        
        billAmountString = String(format:"%.2f", bill).currencyInputFormatting();
        lblTipPercentage.text = "\(tipValueInt)%";
        print("loadConfig - bill:\(bill), billAmountString:\(billAmountString)");
        if (bill > 0.0) {
            txtBillAmount.text = billAmountString; // set bill text field if there is any amount
        }
        
        let lastTime = UserDefaults.standard.object(forKey: "timestamp") as? Date ?? nil;
        print("loadConfig - lastTime:\(lastTime)");
        let now = Date();
        
        if (lastTime != nil) {
            let diff = now.timeIntervalSince(lastTime!);
            if (diff > 60*10) {
                billAmountString = "";
            }
        }
        
        // show formatted bill
        txtBillAmount.text = billAmountString;
    }
    
    // save the current values to persistent storage
    func writeConfig() {
        let bill = billAmountString.asFloat();
        UserDefaults.standard.set(bill, forKey: "billAmount");
        print("writeConfig - bill:\(bill)");
        let now = Date();
        UserDefaults.standard.set(now, forKey:"timestamp");
    }
    
    // force correct formatting of input
    func myTextFieldDidChange(_ textField: UITextField) {
        
        if let amountString = txtBillAmount.text?.currencyInputFormatting() {
            print("text change: \(amountString)")
            txtBillAmount.text = amountString;
            billAmountString = amountString;
            updateValues();
        }
    }
    
    func updateValues() {
        if (billAmountString.isEmpty) {
            viewPerPerson.isHidden = true;
            billAmountString = "0";
        }
        // show main two elements
        displayTipAndTotal();
        let tipAmount = (billAmountString.asFloat().multiplied(by: Float(tipValue)));
        let mealTotal = billAmountString.asFloat().adding(tipAmount);

        // calculate per person values
        let forTwo = mealTotal / 2;
        if let formattedBillAmount = formatter.string(from: forTwo as NSNumber) {
            lblPerPerson2.text = "\(formattedBillAmount)";
        }
        let forThree = mealTotal / 3;
        if let formattedBillAmount = formatter.string(from: forThree as NSNumber) {
            lblPerPerson3.text = "\(formattedBillAmount)";
        }
        let forFour = mealTotal / 4;
        if let formattedBillAmount = formatter.string(from: forFour as NSNumber) {
            lblPerPerson4.text = "\(formattedBillAmount)";
        }
        let forFive = mealTotal / 5;
        if let formattedBillAmount = formatter.string(from: forFive as NSNumber) {
            lblPerPerson5.text = "\(formattedBillAmount)";
        }
        
        // show per person view only if there is something to show
        if (billAmountString.asFloat() > 0.0) {
            viewPerPerson.isHidden = false;
        }
    }
    
    // displays the Tip and Total values only
    func displayTipAndTotal() {
//        print("displayTipAndTotal - billAmountString:\(billAmountString)");
        let amount = billAmountString.isEmpty ? Float(0) : billAmountString.asFloat();
        let tipAmount = (amount.multiplied(by: Float(tipValue)));
        if let formattedTipAmount = formatter.string(from: tipAmount as NSNumber) {
            lslTipTotal.text = "\(formattedTipAmount)";
            print(formattedTipAmount);
        }
        let mealTotal = amount.adding(tipAmount);
        if let formattedBillAmount = formatter.string(from: mealTotal as NSNumber) {
            lblMealTotal.text = "\(formattedBillAmount)";
            lblPerPerson1.text = "\(formattedBillAmount)";
        }
    }

    // from Tap Gesture Recognizer to hide keypad
    @IBAction func onTap(_ sender: Any) {
        view.endEditing(true);
    }

}

