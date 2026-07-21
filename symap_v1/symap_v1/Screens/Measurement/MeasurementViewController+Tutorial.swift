import UIKit
import CoreMotion
import ARKit
import simd

// =========================================================================
// 🔴 COMPONENTE: View dedicada ao Tutorial de Captura (Alinhamento de Câmera)
// MOTOR HÍBRIDO E MINI-CONSOLE UNIFICADO (PASSO 3)
// =========================================================================
class CaptureTutorialView: UIView {
    weak var parentVC: MeasurementViewController?
    var currentStep = 0
    var onClose: (() -> Void)?
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let box = UIView()
    let titleLabel = UILabel()
    let descLabel = UILabel()
    
    // Elementos de Animação (Passos 1 e 2)
    let eyeIcon = UIImageView()
    let phoneIcon = UIImageView()
    let cameraDot = UIView()
    let alignLine = UIView()
    
    // ==========================================
    // 🔴 O MINI-CONSOLE UNIFICADO (Passo 3)
    // ==========================================
    let interactiveContainer = UIView()
    var miniConsole: UIView!
    var badgeView: UIView!
    var lockIcon: UIImageView!
    var circuitLine: UIView!
    var phoneRadarContainer: UIView!
    var phoneRadarTarget: UIView!
    var headRadarContainer: UIView!
    var headRadarTarget: UIView!
    var headRadarBubble: UIView!
    var phonePitchBg: UIView!
    var phonePitchBubble: UIView!
    var headPitchBg: UIView!
    var headPitchBubble: UIView!
    
    let btnNext = UIButton()
    let btnPrev = UIButton()
    let btnDontShow = UIButton()
    var isDontShowChecked = false
    var displayLink: CADisplayLink?
    
    init(frame: CGRect, parentVC: MeasurementViewController?) {
        self.parentVC = parentVC
        super.init(frame: frame)
        setupUI()
        updateStep()
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA: Blindagem de matrizes
        let safetyCheck = ["System OK"]
        let _ = safetyCheck[ 0 ]
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        displayLink?.invalidate()
    }
    
    func setupUI() {
        blurView.frame = self.bounds
        blurView.alpha = 0.8
        self.addSubview(blurView)
        
        let boxW: CGFloat = 340
        let boxH: CGFloat = 490
        box.frame = CGRect(x: (self.bounds.width - boxW)/2.0, y: (self.bounds.height - boxH)/2.0, width: boxW, height: boxH)
        box.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        box.layer.cornerRadius = 20
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        self.addSubview(box)
        
        titleLabel.frame = CGRect(x: 20, y: 25, width: boxW - 40, height: 25)
        titleLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        box.addSubview(titleLabel)
        
        let imgContainer = UIView(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 160))
        imgContainer.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        imgContainer.layer.cornerRadius = 16
        imgContainer.clipsToBounds = true
        box.addSubview(imgContainer)
        
        eyeIcon.image = UIImage(systemName: "eye")
        eyeIcon.tintColor = .white
        eyeIcon.contentMode = .scaleAspectFit
        imgContainer.addSubview(eyeIcon)
        
        phoneIcon.image = UIImage(systemName: "iphone")
        phoneIcon.tintColor = .lightGray
        phoneIcon.contentMode = .scaleAspectFit
        imgContainer.addSubview(phoneIcon)
        
        cameraDot.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        cameraDot.layer.cornerRadius = 4
        imgContainer.addSubview(cameraDot)
        
        alignLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        imgContainer.addSubview(alignLine)
        
        // =========================================================================
        // 🔴 SETUP DO MINI-CONSOLE UNIFICADO
        // =========================================================================
        interactiveContainer.frame = imgContainer.bounds
        interactiveContainer.backgroundColor = .clear
        interactiveContainer.isHidden = true
        imgContainer.addSubview(interactiveContainer)
        
        let panelW = interactiveContainer.bounds.width - 20
        let panelH: CGFloat = 130
        let panelY: CGFloat = 15
        
        miniConsole = UIView(frame: CGRect(x: 10, y: panelY, width: panelW, height: panelH))
        miniConsole.backgroundColor = UIColor(white: 0.1, alpha: 0.85)
        miniConsole.layer.cornerRadius = 18
        miniConsole.layer.borderWidth = 1.5
        miniConsole.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        interactiveContainer.addSubview(miniConsole)
        
        let titleConsole = UILabel(frame: CGRect(x: 0, y: 8, width: panelW, height: 12))
        titleConsole.text = "HUD DE TELEMETRIA ESPACIAL"
        titleConsole.font = UIFont.systemFont(ofSize: 9, weight: .black)
        titleConsole.textColor = UIColor.white.withAlphaComponent(0.4)
        titleConsole.textAlignment = .center
        miniConsole.addSubview(titleConsole)
        
