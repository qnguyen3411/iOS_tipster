//
//  ViewController.swift
//  tipster
//
//  Created by Quang Nguyen on 9/5/18.
//  Copyright © 2018 Quang Nguyen. All rights reserved.
//

import UIKit



extension String {
  func toDouble() -> Double? {
    return NumberFormatter().number(from:(self))?.doubleValue
  }
}

extension Double {
  /// Rounds the double to decimal places value
  func rounded(toPlaces places:Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
  
  func toFloorInt() -> Int? {
    let intString = String(format: "%.0f", self)
    return Int(intString)
  }
}

enum OutputError: Error {
  
  case multipleDecimalPtError
  
  case stringToDoubleError
  
  case maxDecimalError
  
}

enum DisplayError: Error {
  case labelNotFoundError
}

enum TaxAddition: Double {
  
  case none = 0.0
  
  case low = 0.05
  
  case high = 0.1
}


struct BillValue {
  // Value of bill as a string
  var stringVal: String = "0"
  
  var taxRate: Double = 0.0
  
  var groupSize: Int = 1
  
  mutating func takeNumInput(_ num: Int) throws {
    
    guard !hasMaxDecimalPlaces(2) else {
      throw OutputError.maxDecimalError
    }
    
    if stringVal == "0" {
      stringVal = "\(num)"
    } else {
      stringVal += "\(num)"
    }
  }
  
  mutating func addDecimalPoint() throws {
    
    guard !stringVal.contains(".") else {
      throw OutputError.multipleDecimalPtError
    }
    
    stringVal += "."
  }
  
  mutating func clear() {
    stringVal = "0"
  }
  
  // Returns the tax rate plus tax addition
  func totalTaxRate(addedWith taxAddition: TaxAddition) -> Double{
    return taxRate + taxAddition.rawValue
  }
  
  // Returns the total tax amount
  func totalTax(taxAddition: TaxAddition) throws -> Double {
    
    let totalTaxRate = self.totalTaxRate(addedWith: taxAddition)
    if let doubleVal = stringVal.toDouble() {
      return doubleVal * totalTaxRate
    } else {
      throw OutputError.stringToDoubleError
    }
  }
  
  // Returns the charge plus the total tax
  func totalCharge(taxAddition: TaxAddition) throws -> Double {
    
    let tax = try totalTax(taxAddition: taxAddition)
    
    if let doubleVal = stringVal.toDouble() {
      return (doubleVal + tax) / Double(groupSize)
      
    } else {
      throw OutputError.stringToDoubleError
    }
  }
  
  // Returns true if stringVal already has `maxPlaces` decimal place
  func hasMaxDecimalPlaces(_ maxPlaces: Int) -> Bool {
    let preDecimalPtString = stringVal.split(
      separator: ".")[0]
    return stringVal.count - preDecimalPtString.count >= maxPlaces + 1
  }
  
}

class taxDisplay : UIStackView {
  
  var rateLabel: UILabel? {
    get {
      return self.subviews[0] as? UILabel
    }
  }
  
  var taxLabel: UILabel? {
    get {
      return self.subviews[1] as? UILabel
    }
  }
  
  var totalLabel: UILabel? {
    get {
      return self.subviews[2] as? UILabel
    }
  }
  
  func update(rate: Double, tax: Double, total: Double) throws {
    
    if let rateLabel = self.rateLabel {
      rateLabel.text = String(format: "%.0f", rate * 100) + "%"
    } else {
      throw DisplayError.labelNotFoundError
    }
    
    if let taxLabel = self.taxLabel {
      taxLabel.text = String(format: "%.2f", tax)
    } else {
      throw DisplayError.labelNotFoundError
    }
    
    if let totalLabel = self.totalLabel {
      totalLabel.text = String(format: "%.2f", total)
    } else {
      throw DisplayError.labelNotFoundError
    }
  }
  
}

class ViewController: UIViewController {
  
  @IBOutlet var taxDisplayList: [taxDisplay]!
  @IBOutlet weak var totalChargeLabel: UILabel!
  @IBOutlet weak var groupSizeLabel: UILabel!
  
  
  @IBAction func taxSlider(_ sender: UISlider) {
    do {
      billValue.taxRate = Double(sender.value)
      try updateTaxDisplays(with: billValue)
    } catch {
      print("ERROR")
    }
  }
  
  
  @IBAction func groupSlider(_ sender: UISlider) {
    print(sender.value)
    if let groupSize = Double(sender.value).toFloorInt(){
      do{
        billValue.groupSize = groupSize
        groupSizeLabel.text = "Group: \(groupSize)"
        try updateScreen(with: billValue)
      } catch {
        print("ERROR")
      }
    }
  }
  
  
  @IBAction func numPadBtnPressed(_ sender: UIButton) {
    do {
      try billValue.takeNumInput(sender.tag)
      try updateScreen(with: billValue)
      
    } catch {
      print("ERROR")
    }
  }
  
  @IBAction func clearBtnPressed(_ sender: UIButton) {
    do {
      billValue.clear()
      try updateScreen(with: billValue)
    } catch {
      print("ERROR")
    }
  }
  
  @IBAction func decimalBtnPressed(_ sender: UIButton) {
    do {
      try billValue.addDecimalPoint()
      try updateScreen(with: billValue)
    } catch {
      print("ERROR")
    }
  }
  
  func updateTotalChargeLabel(with billValue: BillValue) {
    totalChargeLabel.text = billValue.stringVal
  }
  
  func updateTaxDisplays(with billValue: BillValue) throws {
    
    try updateTaxDisplay(displayIndex: 0, taxAddition: .none)
    try updateTaxDisplay(displayIndex: 1, taxAddition: .low)
    try updateTaxDisplay(displayIndex: 2, taxAddition: .high)
  }
  
  func updateTaxDisplay(displayIndex: Int, taxAddition: TaxAddition) throws {
    try taxDisplayList[displayIndex].update(
      rate: billValue.totalTaxRate(addedWith: taxAddition),
      tax: billValue.totalTax(taxAddition: taxAddition),
      total: try billValue.totalCharge(taxAddition: taxAddition))
  }
  
  func updateScreen(with billValue: BillValue) throws {
    updateTotalChargeLabel(with: billValue)
    try updateTaxDisplays(with: billValue)
  }
  
  var billValue = BillValue()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    do {
      try updateScreen(with: billValue)
    } catch {
      print("ERROR")
    }
    // Do any additional setup after loading the view, typically from a nib.
  }


}

