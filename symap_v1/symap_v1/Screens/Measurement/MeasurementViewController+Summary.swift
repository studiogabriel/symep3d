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
        self.isPdfGenerated = false  // 🔴 Reseta a trava do PDF sempre que entrar no resumo
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
        
        // =========================================================================
        // 🔴 NOVO: MOTOR 3D PARA EXIBIR O HOLOGRAMA DO PACIENTE NO RESUMO
        // =========================================================================
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
        
        if let clonedFace = self.safeFaceCache {
            clonedFace.transform = SCNMatrix4Identity
            clonedFace.position = SCNVector3(0, 0, 0)
            
            if clonedFace.childNodes.count > 0 {
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL: Leitura segura de matriz de malha 3D
                let maskNode = clonedFace.childNodes[ 0 ]
                maskNode.isHidden = false
                
                if let oldGeo = maskNode.geometry {
                    let newGeo = oldGeo.copy() as! SCNGeometry
                    let holoMaterial = SCNMaterial()
                    holoMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8) // Ciano
                    holoMaterial.fillMode = .lines // Wireframe Tech
                    holoMaterial.lightingModel = .constant
                    holoMaterial.isDoubleSided = true
                    holoMaterial.colorBufferWriteMask = .all // Desbloqueia a cor
                    
                    newGeo.materials = [holoMaterial]
                    maskNode.geometry = newGeo
                }
                
                // Limpa as linhas residuais da triagem para deixar APENAS o holograma da face visível
                for (index, child) in clonedFace.childNodes.enumerated() {
                    if index != 0 { child.isHidden = true }
                }
            }
            holoScene.rootNode.addChildNode(clonedFace)
        }
        
        // 🔴 CORREÇÃO DO ZOOM: Câmera recuada para 20cm e destravada para não cortar o nariz!
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.01
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.20) // zoom holograma
        holoScene.rootNode.addChildNode(cameraNode)
        
        summaryContainer.addSubview(holoView)
        
        // 🔴 TEXTO EXPLICATIVO DA TECNOLOGIA E MANUAL DE GESTOS (Expandido)
        let techDesc = UILabel(frame: CGRect(x: 20, y: 325, width: view.bounds.width - 40, height: 110))
        techDesc.numberOfLines = 0
        techDesc.textAlignment = .center
        techDesc.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        techDesc.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        techDesc.text = "GÊMEO DIGITAL BIOMÉTRICO (IA)\nO holograma acima não é uma foto, é a reconstrução volumétrica exata da sua face gerada por infravermelhos. Com 100% de precisão matemática, nós eliminamos o erro humano na medição das suas lentes.\n\n COMO MANIPULAR O SEU ROSTO 3D:\n Rotacionar: Arraste com 1 dedo. |  Zoom: Pinça com 2 dedos.\n Mover: Arraste com 2 dedos juntos na tela."
        summaryContainer.addSubview(techDesc)
        
        // 🔴 INFORMAÇÕES CLÍNICAS
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
        
        // =========================================================================
        // 🔴 NOVO: BOTÕES REORGANIZADOS E REDESENHADOS (Cores Atualizadas)
        // =========================================================================
        let btnPDF = UIButton()
        btnPDF.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Azul Ciano Padrão da Symep
        btnPDF.setTitle("Gerar Laudo PDF", for: .normal)
        btnPDF.setTitleColor(.black, for: .normal)
        btnPDF.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnPDF.layer.cornerRadius = 12
        btnPDF.addTarget(self, action: #selector(executePDFGeneration), for: .touchUpInside)
        
        // Fileira 2: Títulos reduzidos e na cor Cinza Padrão do App
        let btnReset = UIButton()
        btnReset.backgroundColor = UIColor(white: 0.2, alpha: 0.9) // Cinza Padrão
        btnReset.setTitle("Refazer", for: .normal)
        btnReset.setTitleColor(.white, for: .normal)
        btnReset.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnReset.layer.cornerRadius = 10
        btnReset.addTarget(self, action: #selector(resetToStartMeasure), for: .touchUpInside)
        
        let btnHome = UIButton()
        btnHome.backgroundColor = UIColor(white: 0.2, alpha: 0.9) // Cinza Padrão
        btnHome.setTitle("Painel", for: .normal)
        btnHome.setTitleColor(.white, for: .normal)
        btnHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnHome.layer.cornerRadius = 10
        btnHome.addTarget(self, action: #selector(returnToTriagem), for: .touchUpInside)
        
        let btnExit = UIButton()
        btnExit.backgroundColor = UIColor(white: 0.2, alpha: 0.9) // Cinza Padrão
        btnExit.setTitle("Encerrar", for: .normal)
        btnExit.setTitleColor(.white, for: .normal)
        btnExit.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnExit.layer.cornerRadius = 10
        btnExit.addTarget(self, action: #selector(exitAppFully), for: .touchUpInside)
        
        // Agrupador horizontal da Fileira 2
        let bottomStack = UIStackView(arrangedSubviews: [btnReset, btnHome, btnExit])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 10
        bottomStack.distribution = .fillEqually
        
        // Agrupador Master Vertical (PDF em cima, as outras opções embaixo)
        let masterStack = UIStackView(arrangedSubviews: [btnPDF, bottomStack])
        masterStack.axis = .vertical
        masterStack.spacing = 12
        masterStack.distribution = .fillEqually
        masterStack.frame = CGRect(x: 30, y: view.bounds.height - 140, width: view.bounds.width - 60, height: 110)
        summaryContainer.addSubview(masterStack)
        
        UIView.animate(withDuration: 0.3) { self.summaryContainer.alpha = 1.0 }
    }
    
    // ============================================================================
    // --- CONTROLE DOS BOTÕES DE SAÍDA E RESET ---
    // ============================================================================
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
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
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
                    self.isPdfGenerated = true  // 🔴 PDF Salvo com Sucesso! Libera os botões de saída
                    self.saveMeasurementToCloud(storagePath: internalPath)
                    self.showLocalShareSheet(pdfData: pdfData)
                }
            }
        }
    }
}
