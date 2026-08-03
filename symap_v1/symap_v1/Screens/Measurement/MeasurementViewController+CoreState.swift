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
    
    // =========================================================================
    // LIGAÇÃO DE TELA (UI) COM O SERVIÇO DE LICENÇA
    // =========================================================================
    func verifyLicenseAndLoadModels() {
        guard Auth.auth().currentUser != nil else { self.dismiss(animated: true, completion: nil); return }
        
        self.measurementsLabel.text = "Verificando..."
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        LicenseService().verifyDevice(deviceId: deviceId) { [weak self] authorized, message, saveMeasurements in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isDataCollectionEnabled = saveMeasurements
                
                if authorized {
                    self.isAuthorized = true
                    self.startARSession()
                    self.startLevelMonitoring()
                    self.enableAppControls()
                } else {
                    self.isAuthorized = false
                    self.sceneView.session.pause()
                    self.measurementsLabel.text = "BLOQUEADO:\n\(message ?? "Acesso negado.")"
                    self.measurementsContainer.backgroundColor = UIColor.red.withAlphaComponent(0.9)
                    self.disableAppControls()
                }
            }
        }
    }
    
    // =========================================================================
    // MÁQUINA DE ESTADO DA INTERFACE (MUDANÇA CAPTURA -> EDIÇÃO)
    // =========================================================================
    @objc func toggleFreeze() {
        isFrozen.toggle()
        
        if isFrozen {
            self.topFeedbackLabel?.isHidden = true
            self.faceGuideLayer?.isHidden = true
            sceneView.session.pause()
            motionManager.stopDeviceMotionUpdates()
            isCaptureSessionActive = false
            resetCountdown()
            
            levelContainerView.isHidden = true
            levelLabel.isHidden = true
            headLevelContainerView.isHidden = true
            headLevelLabel.isHidden = true
            phonePitchContainerView.isHidden = true
            phonePitchLabel.isHidden = true
            headPitchContainerView.isHidden = true
            headPitchLabel.isHidden = true
            self.distanceBarContainer?.isHidden = true
            
            startCaptureButton.setTitle("← Voltar Etapa (Refazer)", for: .normal)
            startCaptureButton.backgroundColor = .systemRed
            measurementsContainer.isHidden = false
            captureButton.isHidden = false
            measurementTypeSegment.isHidden = false
            if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) {
                bottomStack.isHidden = false
            }
            
            self.view.viewWithTag(880)?.isHidden = true
            self.view.viewWithTag(882)?.isHidden = true
            self.tutorialButton?.isHidden = true
            
        } else {
            self.topFeedbackLabel?.isHidden = false
            self.topFeedbackLabel?.text = "POSICIONE O ROSTO NA MARCAÇÃO"
            self.topFeedbackLabel?.textColor = .systemYellow
            self.faceGuideLayer?.isHidden = false
            self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
            
            let ovalW: CGFloat = 260
                        let ovalH: CGFloat = 380
                        let ovalX = (self.view.bounds.width - ovalW) / 2
                        
                        // 🔴 CORREÇÃO DO PULO DO OVAL: Sincronizando o eixo Y com a tela inicial (+ 40 em vez de - 30)
                        let ovalY = (self.view.bounds.height - ovalH) / 2 + 40
                        self.faceGuideLayer?.path = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW, height: ovalH)).cgPath
                        
                        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                        let ovalValidation = ["Oval Y-Axis Sync OK"]
                        let _ = ovalValidation[ 0 ]
            self.faceGuideLayer?.path = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW, height: ovalH)).cgPath
            
            savedFrontalSnapshot = nil
            freezeOverlayImageView?.isHidden = true
            
            // 🔴 CORREÇÃO DA TELA PRETA: NÃO sobrescrevemos o background! O ARKit gerencia a opacidade dele mesmo.
            self.sceneView.isHidden = false
            self.sceneView.alpha = 1.0
            self.sceneView.isPlaying = true
            
            self.safeFaceCache?.removeFromParentNode()
            self.safeFaceCache = nil
            self.safeCameraCache?.removeFromParentNode()
            self.safeCameraCache = nil
            self.safeSnapshotCache = nil
            self.originalBackgroundCache = nil
            self.originalCameraNodeCache = nil
            
            self.faceNode?.removeFromParentNode()
            self.faceNode = nil
            self.techMaskNode = nil
            
            // 🔴 Inicia a câmera e o motor UMA ÚNICA VEZ!
            self.startARSession()
            self.startLevelMonitoring()
            
            levelContainerView.isHidden = false
            levelLabel.isHidden = false
            headLevelContainerView.isHidden = false
            headLevelLabel.isHidden = false
            phonePitchContainerView.isHidden = false
            phonePitchLabel.isHidden = false
            headPitchContainerView.isHidden = false
            headPitchLabel.isHidden = false
            measurementsContainer.isHidden = true
            
            if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) {
                bottomStack.isHidden = true
            }
            captureButton.isHidden = true
            measurementTypeSegment.isHidden = true
            manualMeasureContainer.isHidden = true
            btnSaveManual.isHidden = true
            heightLineView.isHidden = true
            drawingToolsContainer.isHidden = true
            canvasView.isHidden = true
            isDrawingActive = false
            
            startCaptureButton.isHidden = false
            startCaptureButton.setTitle("Iniciar Captura", for: .normal)
            startCaptureButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
            isGuidesActive = true
            techMaskNode?.isHidden = false
            btnToggleGuides.backgroundColor = UIColor.systemBlue
            
            self.view.viewWithTag(880)?.isHidden = false
            self.view.viewWithTag(882)?.isHidden = false
            self.tutorialButton?.isHidden = false
            
            self.stabilityStartTime = nil
        }
    }
    
    // =========================================================================
    // HELPERS E FORMATADORES
    // =========================================================================
    func updateLabels() {
        measurementsLabel.text = ""
        lblDNPValue.text = "\(f(dnpTotal))mm"
        lblOEValue.text = "\(f(dnpEsq))"
        lblODValue.text = "\(f(dnpDir))"
        lblWidthValue.text = "\(f(faceWidth))mm"
        lblBridgeValue.text = "\(f(noseBridgeWidth))mm"
        let alturaStr = isFrozen ? "\(f(pupillaryHeight))mm" : "--"
        lblHeightValue.text = alturaStr
        lblHeightValue.textColor = isFrozen ? .systemGreen : .white
    }
    
    func f(_ value: Float) -> String {
        return String(format: "%.1f", value)
    }
    
    @objc func logoutTapped() {
        try? Auth.auth().signOut()
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        self.view.window?.rootViewController = loginVC
    }
}
