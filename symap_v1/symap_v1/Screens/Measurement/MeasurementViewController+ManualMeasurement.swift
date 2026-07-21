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
    
    func setupManualMeasurementUI() {
        let iconOff = UIImage(systemName: "xmark.circle")!
        let iconMont = UIImage(systemName: "scope")!
        let iconVert = UIImage(systemName: "arrow.up.and.down")!
        let iconHoriz = UIImage(systemName: "arrow.left.and.right")!
        let iconDiag = UIImage(systemName: "arrow.up.right.and.arrow.down.left")!
        
        measurementTypeSegment = UISegmentedControl(items: [iconOff, iconMont, iconVert, iconHoriz, iconDiag])
        
        // CORREÇÃO UX: Subimos o menu eliminando o espaço vazio da antiga seleção de lentes
        let instrY = measurementsContainer.frame.maxY + 15
        measurementTypeSegment.frame = CGRect(x: 15, y: instrY, width: view.bounds.width - 30, height: 35)
        measurementTypeSegment.selectedSegmentIndex = 0
        measurementTypeSegment.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        measurementTypeSegment.selectedSegmentTintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        
        let normalAttr = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let selectedAttr = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        measurementTypeSegment.setTitleTextAttributes(normalAttr, for: .normal)
        measurementTypeSegment.setTitleTextAttributes(selectedAttr, for: .selected)
        measurementTypeSegment.addTarget(self, action: #selector(measurementTypeChanged), for: .valueChanged)
        measurementTypeSegment.isHidden = true
        view.addSubview(measurementTypeSegment)
        
        manualMeasureContainer = UIView(frame: view.bounds)
        manualMeasureContainer.isUserInteractionEnabled = true
        manualMeasureContainer.backgroundColor = .clear
        manualMeasureContainer.isHidden = true
        view.addSubview(manualMeasureContainer)
        
        manualLineLayer = CAShapeLayer()
        manualLineLayer.strokeColor = UIColor.yellow.cgColor
        manualLineLayer.lineWidth = 2.0
        manualLineLayer.fillColor = UIColor.yellow.cgColor
        manualMeasureContainer.layer.addSublayer(manualLineLayer)
        
        manualHandleA = createHandle(text: "A", color: .yellow)
        manualHandleB = createHandle(text: "B", color: .yellow)
        manualMeasureContainer.addSubview(manualHandleA)
        manualMeasureContainer.addSubview(manualHandleB)
        
        manualMeasureLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 25))
        manualMeasureLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        manualMeasureLabel.textColor = .yellow
        manualMeasureLabel.textAlignment = .center
        manualMeasureLabel.font = UIFont.boldSystemFont(ofSize: 14)
        manualMeasureLabel.layer.cornerRadius = 5
        manualMeasureLabel.clipsToBounds = true
        manualMeasureContainer.addSubview(manualMeasureLabel)
        
        btnSaveManual = UIButton(frame: CGRect(x: (view.bounds.width - 160)/2, y: view.bounds.height - 150, width: 160, height: 50))
        // 🔴 PADRONIZAÇÃO: Botão Salvar Medida no padrão primário (Azul Ciano e texto preto)
        btnSaveManual.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnSaveManual.setTitle("Salvar Medida", for: .normal)
        btnSaveManual.setTitleColor(.black, for: .normal)
        btnSaveManual.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnSaveManual.layer.cornerRadius = 25
        btnSaveManual.layer.borderWidth = 2
        btnSaveManual.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        btnSaveManual.addTarget(self, action: #selector(saveManualMeasurement), for: .touchUpInside)
        btnSaveManual.isHidden = true
        view.addSubview(btnSaveManual)
    }
    
    // =========================================================================
    // ARRASTE DA RÉGUA MANUAL (RESTAURADO E OTIMIZADO)
    // =========================================================================
    @objc func handleManualPan(_ gesture: UIPanGestureRecognizer) {
        guard let v = gesture.view else { return }
        let t = gesture.translation(in: view)
        v.center = CGPoint(x: v.center.x + t.x, y: v.center.y + t.y)
        gesture.setTranslation(.zero, in: view)
        
        if currentManualMode == 2 {
            if v == manualHandleA { manualHandleB.center.x = manualHandleA.center.x }
            else if v == manualHandleB { manualHandleA.center.x = manualHandleB.center.x }
        } else if currentManualMode == 3 {
            if v == manualHandleA { manualHandleB.center.y = manualHandleA.center.y }
            else if v == manualHandleB { manualHandleA.center.y = manualHandleB.center.y }
        }
        
        // =======================================================
        // 🔴 NOVO: SISTEMA DE LUPA MINIMALISTA (MAGNIFIER)
        // =======================================================
        let loupeTag = 888
        let snapTag = 889
        
        if gesture.state == .began {
            impactFeedback.impactOccurred(intensity: 0.8)
            var loupe = view.viewWithTag(loupeTag)
            if loupe == nil {
                // Criação do aro da Lupa (100x100 redondo)
                loupe = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                loupe?.tag = loupeTag
                loupe?.layer.cornerRadius = 50
                loupe?.layer.borderWidth = 3
                loupe?.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
                loupe?.clipsToBounds = true
                loupe?.backgroundColor = .black
                loupe?.isUserInteractionEnabled = false
                view.addSubview(loupe!)
                
                // 📸 MÁGICA: Tira um print rápido e oculto apenas do rosto do paciente
                if let snap = self.sceneView.snapshotView(afterScreenUpdates: false) {
                    snap.tag = snapTag
                    snap.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // 🔍 Zoom de 2x
                    loupe?.insertSubview(snap, at: 0)
                }
                
                // 🎯 Desenha a Mira Central (Crosshair) Azul Ciano
                let chSize: CGFloat = 16
                let chThick: CGFloat = 2.0
                let vLine = UIView(frame: CGRect(x: 50 - chThick/2, y: 50 - chSize/2, width: chThick, height: chSize))
                vLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                loupe?.addSubview(vLine)
                
                let hLine = UIView(frame: CGRect(x: 50 - chSize/2, y: 50 - chThick/2, width: chSize, height: chThick))
                hLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                loupe?.addSubview(hLine)
            }
            
            loupe?.alpha = 0
            UIView.animate(withDuration: 0.2) { loupe?.alpha = 1.0 }
        }
        
        if gesture.state == .changed {
            if let loupe = view.viewWithTag(loupeTag), let snap = loupe.viewWithTag(snapTag) {
                let fingerPos = v.center
                // 1. Posiciona a lupa 80 pixels ACIMA do dedo para não ser tampada
                loupe.center = CGPoint(x: fingerPos.x, y: fingerPos.y - 80)
                
                // 2. Cálculo trigonométrico reverso para arrastar o mapa do rosto na velocidade 2x
                let offsetX = view.bounds.width / 2 - fingerPos.x
                let offsetY = view.bounds.height / 2 - fingerPos.y
                snap.center = CGPoint(x: 50 + offsetX * 2.0, y: 50 + offsetY * 2.0)
            }
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            if let loupe = view.viewWithTag(loupeTag) {
                UIView.animate(withDuration: 0.2, animations: {
                    loupe.alpha = 0
                }) { _ in
                    loupe.removeFromSuperview()
                }
            }
        }
        
        impactFeedback.impactOccurred(intensity: 0.4)
        updateManualMeasurement()
    }
    
    @objc func measurementTypeChanged() {
        let index = measurementTypeSegment.selectedSegmentIndex
        if index == 0 { saveManualMeasurement() } else { startManualMeasurement(mode: index) }
    }
    
    func updateSegmentTitles() {
        let iconMont = pupillaryHeight > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "scope")!
        let iconVert = manualFrameHeight > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.up.and.down")!
        let iconHoriz = manualFrameWidth > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.left.and.right")!
        let iconDiag = manualFrameDiagonal > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.up.right.and.arrow.down.left")!
        
        measurementTypeSegment.setImage(iconMont, forSegmentAt: 1)
        measurementTypeSegment.setImage(iconVert, forSegmentAt: 2)
        measurementTypeSegment.setImage(iconHoriz, forSegmentAt: 3)
        measurementTypeSegment.setImage(iconDiag, forSegmentAt: 4)
    }
    
    // =========================================================================
    // INICIA A MEDIÇÃO MANUAL
    // =========================================================================
    func startManualMeasurement(mode: Int) {
        currentManualMode = mode
        btnSaveManual.isHidden = false
        
        // 🔴 Trava o seletor para obrigar o clique no Salvar Medida
        measurementTypeSegment.isEnabled = false
        updateManualInterface(active: true)
        
        if !drawingToolsContainer.isHidden { toggleDrawingPanel() }
        
        let cx = view.bounds.midX
        let cy = view.bounds.midY
        
        manualMeasureContainer.isHidden = true
        heightLineView.isHidden = true
        heightLineView.isUserInteractionEnabled = false
        
        if mode == 1 {
            heightLineView.isHidden = false
            heightLineView.isUserInteractionEnabled = true
            heightLineView.alpha = 1.0
            
            if pupillaryHeight == 0 {
                heightLineView.center.y = cy + 50
                calculatePupilHeight()
            }
        } else if mode >= 2 && mode <= 4 {
            manualMeasureContainer.isHidden = false
            
            if mode == 2 {
                manualHandleA.center = CGPoint(x: cx, y: cy - 40); manualHandleB.center = CGPoint(x: cx, y: cy + 40)
            } else if mode == 3 {
                manualHandleA.center = CGPoint(x: cx - 60, y: cy); manualHandleB.center = CGPoint(x: cx + 60, y: cy)
            } else if mode == 4 {
                manualHandleA.center = CGPoint(x: cx - 50, y: cy - 40); manualHandleB.center = CGPoint(x: cx + 50, y: cy + 40)
            }
            updateManualMeasurement()
        }
        
        // 🔴 INTELIGÊNCIA UX: Dispara o Popup do Passo a Passo (se não foi silenciado)
        let hideKey = "hideManualStep\(mode)"
        if !UserDefaults.standard.bool(forKey: hideKey) {
            let tut = SingleStepManualTutorialView(step: mode, frame: self.view.bounds)
            tut.onClose = { [weak tut] in
                UIView.animate(withDuration: 0.3, animations: { tut?.alpha = 0 }) { _ in tut?.removeFromSuperview() }
            }
            tut.alpha = 0
            self.view.addSubview(tut)
            UIView.animate(withDuration: 0.3) { tut.alpha = 1.0 }
        }
    }
    
    @objc func saveManualMeasurement() {
        manualMeasureContainer.isHidden = true
        heightLineView.isHidden = true
        heightLineView.isUserInteractionEnabled = false
        btnSaveManual.isHidden = true
        currentManualMode = 0
        
        // 🔴 Libera o seletor novamente
        measurementTypeSegment.isEnabled = true
        if measurementTypeSegment.selectedSegmentIndex != 0 {
            measurementTypeSegment.selectedSegmentIndex = 0
        }
        
        updateManualInterface(active: false)
        updateSegmentTitles()
        btnSaveManual.setTitle("Salvar Medida", for: .normal)
    }
    
    // =========================================================================
    // ATUALIZA A RÉGUA EM TEMPO REAL (Cálculo Físico 3D)
    // =========================================================================
    func updateManualMeasurement() {
        let p1 = manualHandleA.center; let p2 = manualHandleB.center
        
        let path = UIBezierPath()
        path.move(to: p1); path.addLine(to: p2)
        
        let angle = atan2(p2.y - p1.y, p2.x - p1.x)
        let arrowSize: CGFloat = 10.0
        
        path.move(to: p1); path.addLine(to: CGPoint(x: p1.x + arrowSize * cos(angle + .pi/6), y: p1.y + arrowSize * sin(angle + .pi/6)))
        path.move(to: p1); path.addLine(to: CGPoint(x: p1.x + arrowSize * cos(angle - .pi/6), y: p1.y + arrowSize * sin(angle - .pi/6)))
        
        path.move(to: p2); path.addLine(to: CGPoint(x: p2.x + arrowSize * cos(angle + .pi - .pi/6), y: p2.y + arrowSize * sin(angle + .pi - .pi/6)))
        path.move(to: p2); path.addLine(to: CGPoint(x: p2.x + arrowSize * cos(angle + .pi + .pi/6), y: p2.y + arrowSize * sin(angle + .pi + .pi/6)))
        
        manualLineLayer.path = path.cgPath
        
        let labelY = measurementTypeSegment.frame.maxY + 10
        let labelW: CGFloat = 120
        let labelX = view.bounds.width - labelW - 20
        manualMeasureLabel.frame = CGRect(x: labelX, y: labelY, width: labelW, height: 30)
        
        if let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView {
            let frameRef = BiometryEngine.frameReferencePoint(
                leftEye: simd_float3(lEye.x, lEye.y, lEye.z),
                rightEye: simd_float3(rEye.x, rEye.y, rEye.z),
                cameraPos: simd_float3(cam.worldPosition.x, cam.worldPosition.y, cam.worldPosition.z))
            
            let frameZPos = SCNVector3(frameRef.x, frameRef.y, frameRef.z)
            let frameScreenZ = sceneView.projectPoint(frameZPos).z
            
            let p3DA = sceneView.unprojectPoint(SCNVector3(Float(p1.x), Float(p1.y), frameScreenZ))
            let p3DB = sceneView.unprojectPoint(SCNVector3(Float(p2.x), Float(p2.y), frameScreenZ))
            
            let rawDistMm = BiometryEngine.distanceMm(simd_float3(p3DA.x, p3DA.y, p3DA.z), simd_float3(p3DB.x, p3DB.y, p3DB.z))
            var distMm: Float = 0.0
            
            // Aplicação das Constantes de Calibração Pura (BiometryEngine)
            if currentManualMode == 2 {
                distMm = rawDistMm * CalibrationFactors.manualHeight
                manualFrameHeight = distMm
            } else if currentManualMode == 3 {
                distMm = rawDistMm * CalibrationFactors.manualWidth
                manualFrameWidth = distMm
            } else if currentManualMode == 4 {
                distMm = rawDistMm * CalibrationFactors.manualDiagonal
                manualFrameDiagonal = distMm
            } else if currentManualMode == 1 {
                distMm = rawDistMm * CalibrationFactors.pupilHeight
                pupillaryHeight = distMm
                updateLabels()
            }
            
            manualMeasureLabel.text = String(format: "%.1f mm", distMm)
        }
    }
    // =========================================================================
        // --- GESTOS DA RÉGUA DE ALTURA PUPILAR (LINHA VERMELHA) ---
        // =========================================================================
        @objc func handlePanGesture(_ g: UIPanGestureRecognizer) {
            guard isFrozen, let line = heightLineView, !line.isHidden, heightLineView.isUserInteractionEnabled else { return }
            let t = g.translation(in: view)
            line.center.y = max(100, min(view.bounds.height-100, line.center.y + t.y))
            g.setTranslation(.zero, in: view)
            calculatePupilHeight()
        }

        @objc func calculatePupilHeight() {
            guard let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView else { return }
            let ep = sceneView.projectPoint(lEye)
            let redLineY = Float(heightLineView.center.y)
            
            if redLineY < ep.y {
                pupillaryHeight = 0.0
                heightLineLabel.text = "H: 0.0 mm"
                return
            }
            
            let cx = (lEye.x + rEye.x) / 2.0
            let cy = (lEye.y + rEye.y) / 2.0
            let cz = (lEye.z + rEye.z) / 2.0
            
            let camPos = cam.worldPosition
            let dirX = camPos.x - cx
            let dirY = camPos.y - cy
            let dirZ = camPos.z - cz
            let distance = sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
            
            let frameZPos = SCNVector3(cx + (dirX / distance) * 0.015, cy + (dirY / distance) * 0.015, cz + (dirZ / distance) * 0.015)
            let frameScreenZ = sceneView.projectPoint(frameZPos).z
            
            let p3DEye = sceneView.unprojectPoint(SCNVector3(ep.x, ep.y, frameScreenZ))
            let p3DLine = sceneView.unprojectPoint(SCNVector3(ep.x, redLineY, frameScreenZ))
            
            let rawHMm = sqrt(pow(p3DLine.x - p3DEye.x, 2) + pow(p3DLine.y - p3DEye.y, 2) + pow(p3DLine.z - p3DEye.z, 2)) * 1000.0
            
            let hMm = rawHMm * CalibrationFactors.pupilHeight
            pupillaryHeight = hMm
            heightLineLabel.text = String(format: "H: %.1f mm", hMm)
            updateLabels()
        }
}
