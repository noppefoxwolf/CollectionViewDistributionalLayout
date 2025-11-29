import UIKit

final class SafeAreaDebugView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // SafeArea枠を描画
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        context.setLineDash(phase: 0, lengths: [5, 5])
        
        let safeAreaRect = bounds.inset(by: safeAreaInsets)
        context.stroke(safeAreaRect)
        
        // 中心線を描画
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(1.0)
        context.setLineDash(phase: 0, lengths: [3, 3])
        
        // 水平中心線
        let centerY = safeAreaRect.midY
        context.move(to: CGPoint(x: safeAreaRect.minX, y: centerY))
        context.addLine(to: CGPoint(x: safeAreaRect.maxX, y: centerY))
        context.strokePath()
        
        // 垂直中心線
        let centerX = safeAreaRect.midX
        context.move(to: CGPoint(x: centerX, y: safeAreaRect.minY))
        context.addLine(to: CGPoint(x: centerX, y: safeAreaRect.maxY))
        context.strokePath()
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsDisplay()
    }
}