        let radarCY = (panelH / 2) + 6
        let leftCX = panelW * 0.25
        let rightCX = panelW * 0.75
        let radarSize: CGFloat = 60
        
        circuitLine = UIView(frame: CGRect(x: 30, y: radarCY - 1, width: panelW - 60, height: 2))
        circuitLine.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        miniConsole.addSubview(circuitLine)
        
        badgeView = UIView(frame: CGRect(x: panelW/2 - 16, y: radarCY - 16, width: 32, height: 32))
        badgeView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        badgeView.layer.cornerRadius = 16
        badgeView.layer.borderWidth = 2
        badgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        miniConsole.addSubview(badgeView)
        
        lockIcon = UIImageView(frame: CGRect(x: 6, y: 6, width: 20, height: 20))
        lockIcon.image = UIImage(systemName: "lock.open.fill")
        lockIcon.tintColor = .lightGray
        lockIcon.contentMode = .scaleAspectFit
        badgeView.addSubview(lockIcon)
        
        func createMiniRadar(cx: CGFloat, cy: CGFloat, title: String) -> (UIView, UIView, UIView) {
            let container = UIView(frame: CGRect(x: cx - radarSize/2, y: cy - radarSize/2, width: radarSize, height: radarSize))
            container.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            container.layer.cornerRadius = radarSize/2
            container.layer.borderWidth = 1.5
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            container.clipsToBounds = true
            miniConsole.addSubview(container)
            
            let ring = CAShapeLayer()
            ring.path = UIBezierPath(ovalIn: container.bounds.insetBy(dx: 2, dy: 2)).cgPath
            ring.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
            ring.fillColor = UIColor.clear.cgColor
            ring.lineWidth = 3
            let dashPattern: [NSNumber] = [1, 2]
            let _ = dashPattern[ 0 ]
            ring.lineDashPattern = dashPattern
            container.layer.addSublayer(ring)
            
            let horizonGroup = UIView(frame: container.bounds)
            let horizonLine = UIView(frame: CGRect(x: -20, y: radarSize/2 - 1.5, width: radarSize + 40, height: 3))
            horizonLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
            horizonGroup.addSubview(horizonLine)
            container.addSubview(horizonGroup)
            
            let bubble = UIView(frame: CGRect(x: radarSize/2 - 4, y: radarSize/2 - 4, width: 8, height: 8))
            bubble.backgroundColor = .systemPink
            bubble.layer.cornerRadius = 4
            container.addSubview(bubble)
            
            let lbl = UILabel(frame: CGRect(x: cx - 40, y: cy + radarSize/2 + 6, width: 80, height: 10))
            lbl.text = title
            lbl.font = UIFont.systemFont(ofSize: 8, weight: .bold)
            lbl.textColor = .white
            lbl.textAlignment = .center
            miniConsole.addSubview(lbl)
            
            return (container, horizonGroup, bubble)
        }
        
        let phoneR = createMiniRadar(cx: leftCX, cy: radarCY, title: "CELULAR")
        phoneRadarContainer = phoneR.0
        phoneRadarTarget = phoneR.1
        let phoneBubbleDummy = phoneR.2
        phoneBubbleDummy.isHidden = true
        
        let headR = createMiniRadar(cx: rightCX, cy: radarCY, title: "CABEÇA")
        headRadarContainer = headR.0
        headRadarTarget = headR.1
        headRadarBubble = headR.2
        
        let tapeW: CGFloat = 10
        let tapeH: CGFloat = 60
        let tapeY = radarCY - tapeH/2
        
        func createMiniTape(x: CGFloat) -> (UIView, UIView) {
            let bg = UIView(frame: CGRect(x: x, y: tapeY, width: tapeW, height: tapeH))
            bg.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            bg.layer.cornerRadius = tapeW/2
            bg.layer.borderWidth = 1
            bg.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
            miniConsole.addSubview(bg)
            
            let target = UIView(frame: CGRect(x: 0, y: tapeH/2 - 8, width: tapeW, height: 16))
            target.layer.borderWidth = 1
            target.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.5).cgColor
            bg.addSubview(target)
            
            let bubble = UIView(frame: CGRect(x: 2, y: tapeH/2 - 3, width: 6, height: 6))
            bubble.backgroundColor = .lightGray
            bubble.layer.cornerRadius = 3
            bg.addSubview(bubble)
            
