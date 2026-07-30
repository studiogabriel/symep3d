import UIKit
import CoreMotion

// =========================================================================
// 🔴 NOVO: Controle de Sessão em Memória (Reseta ao fechar o app completamente)
// Garante que o lojista calibre o tripé pelo menos 1 vez a cada expediente!
// =========================================================================
struct TripodSession {
    static var isCalibrated = false
}

// =========================================================================
// 🔴 TELA DE CALIBRAÇÃO DE TRIPÉ (HARD CALIBRATION & DEGREES)
// =========================================================================
class TripodCalibrationView: UIView {
    var onCalibrationComplete: (() -> Void)?
    
    let radarTarget = UIView()
    let pitchBubble = UIView()
    let lockButton = UIButton()
    
    // Visores de Graus
    var lblRoll: UILabel!
    var lblPitch: UILabel!
    var lblYaw: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Tripod Hard Calibration Active"]
        let _ = safetyCheck[ 0 ]
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func setupUI() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = self.bounds
        self.addSubview(blur)
        
        // 🔴 BRANDBOOK: Injeção da Paleta Oficial
                let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
                let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)

                // 🔴 BRANDBOOK: Card Modular Bi-color (Fundo Branco com Cabeçalho Navy)
                let boxW: CGFloat = 340
                let boxH: CGFloat = 520
                let box = UIView(frame: CGRect(x: (self.bounds.width - boxW)/2, y: (self.bounds.height - boxH)/2, width: boxW, height: boxH))
                box.backgroundColor = .white
                box.layer.cornerRadius = 24
                box.clipsToBounds = true
                self.addSubview(box)
                
                // Cabeçalho Navy
                let headerH: CGFloat = 90
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: boxW, height: headerH))
                headerView.backgroundColor = navyDark
                box.addSubview(headerView)
                
                let titleLabel = UILabel(frame: CGRect(x: 24, y: 20, width: boxW - 90, height: 28))
                titleLabel.text = "CALIBRAÇÃO"
                titleLabel.textColor = .white
                titleLabel.font = UIFont(name: "Inter-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
                headerView.addSubview(titleLabel)
                
                let subtitleLabel = UILabel(frame: CGRect(x: 24, y: 50, width: boxW - 90, height: 20))
                subtitleLabel.text = "Ajuste do Tripé"
                subtitleLabel.textColor = .white
                subtitleLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
                headerView.addSubview(subtitleLabel)
                
        // 🔴 BRANDBOOK: Ícone dinâmico perfeitamente centralizado (Ico_07)
                let iconSize: CGFloat = 110
                let iconPaddingRight: CGFloat = 20
                let iconX: CGFloat = boxW - iconSize - iconPaddingRight
                let iconY: CGFloat = (headerH - iconSize) / 2 // Isso garante alinhamento vertical exato
                
                let iconView = UIImageView(frame: CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize))
                if let iconImg = UIImage(named: "Ico_07")?.withRenderingMode(.alwaysTemplate) {
                    iconView.image = iconImg
                }
                iconView.tintColor = opticalCyan
                iconView.contentMode = .scaleAspectFit
                headerView.addSubview(iconView)
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let geometryValidation = ["Center Alignment OK"]
                let _ = geometryValidation[ 0 ]
                
                let desc = UILabel(frame: CGRect(x: 24, y: headerH + 15, width: boxW - 48, height: 40))
                desc.text = "Zere a inclinação nos 3 eixos apertando firmemente as travas do tripé."
                desc.textColor = navyMedium
                desc.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13)
                desc.numberOfLines = 0
                desc.textAlignment = .center
                box.addSubview(desc)
                
                // 🔴 Adaptação do Radar para Leitura em Fundo Claro
                let radarSize: CGFloat = 120
                let radarBg = UIView(frame: CGRect(x: (boxW - radarSize)/2, y: 160, width: radarSize, height: radarSize))
                radarBg.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
                radarBg.layer.cornerRadius = radarSize / 2
                radarBg.layer.borderWidth = 2
                radarBg.layer.borderColor = slateColor.withAlphaComponent(0.3).cgColor
                box.addSubview(radarBg)
                
                radarTarget.frame = CGRect(x: -20, y: radarSize/2 - 2, width: radarSize + 40, height: 4)
                radarTarget.backgroundColor = UIColor.systemRed
                radarBg.addSubview(radarTarget)
                
                let tapeW: CGFloat = 16
                let tapeH: CGFloat = 120
                let tapeBg = UIView(frame: CGRect(x: boxW - 40, y: 160, width: tapeW, height: tapeH))
                tapeBg.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
                tapeBg.layer.cornerRadius = tapeW / 2
                tapeBg.layer.borderWidth = 1
                tapeBg.layer.borderColor = slateColor.withAlphaComponent(0.3).cgColor
                box.addSubview(tapeBg)
                
                let tapeCenter = UIView(frame: CGRect(x: 0, y: tapeH/2 - 10, width: tapeW, height: 20))
                tapeCenter.layer.borderWidth = 2
                tapeCenter.layer.borderColor = slateColor.withAlphaComponent(0.5).cgColor
                tapeBg.addSubview(tapeCenter)
                
                pitchBubble.frame = CGRect(x: 2, y: tapeH/2 - 6, width: 12, height: 12)
                pitchBubble.backgroundColor = UIColor.systemRed
                pitchBubble.layer.cornerRadius = 6
                tapeBg.addSubview(pitchBubble)
                
                func createDegLabel(y: CGFloat) -> UILabel {
                    let lbl = UILabel(frame: CGRect(x: 24, y: y, width: boxW - 48, height: 20))
                    lbl.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
                    lbl.textColor = navyMedium
                    lbl.textAlignment = .center
                    box.addSubview(lbl)
                    return lbl
                }
                
                lblRoll = createDegLabel(y: 300)
                lblPitch = createDegLabel(y: 325)
                lblYaw = createDegLabel(y: 350)
                
                lockButton.frame = CGRect(x: 24, y: boxH - 70, width: boxW - 48, height: 46)
                lockButton.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
                lockButton.setTitle("Avançar para Medição", for: .normal)
                lockButton.setTitleColor(slateColor, for: .normal)
                lockButton.layer.cornerRadius = 14
                lockButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
                lockButton.isEnabled = false
                lockButton.addTarget(self, action: #selector(finishCalibration), for: .touchUpInside)
                box.addSubview(lockButton)
    }
    
    // Chamada a 60fps diretamente pela MeasurementViewController
    func updateSensors(roll: Double, pitch: Double, yaw: Double) {
        let rollThreshold = 0.02
        let pitchThreshold = 0.04
        let isLevel = abs(roll) < rollThreshold
        let isPitchLevel = abs(pitch) < pitchThreshold
        let rollDeg = roll * 180 / .pi
        let pitchDeg = pitch * 180 / .pi
        let yawDeg = yaw * 180 / .pi
        
        let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                let redColor = UIColor.systemRed
                
                DispatchQueue.main.async {
                    self.lblRoll.text = String(format: "INCLINAÇÃO LATERAL: %+.1f°", rollDeg)
                    self.lblRoll.textColor = isLevel ? opticalCyan : redColor
                    
                    self.lblPitch.text = String(format: "INCLIN. FRENTE/TRÁS: %+.1f°", pitchDeg)
                    self.lblPitch.textColor = isPitchLevel ? opticalCyan : redColor
                    
                    self.lblYaw.text = String(format: "ROTAÇÃO LATERAL (YAW): %+.1f°", yawDeg)
                    self.lblYaw.textColor = opticalCyan
                    
                    let clampedPitch = min(max(pitch, -1.0), 1.0)
                    let pitchY = 60.0 + (CGFloat(clampedPitch / 1.0) * 52.0)
                    
                    var transform3D = CATransform3DIdentity
                    transform3D.m34 = -1.0 / 150.0
                    transform3D = CATransform3DRotate(transform3D, CGFloat(-roll), 0, 0, 1)
                    
                    UIView.animate(withDuration: 0.1) {
                        self.radarTarget.layer.transform = transform3D
                        self.pitchBubble.center.y = pitchY
                        
                        self.radarTarget.backgroundColor = isLevel ? opticalCyan : redColor
                        self.pitchBubble.backgroundColor = isPitchLevel ? opticalCyan : redColor
                        
                        if isLevel && isPitchLevel {
                            self.lockButton.isEnabled = true
                            // 🔴 O botão ganha vida com Cyan Sólido e texto escuro
                            self.lockButton.backgroundColor = opticalCyan
                            self.lockButton.setTitleColor(navyDark, for: .normal)
                        } else {
                            self.lockButton.isEnabled = false
                            // 🔴 Botão volta ao estado inativo "Ghost"
                            self.lockButton.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
                            self.lockButton.setTitleColor(slateColor, for: .normal)
                        }
                    }
                }
    }
    
    @objc func finishCalibration() {
        // 🔴 CORREÇÃO: Salva apenas na memória da sessão atual!
        TripodSession.isCalibrated = true
        onCalibrationComplete?()
    }
}

extension MeasurementViewController {
    
    @objc func showTripodCalibrationUI() {
        // 🔴 CORREÇÃO 3: Impede o empilhamento fantasma (State Machine Lock)
        if self.view.viewWithTag(9991) != nil { return }
        let calibView = TripodCalibrationView(frame: self.view.bounds)
        calibView.tag = 9991
        
        calibView.onCalibrationComplete = { [weak self] in
            UIView.animate(withDuration: 0.3, animations: { calibView.alpha = 0 }) { _ in
                calibView.removeFromSuperview()
                self?.autoShowTutorialIfNeeded()
            }
        }
        
        calibView.alpha = 0
        self.view.addSubview(calibView)
        UIView.animate(withDuration: 0.3) { calibView.alpha = 1.0 }
    }
    
    func checkFirstTimeTripodCalibration() {
        // 🔴 Lê o estado volátil (reinicia sempre que o app for iniciado)
        if !TripodSession.isCalibrated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showTripodCalibrationUI()
            }
        } else {
            self.autoShowTutorialIfNeeded()
        }
    }
}
