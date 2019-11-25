//
//  SplitflapView.swift
//
//
//  Created by Joshua Asbury on 25/11/19.
//

import UIKit

// MARK: - Configuration

private let skewedIdentityTransform: CATransform3D = {
    let zDepth: CGFloat = 1000
    var skewedIdentityTransform = CATransform3DIdentity
    skewedIdentityTransform.m34 = 1 / -zDepth
    return skewedIdentityTransform
}()

private let segmentUpwardRotationTransform: CATransform3D = {
    CATransform3DRotate(skewedIdentityTransform, .pi / -2, 1, 0, 0)
}()

private let segmentDownwardRotationTransform: CATransform3D = {
    CATransform3DRotate(skewedIdentityTransform, .pi / 2, 1, 0, 0)
}()

public class SplitflapView: UIView {
    public enum Constants {
        public static let defaultAnimationDuration: TimeInterval = 0.4
        public static let maxShadowAlpha: CGFloat = 0.4
    }

    public var tokens: [Character] {
        didSet {
            currentIndex = min(currentIndex, tokens.count)
        }
    }

    private let topSegmentView = SplitflapSegmentView(position: .top)
    private let bottomSegmentView = SplitflapSegmentView(position: .bottom)

    private var currentIndex = -1

    public init(tokens: [Character]) {
        self.tokens = tokens

        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder: NSCoder) {
        tokens = []

        super.init(coder: coder)

        commonInit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let segmentHeight = bounds.height / 2
        topSegmentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: segmentHeight)
        bottomSegmentView.frame = CGRect(x: 0, y: segmentHeight, width: bounds.width, height: segmentHeight)
    }

    private func commonInit() {
        addSubview(topSegmentView)
        addSubview(bottomSegmentView)

        topSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        bottomSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)

        let topSegmentTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(topSegmentTapped(_:)))
        topSegmentView.addGestureRecognizer(topSegmentTapGestureRecognizer)

        let bottomSegmentTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(bottomSegmentTapped(_:)))
        bottomSegmentView.addGestureRecognizer(bottomSegmentTapGestureRecognizer)

        if !tokens.isEmpty {
            nextToken(withDuration: .zero)
        }
    }

    private func updateIndex(by value: Int) {
        // wrapping bounds check
        var index = currentIndex + value
        if index < tokens.startIndex {
            index += tokens.endIndex
        } else if index >= tokens.endIndex {
            index -= tokens.endIndex
        }
        // persist indeex and present token
        currentIndex = index
    }

    // MARK: - Interactions

    @objc private func topSegmentTapped(_ sender: UITapGestureRecognizer) {
        nextToken()
    }

    @objc private func bottomSegmentTapped(_ sender: UITapGestureRecognizer) {
        previousToken()
    }

    // MARK: - Animating the Flap View

    var topSegmentAnimator: UIViewPropertyAnimator?
    var bottomSegmentAnimator: UIViewPropertyAnimator?
    var bottomShadowAnimator: UIViewPropertyAnimator?

    // MARK: - Core Animation Logic

    public func nextToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration) {
        guard bottomShadowAnimator == nil, topSegmentAnimator == nil, bottomSegmentAnimator == nil else { return }

        updateIndex(by: 1)

        let token = tokens[currentIndex]

        guard duration > .zero else {
            topSegmentView.set(character: token)
            bottomSegmentView.set(character: token)
            return
        }

        let animTopSegment = SplitflapSegmentView(position: .top)
        let animBottomSegment = SplitflapSegmentView(position: .bottom)

        animTopSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegment.frame = topSegmentView.frame
        animBottomSegment.frame = bottomSegmentView.frame

        addSubview(animTopSegment)
        addSubview(animBottomSegment)

        animTopSegment.set(character: topSegmentView.token)
        animBottomSegment.set(character: token)
        topSegmentView.set(character: token)

        animTopSegment.transform3D = skewedIdentityTransform
        animBottomSegment.transform3D = segmentDownwardRotationTransform
        topSegmentView.shadow.alpha = .zero
        bottomSegmentView.shadow.alpha = .zero

        let flapAnimationDuration = duration / 2

        bottomShadowAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut, animations: {
            self.bottomSegmentView.shadow.alpha = Constants.maxShadowAlpha
        })
        bottomShadowAnimator?.addCompletion { _ in
            self.bottomSegmentView.shadow.alpha = .zero
            self.bottomShadowAnimator = nil
        }
        bottomShadowAnimator?.scrubsLinearly = false

        topSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeIn, animations: {
            animTopSegment.transform3D = segmentUpwardRotationTransform
            animTopSegment.shadow.alpha = Constants.maxShadowAlpha / 2
        })
        topSegmentAnimator?.addCompletion { _ in
            animTopSegment.removeFromSuperview()
            self.topSegmentAnimator = nil
            self.bottomSegmentAnimator?.startAnimation()
        }
        topSegmentAnimator?.scrubsLinearly = false

        bottomSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeOut, animations: {
            animBottomSegment.transform3D = skewedIdentityTransform
        })
        bottomSegmentAnimator?.addCompletion { _ in
            self.bottomSegmentView.set(character: token)
            animBottomSegment.removeFromSuperview()
            self.bottomSegmentAnimator = nil
        }
        bottomSegmentAnimator?.scrubsLinearly = false

        // Animate all the things that should start immediately
        bottomShadowAnimator?.startAnimation()
        topSegmentAnimator?.startAnimation()
    }

    public func previousToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration) {
        guard bottomShadowAnimator == nil, topSegmentAnimator == nil, bottomSegmentAnimator == nil else { return }

        updateIndex(by: -1)

        let token = tokens[currentIndex]

        guard duration > .zero else {
            topSegmentView.set(character: token)
            bottomSegmentView.set(character: token)
            return
        }

        let animTopSegment = SplitflapSegmentView(position: .top)
        let animBottomSegment = SplitflapSegmentView(position: .bottom)

        animTopSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegment.frame = topSegmentView.frame
        animBottomSegment.frame = bottomSegmentView.frame

        addSubview(animTopSegment)
        addSubview(animBottomSegment)

        animTopSegment.set(character: token)
        animBottomSegment.set(character: bottomSegmentView.token)
        bottomSegmentView.set(character: token)

        animTopSegment.transform3D = segmentUpwardRotationTransform
        animTopSegment.shadow.alpha = Constants.maxShadowAlpha / 2
        animBottomSegment.transform3D = skewedIdentityTransform
        bottomSegmentView.shadow.alpha = Constants.maxShadowAlpha

        let flapAnimationDuration = duration / 2

        bottomShadowAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut, animations: {
            self.bottomSegmentView.shadow.alpha = .zero
        })
        bottomShadowAnimator?.addCompletion { _ in
            self.bottomShadowAnimator = nil
        }
        bottomShadowAnimator?.scrubsLinearly = false

        topSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeOut, animations: {
            animTopSegment.transform3D = skewedIdentityTransform
            animTopSegment.shadow.alpha = .zero
        })
        topSegmentAnimator?.addCompletion { _ in
            self.topSegmentView.set(character: token)
            animTopSegment.removeFromSuperview()
            self.topSegmentAnimator = nil
        }
        topSegmentAnimator?.scrubsLinearly = false

        bottomSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeIn, animations: {
            animBottomSegment.transform3D = segmentDownwardRotationTransform
        })
        bottomSegmentAnimator?.addCompletion { _ in
            self.bottomSegmentView.set(character: token)
            animBottomSegment.removeFromSuperview()
            self.bottomSegmentAnimator = nil
            self.topSegmentAnimator?.startAnimation()
        }
        bottomSegmentAnimator?.scrubsLinearly = false

        // Animate all the things that should start immediately
        bottomShadowAnimator?.startAnimation()
        bottomSegmentAnimator?.startAnimation()
    }
}
