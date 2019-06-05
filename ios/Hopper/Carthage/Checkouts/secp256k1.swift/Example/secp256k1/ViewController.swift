//
//  ViewController.swift
//  secp256k1
//
//  Created by Koray Koska on 02/14/2018.
//  Copyright (c) 2018 Koray Koska. All rights reserved.
//

import UIKit
import secp256k1

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        if ctx != nil {
            print("Context created")
        } else {
            print("Context creation failed")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

