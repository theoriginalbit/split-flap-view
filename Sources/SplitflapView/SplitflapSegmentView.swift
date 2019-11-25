//
//  SplitflapSegmentView.swift
//
//
//  Created by Joshua Asbury on 25/11/19.
//

import UIKit

class SplitflapSegmentView: UIView {
    private let digitLabel = UILabel()
    private let mainLineView = UIView()
    private let secondaryLineView = UIView()

    let shadow = UIView()

    let position: Position

    var token: Character {
        return digitLabel.text!.first!
    }

    var textColor: UIColor = .black {
        didSet {
            digitLabel.textColor = textColor
        }
    }

    var flipPointColor: UIColor = .gray {
        didSet {
            mainLineView.backgroundColor = flipPointColor
        }
    }

    var cornerRadius: CGFloat {
        didSet {
            setNeedsLayout()
        }
    }

    var flipPointHeightFactor: CGFloat = 1.0 {
        didSet {
            setNeedsLayout()
        }
    }

    private var cornerRadii: CGSize {
        return CGSize(width: cornerRadius, height: cornerRadius)
    }

    enum Position {
        case top
        case bottom
    }

    init(position: Position, cornerRadius: CGFloat = 6.0) {
        self.cornerRadius = cornerRadius
        self.position = position

        super.init(frame: .zero)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(character: Character) {
        digitLabel.text = String(character)
    }

    private func setupViews() {
        layer.masksToBounds = true
        backgroundColor = .white

        digitLabel.textAlignment = .center
        digitLabel.textColor = textColor
        digitLabel.backgroundColor = .clear
        digitLabel.text = "0"

        addSubview(digitLabel)

        mainLineView.backgroundColor = flipPointColor
        secondaryLineView.backgroundColor = .clear
        addSubview(mainLineView)
        addSubview(secondaryLineView)

        shadow.backgroundColor = .black
        shadow.alpha = 0.0
        addSubview(shadow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Round corners
        let path: UIBezierPath

        if position == .top {
            path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: cornerRadii)
        } else {
            path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: cornerRadii)
        }

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        layer.mask = maskLayer

        // Position elements
        var digitLabelFrame = bounds
        var mainLineViewFrame = bounds
        var secondaryLineViewFrame = bounds

        if position == .top {
            digitLabelFrame.size.height = digitLabelFrame.height * 2
            digitLabelFrame.origin.y = 0
            mainLineViewFrame = CGRect(x: 0, y: bounds.height - (2 * flipPointHeightFactor), width: bounds.width, height: 4 * flipPointHeightFactor)
            secondaryLineViewFrame = CGRect(x: 0, y: bounds.height - (1 * flipPointHeightFactor), width: bounds.width, height: 2 * flipPointHeightFactor)
        } else {
            digitLabelFrame.size.height = digitLabelFrame.height * 2
            digitLabelFrame.origin.y = -digitLabelFrame.height / 2
            mainLineViewFrame = CGRect(x: 0, y: -2 * flipPointHeightFactor, width: bounds.width, height: 3 * flipPointHeightFactor)
            secondaryLineViewFrame = CGRect(x: 0, y: -2 * flipPointHeightFactor, width: bounds.width, height: 2 * flipPointHeightFactor)
        }

        digitLabel.frame = digitLabelFrame
        digitLabel.font = UIFont(name: "Menlo", size: min(bounds.width, bounds.height) * 2 + (4 * flipPointHeightFactor))
        shadow.frame = digitLabelFrame
        mainLineView.frame = mainLineViewFrame
        secondaryLineView.frame = secondaryLineViewFrame
    }
}
