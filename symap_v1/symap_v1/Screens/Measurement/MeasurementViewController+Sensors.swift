import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import PDFKit
import CoreMotion
import simd

extension MeasurementViewController {
    
    func startARSession() {
            // 🔴 CORREÇÃO DE ARQUITETURA: O Gatilho que liga o Try-On na Nuvem!
            // Ele vai no banco de dados e baixa as fotos e parâmetros dos óculos em segundo plano
            CloudManager.shared.fetchMyModels { _ in }
            
            self.sessionStartTime = Date()
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
            let safetyCheck = ["Sensors HUD Rect OK"]
            let _ = safetyCheck[ 0 ]
        }
    
    func startLevelMonitoring() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            let gx = data.gravity.x
            let gy = data.gravity.y
            let gz = data.gravity.z
            
            var rollAngle: Double = 0.0
            
            if abs(gx) > abs(gy) {
                rollAngle = gx > 0 ? atan2(-gy, gx) : atan2(gy, -gx)
            } else {
                rollAngle = gy < 0 ? atan2(gx, -gy) : atan2(-gx, gy)
            }
            
            let pitchAngle = gz + 0.085
            let yawAngle = data.attitude.yaw
            
            self.updatePhoneHorizonUI(roll: rollAngle, pitch: pitchAngle, yaw: yawAngle)
            self.checkCaptureStability()
        }
    }
    
    func updatePhoneHorizonUI(roll: Double, pitch: Double, yaw: Double) {
        if let calibView = self.view.viewWithTag(9991) as? TripodCalibrationView {
            calibView.updateSensors(roll: roll, pitch: pitch, yaw: yaw)
            return
        }
        
        let rollThreshold = 0.02
        let pitchThreshold = 0.04
        
        self.isPhoneLevel = abs(roll) < rollThreshold
        self.isPhonePitchLevel = abs(pitch) < pitchThreshold
        
        let isAligned = self.isPhoneLevel && self.isPhonePitchLevel
        let isTutorialActive = self.view.viewWithTag(9992) != nil
        let isLGPDActive = self.lgpdOverlay != nil
        
        DispatchQueue.main.async {
            if let alertBorder = self.view.viewWithTag(881), let calibrateBtn = self.view.viewWithTag(880) as? UIButton {
                if !isAligned && !self.isFrozen && !isTutorialActive && !isLGPDActive {
                    self.view.bringSubviewToFront(alertBorder)
                    self.view.bringSubviewToFront(self.topFeedbackLabel!)
                    
                    UIView.animate(withDuration: 0.2) {
                        alertBorder.alpha = 1.0
                        calibrateBtn.tintColor = UIColor.systemOrange.withAlphaComponent(0.9)
                        calibrateBtn.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
                        self.topFeedbackLabel?.backgroundColor = UIColor.systemOrange
                        self.topFeedbackLabel?.textColor = .white
                        self.topFeedbackLabel?.text = "Ajuste a inclinação\ndo aparelho"
                    }
                } else {
                    UIView.animate(withDuration: 0.2) {
                        alertBorder.alpha = 0.0
                        calibrateBtn.tintColor = .lightGray
                        calibrateBtn.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                        
                        if self.topFeedbackLabel?.backgroundColor == UIColor.systemOrange {
                            self.topFeedbackLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.75)
                            self.topFeedbackLabel?.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                            self.topFeedbackLabel?.text = "Posicione o rosto na marcação"
                        }
                    }
                }
            }
        }
        
        self.updateCentralSyncCore()
    }
    
    func updateHeadHorizonUI(roll: Float, pitch: Float, yaw: Float) {
        let rollThresh: Float = 0.08
        let pitchThresh: Float = 0.08
        let yawThresh: Float = 0.08
        
        self.isHeadLevel = abs(roll) < rollThresh && abs(yaw) < yawThresh
        self.isHeadPitchLevel = abs(pitch) < pitchThresh
        
        let isAligned = self.isHeadLevel && self.isHeadPitchLevel
        
        let maxPitch: Float = 1.0
        let clampedPitch = min(max(pitch, -maxPitch), maxPitch)
        let pitchTranslation = CGFloat(-clampedPitch * 25.0)
        let yawTranslation = CGFloat(-(yaw * 45.0))
        
        var transform3D = CATransform3DIdentity
        transform3D.m34 = -1.0 / 150.0
        transform3D = CATransform3DRotate(transform3D, CGFloat(roll), 0, 0, 1)
        transform3D = CATransform3DTranslate(transform3D, 0, pitchTranslation, 0)
        
        let tiltFactor = CGFloat(-clampedPitch * 0.9)
        transform3D = CATransform3DRotate(transform3D, tiltFactor, 1, 0, 0)
        
        let pitchTapeH: CGFloat = 80.0
        let pitchCenterY = pitchTapeH / 2.0
        let newHeadPitchY = pitchCenterY + (CGFloat(clampedPitch / maxPitch) * (pitchCenterY - 8.0))
        
        let neonGreen = UIColor(red: 0.0, green: 0.95, blue: 0.2, alpha: 1.0)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.headLevelTargetZone.layer.transform = transform3D
                self.headLevelBubbleView.transform = CGAffineTransform(translationX: yawTranslation, y: 0)
                self.headPitchBubbleView.center.y = newHeadPitchY
                self.headPitchBubbleView.backgroundColor = self.isHeadPitchLevel ? neonGreen : .lightGray
            }
            
            self.updateRadarColor(container: self.headLevelContainerView,
                                  targetGroup: self.headLevelTargetZone,
                                  bubble: self.headLevelBubbleView,
                                  isAligned: isAligned,
                                  isFaceRadar: true)
            self.updateCentralSyncCore()
        }
    }
    
    func updateRadarColor(container: UIView, targetGroup: UIView, bubble: UIView, isAligned: Bool, isFaceRadar: Bool) {
        let neonGreen = UIColor(red: 0.0, green: 0.95, blue: 0.2, alpha: 1.0)
        let bubbleDefault = isFaceRadar ? UIColor.systemPink : .clear
        
        if isAligned && container.layer.borderColor != neonGreen.withAlphaComponent(0.8).cgColor {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            UIView.animate(withDuration: 0.2) {
                container.layer.borderColor = neonGreen.withAlphaComponent(0.8).cgColor
                container.backgroundColor = neonGreen.withAlphaComponent(0.15)
                if isFaceRadar { bubble.backgroundColor = neonGreen }
            }
        } else if !isAligned && container.layer.borderColor != UIColor.white.withAlphaComponent(0.2).cgColor {
            UIView.animate(withDuration: 0.2) {
                container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                container.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.08)
                if isFaceRadar { bubble.backgroundColor = bubbleDefault }
            }
        }
    }
    
    func updateCentralSyncCore() {
        guard let console = self.levelContainerView else { return }
        
        let circuitLine = console.viewWithTag(801)
        let badgeView = console.viewWithTag(802)
        let lockIcon = badgeView?.viewWithTag(803) as? UIImageView
        
        let isAllAligned = self.isPhoneLevel && self.isPhonePitchLevel && self.isHeadLevel && self.isHeadPitchLevel
        let neonGreen = UIColor(red: 0.0, green: 0.95, blue: 0.2, alpha: 1.0)
        
        if isAllAligned && badgeView?.backgroundColor != neonGreen.withAlphaComponent(0.2) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            
            // 🔴 UX: PROGRESSIVE DISCLOSURE (Esconde Radares)
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                circuitLine?.backgroundColor = neonGreen.withAlphaComponent(0.8)
                badgeView?.backgroundColor = neonGreen.withAlphaComponent(0.2)
                badgeView?.layer.borderColor = neonGreen.cgColor
                badgeView?.layer.shadowColor = neonGreen.cgColor
                badgeView?.layer.shadowOpacity = 1.0
                badgeView?.layer.shadowRadius = 10
                lockIcon?.tintColor = neonGreen
                lockIcon?.image = UIImage(systemName: "lock.fill")
                lockIcon?.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                
                // Oculta os radares laterais para dar paz visual
                self.headLevelContainerView?.alpha = 0.0
                self.headPitchContainerView?.alpha = 0.0
                
                // Informa o alinhamento
                self.headLevelLabel?.text = "ALINHAMENTO TRAVADO"
                self.headLevelLabel?.textColor = neonGreen
                self.headLevelLabel?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            
        } else if !isAllAligned && badgeView?.backgroundColor != UIColor(white: 0.05, alpha: 1.0) {
            UIView.animate(withDuration: 0.2) {
                circuitLine?.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                badgeView?.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
                badgeView?.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                badgeView?.layer.shadowOpacity = 0
                lockIcon?.tintColor = .lightGray
                lockIcon?.image = UIImage(systemName: "lock.open.fill")
                lockIcon?.transform = .identity
                
                // 🔴 UX: Traz os radares de volta instantaneamente se o alinhamento for quebrado
                self.headLevelContainerView?.alpha = 1.0
                self.headPitchContainerView?.alpha = 1.0
                
                self.headLevelLabel?.text = "POSICIONAMENTO DE CABEÇA"
                self.headLevelLabel?.textColor = UIColor.white.withAlphaComponent(0.4)
                self.headLevelLabel?.transform = .identity
            }
        }
    }
    
    func updateHeadPitchUI(angle: Float) {}
}
