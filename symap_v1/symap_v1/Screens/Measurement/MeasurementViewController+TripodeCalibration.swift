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
        
        let boxW: CGFloat = 340
        let boxH: CGFloat = 520
        let box = UIView(frame: CGRect(x: (self.bounds.width - boxW)/2, y: (self.bounds.height - boxH)/2, width: boxW, height: boxH))
        box.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        box.layer.cornerRadius = 20
        box.layer.borderWidth = 2
        box.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        self.addSubview(box)
        
        let title = UILabel(frame: CGRect(x: 20, y: 30, width: boxW - 40, height: 25))
        title.text = "CALIBRAÇÃO DO TRIPÉ"
        title.textColor = .white
        title.font = UIFont.boldSystemFont(ofSize: 20)
        title.textAlignment = .center
        box.addSubview(title)
        
        let desc = UILabel(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 60))
        desc.text = "Zere a inclinação nos 3 eixos apertando firmemente as travas do tripé. Busque os 0.0 Graus."
        desc.textColor = .lightGray
        desc.font = UIFont.systemFont(ofSize: 14)
        desc.numberOfLines = 0
        desc.textAlignment = .center
        box.addSubview(desc)
        
        let radarSize: CGFloat = 120
        let radarBg = UIView(frame: CGRect(x: (boxW - radarSize)/2, y: 150, width: radarSize, height: radarSize))
        radarBg.layer.cornerRadius = radarSize / 2
        radarBg.layer.borderWidth = 2
        radarBg.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        box.addSubview(radarBg)
        
        radarTarget.frame = CGRect(x: -20, y: radarSize/2 - 2, width: radarSize + 40, height: 4)
        radarTarget.backgroundColor = .systemRed
        radarBg.addSubview(radarTarget)
        
        let tapeW: CGFloat = 16
        let tapeH: CGFloat = 120
        let tapeBg = UIView(frame: CGRect(x: boxW - 40, y: 150, width: tapeW, height: tapeH))
        tapeBg.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        tapeBg.layer.cornerRadius = tapeW / 2
        tapeBg.layer.borderWidth = 1
        tapeBg.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        box.addSubview(tapeBg)
        
        let tapeCenter = UIView(frame: CGRect(x: 0, y: tapeH/2 - 10, width: tapeW, height: 20))
        tapeCenter.layer.borderWidth = 2
        tapeCenter.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        tapeBg.addSubview(tapeCenter)
        
        pitchBubble.frame = CGRect(x: 2, y: tapeH/2 - 6, width: 12, height: 12)
        pitchBubble.backgroundColor = .systemRed
        pitchBubble.layer.cornerRadius = 6
        tapeBg.addSubview(pitchBubble)
        
        func createDegLabel(y: CGFloat) -> UILabel {
            let lbl = UILabel(frame: CGRect(x: 20, y: y, width: boxW - 40, height: 20))
            lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
            lbl.textAlignment = .center
            box.addSubview(lbl)
            return lbl
        }
        
        lblRoll = createDegLabel(y: 290)
        lblPitch = createDegLabel(y: 315)
        lblYaw = createDegLabel(y: 340)
        
        lockButton.frame = CGRect(x: 30, y: boxH - 75, width: boxW - 60, height: 55)
        lockButton.backgroundColor = .darkGray
        lockButton.setTitle("Avançar para Medição", for: .normal)
        lockButton.setTitleColor(.lightGray, for: .normal)
        lockButton.layer.cornerRadius = 16
        lockButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
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
        
        let neonGreen = UIColor(red: 0.0, green: 0.95, blue: 0.2, alpha: 1.0)
        let redColor = UIColor.systemRed
        
        DispatchQueue.main.async {
            self.lblRoll.text = String(format: "INCLINAÇÃO LATERAL: %+.1f°", rollDeg)
            self.lblRoll.textColor = isLevel ? neonGreen : redColor
            
            self.lblPitch.text = String(format: "INCLIN. FRENTE/TRÁS: %+.1f°", pitchDeg)
            self.lblPitch.textColor = isPitchLevel ? neonGreen : redColor
            
            self.lblYaw.text = String(format: "ROTAÇÃO LATERAL (YAW): %+.1f°", yawDeg)
            self.lblYaw.textColor = neonGreen
            
            let clampedPitch = min(max(pitch, -1.0), 1.0)
            let pitchY = 60.0 + (CGFloat(clampedPitch / 1.0) * 52.0)
            
            var transform3D = CATransform3DIdentity
            transform3D.m34 = -1.0 / 150.0
            transform3D = CATransform3DRotate(transform3D, CGFloat(-roll), 0, 0, 1)
            
            UIView.animate(withDuration: 0.1) {
                self.radarTarget.layer.transform = transform3D
                self.pitchBubble.center.y = pitchY
                self.radarTarget.backgroundColor = isLevel ? neonGreen : redColor
                self.pitchBubble.backgroundColor = isPitchLevel ? neonGreen : redColor
                
                if isLevel && isPitchLevel {
                    self.lockButton.isEnabled = true
                    self.lockButton.backgroundColor = neonGreen
                    self.lockButton.setTitleColor(.black, for: .normal)
                } else {
                    self.lockButton.isEnabled = false
                    self.lockButton.backgroundColor = .darkGray
                    self.lockButton.setTitleColor(.lightGray, for: .normal)
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
