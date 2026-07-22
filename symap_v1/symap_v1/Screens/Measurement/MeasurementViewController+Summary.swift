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
    
    @objc func showSummaryScreen() {
        self.isPdfGenerated = false
        self.manualMeasureContainer.isHidden = true
        self.measurementTypeSegment.isHidden = true
        self.captureButton.isHidden = true
        self.startCaptureButton.isHidden = true
        self.measurementsContainer.isHidden = true
        self.heightLineView.isHidden = true
        if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) { bottomStack.isHidden = true }
        
        if summaryContainer == nil {
            summaryContainer = UIView(frame: view.bounds)
            summaryContainer.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
            view.addSubview(summaryContainer)
        }
        
        summaryContainer.subviews.forEach { $0.removeFromSuperview() }
        summaryContainer.isHidden = false
        summaryContainer.alpha = 0
        
        let title = UILabel(frame: CGRect(x: 20, y: 55, width: view.bounds.width - 40, height: 30))
        title.text = "RESUMO CLÍNICO"
        title.textAlignment = .center
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 22, weight: .black)
        summaryContainer.addSubview(title)
        
        let holoView = SCNView(frame: CGRect(x: 40, y: 95, width: view.bounds.width - 80, height: 230))
        holoView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        holoView.layer.cornerRadius = 16
        holoView.clipsToBounds = true
        holoView.layer.borderWidth = 2
        holoView.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3).cgColor
        holoView.autoenablesDefaultLighting = true
        holoView.allowsCameraControl = true
        holoView.isPlaying = true
        
        let holoScene = SCNScene()
        holoView.scene = holoScene
        
        // 🔴 ERRO 2 CORRIGIDO: Fazemos um "clone() profundo" para proteger a matriz original!
        if let baseFace = self.safeFaceCache {
            let clonedFace = baseFace.clone()
            clonedFace.transform = SCNMatrix4Identity
            clonedFace.position = SCNVector3(0, 0, 0)
            
            if clonedFace.childNodes.count > 0 {
                // Nossa blindagem estrutural matriz
                let maskNode = clonedFace.childNodes[ 0 ]
                maskNode.isHidden = false
                
                if let oldGeo = maskNode.geometry {
                    let newGeo = oldGeo.copy() as! SCNGeometry
                    let holoMaterial = SCNMaterial()
                    holoMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
                    holoMaterial.fillMode = .lines
                    holoMaterial.lightingModel = .constant
                    holoMaterial.isDoubleSided = true
                    holoMaterial.colorBufferWriteMask = .all
                    
                    newGeo.materials = [holoMaterial]
                    maskNode.geometry = newGeo
                }
                
                // Oculta linhas indesejadas (sensores), deixa só o óculos customizado
                for (index, child) in clonedFace.childNodes.enumerated() {
                    if index != 0 && child.name != "customGlasses" { child.isHidden = true }
                }
            }
            holoScene.rootNode.addChildNode(clonedFace)
        }
        
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.01
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.20)
        holoScene.rootNode.addChildNode(cameraNode)
        
        summaryContainer.addSubview(holoView)
        
        let techDesc = UILabel(frame: CGRect(x: 20, y: 325, width: view.bounds.width - 40, height: 110))
        techDesc.numberOfLines = 0
        techDesc.textAlignment = .center
        techDesc.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        techDesc.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        techDesc.text = "GÊMEO DIGITAL BIOMÉTRICO (IA)\nO holograma acima não é uma foto, é a reconstrução volumétrica exata da sua face gerada por infravermelhos. Com 100% de precisão matemática, nós eliminamos o erro humano na medição das suas lentes.\n\n COMO MANIPULAR O SEU ROSTO 3D:\n Rotacionar: Arraste com 1 dedo. |  Zoom: Pinça com 2 dedos.\n Mover: Arraste com 2 dedos juntos na tela."
        summaryContainer.addSubview(techDesc)
        
        let info = UITextView(frame: CGRect(x: 30, y: 440, width: view.bounds.width - 60, height: view.bounds.height - 600))
        info.backgroundColor = .clear
        info.textColor = .lightGray
        info.font = UIFont.systemFont(ofSize: 13)
        info.isEditable = false
        info.text = """
        👤 Paciente: \(self.patientName)
        👓 Lente: \(self.selectedLensType)
        📏 DNP Total: \(self.f(self.dnpTotal)) mm | Ponte: \(self.f(self.noseBridgeWidth)) mm
        📏 Largura do Rosto: \(self.f(self.faceWidth)) mm
        - Altura de Montagem (H): \(self.f(self.pupillaryHeight)) mm
        - Lente Horizontal: \(self.f(self.manualFrameWidth)) mm
        - Lente Vertical: \(self.f(self.manualFrameHeight)) mm
        - Diagonal da Lente: \(self.f(self.manualFrameDiagonal)) mm
        - Visão Longe OD: \(self.rxEsfOD) | \(self.rxCilOD) | \(self.rxEixoOD)
        - Visão Longe OE: \(self.rxEsfOE) | \(self.rxCilOE) | \(self.rxEixoOE)
        - Comportamento Visual IA:
        \(self.visionBehaviorResult)
        """
        summaryContainer.addSubview(info)
        
        let btnPDF = UIButton()
        btnPDF.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnPDF.setTitle("Gerar Laudo PDF", for: .normal)
        btnPDF.setTitleColor(.black, for: .normal)
        btnPDF.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnPDF.layer.cornerRadius = 12
        btnPDF.addTarget(self, action: #selector(executePDFGeneration), for: .touchUpInside)
        
        let btnReset = UIButton()
        btnReset.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        btnReset.setTitle("Refazer", for: .normal)
        btnReset.setTitleColor(.white, for: .normal)
        btnReset.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnReset.layer.cornerRadius = 10
        btnReset.addTarget(self, action: #selector(resetToStartMeasure), for: .touchUpInside)
        
        let btnHome = UIButton()
        btnHome.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        btnHome.setTitle("Painel", for: .normal)
        btnHome.setTitleColor(.white, for: .normal)
        btnHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnHome.layer.cornerRadius = 10
        btnHome.addTarget(self, action: #selector(returnToTriagem), for: .touchUpInside)
        
        let btnExit = UIButton()
        btnExit.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        btnExit.setTitle("Encerrar", for: .normal)
        btnExit.setTitleColor(.white, for: .normal)
        btnExit.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnExit.layer.cornerRadius = 10
        btnExit.addTarget(self, action: #selector(exitAppFully), for: .touchUpInside)
        
        let bottomStack = UIStackView(arrangedSubviews: [btnReset, btnHome, btnExit])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 10
        bottomStack.distribution = .fillEqually
        
        let btnCustomModel = UIButton()
        btnCustomModel.backgroundColor = UIColor.systemPurple
        btnCustomModel.setTitle("⚙️ Personalizar Armação", for: .normal)
        btnCustomModel.setTitleColor(.white, for: .normal)
        btnCustomModel.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnCustomModel.layer.cornerRadius = 12
        btnCustomModel.addTarget(self, action: #selector(openConfigurator), for: .touchUpInside)
        
        let masterStack = UIStackView(arrangedSubviews: [btnCustomModel, btnPDF, bottomStack])
        masterStack.axis = .vertical
        masterStack.spacing = 12
        masterStack.distribution = .fillEqually
        masterStack.frame = CGRect(x: 30, y: view.bounds.height - 190, width: view.bounds.width - 60, height: 160)
        summaryContainer.addSubview(masterStack)
        
        UIView.animate(withDuration: 0.3) { self.summaryContainer.alpha = 1.0 }
    }
    
    @objc func openConfigurator() {
        guard let currentModel = self.currentCloudModel else {
            let alert = UIAlertController(title: "Nenhum Óculos Selecionado", message: "Por favor, retorne, escolha um modelo no menu (👓) e vista no espelho virtual antes de abrir a personalização.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Entendi", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let configVC = ConfiguratorViewController()
        let nomePadronizado = currentModel.name.lowercased().replacingOccurrences(of: " ", with: "_")
        configVC.currentModelName = nomePadronizado
        configVC.bridgeSize = self.noseBridgeWidth
        configVC.leftWidth = self.faceWidthLeft
        configVC.rightWidth = self.faceWidthRight
        configVC.nasalProfile = self.nasalProfile
        
        let targetFace = self.safeFaceCache ?? self.faceNode
        if targetFace?.childNodes.count ?? 0 > 0, let faceMeshNode = targetFace?.childNodes[ 0 ].clone() {
            let holoMaterial = SCNMaterial()
            holoMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.25)
            holoMaterial.fillMode = .lines
            holoMaterial.lightingModel = .constant
            holoMaterial.isDoubleSided = true
            faceMeshNode.geometry?.firstMaterial = holoMaterial
            
            faceMeshNode.scale = SCNVector3(1000, 1000, 1000)
            let faceY = -(self.glassesYOffset * 1000)
            let faceZ: Float = -50.0
            faceMeshNode.position = SCNVector3(0, faceY, faceZ)
            configVC.patientFaceNode = faceMeshNode
        }
        
        configVC.modalPresentationStyle = .overFullScreen
        configVC.modalTransitionStyle = .crossDissolve
        
        configVC.onApplyCustomization = { [weak self] (edits, newColor, customNode) in
            guard let self = self, let newNode = customNode?.clone() else { return }
            
            let tFace = self.safeFaceCache ?? self.faceNode
            // 🔴 ERRO 2 CORRIGIDO: Limpa todos os óculos anteriores antes de colocar o novo parametrizado
            tFace?.childNodes.filter({ $0.name == "customGlasses" }).forEach({ $0.removeFromParentNode() })
            
            if let oldGlasses = self.glassesNode {
                newNode.position = oldGlasses.position
                newNode.scale = oldGlasses.scale
                newNode.eulerAngles = oldGlasses.eulerAngles
            } else {
                newNode.scale = SCNVector3(0.001, 0.001, 0.001)
            }
            
            let corFinal = newColor ?? UIColor(white: 0.2, alpha: 1.0)
            func applyRealisticTexture(to node: SCNNode) {
                if let geo = node.geometry {
                    let mat = geo.firstMaterial ?? SCNMaterial()
                    mat.diffuse.contents = corFinal
                    mat.lightingModel = .physicallyBased
                    geo.firstMaterial = mat
                }
            }
            
            applyRealisticTexture(to: newNode)
            if let morpher = newNode.morpher {
                for (key, value) in edits { morpher.setWeight(CGFloat(value), forTargetNamed: key) }
            }
            newNode.enumerateChildNodes { (child, _) in
                applyRealisticTexture(to: child)
                if let morpher = child.morpher {
                    for (key, value) in edits { morpher.setWeight(CGFloat(value), forTargetNamed: key) }
                }
            }
            
            tFace?.addChildNode(newNode)
            self.glassesNode = newNode
            
            self.pupillaryHeight = 0.0
            self.manualFrameHeight = 0.0
            self.manualFrameWidth = 0.0
            self.manualFrameDiagonal = 0.0
            self.updateSegmentTitles()
            self.updateLabels()
            
            if let corFinal = newColor {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                corFinal.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let corHex = String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
                UserDefaults.standard.set(corHex, forKey: "lastColor")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let alert = UIAlertController(title: "Armação Atualizada", message: "O design personalizado foi sincronizado com o rosto do cliente.\n\nComo a armação mudou de tamanho, por favor tire as medidas manuais (Altura de Montagem, Altura do Aro, Largura e Diagonal) novamente no novo formato para garantir a precisão do PDF.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK, Vou medir", style: .default, handler: { _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.summaryContainer?.alpha = 0
                    }) { _ in
                        self.summaryContainer?.isHidden = true
                        self.measurementsContainer.isHidden = false
                        self.measurementTypeSegment.isHidden = false
                        
                        // 🔴 ERRO 1 CORRIGIDO: Exibe apenas o botão AZUL (Avançar). Esconde os demais!
                        self.captureButton.isHidden = false
                        self.startCaptureButton.isHidden = true // Este é o vermelho (Refazer)!
                        
                        self.view.viewWithTag(880)?.isHidden = true // Esconde botão Tripé
                        self.view.viewWithTag(882)?.isHidden = true // Esconde botão Provador Virtual
                        self.tutorialButton?.isHidden = true      // Esconde Tutorial
                        
                        if let bottomStack = self.view.subviews.first(where: { $0 is UIStackView }) {
                            bottomStack.isHidden = false
                        }
                        
                        self.currentManualMode = 0
                        self.measurementTypeSegment.selectedSegmentIndex = 0
                        self.manualMeasureContainer.isHidden = true
                        self.heightLineView.isHidden = true
                    }
                }))
                self.present(alert, animated: true)
            }
        }
        
        self.present(configVC, animated: true, completion: nil)
    }
    
    func performExitAction(action: @escaping () -> Void) {
        if !self.isPdfGenerated {
            let alert = UIAlertController(title: "Atenção: Laudo Não Salvo", message: "O laudo em PDF ainda não foi gerado. Deseja mesmo sair desta tela e perder os dados?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Sair Sem Salvar", style: .destructive, handler: { _ in
                action()
            }))
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            action()
        }
    }
    
    @objc func resetToStartMeasure() {
        performExitAction {
            let blackCurtain = UIView(frame: self.view.bounds)
            blackCurtain.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
            if let window = UIApplication.shared.windows.first(where: { $0 is UIWindow }) {
                window.addSubview(blackCurtain)
            } else {
                self.view.addSubview(blackCurtain)
                self.view.bringSubviewToFront(blackCurtain)
            }
            
            self.summaryContainer?.isHidden = true
            self.summaryContainer?.alpha = 0
            self.isMappingVisionCompleted = false
            self.approvalContainer?.isHidden = true
            self.prescriptionWizardContainer?.isHidden = true
            self.distanceBarContainer?.isHidden = true
            self.manualFrameWidth = 0.0
            self.manualFrameHeight = 0.0
            self.manualFrameDiagonal = 0.0
            self.pupillaryHeight = 0.0
            self.updateSegmentTitles()
            
            self.isFrozen = true
            self.toggleFreeze()
            
            UIView.animate(withDuration: 0.5, delay: 0.8, animations: {
                blackCurtain.alpha = 0
            }) { _ in
                blackCurtain.removeFromSuperview()
            }
        }
    }
    
    @objc func returnToTriagem() {
        performExitAction {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func exitAppFully() {
        performExitAction {
            try? Auth.auth().signOut()
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self.view.window?.rootViewController = loginVC
        }
    }
    
    @objc func executePDFGeneration() {
        guard let snapshot = self.savedFrontalSnapshot else { return }
        let pdfData = createPDF(image: snapshot)
        
        let loadingAlert = UIAlertController(title: "Salvando na Nuvem...", message: "O laudo está sendo enviado para a aba de Relatórios do seu painel. Aguarde.", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        guard let user = Auth.auth().currentUser else {
            loadingAlert.dismiss(animated: true) { self.showLocalShareSheet(pdfData: pdfData) }
            return
        }
        
        let fileName = "laudo_\(Int(Date().timeIntervalSince1970)).pdf"
        let storageRef = Storage.storage().reference().child("laudos/\(user.uid)/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        
        storageRef.putData(pdfData, metadata: metadata) { (meta, error) in
            if error != nil {
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self.saveMeasurementToCloud(storagePath: nil)
                        self.showLocalShareSheet(pdfData: pdfData)
                    }
                }
                return
            }
            
            let internalPath = "laudos/\(user.uid)/\(fileName)"
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    self.isPdfGenerated = true
                    self.saveMeasurementToCloud(storagePath: internalPath)
                    self.showLocalShareSheet(pdfData: pdfData)
                }
            }
        }
    }
}
