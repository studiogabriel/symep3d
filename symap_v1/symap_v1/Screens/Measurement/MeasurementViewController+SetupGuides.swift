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
    func setupHeightRulerUI() {
        let width = view.bounds.width;     let centerY = view.bounds.height / 2
        heightLineView = UIView(frame: CGRect(x: 0, y: centerY + 50, width: width, height: 2))
        heightLineView.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        heightLineView.isHidden = true
        let hitArea = UIView(frame: CGRect(x: 0, y: -20, width: width, height: 42))
        hitArea.backgroundColor = .clear
        heightLineView.addSubview(hitArea)
        heightLineLabel = UILabel(frame: CGRect(x: 20, y: -25, width: 150, height: 20))
        heightLineLabel.text = "H: 0.0mm"
        heightLineLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        heightLineLabel.font = UIFont.boldSystemFont(ofSize: 14)
        heightLineLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        heightLineView.addSubview(heightLineLabel)
        view.addSubview(heightLineView)
    }

    func setupLevelUI() {
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Aviation HUD Rectangular OK"]
        let _ = safetyCheck[ 0 ]
        let padding: CGFloat = 15
        let panelW = view.bounds.width - (padding * 2)
        let panelH: CGFloat = 125
        let panelY: CGFloat = 50

        // 1. O CONSOLE UNIFICADO
        let consoleView = UIView(frame: CGRect(x: padding, y: panelY, width: panelW, height: panelH))
        consoleView.backgroundColor = UIColor(white: 0.1, alpha: 0.45)
        consoleView.layer.cornerRadius = 24
        consoleView.layer.borderWidth = 1.5
        consoleView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        consoleView.clipsToBounds = true
        view.addSubview(consoleView)

        levelContainerView = consoleView
        let consoleBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        consoleBlur.frame = consoleView.bounds
        consoleView.addSubview(consoleBlur)

        let consoleTitle = UILabel(frame: CGRect(x: 0, y: 12, width: panelW, height: 14))
        consoleTitle.text = "POSICIONAMENTO DE CABEÇA"
        consoleTitle.font = UIFont.systemFont(ofSize: 10, weight: .black)
        consoleTitle.textColor = UIColor.white.withAlphaComponent(0.4)
        consoleTitle.textAlignment = .center
        consoleView.addSubview(consoleTitle)
        levelLabel = consoleTitle

        // 2. VARIÁVEIS "FANTASMAS" (DUMMY) PARA O CELULAR
        let dummy = UIView()
        dummy.isHidden = true
        view.addSubview(dummy)
        self.levelBubbleView = dummy
        self.levelTargetZone = dummy
        self.phonePitchContainerView = dummy
        self.phonePitchBubbleView = dummy
        self.phonePitchTargetZone = dummy
        self.phonePitchLabel = UILabel()

        // 3. A PONTE DE SINCRONIA CENTRAL E CADEADO
        let radarCY = (panelH / 2) + 6
        let circuitLine = UIView(frame: CGRect(x: 40, y: radarCY - 1, width: panelW - 80, height: 2))
        circuitLine.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        circuitLine.tag = 801
        consoleView.addSubview(circuitLine)

        let badgeSize: CGFloat = 36
        let badgeView = UIView(frame: CGRect(x: (panelW - badgeSize)/2, y: radarCY - badgeSize/2, width: badgeSize, height: badgeSize))
        badgeView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        badgeView.layer.cornerRadius = badgeSize / 2
        badgeView.layer.borderWidth = 2
        badgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        badgeView.tag = 802
        consoleView.addSubview(badgeView)

        let lockIcon = UIImageView(frame: CGRect(x: 8, y: 8, width: 20, height: 20))
        lockIcon.image = UIImage(systemName: "lock.open.fill")
        lockIcon.tintColor = .lightGray
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.tag = 803
        badgeView.addSubview(lockIcon)

        // 4. O VISOR PANORÂMICO DA CABEÇA
        let radarW: CGFloat = 220
        let radarH: CGFloat = 65
        let cx = panelW / 2
        let headContainer = UIView(frame: CGRect(x: cx - radarW/2, y: radarCY - radarH/2, width: radarW, height: radarH))
        headContainer.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.08)
        headContainer.layer.cornerRadius = 16
        headContainer.layer.borderWidth = 2.0
        headContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        headContainer.clipsToBounds = true
        consoleView.addSubview(headContainer)

        let ring = CAShapeLayer()
        ring.path = UIBezierPath(roundedRect: headContainer.bounds.insetBy(dx: 3, dy: 3), cornerRadius: 14).cgPath
        ring.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
        ring.fillColor = UIColor.clear.cgColor
        ring.lineWidth = 3.0
        let dashPattern: [NSNumber] = [1, 2]
        let _ = dashPattern[ 0 ]
        ring.lineDashPattern = dashPattern
        headContainer.layer.addSublayer(ring)

        let horizonGroup = UIView(frame: headContainer.bounds)
        horizonGroup.backgroundColor = .clear
        let horizonLine = UIView(frame: CGRect(x: -40, y: radarH/2 - 1.5, width: radarW + 80, height: 3))
        horizonLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        horizonGroup.addSubview(horizonLine)

        for i in [-1, 1] {
            let ladderY = radarH/2 + CGFloat(i * 16)
            let ladder = UIView(frame: CGRect(x: radarW/2 - 15, y: ladderY, width: 30, height: 2))
            ladder.backgroundColor = UIColor.white.withAlphaComponent(0.4)
            horizonGroup.addSubview(ladder)
        }
        headContainer.addSubview(horizonGroup)

        let planeLeft = UIView(frame: CGRect(x: radarW/2 - 20, y: radarH/2 - 1, width: 15, height: 2))
        planeLeft.backgroundColor = .systemYellow
        let planeRight = UIView(frame: CGRect(x: radarW/2 + 5, y: radarH/2 - 1, width: 15, height: 2))
        planeRight.backgroundColor = .systemYellow
        let planeDot = UIView(frame: CGRect(x: radarW/2 - 2, y: radarH/2 - 2, width: 4, height: 4))
        planeDot.backgroundColor = .systemYellow
        planeDot.layer.cornerRadius = 2
        headContainer.addSubview(planeLeft)
        headContainer.addSubview(planeRight)
        headContainer.addSubview(planeDot)

        let yawBubble = UIView(frame: CGRect(x: radarW/2 - 5, y: radarH/2 - 5, width: 10, height: 10))
        yawBubble.backgroundColor = .systemPink
        yawBubble.layer.cornerRadius = 5
        yawBubble.layer.shadowColor = UIColor.systemPink.cgColor
        yawBubble.layer.shadowOpacity = 1.0
        yawBubble.layer.shadowRadius = 5
        headContainer.addSubview(yawBubble)

        let glassGlare = CAShapeLayer()
        let glareRect = CGRect(x: radarW * 0.05, y: radarH * 0.05, width: radarW * 0.9, height: radarH * 0.35)
        glassGlare.path = UIBezierPath(roundedRect: glareRect, cornerRadius: 8).cgPath
        glassGlare.fillColor = UIColor.white.withAlphaComponent(0.15).cgColor
        headContainer.layer.addSublayer(glassGlare)

        headLevelContainerView = headContainer
        headLevelBubbleView = yawBubble
        headLevelTargetZone = horizonGroup
        headLevelLabel = consoleTitle

        // 5. O NÍVEL DE DISTÂNCIA / PROFUNDIDADE
        let tapeW: CGFloat = 14
        let tapeH: CGFloat = 80
        let tapeY = (panelH - tapeH) / 2
        let headTapeBg = UIView(frame: CGRect(x: panelW - 20 - tapeW, y: tapeY, width: tapeW, height: tapeH))
        headTapeBg.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        headTapeBg.layer.cornerRadius = tapeW / 2
        headTapeBg.layer.borderWidth = 1
        headTapeBg.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        consoleView.addSubview(headTapeBg)

        let headTapeTarget = UIView(frame: CGRect(x: 0, y: (tapeH - 20)/2, width: tapeW, height: 20))
        headTapeTarget.layer.borderWidth = 1
        headTapeTarget.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.5).cgColor
        headTapeBg.addSubview(headTapeTarget)

        let headTapeBubble = UIView(frame: CGRect(x: 2, y: (tapeH - 10)/2, width: 10, height: 10))
        headTapeBubble.backgroundColor = .lightGray
        headTapeBubble.layer.cornerRadius = 5
        headTapeBg.addSubview(headTapeBubble)

        let lblHeadPitch = UILabel(frame: CGRect(x: 0, y: tapeY + tapeH + 4, width: 40, height: 20))
        lblHeadPitch.text = "FRENTE\nTRÁS"
        lblHeadPitch.numberOfLines = 2
        lblHeadPitch.font = UIFont.systemFont(ofSize: 7, weight: .bold)
        lblHeadPitch.textColor = .lightGray
        lblHeadPitch.textAlignment = .center
        lblHeadPitch.center.x = headTapeBg.center.x
        consoleView.addSubview(lblHeadPitch)

        headPitchContainerView = headTapeBg
        headPitchTargetZone = headTapeTarget
        headPitchBubbleView = headTapeBubble
        headPitchLabel = lblHeadPitch

        // 6. ACOMPANHAMENTO DINÂMICO
        DispatchQueue.main.async {
            if let feedback = self.topFeedbackLabel {
                feedback.frame = CGRect(x: 20, y: panelY + panelH + 15, width: self.view.bounds.width - 40, height: 60)
                feedback.font = UIFont.systemFont(ofSize: 16, weight: .black)
                self.view.bringSubviewToFront(feedback)
            }
            if let distBar = self.distanceBarContainer {
                self.view.bringSubviewToFront(distBar)
            }
        }
    }

    func setupCountdownUI() {
        let size: CGFloat = 160
        countdownLabel = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
        countdownLabel.center = view.center
        countdownLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 70, weight: .bold)
        countdownLabel.textColor = .white
        countdownLabel.textAlignment = .center
        countdownLabel.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        countdownLabel.layer.cornerRadius = size / 2
        countdownLabel.clipsToBounds = true
        countdownLabel.layer.borderWidth = 4
        countdownLabel.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        countdownLabel.isHidden = true
        view.addSubview(countdownLabel)
    }

    @objc func toggleGuides() {
        isGuidesActive.toggle()
        if isGuidesActive {
            btnToggleGuides.backgroundColor = UIColor.systemBlue
            techMaskNode?.isHidden = false
        } else {
            btnToggleGuides.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
            techMaskNode?.isHidden = true
        }
    }

    func setupTechMask(on faceNode: SCNNode) {
        let container = SCNNode()
        container.position = SCNVector3(0, 0, 0.06)
        faceNode.addChildNode(container)
        self.techMaskNode = container
        container.isHidden = true

        let frameGeo = SCNBox(width: 0.18, height: 0.24, length: 0.001, chamferRadius: 0.0)
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
        frameMat.lightingModel = .constant
        frameMat.fillMode = .lines
        frameGeo.firstMaterial = frameMat
        let frameNode = SCNNode(geometry: frameGeo)
        frameNode.position = SCNVector3(0, 0.01, 0)
        container.addChildNode(frameNode)

        let pupilGeo = SCNCylinder(radius: 0.0015, height: 0.12)
        pupilGeo.firstMaterial?.diffuse.contents = UIColor.cyan
        pupilGeo.firstMaterial?.lightingModel = .constant
        pupilLineNode = SCNNode(geometry: pupilGeo)
        pupilLineNode?.eulerAngles.z = .pi / 2
        pupilLineNode?.position.y = 0.02
        container.addChildNode(pupilLineNode!)

        let centerGeo = SCNCylinder(radius: 0.001, height: 0.20)
        centerGeo.firstMaterial?.diffuse.contents = UIColor.magenta
        centerGeo.firstMaterial?.lightingModel = .constant
        let centerNode = SCNNode(geometry: centerGeo)
        container.addChildNode(centerNode)

        let mouthGeo = SCNCylinder(radius: 0.001, height: 0.08)
        mouthGeo.firstMaterial?.diffuse.contents = UIColor.systemGreen
        mouthGeo.firstMaterial?.lightingModel = .constant
        let mouthNode = SCNNode(geometry: mouthGeo)
        mouthNode.eulerAngles.z = .pi / 2
        mouthNode.position.y = -0.03
        container.addChildNode(mouthNode)

        let earGeo = SCNCylinder(radius: 0.001, height: 0.18)
        earGeo.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.6)
        earGeo.firstMaterial?.lightingModel = .constant
        let earNode = SCNNode(geometry: earGeo)
        earNode.eulerAngles.z = .pi / 2
        earNode.position.y = 0.0
        container.addChildNode(earNode)

        let noseGeo = SCNCylinder(radius: 0.001, height: 0.06)
        noseGeo.firstMaterial?.diffuse.contents = UIColor.orange
        noseGeo.firstMaterial?.lightingModel = .constant
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.eulerAngles.z = .pi / 2
        noseNode.position.y = -0.015
        container.addChildNode(noseNode)

        let chinGeo = SCNCylinder(radius: 0.001, height: 0.06)
        chinGeo.firstMaterial?.diffuse.contents = UIColor.purple
        chinGeo.firstMaterial?.lightingModel = .constant
        let chinNode = SCNNode(geometry: chinGeo)
        chinNode.eulerAngles.z = .pi / 2
        chinNode.position.y = -0.07
        container.addChildNode(chinNode)

        let boxGeo = SCNBox(width: 0.14, height: 0.06, length: 0.001, chamferRadius: 0)
        boxGeo.firstMaterial?.diffuse.contents = UIColor.clear
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.green.withAlphaComponent(0.8)
        wireMat.fillMode = .lines
        wireMat.lightingModel = .constant
        boxGeo.firstMaterial = wireMat
        let boxNode = SCNNode(geometry: boxGeo)
        boxNode.position.y = 0.02
        container.addChildNode(boxNode)

        let templeGeo = SCNCylinder(radius: 0.0005, height: 1.0)
        templeGeo.firstMaterial?.diffuse.contents = UIColor.yellow
        templeLineNode = SCNNode(geometry: templeGeo)
        templeLineNode?.eulerAngles.z = .pi / 2
        container.addChildNode(templeLineNode!)

        let coneGeoY = SCNCone(topRadius: 0, bottomRadius: 0.0015, height: 0.004)
        coneGeoY.firstMaterial?.diffuse.contents = UIColor.yellow
        templeLeftArrow = SCNNode(geometry: coneGeoY)
        templeLeftArrow?.eulerAngles.z = -Float.pi / 2
        container.addChildNode(templeLeftArrow!)

        templeRightArrow = SCNNode(geometry: coneGeoY)
        templeRightArrow?.eulerAngles.z = Float.pi / 2
        container.addChildNode(templeRightArrow!)

        let bridgeGeoRuler = SCNCylinder(radius: 0.0005, height: 1.0)
        bridgeGeoRuler.firstMaterial?.diffuse.contents = UIColor.orange
        bridgeLineNode = SCNNode(geometry: bridgeGeoRuler)
        bridgeLineNode?.eulerAngles.z = .pi / 2
        container.addChildNode(bridgeLineNode!)

        let coneGeo = SCNCone(topRadius: 0, bottomRadius: 0.0015, height: 0.004)
        coneGeo.firstMaterial?.diffuse.contents = UIColor.orange
        bridgeLeftArrow = SCNNode(geometry: coneGeo)
        bridgeLeftArrow?.eulerAngles.z = -Float.pi / 2
        container.addChildNode(bridgeLeftArrow!)

        bridgeRightArrow = SCNNode(geometry: coneGeo)
        bridgeRightArrow?.eulerAngles.z = Float.pi / 2
        container.addChildNode(bridgeRightArrow!)
    }
}
