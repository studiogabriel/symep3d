import UIKit
import SceneKit
import ARKit
import CoreMotion

extension MeasurementViewController {
    
    func startVisagismSummary() {
        // Pausa a câmera e salva a face atual para o holograma
        sceneView.session.pause()
        motionManager.stopDeviceMotionUpdates()
        self.safeFaceCache = self.faceNode?.clone()
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
        let safetyCheck = ["Visagism Phase Active"]
        let _ = safetyCheck[ 0 ]
        
        // =======================================================
        // 🔴 1. EXPERIÊNCIA UX: TELA FAKE DE "ANALISANDO BIOMETRIA"
        // =======================================================
        let loadingContainer = UIView(frame: view.bounds)
        loadingContainer.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        loadingContainer.tag = 8887
        loadingContainer.alpha = 0.0
        view.addSubview(loadingContainer)
        
        let scanTitle = UILabel(frame: CGRect(x: 20, y: view.bounds.height / 2 - 60, width: view.bounds.width - 40, height: 30))
        scanTitle.text = "PROCESSANDO BIOMETRIA..."
        scanTitle.textAlignment = .center
        scanTitle.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        scanTitle.font = UIFont.systemFont(ofSize: 18, weight: .black)
        loadingContainer.addSubview(scanTitle)
        
        let progressBarBg = UIView(frame: CGRect(x: 50, y: view.bounds.height / 2, width: view.bounds.width - 100, height: 6))
        progressBarBg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        progressBarBg.layer.cornerRadius = 3
        loadingContainer.addSubview(progressBarBg)
        
        let progressBarFill = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 6))
        progressBarFill.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        progressBarFill.layer.cornerRadius = 3
        progressBarBg.addSubview(progressBarFill)
        
        let scanSteps = UILabel(frame: CGRect(x: 20, y: view.bounds.height / 2 + 30, width: view.bounds.width - 40, height: 20))
        scanSteps.text = "Mapeando 30.000 pontos faciais..."
        scanSteps.textAlignment = .center
        scanSteps.textColor = .lightGray
        scanSteps.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        loadingContainer.addSubview(scanSteps)
        
        // Esconde a interface da câmera
        self.topFeedbackLabel?.isHidden = true
        self.faceGuideLayer?.isHidden = true
        self.startCaptureButton.isHidden = true
        self.levelContainerView.isHidden = true
        self.phonePitchContainerView.isHidden = true
        self.view.viewWithTag(882)?.isHidden = true
        self.view.viewWithTag(880)?.isHidden = true
        
        UIView.animate(withDuration: 0.3) { loadingContainer.alpha = 1.0 }
        
        // 🔴 MÁGICA: Animação de processamento (Teatro UX)
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
            progressBarFill.frame.size.width = progressBarBg.bounds.width * 0.4
        }) { _ in
            scanSteps.text = "Calculando proporções de visagismo..."
            UIView.animate(withDuration: 1.5, delay: 0.2, options: .curveEaseInOut, animations: {
                progressBarFill.frame.size.width = progressBarBg.bounds.width
            }) { _ in
                // Fim do teatro: Remove o loading e exibe a verdadeira tela de Visagismo!
                UIView.animate(withDuration: 0.3, animations: { loadingContainer.alpha = 0.0 }) { _ in
                    loadingContainer.removeFromSuperview()
                    self.showVisagismResults()
                }
            }
        }
    }
    
    // =======================================================
    // 🔴 2. A TELA DE VISAGISMO OFICIAL E PERSONALIZADA
    // =======================================================
    func showVisagismResults() {
        let visagismContainer = UIView(frame: view.bounds)
        visagismContainer.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        visagismContainer.tag = 8888
        visagismContainer.alpha = 0.0
        view.addSubview(visagismContainer)
        
        let title = UILabel(frame: CGRect(x: 20, y: 60, width: view.bounds.width - 40, height: 30))
        title.text = "ANÁLISE DE VISAGISMO"
        title.textAlignment = .center
        title.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        title.font = UIFont.systemFont(ofSize: 22, weight: .black)
        visagismContainer.addSubview(title)
        
        // Holograma
        let holoView = SCNView(frame: CGRect(x: 40, y: 100, width: view.bounds.width - 80, height: 230))
        holoView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        holoView.layer.cornerRadius = 16
        holoView.layer.borderWidth = 2
        holoView.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3).cgColor
        holoView.autoenablesDefaultLighting = true
        holoView.allowsCameraControl = true
        
        let holoScene = SCNScene()
        holoView.scene = holoScene
        
        if let clonedFace = self.safeFaceCache {
            clonedFace.transform = SCNMatrix4Identity
            clonedFace.position = SCNVector3(0, 0, 0)
            if clonedFace.childNodes.count > 0 {
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Blindado)
                let maskClone = clonedFace.childNodes[ 0 ].clone()
                maskClone.isHidden = false
                if let oldGeo = maskClone.geometry {
                    let newGeo = oldGeo.copy() as! SCNGeometry
                    let holoMaterial = SCNMaterial()
                    holoMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
                    holoMaterial.fillMode = .lines
                    holoMaterial.lightingModel = .constant
                    holoMaterial.isDoubleSided = true
                    newGeo.materials = [holoMaterial]
                    maskClone.geometry = newGeo
                }
                holoScene.rootNode.addChildNode(maskClone)
            }
        }
        
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.01
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.20)
        holoScene.rootNode.addChildNode(cameraNode)
        visagismContainer.addSubview(holoView)
        
        // 🔴 TEXTO PESSOAL E DINÂMICO
        let info = UITextView(frame: CGRect(x: 30, y: 350, width: view.bounds.width - 60, height: view.bounds.height - 480))
        info.backgroundColor = .clear
        info.textColor = .lightGray
        info.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        info.isEditable = false
        
        // Injetando as variáveis do paciente lidas pela câmera
        let patientFirstName = self.patientName.components(separatedBy: " ").first ?? "Paciente"
        let patientStats = """
        IDENTIFICAÇÃO BIOMÉTRICA DE \(patientFirstName.uppercased()):
        • Largura do Rosto: \(String(format: "%.1f", self.faceWidth)) mm
        • Base Nasal: \(String(format: "%.1f", self.noseBridgeWidth)) mm
        • Distância Pupilar: \(String(format: "%.1f", self.dnpTotal)) mm
        • Formato Mapeado: \(self.faceShape.uppercased())
        
        """
        
        let fullText = patientStats + self.frameSuggestion
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 10
        style.alignment = .justified
        
        let attrText = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: style
        ])
        
        // Pinta a caixa de identificação do paciente com a nossa cor Ciano
        let statRange = (fullText as NSString).range(of: patientStats)
        attrText.addAttribute(.foregroundColor, value: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), range: statRange)
        attrText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 13), range: statRange)
        
        info.attributedText = attrText
        visagismContainer.addSubview(info)
        
        let btnNext = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
        btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnNext.setTitle("Avançar para Medição Técnica", for: .normal)
        btnNext.setTitleColor(.black, for: .normal)
        btnNext.layer.cornerRadius = 15
        btnNext.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnNext.addTarget(self, action: #selector(finishVisagismAndStartMeasurement), for: .touchUpInside)
        visagismContainer.addSubview(btnNext)
        
        UIView.animate(withDuration: 0.3) { visagismContainer.alpha = 1.0 }
    }
    
    @objc func finishVisagismAndStartMeasurement() {
        guard let visagismView = self.view.viewWithTag(8888) else { return }
        
        self.isVisagismCompleted = true
        
        UIView.animate(withDuration: 0.3, animations: { visagismView.alpha = 0.0 }) { _ in
            visagismView.removeFromSuperview()
            
            // 🔴 3. CORREÇÃO DA CÂMERA E DO ÓCULOS SUMINDO
            // Limpamos o holograma falso
            self.safeFaceCache?.removeFromParentNode()
            self.safeFaceCache = nil
            
            // Religa o ARKit SEM RESETAR AS ÂNCORAS (A mágica que mantém o rosto colado!)
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            self.sceneView.session.run(config) // <-- Sem removeExistingAnchors!
            
            self.startLevelMonitoring()
            self.topFeedbackLabel?.isHidden = false
            self.faceGuideLayer?.isHidden = false
            self.levelContainerView.isHidden = false
            self.phonePitchContainerView.isHidden = false
            
            self.startCaptureButton.isHidden = false
            self.startCaptureButton.setTitle("Iniciar Captura (Medição)", for: .normal)
            
            self.view.viewWithTag(882)?.isHidden = false // Habilita Botão Try-On
            self.view.viewWithTag(880)?.isHidden = false // Habilita Botão Tripé
            
            // 🔴 AGORA sim aplica o modelo no rosto vivo!
            self.applyRecommendedModel(modelIdOrName: self.recommendedAutoModel)
        }
    }
    
    func applyRecommendedModel(modelIdOrName: String) {
            // 🔴 INTELIGÊNCIA ESCALÁVEL: Ele varre o banco de dados e encontra o óculos que contém a palavra-chave (ex: "suki" encontra "SL Suki Feminino")
            if let cloudModel = CloudManager.shared.availableModels.first(where: { $0.name.lowercased().contains(modelIdOrName.lowercased()) }) {
                self.loadCloudModel(model: cloudModel)
            } else {
                print("⚠️ AVISO: A IA recomendou a linha '\(modelIdOrName)', mas o catálogo da nuvem não possui este modelo.")
            }
        }
}
