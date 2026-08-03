import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import PDFKit
import CoreMotion
import simd
import AVFoundation

extension MeasurementViewController {
    
    @objc func onStartCaptureTapped() {
        // 🔴 Método mantido apenas por herança de segurança para o StateMachine,
        // mas a UI agora faz o Auto-Capture automático.
        if isFrozen {
            toggleFreeze()
            return
        }
    }
    
    func checkCaptureStability() {
        // 🔴 AUTO-CAPTURA ATIVADA: Apenas não pode estar congelado
        guard !isFrozen else { return }
                
                // 🔴 PREVENÇÃO DE AUTO-CAPTURA INVISÍVEL (BUG FIX)
                // Se a Calibração de Tripé (9991), Tutorial (9992) ou o termo LGPD estiverem abertos, a câmera de fundo não deve disparar o visagismo!
                if self.view.viewWithTag(9991) != nil || self.view.viewWithTag(9992) != nil || self.lgpdOverlay != nil {
                    self.stabilityStartTime = nil
                    self.resetCountdown()
                    return
                }
                
                let safetyCheck = ["Auto Capture Flow OK"]
                let _ = safetyCheck[ 0 ]
        
        // 🔴 Oculta sumariamente qualquer resquício da barra antiga
        self.distanceBarContainer?.isHidden = true
        self.distanceInstructionLabel?.isHidden = true
        
        var currentDistance: Float = 0.0
        if let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView {
            let cx = (lEye.x + rEye.x) / 2.0
            let cy = (lEye.y + rEye.y) / 2.0
            let cz = (lEye.z + rEye.z) / 2.0
            let camPos = cam.worldPosition
            currentDistance = sqrt(pow(camPos.x - cx, 2) + pow(camPos.y - cy, 2) + pow(camPos.z - cz, 2))
        }
        
        let isDistancePerfect = currentDistance >= 0.35 && currentDistance <= 0.40
        let allConditionsMet = isPhoneLevel && isHeadLevel && isPhonePitchLevel && isHeadPitchLevel && isFaceDetected && isDistancePerfect
        
        DispatchQueue.main.async {
            // =========================================================================
            // 🔴 UX NATIVA: Feedback visual embutido DIRETAMENTE no Oval do Rosto!
            // =========================================================================
            UIView.animate(withDuration: 0.1) {
                if !self.isFaceDetected {
                    self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
                    self.faceGuideLayer?.lineWidth = 2.0
                } else if currentDistance < 0.35 {
                    self.faceGuideLayer?.strokeColor = UIColor.systemOrange.cgColor // Muito perto (Laranja)
                    self.faceGuideLayer?.lineWidth = 6.0 // Fica bem grosso pra chamar atenção
                } else if currentDistance > 0.40 {
                    self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor // Longe (Branco Pálido)
                    self.faceGuideLayer?.lineWidth = 2.0
                } else {
                    self.faceGuideLayer?.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor // Perfeito (Ciano)
                    self.faceGuideLayer?.lineWidth = 4.0
                }
            }
            
            // =========================================================================
                    // 🔴 GATILHO DA AUTO-CAPTURA (AGORA INTEGRADO AO BRANDBOOK)
                    // =========================================================================
                    let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                    let navyDarkBase = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 0.85)
                    let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 0.95)
                    
