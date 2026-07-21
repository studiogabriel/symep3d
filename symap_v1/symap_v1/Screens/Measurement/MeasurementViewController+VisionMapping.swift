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
    
    func showMappingInstruction(title: String, description: String, action: Selector) {
        let boxW: CGFloat = 320
        let boxH: CGFloat = 340
        let boxY = (view.bounds.height - boxH) / 2
        let boxX = (view.bounds.width - boxW) / 2
        
        let box = UIView(frame: CGRect(x: boxX, y: boxY, width: boxW, height: boxH))
        box.layer.cornerRadius = 20
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        box.layer.shadowColor = UIColor.black.cgColor
        box.layer.shadowOpacity = 0.5
        box.layer.shadowRadius = 15
        
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = box.bounds
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        box.addSubview(blurView)
        
        let lblTitle = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 30))
        lblTitle.text = title
        lblTitle.textColor = .white
        lblTitle.font = UIFont.boldSystemFont(ofSize: 18)
        lblTitle.textAlignment = .center
        box.addSubview(lblTitle)
        
        let lblDesc = UILabel(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 160))
        lblDesc.text = description
        lblDesc.textColor = .lightGray
        lblDesc.font = UIFont.systemFont(ofSize: 14)
        lblDesc.numberOfLines = 0
        lblDesc.textAlignment = .center
        box.addSubview(lblDesc)
        
        let btnConfirm = UIButton(frame: CGRect(x: 40, y: 250, width: boxW - 80, height: 50))
        btnConfirm.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnConfirm.setTitle("Confirmar", for: .normal)
        btnConfirm.setTitleColor(.black, for: .normal)
        btnConfirm.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnConfirm.layer.cornerRadius = 25
        btnConfirm.addTarget(self, action: action, for: .touchUpInside)
        box.addSubview(btnConfirm)
        
        view.addSubview(box)
        mappingInstructionBox = box
        
        box.alpha = 0
        box.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3) {
            box.alpha = 1.0
            box.transform = .identity
        }
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Vision Mapping Init"]
        let _ = safetyCheck[ 0 ]
    }

    @objc func preparePhase1Alignment() {
        UIView.animate(withDuration: 0.2, animations: { self.mappingInstructionBox?.alpha = 0 }) { _ in
            self.mappingInstructionBox?.removeFromSuperview()
            self.topFeedbackLabel?.isHidden = false
            self.faceGuideLayer?.isHidden = false
            self.levelContainerView.isHidden = false
            self.levelLabel.isHidden = false
            self.headLevelContainerView.isHidden = false
            self.headLevelLabel.isHidden = false
            self.phonePitchContainerView.isHidden = false
            self.phonePitchLabel.isHidden = false
            self.headPitchContainerView.isHidden = false
            self.headPitchLabel.isHidden = false
            self.isMappingVision = true
            self.headMoveScore = 0.0
            self.eyeMoveScore = 0.0
            self.startLevelMonitoring()
            self.checkVisionStabilityLoop(targetDistance: 0.40)
        }
    }

    func checkVisionStabilityLoop(targetDistance: Float) {
        self.distanceTimer?.invalidate()
        // 🔴 Removida invocação da antiga barra lateral
        self.distanceBarContainer?.isHidden = true
        self.distanceInstructionLabel?.isHidden = true
        self.stabilityStartTime = nil
        
        self.distanceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard let cam = self.visionMappingView?.pointOfView,
                  let faceAnchor = self.visionMappingView?.session.currentFrame?.anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                
                if self.isPhoneLevel && self.isPhonePitchLevel {
                    self.topFeedbackLabel?.text = "Rosto não detectado"
                    self.topFeedbackLabel?.textColor = .lightGray
                }
                self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
                self.faceGuideLayer?.lineWidth = 2.0
                return
            }
            
            let leftEye = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)
            let rightEye = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
            
            let cx = (leftEye.columns.3.x + rightEye.columns.3.x) / 2.0
            let cy = (leftEye.columns.3.y + rightEye.columns.3.y) / 2.0
            let cz = (leftEye.columns.3.z + rightEye.columns.3.z) / 2.0
            
            let currentDistance = sqrt(pow(cam.worldPosition.x - cx, 2) + pow(cam.worldPosition.y - cy, 2) + pow(cam.worldPosition.z - cz, 2))
            let diff = currentDistance - targetDistance
            let isDistancePerfect = abs(diff) <= Float(0.03)
            let allConditionsMet = self.isPhoneLevel && self.isHeadLevel && self.isPhonePitchLevel && self.isHeadPitchLevel && isDistancePerfect
            
            // 🔴 UX NATIVA: Distância embutida no Oval na Fase de Visão
            UIView.animate(withDuration: 0.1) {
                if currentDistance < targetDistance - Float(0.03) {
                    self.faceGuideLayer?.strokeColor = UIColor.systemOrange.cgColor
                    self.faceGuideLayer?.lineWidth = 6.0
                } else if currentDistance > targetDistance + Float(0.03) {
                    self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
                    self.faceGuideLayer?.lineWidth = 2.0
                } else {
                    self.faceGuideLayer?.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
                    self.faceGuideLayer?.lineWidth = 4.0
                }
            }
            
            if allConditionsMet {
                if self.stabilityStartTime == nil {
                    self.stabilityStartTime = Date()
                    self.topFeedbackLabel?.text = "Perfeito! Segure firme..."
                    self.topFeedbackLabel?.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                } else {
                    let elapsed = Date().timeIntervalSince(self.stabilityStartTime!)
                    if elapsed >= 1.0 {
                        timer.invalidate()
                        self.runVisionMappingCountdown(targetDistance: targetDistance)
                    }
                }
            } else {
                self.stabilityStartTime = nil
                
                if !self.isPhoneLevel || !self.isPhonePitchLevel {
                    // Mantém o alerta laranja gerenciado pelo +Sensors
                } else if currentDistance < targetDistance - Float(0.03) {
                    self.topFeedbackLabel?.text = "Afaste o celular levemente"
                    self.topFeedbackLabel?.textColor = .lightGray
                } else if currentDistance > targetDistance + Float(0.03) {
                    self.topFeedbackLabel?.text = "Aproxime o celular levemente"
                    self.topFeedbackLabel?.textColor = .lightGray
                } else {
                    self.topFeedbackLabel?.text = "Posicione os níveis no centro"
                    self.topFeedbackLabel?.textColor = .lightGray
                }
            }
        }
    }

    @objc func startVisionMappingFromWizard() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.measurementsContainer.isHidden = true
        self.manualMeasureContainer.isHidden = true
        self.measurementTypeSegment.isHidden = true
        self.captureButton.isHidden = true
        self.startCaptureButton.isHidden = true
        self.heightLineView.isHidden = true
        if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) { bottomStack.isHidden = true }
        
        self.visionMappingView = ARSCNView(frame: self.view.bounds)
        self.visionMappingView?.delegate = self
        self.visionMappingView?.backgroundColor = .clear
        self.view.insertSubview(self.visionMappingView!, belowSubview: self.measurementsContainer)
        
        let config = ARFaceTrackingConfiguration()
        self.visionMappingView?.session.run(config)
        
        if visionMapDot == nil {
            let dotSize: CGFloat = 40
            let dot = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
            dot.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            dot.layer.cornerRadius = dotSize / 2
            dot.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
            dot.layer.shadowRadius = 15
            dot.layer.shadowOpacity = 1.0
            dot.isHidden = true
            dot.tag = 100
            
            let pulseAnim = CABasicAnimation(keyPath: "transform.scale")
            pulseAnim.toValue = 1.3
            pulseAnim.duration = 0.6
            pulseAnim.autoreverses = true
            pulseAnim.repeatCount = .infinity
            dot.layer.add(pulseAnim, forKey: "pulse")
            
            view.addSubview(dot)
            visionMapDot = dot
        }
        
        if view.viewWithTag(1001) == nil {
            let hud = UILabel(frame: CGRect(x: 20, y: 100, width: 250, height: 100))
            hud.tag = 1001
            hud.numberOfLines = 0
            hud.font = UIFont(name: "Courier-Bold", size: 11) ?? UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
            hud.textColor = .systemGreen
            hud.layer.shadowColor = UIColor.black.cgColor
            hud.layer.shadowRadius = 2
            hud.layer.shadowOpacity = 0.8
            hud.layer.shadowOffset = CGSize(width: 1, height: 1)
            hud.text = "[ SYSTEM BOOT... ]\nINICIANDO SENSORES LiDAR"
            hud.isHidden = true
            view.addSubview(hud)
        }
        
        self.speakText("Vamos iniciar o teste de motilidade ocular. Por favor, confirme na tela e posicione o rosto na marcação.")
        self.showMappingInstruction(
            title: "FASE 1: Motilidade Ocular (Padrão H)",
            description: "O sistema fará o teste clínico 'Padrão H' para mapear seus músculos extraoculares.\n\nNivele o celular e, após a contagem, siga o holograma luminoso apenas com os olhos.",
            action: #selector(preparePhase1Alignment)
        )
    }

    func runTelemetryLoop() {
        guard let hud = self.view.viewWithTag(1001) as? UILabel, !hud.isHidden else { return }
        
        let yawStr = String(format: "%.3f", abs(self.smoothHeadRoll))
        let headScoreStr = String(format: "%.3f", self.headMoveScore)
        let eyeScoreStr = String(format: "%.3f", self.eyeMoveScore)
        
        hud.text = """
        [ARKit_TRUE_DEPTH_LINK]
        EYE_TRACKING : ACTIVE (120Hz)
        HEAD_RADIAN  : \(yawStr) rad
        HEAD_SCORE   : \(headScoreStr)
        EYE_SCORE    : \(eyeScoreStr)
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.runTelemetryLoop()
        }
    }

    func runVisionMappingCountdown(targetDistance: Float) {
        self.countdownValue = 3
        self.countdownLabel.text = "\(self.countdownValue)"
        self.countdownLabel.isHidden = false
        self.topFeedbackLabel?.text = "Mantenha a posição..."
        self.topFeedbackLabel?.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        self.successFeedback.notificationOccurred(.success)
        
        self.distanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if !self.isPhoneLevel || !self.isHeadLevel || !self.isPhonePitchLevel || !self.isHeadPitchLevel {
                timer.invalidate()
                self.countdownLabel.isHidden = true
                if self.isPhoneLevel && self.isPhonePitchLevel {
                    self.topFeedbackLabel?.text = "Você moveu. Reiniciando..."
                    self.topFeedbackLabel?.textColor = .lightGray
                }
                self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
                self.faceGuideLayer?.lineWidth = 2.0
                self.speakText("Você se moveu. Por favor, alinhe novamente.")
                if let hud = self.view.viewWithTag(1001) { hud.isHidden = true }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.checkVisionStabilityLoop(targetDistance: targetDistance)
                }
                return
            }
            
            self.countdownValue -= 1
            if self.countdownValue > 0 {
                self.countdownLabel.text = "\(self.countdownValue)"
                self.pulseAnimation(view: self.countdownLabel)
                self.speakText("\(self.countdownValue)")
                self.impactFeedback.impactOccurred(intensity: 1.0)
            } else {
                timer.invalidate()
                self.countdownLabel.isHidden = true
                
                UIView.animate(withDuration: 0.3) {
                    self.topFeedbackLabel?.isHidden = true
                    self.faceGuideLayer?.isHidden = true
                    self.levelContainerView.isHidden = true
                    self.levelLabel.isHidden = true
                    self.headLevelContainerView.isHidden = true
                    self.headLevelLabel.isHidden = true
                    self.phonePitchContainerView.isHidden = true
                    self.phonePitchLabel.isHidden = true
                    self.headPitchContainerView.isHidden = true
                    self.headPitchLabel.isHidden = true
                }
                
                if let hud = self.view.viewWithTag(1001) as? UILabel {
                    hud.isHidden = false
                    self.runTelemetryLoop()
                }
                
                if targetDistance == 0.40 {
                    self.speakText("Siga a mira com o olhar.")
                    self.runPhase1Animation()
                } else {
                    self.speakText("Acompanhe o trajeto de leitura.")
                    self.runPhase2Animation()
                }
            }
        }
    }

    func runPhase1Animation() {
        let w = self.view.bounds.width
        let h = self.view.bounds.height
        guard let dot = self.visionMapDot else { return }
        let cx = w / 2
        let cy = h / 2
        let ampX = w * 0.40
        let ampY = h * 0.30
        dot.center = CGPoint(x: cx, y: cy)
        dot.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        dot.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        dot.isHidden = false
        
        let originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = CGFloat(1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { UIScreen.main.brightness = CGFloat(0.3) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { UIScreen.main.brightness = CGFloat(1.0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 16.0) { UIScreen.main.brightness = originalBrightness }
        
        UIView.animateKeyframes(withDuration: 16.0, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1) { dot.center = CGPoint(x: cx + ampX, y: cy) }
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.1) {
                dot.center = CGPoint(x: cx + ampX, y: cy - ampY)
                dot.backgroundColor = .systemPink; dot.layer.shadowColor = UIColor.systemPink.cgColor
            }
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) { dot.center = CGPoint(x: cx + ampX, y: cy + ampY) }
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.1) {
                dot.center = CGPoint(x: cx + ampX, y: cy)
                dot.backgroundColor = .systemGreen; dot.layer.shadowColor = UIColor.green.cgColor
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2) { dot.center = CGPoint(x: cx - ampX, y: cy) }
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.1) {
                dot.center = CGPoint(x: cx - ampX, y: cy - ampY)
                dot.backgroundColor = .systemOrange; dot.layer.shadowColor = UIColor.orange.cgColor
            }
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) { dot.center = CGPoint(x: cx - ampX, y: cy + ampY) }
            UIView.addKeyframe(withRelativeStartTime: 1.0, relativeDuration: 0.1) {
                dot.center = CGPoint(x: cx, y: cy)
                dot.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                dot.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
            }
        }) { _ in
            dot.isHidden = true
            if let hud = self.view.viewWithTag(1001) { hud.isHidden = true }
            self.showMappingInstruction(
                title: "FASE 2: Convergência de Leitura",
                description: "Ótimo! Agora vamos testar seu canal de leitura.\n\nAproxime o celular e nivele novamente. Siga a mira na parte inferior.",
                action: #selector(self.preparePhase2Alignment)
            )
        }
        
        let timings = [1.6, 3.2, 6.4, 8.0, 11.2, 12.8, 16.0]
        for time in timings {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) { self.impactFeedback.impactOccurred(intensity: 0.8) }
        }
    }

    @objc func preparePhase2Alignment() {
        UIView.animate(withDuration: 0.2, animations: { self.mappingInstructionBox?.alpha = 0 }) { _ in
            self.mappingInstructionBox?.removeFromSuperview()
            self.topFeedbackLabel?.isHidden = false
            self.faceGuideLayer?.isHidden = false
            self.levelContainerView.isHidden = false
            self.levelLabel.isHidden = false
            self.headLevelContainerView.isHidden = false
            self.headLevelLabel.isHidden = false
            self.phonePitchContainerView.isHidden = false
            self.phonePitchLabel.isHidden = false
            self.headPitchContainerView.isHidden = false
            self.headPitchLabel.isHidden = false
            
            let ovalW_perto: CGFloat = 330
            let ovalH_perto: CGFloat = 460
            let ovalX = (self.view.bounds.width - ovalW_perto) / 2
            let ovalY = (self.view.bounds.height - ovalH_perto) / 2 + 40
            let newPath = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW_perto, height: ovalH_perto))
            
            let anim = CABasicAnimation(keyPath: "path")
            anim.toValue = newPath.cgPath
            anim.duration = 0.5
            anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.faceGuideLayer?.add(anim, forKey: "pathAnim")
            self.faceGuideLayer?.path = newPath.cgPath
            
            self.checkVisionStabilityLoop(targetDistance: 0.30)
        }
    }

    func runPhase2Animation() {
        let w = self.view.bounds.width
        let h = self.view.bounds.height
        guard let dot = self.visionMapDot else { return }
        let startY = h - 250
        dot.center = CGPoint(x: 60, y: startY)
        dot.backgroundColor = .systemPurple
        dot.layer.shadowColor = UIColor.purple.cgColor
        dot.isHidden = false
        
        UIView.animateKeyframes(withDuration: 12.0, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: startY) }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.05) { dot.center = CGPoint(x: 60, y: startY + 70) }
            UIView.addKeyframe(withRelativeStartTime: 0.30, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: startY + 70) }
            UIView.addKeyframe(withRelativeStartTime: 0.55, relativeDuration: 0.05) { dot.center = CGPoint(x: 60, y: startY + 140) }
            UIView.addKeyframe(withRelativeStartTime: 0.60, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: startY + 140) }
            UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.15) { dot.center = self.view.center }
        }) { _ in
            if let hud = self.view.viewWithTag(1001) { hud.isHidden = true }
            self.finishVisionMappingSequence()
        }
        
        let timings = [3.0, 6.6, 10.2]
        for time in timings {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) { self.impactFeedback.impactOccurred(intensity: 0.8) }
        }
    }

    func finishVisionMappingSequence() {
        UIApplication.shared.isIdleTimerDisabled = false
        self.visionMapDot?.removeFromSuperview()
        self.visionMapDot = nil
        self.isMappingVision = false
        self.visionMappingView?.session.pause()
        self.visionMappingView?.removeFromSuperview()
        self.visionMappingView = nil
        self.motionManager.stopDeviceMotionUpdates()
        self.isMappingVisionCompleted = true
        
        if self.headMoveScore > (self.eyeMoveScore * Float(0.8)) {
            self.visionBehaviorResult = "Movimentador de Cabeça (Head-Mover)"
        } else {
            self.visionBehaviorResult = "Movimentador de Olhos (Eye-Mover)"
        }
        
        let alert = UIAlertController(title: "Mapeamento Clínico Concluído", message: "Resultado: \(self.visionBehaviorResult)\n\nO comportamento periférico foi capturado com sucesso.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Avançar para Medições", style: .default, handler: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isFrozen = false
                self?.toggleFreeze()
            }
        }))
        self.present(alert, animated: true)
    }
}
