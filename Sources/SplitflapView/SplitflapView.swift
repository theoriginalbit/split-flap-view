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

enum FlipDirection {
    case next, previous
}

open class SplitflapView: UIView {
    public enum Constants {
        public static let defaultAnimationDuration: TimeInterval = 0.4
        public static let maxShadowAlpha: CGFloat = 0.4
    }

    open var tokens: [Character] {
        didSet {
            currentIndex = min(currentIndex, tokens.count)
            redrawToken()
        }
    }

    open var currentToken: Character {
        return tokens[currentIndex]
    }

    open var splitflapBackgroundColor: UIColor? {
        didSet {
            topSegmentView.backgroundColor = backgroundColor ?? .white
            bottomSegmentView.backgroundColor = backgroundColor ?? .white
            animTopSegmentView?.backgroundColor = backgroundColor ?? .white
            animBottomSegmentView?.backgroundColor = backgroundColor ?? .white
        }
    }

    open var textColor: UIColor = .black {
        didSet {
            topSegmentView.textColor = textColor
            bottomSegmentView.textColor = textColor
            animTopSegmentView?.textColor = textColor
            animBottomSegmentView?.textColor = textColor
        }
    }

    open var flipPointColor: UIColor = .gray {
        didSet {
            topSegmentView.flipPointColor = flipPointColor
            bottomSegmentView.flipPointColor = flipPointColor
            animTopSegmentView?.flipPointColor = flipPointColor
            animBottomSegmentView?.flipPointColor = flipPointColor
        }
    }

    open var cornerRadius: CGFloat = 6.0 {
        didSet {
            topSegmentView.cornerRadius = cornerRadius
            bottomSegmentView.cornerRadius = cornerRadius
            animTopSegmentView?.cornerRadius = cornerRadius
            animBottomSegmentView?.cornerRadius = cornerRadius
        }
    }

    open var flipPointHeightFactor: CGFloat = 1.0 {
        didSet {
            topSegmentView.flipPointHeightFactor = flipPointHeightFactor
            bottomSegmentView.flipPointHeightFactor = flipPointHeightFactor
            animTopSegmentView?.flipPointHeightFactor = flipPointHeightFactor
            animBottomSegmentView?.flipPointHeightFactor = flipPointHeightFactor
        }
    }

    private let topSegmentView = SplitflapSegmentView(position: .top)
    private let bottomSegmentView = SplitflapSegmentView(position: .bottom)

    private var animTopSegmentView: SplitflapSegmentView?
    private var animBottomSegmentView: SplitflapSegmentView?

    private var currentIndex = 0

    private var primaryAnimator: UIViewPropertyAnimator?
    private var topSegmentAnimator: UIViewPropertyAnimator?
    private var bottomSegmentAnimator: UIViewPropertyAnimator?
    private var animationProgress: CGFloat = 0
    private var flipAnimationDirection: FlipDirection = .next

    public init(tokens: [Character]) {
        self.tokens = tokens

        super.init(frame: .zero)

        commonInit()
    }

