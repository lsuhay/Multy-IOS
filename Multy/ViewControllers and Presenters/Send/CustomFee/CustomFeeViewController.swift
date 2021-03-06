//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

private typealias LocalizeDelegate = CustomFeeViewController

class CustomFeeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var topNameLbl: UILabel!  //gas price
    @IBOutlet weak var topPriceTF: UITextField!
    
    @IBOutlet weak var botNameLbl: UILabel!   //gas limit
    @IBOutlet weak var botLimitTf: UITextField!
    
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint! // for btc   /2 and hide bot elems
    
    let presenter = CustomFeePresenter()
    
    weak var delegate: CustomFeeRateProtocol?
    
    var rate = BigInt.zero()
    var gasLimit = BigInt.zero()
    var previousSelected: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.enableSwipeToBack()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.topPriceTF.becomeFirstResponder()
    }

    func setupUI() {
        unowned let weakSelf =  self
        self.topPriceTF.addDoneCancelToolbar(onDone: (target: self, action: #selector(done)), viewController: weakSelf)
        self.botLimitTf.addDoneCancelToolbar(onDone: (target: self, action: #selector(done)), viewController: weakSelf)
        
        //FIXME: check chainID nullability
        switch self.presenter.blockchainType?.blockchain {
        case BLOCKCHAIN_BITCOIN:
            self.botNameLbl.isHidden = true
            self.botLimitTf.isHidden = true
            self.viewHeightConstraint.constant = viewHeightConstraint.constant / 2
            
            
            self.topNameLbl.text = localize(string: Constants.satoshiPerByteString)
            self.topPriceTF.placeholder = localize(string: Constants.enterSatoshiPerByte)
            self.topPriceTF.placeholder = "0"
            if rate.isNonZero {
                self.topPriceTF.text = rate.stringValue
            }
        case BLOCKCHAIN_ETHEREUM:
            self.botNameLbl.isHidden = false
            self.botLimitTf.isHidden = false
            
            self.botLimitTf.text = gasLimit.stringValue
            
            if rate.isNonZero {
                self.topPriceTF.text = presenter.textForRate(rate)
            }
//            self.viewHeightConstraint.constant = viewHeightConstraint.constant
        default: return
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if presenter.blockchainType!.blockchain == BLOCKCHAIN_ETHEREUM {
            if self.previousSelected != 5 {
                self.delegate?.setPreviousSelected(index: self.previousSelected)
            }
        } else {
            if self.previousSelected != 5 {
                self.delegate?.setPreviousSelected(index: self.previousSelected)
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func minimalUnit() -> BigInt {
        switch presenter.blockchainType?.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return Constants.CustomFee.defaultBTCCustomFeeKey
        case BLOCKCHAIN_ETHEREUM:
            return Constants.CustomFee.defaultETHCustomFeeKey
        default:
            return BigInt("1")
        }
    }
    
    @objc func done() {
        let defaultCustomFee = minimalUnit()
        
        if topPriceTF.text == nil || BigInt(topPriceTF.text!) < defaultCustomFee {
            switch presenter.blockchainType!.blockchain {
            case BLOCKCHAIN_BITCOIN:
                let message = "\(localize(string: Constants.feeRateLessThenString)) \(defaultCustomFee.stringValue) \(localize(string: Constants.satoshiPerByteString))"
                let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    self.topPriceTF.becomeFirstResponder()
                }))
                
                self.present(alert, animated: true, completion: nil)
            case BLOCKCHAIN_ETHEREUM:
                let message = localize(string: Constants.gasPriceLess1String)
                let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    self.topPriceTF.becomeFirstResponder()
                }))
                
                self.present(alert, animated: true, completion: nil)
            default: return
            }
        } else if presenter.blockchainType!.blockchain == BLOCKCHAIN_ETHEREUM && BigInt(botLimitTf.text ?? "0") < BigInt("21000") {
            let message = localize(string: Constants.gasLimitLess21KString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                self.botLimitTf.becomeFirstResponder()
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            self.delegate?.customFeeData(firstValue: presenter.rateForText(topPriceTF.text!), secValue: botLimitTf.isHidden ? nil : BigInt(botLimitTf.text!))
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "," && (textField.text?.contains(","))! {
            return false
        }
        
        if string == "." && (textField.text?.contains("."))! {
            return false
        }
        
//        let endString = textField.text! + string
//        if UInt64(endString)! > 3000 {
//            let message = localize(string: Constants.feeTooHighString)
//            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
//                self.topPriceTF.becomeFirstResponder()
//            }))
//            
//            self.present(alert, animated: true, completion: nil)
//            return false
//        }
        
        return true
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Sends"
    }
}
