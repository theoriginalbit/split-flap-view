//
//  InstantPanGestureRecognizer.swift
//
//
//  Created by Joshua Asbury on 25/11/19.
//

import UIKit

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state != .began else {
            return
        }
        super.touchesBegan(touches, with: event)
        state = .began
    }
}