    public required init?(coder: NSCoder) {
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

        let topSegmentTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTopTapGesture(_:)))
        topSegmentView.addGestureRecognizer(topSegmentTapGestureRecognizer)

        let bottomSegmentTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBottomTapGesture))
        bottomSegmentView.addGestureRecognizer(bottomSegmentTapGestureRecognizer)

        let instantPanGestureRecognizer = InstantPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        instantPanGestureRecognizer.maximumNumberOfTouches = 1
        instantPanGestureRecognizer.require(toFail: topSegmentTapGestureRecognizer)
        instantPanGestureRecognizer.require(toFail: bottomSegmentTapGestureRecognizer)
        addGestureRecognizer(instantPanGestureRecognizer)

        if !tokens.isEmpty {
            redrawToken()
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

    @discardableResult
    open func nextToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration) -> Bool {
        // Disallow index changes while animating
        guard primaryAnimator == nil else { return false }

        updateIndex(by: 1)
        animateToNextToken(withDuration: duration)
        return true
    }

    @discardableResult
    open func previousToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration) -> Bool {
        // Disallow index changes while animating
        guard primaryAnimator == nil else { return false }

        updateIndex(by: -1)
        animateToPreviousToken(withDuration: duration)
        return true
    }

    open func redrawToken() {
        let token = tokens[currentIndex]
        topSegmentView.set(character: token)
        bottomSegmentView.set(character: token)
    }

    // MARK: - Interactions

    @objc private func handleTopTapGesture(_ sender: UITapGestureRecognizer) {
        // Disallow taps while animating
        guard primaryAnimator == nil else { return }

        nextToken()
    }

    @objc private func handleBottomTapGesture(_ sender: UITapGestureRecognizer) {
        // Disallow taps while animating
        guard primaryAnimator == nil else { return }

        previousToken()
    }

    @objc private func handlePanGesture(_ sender: InstantPanGestureRecognizer) {
        switch sender.state {
        case .began:
            didBeginPan(sender)
        case .changed:
            didChangePan(sender)
        case .ended:
            didEndPan(sender)
        default:
            break
        }
    }

    private func didBeginPan(_ recognizer: InstantPanGestureRecognizer) {
        guard !(primaryAnimator?.isRunning ?? false) else { return }

        switch recognizer.velocity(in: self) {
        case let velocity where velocity.y < 0: // swipe up
            flipAnimationDirection = .previous
            updateIndex(by: -1)
            animateToPreviousToken(interactive: true)
        case let velocity where velocity.y > 0: // swipe down
            flipAnimationDirection = .next
            updateIndex(by: 1)
            animateToNextToken(interactive: true)
        default:
            return
        }

        animationProgress = primaryAnimator?.fractionComplete ?? 0
    }

    private func didChangePan(_ recognizer: InstantPanGestureRecognizer) {
        guard primaryAnimator != nil else { return }

        let translation = recognizer.translation(in: self)
        let fraction: CGFloat = min(abs(translation.y) / bounds.height, 1.0)
        let totalProgress = fraction + animationProgress
        primaryAnimator?.fractionComplete = totalProgress

        let stage1Progress = min(totalProgress, 0.5) * 2
        let stage2Progress = max(totalProgress - 0.5, 0) * 2
        topSegmentAnimator?.fractionComplete = flipAnimationDirection == .next ? stage1Progress : stage2Progress
        bottomSegmentAnimator?.fractionComplete = flipAnimationDirection == .next ? stage2Progress : stage1Progress
    }

    private func didEndPan(_ recognizer: InstantPanGestureRecognizer) {
        let overHalfWay = (primaryAnimator?.fractionComplete ?? 0.0) >= 0.5

        if flipAnimationDirection == .next {
            topSegmentAnimator?.startAnimation()
            if overHalfWay {
                bottomSegmentAnimator?.startAnimation()
            }
        } else {
            bottomSegmentAnimator?.startAnimation()
            if overHalfWay {
                topSegmentAnimator?.startAnimation()
            }
        }

        primaryAnimator?.startAnimation()
    }

    // MARK: - Core Animation Logic

    private func animateToNextToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration, interactive: Bool = false) {
        guard primaryAnimator == nil else { return }

        let token = tokens[currentIndex]

        guard duration > .zero else {
            topSegmentView.set(character: token)
            bottomSegmentView.set(character: token)
            return
        }

        let animTopSegmentView = SplitflapSegmentView(position: .top)
        let animBottomSegmentView = SplitflapSegmentView(position: .bottom)

        animTopSegmentView.backgroundColor = topSegmentView.backgroundColor
        animTopSegmentView.textColor = topSegmentView.textColor
        animTopSegmentView.flipPointColor = topSegmentView.flipPointColor
        animTopSegmentView.cornerRadius = topSegmentView.cornerRadius
        animTopSegmentView.flipPointHeightFactor = topSegmentView.flipPointHeightFactor

        animBottomSegmentView.backgroundColor = bottomSegmentView.backgroundColor
        animBottomSegmentView.textColor = bottomSegmentView.textColor
        animBottomSegmentView.flipPointColor = bottomSegmentView.flipPointColor
        animBottomSegmentView.cornerRadius = bottomSegmentView.cornerRadius
        animBottomSegmentView.flipPointHeightFactor = bottomSegmentView.flipPointHeightFactor

        animTopSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegmentView.frame = topSegmentView.frame
        animBottomSegmentView.frame = bottomSegmentView.frame

        self.animTopSegmentView = animTopSegmentView
        self.animBottomSegmentView = animBottomSegmentView

        addSubview(animTopSegmentView)
        addSubview(animBottomSegmentView)

        animTopSegmentView.set(character: topSegmentView.token)
        animBottomSegmentView.set(character: token)
        topSegmentView.set(character: token)

        animTopSegmentView.transform3D = skewedIdentityTransform
        animBottomSegmentView.transform3D = segmentDownwardRotationTransform
        topSegmentView.shadow.alpha = .zero
        bottomSegmentView.shadow.alpha = .zero

        let flapAnimationDuration = duration / 2

        primaryAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut, animations: {
            self.bottomSegmentView.shadow.alpha = Constants.maxShadowAlpha
        })
        primaryAnimator?.addCompletion { _ in
            // Correct the view state
            self.bottomSegmentView.shadow.alpha = .zero
            self.bottomSegmentView.set(character: token)

            // Remove the animated views
            self.animTopSegmentView?.removeFromSuperview()
            self.animTopSegmentView = nil
            self.animBottomSegmentView?.removeFromSuperview()
            self.animBottomSegmentView = nil

            // Clear the animators
            self.primaryAnimator = nil
            self.topSegmentAnimator = nil
            self.bottomSegmentAnimator = nil
        }

        topSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeIn, animations: {
            animTopSegmentView.transform3D = segmentUpwardRotationTransform
            animTopSegmentView.shadow.alpha = Constants.maxShadowAlpha / 2
        })
        topSegmentAnimator?.addCompletion { _ in
            self.bottomSegmentAnimator?.startAnimation()
        }

        bottomSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeOut, animations: {
            animBottomSegmentView.transform3D = skewedIdentityTransform
        })

        // Animate all the things that should start immediately
        if !interactive {
            primaryAnimator?.startAnimation()
            topSegmentAnimator?.startAnimation()
        }

        if let animator = primaryAnimator {
            animationProgress = animator.fractionComplete
        }
    }

    private func animateToPreviousToken(withDuration duration: TimeInterval = Constants.defaultAnimationDuration, interactive: Bool = false) {
        guard primaryAnimator == nil else { return }

        let token = tokens[currentIndex]

        guard duration > .zero else {
            topSegmentView.set(character: token)
            bottomSegmentView.set(character: token)
            return
        }

        let animTopSegmentView = SplitflapSegmentView(position: .top)
        let animBottomSegmentView = SplitflapSegmentView(position: .bottom)

        animTopSegmentView.backgroundColor = topSegmentView.backgroundColor
        animTopSegmentView.textColor = topSegmentView.textColor
        animTopSegmentView.flipPointColor = topSegmentView.flipPointColor
        animTopSegmentView.cornerRadius = topSegmentView.cornerRadius
        animTopSegmentView.flipPointHeightFactor = topSegmentView.flipPointHeightFactor

        animBottomSegmentView.backgroundColor = bottomSegmentView.backgroundColor
        animBottomSegmentView.textColor = bottomSegmentView.textColor
        animBottomSegmentView.flipPointColor = bottomSegmentView.flipPointColor
        animBottomSegmentView.cornerRadius = bottomSegmentView.cornerRadius
        animBottomSegmentView.flipPointHeightFactor = bottomSegmentView.flipPointHeightFactor

        animTopSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegmentView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegmentView.frame = topSegmentView.frame
        animBottomSegmentView.frame = bottomSegmentView.frame

        self.animTopSegmentView = animTopSegmentView
        self.animBottomSegmentView = animBottomSegmentView

        addSubview(animTopSegmentView)
        addSubview(animBottomSegmentView)

        animTopSegmentView.set(character: token)
        animBottomSegmentView.set(character: bottomSegmentView.token)
        bottomSegmentView.set(character: token)

        animTopSegmentView.transform3D = segmentUpwardRotationTransform
        animTopSegmentView.shadow.alpha = Constants.maxShadowAlpha / 2
        animBottomSegmentView.transform3D = skewedIdentityTransform
        bottomSegmentView.shadow.alpha = Constants.maxShadowAlpha

        let flapAnimationDuration = duration / 2

        primaryAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut, animations: {
            self.bottomSegmentView.shadow.alpha = .zero
        })
        primaryAnimator?.addCompletion { _ in
            // Correct the view state
            self.topSegmentView.set(character: token)
            self.bottomSegmentView.set(character: token)

            // Remove the animated views
            self.animTopSegmentView?.removeFromSuperview()
            self.animTopSegmentView = nil
            self.animBottomSegmentView?.removeFromSuperview()
            self.animBottomSegmentView = nil

            // Clear the animators
            self.primaryAnimator = nil
            self.topSegmentAnimator = nil
            self.bottomSegmentAnimator = nil
        }

        topSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeOut, animations: {
            animTopSegmentView.transform3D = skewedIdentityTransform
            animTopSegmentView.shadow.alpha = .zero
        })

        bottomSegmentAnimator = UIViewPropertyAnimator(duration: flapAnimationDuration, curve: .easeIn, animations: {
            animBottomSegmentView.transform3D = segmentDownwardRotationTransform
        })
        bottomSegmentAnimator?.addCompletion { _ in
            self.topSegmentAnimator?.startAnimation()
        }

        // Animate all the things that should start immediately
        if !interactive {
            primaryAnimator?.startAnimation()
            bottomSegmentAnimator?.startAnimation()
        }

        if let animator = primaryAnimator {
            animationProgress = animator.fractionComplete
        }
    }
}
