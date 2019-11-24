// MARK: - Configuration

import UIKit

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

    private let topSegment = FlapSegmentView(position: .top)
    private let bottomSegment = FlapSegmentView(position: .bottom)

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

        if !tokens.isEmpty {
            nextToken(animationDuration: .zero)
        }
    }

    public func nextToken(animationDuration: TimeInterval = Constants.defaultAnimationDuration) {
        updateIndex(by: 1)
        let token = tokens[currentIndex]
        topSegment.set(character: token)
        bottomSegment.set(character: token)
    }

    public func previousToken(animationDuration: TimeInterval = Constants.defaultAnimationDuration) {
        updateIndex(by: -1)
        let token = tokens[currentIndex]
        topSegment.set(character: token)
        bottomSegment.set(character: token)
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
