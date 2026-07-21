import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import PDFKit
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import simd
import PencilKit
import FirebaseStorage
import AVFoundation

extension MeasurementViewController {
    
    func setupLensSelectorUI() {
        let items = ["Visão Simples", "Multifocal", "Bifocal", "Ocupacional"]
        lensTypeSegment = UISegmentedControl(items: items)
        
        let instrY = measurementsContainer.frame.maxY + 15
        lensTypeSegment.frame = CGRect(x: 15, y: instrY, width: view.bounds.width - 30, height: 35)
        lensTypeSegment.selectedSegmentIndex = 0
        lensTypeSegment.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        lensTypeSegment.selectedSegmentTintColor = UIColor.systemBlue
        
        let normalAttr = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let selectedAttr = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        lensTypeSegment.setTitleTextAttributes(normalAttr, for: .normal)
        lensTypeSegment.setTitleTextAttributes(selectedAttr, for: .selected)
        lensTypeSegment.addTarget(self, action: #selector(lensTypeChanged), for: .valueChanged)
        lensTypeSegment.isHidden = true
        view.addSubview(lensTypeSegment)
    }

    @objc func lensTypeChanged() {
        selectedLensType = lensTypeSegment.titleForSegment(at: lensTypeSegment.selectedSegmentIndex) ?? "Visão Simples"
    }

    // =========================================================================
    // --- SISTEMA DE DESENHO LIVRE (PENCILKIT) ---
    // =========================================================================
    func setupDrawingSystem() {
        canvasView = PKCanvasView(frame: view.bounds)
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.isHidden = true
        view.insertSubview(canvasView, aboveSubview: sceneView)
        
        let paletteW: CGFloat = 320
        let paletteH: CGFloat = 60
        let btnY = view.bounds.height - 100
        let bottomButtonY = btnY + 10
        let gap: CGFloat = 15
        let buttonSize: CGFloat = 60
        let pencilY = bottomButtonY - (buttonSize + gap)
        
        drawingToolsContainer = UIView(frame: CGRect(x: 100, y: pencilY, width: paletteW, height: paletteH))
        drawingToolsContainer.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        drawingToolsContainer.layer.cornerRadius = 30
        drawingToolsContainer.layer.borderWidth = 1
        drawingToolsContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        drawingToolsContainer.isHidden = true
        drawingToolsContainer.alpha = 0.0
        view.addSubview(drawingToolsContainer)
        
        let btnSize: CGFloat = 44
        let btnSpacing = (paletteW - (btnSize * 5)) / 6
        let toolY: CGFloat = (paletteH - btnSize) / 2
        
        func createColorBtn(color: UIColor, index: Int, action: Selector) -> UIButton {
            let x = btnSpacing + CGFloat(index) * (btnSize + btnSpacing)
            let b = UIButton(frame: CGRect(x: x, y: toolY, width: btnSize, height: btnSize))
            b.backgroundColor = color
            b.layer.cornerRadius = btnSize / 2
            b.layer.borderWidth = 2
            b.layer.borderColor = UIColor.white.cgColor
            b.addTarget(self, action: action, for: .touchUpInside)
            return b
        }
        
        btnDrawRed = createColorBtn(color: .red, index: 0, action: #selector(setToolRed))
        btnDrawBlack = createColorBtn(color: .black, index: 1, action: #selector(setToolBlack))
        btnDrawBlue = createColorBtn(color: .blue, index: 2, action: #selector(setToolBlue))
        
        btnEraser = UIButton(frame: CGRect(x: btnSpacing + 3 * (btnSize + btnSpacing), y: toolY, width: btnSize, height: btnSize))
        btnEraser.backgroundColor = .gray
        btnEraser.setTitle("🧹", for: .normal)
        btnEraser.layer.cornerRadius = btnSize / 2
        btnEraser.addTarget(self, action: #selector(setToolEraser), for: .touchUpInside)
        
        btnClearDrawing = UIButton(frame: CGRect(x: btnSpacing + 4 * (btnSize + btnSpacing), y: toolY, width: btnSize, height: btnSize))
        btnClearDrawing.backgroundColor = .darkGray
        btnClearDrawing.setTitle("🗑️", for: .normal)
        btnClearDrawing.layer.cornerRadius = btnSize / 2
        btnClearDrawing.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        
        drawingToolsContainer.addSubview(btnDrawRed)
        drawingToolsContainer.addSubview(btnDrawBlack)
        drawingToolsContainer.addSubview(btnDrawBlue)
        drawingToolsContainer.addSubview(btnEraser)
        drawingToolsContainer.addSubview(btnClearDrawing)
    }

    @objc func activateDrawingMode() {
        isDrawingActive = true
        canvasView.isHidden = false
        canvasView.isUserInteractionEnabled = true
        btnToggleDrawing.backgroundColor = UIColor.systemGray
        btnToggleDrawing.transform = .identity
        
        UIView.animate(withDuration: 0.2) {
            self.drawingToolsContainer.alpha = 0.0
            self.drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0)
        } completion: { _ in
            self.drawingToolsContainer.isHidden = true
        }
    }

    @objc func setToolRed() { canvasView.tool = PKInkingTool(.marker, color: .red, width: 5); highlightBtn(btnDrawRed); activateDrawingMode() }
    @objc func setToolBlack() { canvasView.tool = PKInkingTool(.marker, color: .black, width: 5); highlightBtn(btnDrawBlack); activateDrawingMode() }
    @objc func setToolBlue() { canvasView.tool = PKInkingTool(.marker, color: .blue, width: 5); highlightBtn(btnDrawBlue); activateDrawingMode() }
    @objc func setToolEraser() { canvasView.tool = PKEraserTool(.bitmap); highlightBtn(btnEraser); activateDrawingMode() }
    @objc func clearCanvas() { canvasView.drawing = PKDrawing() }

    func highlightBtn(_ sender: UIButton) {
        let buttons = [btnDrawRed, btnDrawBlack, btnDrawBlue, btnEraser]
        buttons.forEach {
            $0?.transform = .identity
            $0?.alpha = 0.6
        }
        sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        sender.alpha = 1.0
    }

    @objc func toggleDrawingPanel() {
        if isDrawingActive {
            isDrawingActive = false
            canvasView.isUserInteractionEnabled = false
            btnToggleDrawing.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
            btnToggleDrawing.transform = .identity
            drawingToolsContainer.isHidden = true
            drawingToolsContainer.alpha = 0.0
        } else {
            if drawingToolsContainer.isHidden {
                drawingToolsContainer.isHidden = false
                drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0)
                drawingToolsContainer.alpha = 0.0
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                    self.drawingToolsContainer.transform = .identity
                    self.drawingToolsContainer.alpha = 1.0
                }
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.drawingToolsContainer.alpha = 0.0
                    self.drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0)
                }) { _ in
                    self.drawingToolsContainer.isHidden = true
                }
            }
        }
    }
}