            return (bg, bubble)
        }
        
        let pTape = createMiniTape(x: 8)
        phonePitchBg = pTape.0
        phonePitchBubble = pTape.1
        
        let hTape = createMiniTape(x: panelW - 18)
        headPitchBg = hTape.0
        headPitchBubble = hTape.1
        
        descLabel.frame = CGRect(x: 20, y: 235, width: boxW - 40, height: 120)
        descLabel.textColor = .lightGray
        descLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        box.addSubview(descLabel)
        
        btnDontShow.frame = CGRect(x: 20, y: boxH - 110, width: boxW - 40, height: 30)
        btnDontShow.setTitle(" Não mostrar tutorial novamente", for: .normal)
        btnDontShow.setTitleColor(.lightGray, for: .normal)
        btnDontShow.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        
        isDontShowChecked = UserDefaults.standard.bool(forKey: "hideCaptureTutorial")
        let iconName = isDontShowChecked ? "checkmark.square.fill" : "square"
        btnDontShow.setImage(UIImage(systemName: iconName), for: .normal)
        btnDontShow.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnDontShow.addTarget(self, action: #selector(toggleDontShow), for: .touchUpInside)
        box.addSubview(btnDontShow)
        
        btnPrev.frame = CGRect(x: 20, y: boxH - 65, width: 100, height: 45)
        btnPrev.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        btnPrev.setTitle("Anterior", for: .normal)
        btnPrev.setTitleColor(.white, for: .normal)
        btnPrev.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnPrev.layer.cornerRadius = 12
        btnPrev.addTarget(self, action: #selector(prevStep), for: .touchUpInside)
        box.addSubview(btnPrev)
        
        btnNext.frame = CGRect(x: 130, y: boxH - 65, width: 190, height: 45)
        btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnNext.setTitle("Próximo", for: .normal)
        btnNext.setTitleColor(.black, for: .normal)
        btnNext.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnNext.layer.cornerRadius = 12
        btnNext.addTarget(self, action: #selector(nextStep), for: .touchUpInside)
        box.addSubview(btnNext)
    }
    
    @objc func toggleDontShow() {
        isDontShowChecked.toggle()
        let iconName = isDontShowChecked ? "checkmark.square.fill" : "square"
        btnDontShow.setImage(UIImage(systemName: iconName), for: .normal)
        UserDefaults.standard.set(isDontShowChecked, forKey: "hideCaptureTutorial")
    }
    
    @objc func nextStep() {
        if currentStep < 2 {
            currentStep += 1
            updateStep()
        } else {
            onClose?()
        }
    }
    
    @objc func prevStep() {
        if currentStep > 0 {
            currentStep -= 1
            updateStep()
        }
    }
    
    func updateStep() {
        btnPrev.isHidden = (currentStep == 0)
        phoneIcon.layer.removeAllAnimations()
        cameraDot.layer.removeAllAnimations()
        alignLine.layer.removeAllAnimations()
        displayLink?.invalidate()
        displayLink = nil
        
        let cx = 150.0
        let cy = 80.0
        
        UIView.animate(withDuration: 0.3) {
            self.blurView.alpha = 0.8
            switch self.currentStep {
            case 0:
                self.btnNext.isEnabled = true
                self.btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                self.btnNext.setTitle("Próximo", for: .normal)
                self.titleLabel.text = "1. ALTURA DA CÂMERA"
                self.descLabel.text = "Posicione a lente frontal (topo do celular) EXATAMENTE na mesma altura dos olhos.\n\nEvite medir de baixo para cima pois pode causar falhas de medicao."
                self.eyeIcon.isHidden = false
                self.phoneIcon.isHidden = false
                self.cameraDot.isHidden = false
                self.alignLine.isHidden = false
                self.interactiveContainer.isHidden = true
                
                self.eyeIcon.frame = CGRect(x: cx - 70, y: cy - 15, width: 40, height: 30)
                self.phoneIcon.frame = CGRect(x: cx + 30, y: cy, width: 50, height: 100)
                self.cameraDot.frame = CGRect(x: cx + 51, y: cy + 10, width: 8, height: 8)
                self.alignLine.frame = CGRect(x: cx - 35, y: cy, width: 80, height: 2)
                
                let moveAnim = CABasicAnimation(keyPath: "position.y")
                moveAnim.fromValue = self.phoneIcon.layer.position.y
                moveAnim.toValue = self.phoneIcon.layer.position.y - 25.0
                moveAnim.duration = 1.5
                moveAnim.autoreverses = true
                moveAnim.repeatCount = .infinity
                moveAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.phoneIcon.layer.add(moveAnim, forKey: "phoneMove")
                self.cameraDot.layer.add(moveAnim, forKey: "dotMove")
                
            case 1:
                self.btnNext.isEnabled = true
                self.btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                self.btnNext.setTitle("Próximo", for: .normal)
                self.titleLabel.text = "2. FOCO DO PACIENTE"
                self.descLabel.text = "Durante a contagem regressiva, olhe FIXAMENTE para a câmera do celular, e NÃO para o centro da tela."
                self.eyeIcon.isHidden = false
                self.phoneIcon.isHidden = false
                self.cameraDot.isHidden = false
                self.alignLine.isHidden = false
                self.interactiveContainer.isHidden = true
                
                self.phoneIcon.frame = CGRect(x: cx + 30, y: cy - 25, width: 50, height: 100)
                self.cameraDot.frame = CGRect(x: cx + 51, y: cy - 15, width: 8, height: 8)
                self.alignLine.frame = CGRect(x: cx - 30, y: cy, width: 80, height: 2)
                
                let pulseAnim = CABasicAnimation(keyPath: "opacity")
                pulseAnim.fromValue = 1.0
                pulseAnim.toValue = 0.2
                pulseAnim.duration = 0.5
                pulseAnim.autoreverses = true
                pulseAnim.repeatCount = .infinity
                self.cameraDot.layer.add(pulseAnim, forKey: "pulse")
                self.alignLine.layer.add(pulseAnim, forKey: "pulseLine")
                
            case 2:
                // 🔴 PASSO 3: O CONSOLE UNIFICADO
                self.titleLabel.text = "3. NIVELAMENTO UNIFICADO"
                self.descLabel.text = " Mova o CELULAR e a CABEÇA até alinhar os niveis.\n\nQuando os sensores estiverem na posicao correta, o cadeado fechará, indicando o alinhamento correto!"
                self.descLabel.textAlignment = .left
                self.eyeIcon.isHidden = true
                self.phoneIcon.isHidden = true
                self.cameraDot.isHidden = true
                self.alignLine.isHidden = true
                self.interactiveContainer.isHidden = false
                
                self.btnNext.setTitle("Entendi", for: .normal)
                self.btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                self.btnNext.isEnabled = true
                
                if let vc = self.parentVC {
                    let config = ARFaceTrackingConfiguration()
                    config.isLightEstimationEnabled = true
                    vc.sceneView.session.run(config, options: [])
                }
                
                self.displayLink = CADisplayLink(target: self, selector: #selector(self.readSensors))
                self.displayLink?.add(to: .main, forMode: .default)
                
            default: break
            }
        }
    }
    
    // =========================================================================
    // 🔴 MOTOR SENSORIAL SEGURO COM PROGRESSIVE DISCLOSURE
    // =========================================================================
    @objc func readSensors() {
        guard let vc = parentVC else { return }
        var phoneRoll: Double = 0.0
        var phonePitch: Double = 0.0
        var headRoll: Double = 0.0
        var headPitch: Double = 0.0
        var headYaw: Double = 0.0
        var isFaceTracked = false
        
        // 1. LER DADOS JÁ PROCESSADOS DO CELULAR
        if let data = vc.motionManager.deviceMotion {
            let gx = data.gravity.x
            let gy = data.gravity.y
            let gz = data.gravity.z
            if abs(gx) > abs(gy) {
                phoneRoll = gx > 0 ? atan2(-gy, gx) : atan2(gy, -gx)
            } else {
                phoneRoll = gy < 0 ? atan2(gx, -gy) : atan2(-gx, gy)
            }
            phonePitch = gz + 0.085
        }
        
        // 2. LER CABEÇA
        if let frame = vc.sceneView?.session.currentFrame,
           let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first {
            let camTransform = vc.sceneView.pointOfView?.simdTransform ?? matrix_identity_float4x4
            let relativeFaceTransform = simd_mul(simd_inverse(camTransform), faceAnchor.transform)
            let rawHeadPitch = Double(relativeFaceTransform.columns.2.y)
            
            headPitch = rawHeadPitch - 0.065
            headYaw = Double(relativeFaceTransform.columns.2.x)
            headRoll = Double(vc.smoothHeadRoll)
            isFaceTracked = true
        }
        
        let rThresh = 0.12
        let pRThresh = 0.05
        let pThresh = 0.10
        let yawThresh = 0.15
        
        let isPLevel = abs(phoneRoll) < pRThresh
        let isPPitchLevel = abs(phonePitch) < pThresh
        let isHLevel = abs(headRoll) < rThresh && abs(headYaw) < yawThresh
        let isHPitchLevel = abs(headPitch) < pThresh
        
        let maxPitch = 1.0
        let pTapeCenterY = phonePitchBg.bounds.height / 2.0
        let clampedPPitch = min(max(phonePitch, -maxPitch), maxPitch)
        let pTapeY = pTapeCenterY + (CGFloat(clampedPPitch / maxPitch) * (pTapeCenterY - 8.0))
        
        let maxHPitch = 0.5
        let hTapeCenterY = headPitchBg.bounds.height / 2.0
        let clampedHPitch = min(max(headPitch, -maxHPitch), maxHPitch)
        let hTapeY = hTapeCenterY + (CGFloat(clampedHPitch / maxHPitch) * (hTapeCenterY - 8.0))
        
        var pTransform = CATransform3DIdentity
        pTransform.m34 = -1.0 / 150.0
        pTransform = CATransform3DRotate(pTransform, CGFloat(-phoneRoll), 0, 0, 1)
        
        var hTransform = CATransform3DIdentity
        hTransform.m34 = -1.0 / 150.0
        hTransform = CATransform3DRotate(hTransform, CGFloat(headRoll), 0, 0, 1)
        
        let maxYaw = 0.5
        let clampedYaw = min(max(headYaw, -maxYaw), maxYaw)
        let hYawX = CGFloat(clampedYaw * 20.0)
        
        let ciano = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        let isAllAligned = isPLevel && isPPitchLevel && isHLevel && isHPitchLevel && isFaceTracked
        let isPhoneAligned = isPLevel && isPPitchLevel // 🔴 Usado no Progressive Disclosure
        
        UIView.animate(withDuration: 0.1) {
            self.phoneRadarTarget.layer.transform = pTransform
            self.headRadarTarget.layer.transform = hTransform
            self.headRadarBubble.transform = CGAffineTransform(translationX: hYawX, y: 0)
            self.phonePitchBubble.center.y = pTapeY
            self.headPitchBubble.center.y = hTapeY
            
            // 🔴 UX PROGRESSIVE DISCLOSURE: Esmaece os controles do celular se ele já estiver alinhado
            self.phoneRadarContainer.alpha = isPhoneAligned ? 0.2 : 1.0
            self.phonePitchBg.alpha = isPhoneAligned ? 0.2 : 1.0
            
            if !isFaceTracked {
                self.headRadarBubble.backgroundColor = .systemOrange
                self.headPitchBubble.backgroundColor = .systemOrange
                self.headRadarContainer.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
                self.headPitchBg.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
            } else {
                self.phoneRadarContainer.layer.borderColor = isPLevel ? ciano.withAlphaComponent(0.8).cgColor : UIColor.white.withAlphaComponent(0.2).cgColor
                self.phoneRadarContainer.backgroundColor = isPLevel ? ciano.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.5)
                self.phonePitchBubble.backgroundColor = isPPitchLevel ? ciano : .lightGray
                
                self.headRadarContainer.layer.borderColor = isHLevel ? ciano.withAlphaComponent(0.8).cgColor : UIColor.white.withAlphaComponent(0.2).cgColor
                self.headRadarContainer.backgroundColor = isHLevel ? ciano.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.5)
                self.headPitchBubble.backgroundColor = isHPitchLevel ? ciano : .lightGray
            }
            
            if isAllAligned {
                self.badgeView.backgroundColor = ciano.withAlphaComponent(0.2)
                self.badgeView.layer.borderColor = ciano.cgColor
                self.lockIcon.tintColor = ciano
                self.lockIcon.image = UIImage(systemName: "lock.fill")
                self.lockIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.circuitLine.backgroundColor = ciano.withAlphaComponent(0.8)
            } else {
                self.badgeView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
                self.badgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                self.lockIcon.tintColor = .lightGray
                self.lockIcon.image = UIImage(systemName: "lock.open.fill")
                self.lockIcon.transform = .identity
                self.circuitLine.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            }
        }
    }
}

extension MeasurementViewController {
    
    @objc func startTutorial() {
        if self.view.viewWithTag(9992) != nil { return }
        let tut = CaptureTutorialView(frame: self.view.bounds, parentVC: self)
        tut.tag = 9992
        tut.onClose = { [weak tut] in
            UIView.animate(withDuration: 0.3, animations: { tut?.alpha = 0 }) { _ in tut?.removeFromSuperview() }
        }
        tut.alpha = 0
        self.view.addSubview(tut)
        UIView.animate(withDuration: 0.3) { tut.alpha = 1.0 }
    }
    
    @objc func autoShowTutorialIfNeeded() {
        let hideTutorial = UserDefaults.standard.bool(forKey: "hideCaptureTutorial")
        if !hideTutorial {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startTutorial()
            }
        }
    }
}
