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

    private let topSegment = SplitflapSegmentView(position: .top)
    private let bottomSegment = SplitflapSegmentView(position: .bottom)

    private var currentIndex = -1

    private var animating = false

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
        topSegment.frame = CGRect(x: 0, y: 0, width: bounds.width, height: segmentHeight)
        bottomSegment.frame = CGRect(x: 0, y: segmentHeight, width: bounds.width, height: segmentHeight)
    }

    private func commonInit() {
        addSubview(topSegment)
        addSubview(bottomSegment)

        topSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        bottomSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 0)

        let topSegmentGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(topSegmentTapped(_:)))
        topSegment.addGestureRecognizer(topSegmentGestureRecognizer)

        let bottomSegmentGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(bottomSegmentTapped(_:)))
        bottomSegment.addGestureRecognizer(bottomSegmentGestureRecognizer)

        if !tokens.isEmpty {
            nextToken(animationDuration: .zero)
        }
    }

    public func nextToken(animationDuration: TimeInterval = Constants.defaultAnimationDuration) {
        guard !animating else { return }

        updateIndex(by: 1)

        let token = tokens[currentIndex]

        guard animationDuration > 0.0 else {
            topSegment.set(character: token)
            bottomSegment.set(character: token)
            return
        }

        animating = true

        let animTopSegment = SplitflapSegmentView(position: .top)
        let animBottomSegment = SplitflapSegmentView(position: .bottom)

        animTopSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegment.frame = topSegment.frame
        animBottomSegment.frame = bottomSegment.frame

        addSubview(animTopSegment)
        addSubview(animBottomSegment)

        animTopSegment.set(character: topSegment.token)
        animBottomSegment.set(character: token)
        topSegment.set(character: token)

        topSegment.transform3D = skewedIdentityTransform
        animBottomSegment.transform3D = segmentDownwardRotationTransform
        topSegment.shadow.alpha = .zero
        bottomSegment.shadow.alpha = .zero

        let flapAnimationDuration = animationDuration / 2

        UIView.animate(withDuration: flapAnimationDuration, delay: .zero, options: [.curveEaseIn], animations: {
            animTopSegment.transform3D = segmentUpwardRotationTransform
            animTopSegment.shadow.alpha = Constants.maxShadowAlpha / 2
        }, completion: { _ in
            animTopSegment.removeFromSuperview()
        })

        UIView.animate(withDuration: flapAnimationDuration, delay: flapAnimationDuration, options: [.curveEaseOut], animations: {
            animBottomSegment.transform3D = skewedIdentityTransform
        }, completion: { _ in
            self.bottomSegment.set(character: token)
            animBottomSegment.removeFromSuperview()
        })

        UIView.animate(withDuration: animationDuration, delay: .zero, options: [.curveEaseIn], animations: {
            self.bottomSegment.shadow.alpha = Constants.maxShadowAlpha
        }, completion: { _ in
            self.bottomSegment.shadow.alpha = .zero
            self.animating = false
        })
    }

    public func previousToken(animationDuration: TimeInterval = Constants.defaultAnimationDuration) {
        guard !animating else { return }

        updateIndex(by: -1)

        let token = tokens[currentIndex]

        guard animationDuration > .zero else {
            topSegment.set(character: token)
            bottomSegment.set(character: token)
            return
        }

        animating = true

        let animTopSegment = SplitflapSegmentView(position: .top)
        let animBottomSegment = SplitflapSegmentView(position: .bottom)

        animTopSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        animBottomSegment.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        animTopSegment.frame = topSegment.frame
        animBottomSegment.frame = bottomSegment.frame

        addSubview(animTopSegment)
        addSubview(animBottomSegment)

        animTopSegment.set(character: token)
        animBottomSegment.set(character: bottomSegment.token)
        bottomSegment.set(character: token)

        animTopSegment.transform3D = segmentUpwardRotationTransform
        animTopSegment.shadow.alpha = Constants.maxShadowAlpha / 2
        animBottomSegment.transform3D = skewedIdentityTransform
        bottomSegment.shadow.alpha = Constants.maxShadowAlpha

        let flapAnimationDuration = animationDuration / 2

        UIView.animate(withDuration: flapAnimationDuration, delay: .zero, options: [.curveEaseIn], animations: {
            animBottomSegment.transform3D = segmentDownwardRotationTransform
        }, completion: { _ in
            animBottomSegment.removeFromSuperview()
        })

        UIView.animate(withDuration: flapAnimationDuration, delay: flapAnimationDuration, options: [.curveEaseOut], animations: {
            animTopSegment.transform3D = skewedIdentityTransform
            animTopSegment.shadow.alpha = .zero
        }, completion: { _ in
            self.topSegment.set(character: token)
            animTopSegment.removeFromSuperview()
        })

        UIView.animate(withDuration: animationDuration, delay: .zero, options: [.curveEaseOut], animations: {
            self.bottomSegment.shadow.alpha = .zero
        }, completion: { _ in
            self.animating = false
        })
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
}