                    // 🔴 BRANDBOOK: Novas Cores
                    let vibrantViolet = UIColor(red: 0.525, green: 0.353, blue: 0.898, alpha: 1.0)
                    let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)

            if allConditionsMet {
                        if self.stabilityStartTime == nil {
                            self.stabilityStartTime = Date()
                            self.topFeedbackLabel?.text = "Perfeito! Mantenha a posição..."
                            // 🔴 BRANDBOOK: Texto do label principal alterado de Navy para Off-White
                            self.topFeedbackLabel?.textColor = offWhite
                            self.topFeedbackLabel?.backgroundColor = opticalCyan
                            
                            self.startCaptureButton.setTitle("✅ Alinhado", for: .normal)
                            self.startCaptureButton.backgroundColor = opticalCyan
                            self.startCaptureButton.setTitleColor(UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0), for: .normal)
                            self.startCaptureButton.layer.borderColor = UIColor.clear.cgColor
                        } else {
                            let elapsed = Date().timeIntervalSince(self.stabilityStartTime!)
                            if elapsed >= 1.0 { self.startCountdown() }
                        }
                    } else {
                        self.stabilityStartTime = nil
                        if self.countdownTimer != nil {
                            self.finishCountdownAndCapture(aborted: true)
                        } else {
                            // Estado Padrão (Fundo Navy Medium e Botão Navy Dark)
                            self.topFeedbackLabel?.backgroundColor = navyMedium
                            
                            if !self.isPhoneLevel || !self.isPhonePitchLevel {
                                self.startCaptureButton.setTitle("Ajuste o Tripé", for: .normal)
                                self.startCaptureButton.backgroundColor = vibrantViolet
                                self.startCaptureButton.setTitleColor(offWhite, for: .normal)
                                self.startCaptureButton.layer.borderColor = vibrantViolet.cgColor
                            } else if !self.isFaceDetected {
                                self.topFeedbackLabel?.text = "Rosto não detectado"
                                self.topFeedbackLabel?.textColor = offWhite
                                
                                self.startCaptureButton.setTitle("Aguardando Rosto...", for: .normal)
                                self.startCaptureButton.backgroundColor = navyDarkBase
                                self.startCaptureButton.setTitleColor(offWhite, for: .normal)
                                self.startCaptureButton.layer.borderColor = offWhite.withAlphaComponent(0.3).cgColor
                            } else if currentDistance < 0.35 {
                                self.topFeedbackLabel?.text = "Afaste o celular levemente"
                                self.topFeedbackLabel?.textColor = offWhite
                                
                                self.startCaptureButton.setTitle("Muito Perto", for: .normal)
                                self.startCaptureButton.backgroundColor = vibrantViolet
                                self.startCaptureButton.setTitleColor(offWhite, for: .normal)
                                self.startCaptureButton.layer.borderColor = vibrantViolet.cgColor
                            } else if currentDistance > 0.40 {
                                self.topFeedbackLabel?.text = "Aproxime o celular levemente"
                                self.topFeedbackLabel?.textColor = offWhite
                                
                                self.startCaptureButton.setTitle("Muito Longe", for: .normal)
                                self.startCaptureButton.backgroundColor = navyDarkBase
                                self.startCaptureButton.setTitleColor(offWhite, for: .normal)
                                self.startCaptureButton.layer.borderColor = offWhite.withAlphaComponent(0.3).cgColor
                            } else {
                                self.topFeedbackLabel?.text = "Mantenha os níveis centralizados"
                                self.topFeedbackLabel?.textColor = offWhite
                                
                                self.startCaptureButton.setTitle("Centralize os Níveis", for: .normal)
                                self.startCaptureButton.backgroundColor = navyDarkBase
                                self.startCaptureButton.setTitleColor(offWhite, for: .normal)
                                self.startCaptureButton.layer.borderColor = offWhite.withAlphaComponent(0.3).cgColor
                            }
                        }
                    }
        }
    }
    
    func startCountdown() {
        if countdownTimer != nil { return }
        guard !isFrozen else { return }
        
        countdownValue = 3
        DispatchQueue.main.async {
                    self.countdownLabel.text = "\(self.countdownValue)"
                    self.countdownLabel.isHidden = false
                    
                    // 🔴 BRANDBOOK: Paleta Oficial para o momento da Contagem
                    let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                    let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)
                    let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                    
                    self.startCaptureButton.setTitle("Capturando...", for: .normal)
                    self.startCaptureButton.backgroundColor = opticalCyan
                    self.startCaptureButton.setTitleColor(navyDark, for: .normal)
                    self.startCaptureButton.layer.shadowOpacity = 0
                    
                    self.topFeedbackLabel?.text = "Mantenha a posição..."
                    // 🔴 CORREÇÃO: O texto antes era ciano sobre ciano. Agora brilha em Off-White!
                    self.topFeedbackLabel?.textColor = offWhite
                }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if !self.isPhoneLevel || !self.isHeadLevel || !self.isPhonePitchLevel || !self.isHeadPitchLevel {
                self.finishCountdownAndCapture(aborted: true)
                return
            }
            
            self.countdownValue -= 1
            if self.countdownValue > 0 {
                self.countdownLabel.text = "\(self.countdownValue)"
                self.pulseAnimation(view: self.countdownLabel)
            } else {
                self.finishCountdownAndCapture(aborted: false)
            }
        }
    }
    
    func finishCountdownAndCapture(aborted: Bool) {
            stabilityStartTime = nil
            resetCountdown()
            
            if aborted {
                DispatchQueue.main.async {
                    if self.isPhoneLevel && self.isPhonePitchLevel {
                        self.topFeedbackLabel?.text = "Você moveu. Tente novamente"
                        self.topFeedbackLabel?.textColor = .lightGray
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let flash = UIView(frame: self.view.bounds)
                    flash.backgroundColor = .white
                    flash.alpha = 0.0
                    self.view.addSubview(flash)
                    UIView.animate(withDuration: 0.1, animations: { flash.alpha = 0.7 }) { _ in
                        UIView.animate(withDuration: 0.2) { flash.alpha = 0.0 } completion: { _ in flash.removeFromSuperview() }
                    }
                    
                    // 🔴 A MÁGICA DA NOVA FASE: Roteia para Visagismo ou para a Foto Médica!
                    if !self.isVisagismCompleted {
                        self.startVisagismSummary()
                    } else {
                        self.startApprovalStep()
                    }
                }
            }
        }
    
    func resetCountdown() {
        guard countdownTimer != nil else { return }
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = 3
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.countdownLabel.alpha = 0.0
            } completion: { _ in
                self.countdownLabel.isHidden = true
                self.countdownLabel.alpha = 1.0
            }
        }
    }
    
    func pulseAnimation(view: UIView) {
        UIView.animate(withDuration: 0.1, animations: { view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) }) { _ in
            UIView.animate(withDuration: 0.1) { view.transform = .identity }
        }
    }
}
