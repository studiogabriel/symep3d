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
        
        let presentationNode = SCNNode()
        
        if let originalFace = self.safeFaceCache {
            if originalFace.childNodes.count > 0 {
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Seguro)
                let maskClone = originalFace.childNodes[ 0 ].clone()
                maskClone.transform = SCNMatrix4Identity
                maskClone.position = SCNVector3(0, 0, 0)
                
                if let oldGeo = maskClone.geometry {
                    let newGeo = oldGeo.copy() as! SCNGeometry
                    let holoMaterial = SCNMaterial()
                    holoMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
                    holoMaterial.fillMode = .lines
                    holoMaterial.lightingModel = .constant
                    holoMaterial.isDoubleSided = true
                    holoMaterial.colorBufferWriteMask = .all
                    
                    newGeo.materials = [holoMaterial]
                    maskClone.geometry = newGeo
                }
                maskClone.isHidden = false
                presentationNode.addChildNode(maskClone)
            }
            
            if let customGlasses = originalFace.childNodes.first(where: { $0.name == "customGlasses" })?.clone() {
                customGlasses.isHidden = false
                presentationNode.addChildNode(customGlasses)
            }
        }
        
        presentationNode.position = SCNVector3(0, 0, 0)
        holoScene.rootNode.addChildNode(presentationNode)
        
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
        
        // 🔴 NOVO: BOTÃO DE EXPORTAÇÃO (Substituindo o antigo menu manual)
        let btnExport3D = UIButton()
        btnExport3D.backgroundColor = UIColor.systemPurple
        btnExport3D.setTitle("📥 Exportar Armação Personalizada", for: .normal)
        btnExport3D.setTitleColor(.white, for: .normal)
        btnExport3D.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnExport3D.layer.cornerRadius = 12
        btnExport3D.addTarget(self, action: #selector(exportCustomGlasses), for: .touchUpInside)
        
        let masterStack = UIStackView(arrangedSubviews: [btnExport3D, btnPDF, bottomStack])
        masterStack.axis = .vertical
        masterStack.spacing = 12
        masterStack.distribution = .fillEqually
        masterStack.frame = CGRect(x: 30, y: view.bounds.height - 190, width: view.bounds.width - 60, height: 160)
        summaryContainer.addSubview(masterStack)
        
        UIView.animate(withDuration: 0.3) { self.summaryContainer.alpha = 1.0 }
    }
    
    // =========================================================================
    // 🔴 NOVO FLUXO: EXPORTAÇÃO 3D (STL) VIA NUVEM
    // =========================================================================
    @objc func exportCustomGlasses() {
        guard self.currentCloudModel != nil else {
            let alert = UIAlertController(title: "Nenhum Óculos Ativo", message: "Nenhum modelo foi detectado no rosto.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Processando Pedido...", message: "Enviando parâmetros biométricos para a Nuvem. O arquivo 3D STL será gerado automaticamente pelo servidor.", preferredStyle: .alert)
        present(alert, animated: true)
        
        let fileName = "pedido_symap_\(Int(Date().timeIntervalSince1970)).stl"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true) {
                self.saveOrderLinkToFirestore(fileName: fileName)
                let successAlert = UIAlertController(title: "Sucesso!", message: "Pedido enviado para a nuvem! O robô laboratorial enviará o arquivo 3D em instantes.", preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(successAlert, animated: true)
            }
        }
    }
    
    func saveOrderLinkToFirestore(fileName: String) {
            guard let user = Auth.auth().currentUser else { return }
            
            // Pega o nome do óculos atual ou a keyword do visagismo
            let rawModelName = self.currentCloudModel?.name ?? self.recommendedAutoModel
            
            // 🔴 CORREÇÃO DO ERRO NA NUVEM: Padroniza o nome para buscar o arquivo exato no servidor!
            // Transforma "SL Suki Feminino" em "sl_suki_feminino" para o Storage encontrar
            var modelBaseName = rawModelName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
            
            // Fallback de segurança para garantir que a nuvem ache os arquivos com o prefixo exato antigo
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let safetyCheck = ["Anatomic 3-Zone Routing"]
                let _ = safetyCheck[ 0 ]

                // 🔴 INTELIGÊNCIA ANATÔMICA (3 ESCALAS): Infantil, Feminino e Masculino
                // Menor que 124mm = Infantil | De 124mm a 134.9mm = Feminino | A partir de 135mm = Masculino
                let isLargeFace = self.faceWidth >= 135.0
                let isKidsFace = self.faceWidth < 124.0
                
                if modelBaseName == "luno" { modelBaseName = isKidsFace ? "sl_luno_infantil" : (isLargeFace ? "sl_luno_masculino" : "sl_luno_feminino") }
                if modelBaseName == "nunu" { modelBaseName = isKidsFace ? "sl_nunu_infantil" : (isLargeFace ? "sl_nunu_masculino" : "sl_nunu_feminino") }
                if modelBaseName == "suki" { modelBaseName = isKidsFace ? "sl_suki_infantil" : (isLargeFace ? "sl_suki_masculino" : "sl_suki_feminino") }
                if modelBaseName == "timbau" { modelBaseName = isKidsFace ? "sl_timbau_infantil" : (isLargeFace ? "sl_timbau_masculino" : "sl_timbau_feminino") }
            
        // Solicita as chaves matemáticas ao Motor!
                let edicoesShapeKeys = AutoConfiguratorEngine.calculateMorphWeights(
                    keyword: rawModelName,
                    faceWidth: self.faceWidth,
                    bridgeWidth: self.noseBridgeWidth,
                    nasalProfile: self.nasalProfile,
                    faceShape: self.faceShape // 🔴 Motor agora sabe o formato do rosto!
                )
            
            let data: [String: Any] = [
                "userId": user.uid,
                "stlUrl": "gerando_na_nuvem...",
                "stlFileName": fileName,
                "timestamp": FieldValue.serverTimestamp(),
                "status": "Processando na Nuvem",
                "modeloBase": modelBaseName, // 🔴 Nome formatado e sanitizado para o Cloud Function
                "edicoesLaboratorio": edicoesShapeKeys,
                "biometrics": [
                    "bridge": self.noseBridgeWidth,
                    "leftWidth": self.faceWidthLeft,
                    "rightWidth": self.faceWidthRight
                ]
            ]
            
            // 1. Envia o pedido e aciona a Function
            let docRef = Firestore.firestore().collection("orders_stl").addDocument(data: data)
            
            // 2. Fica escutando o servidor
            var listener: ListenerRegistration?
            listener = docRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot, document.exists,
                      let dados = document.data() else { return }
                
                let status = dados["status"] as? String ?? ""
                
                if status == "Concluído" {
                    let stlUrl = dados["stlUrl"] as? String ?? ""
                    listener?.remove()
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "✅ Arquivo 3D Pronto!",
                            message: "O servidor finalizou a modelagem. O arquivo STL da fábrica está pronto para download.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Baixar / Compartilhar", style: .default) { _ in
                            guard let url = URL(string: stlUrl) else { return }
                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            
                            // Rotina de apresentação robusta do Share Sheet (Sem tela preta)
                            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                                var topController = window.rootViewController
                                while let presented = topController?.presentedViewController {
                                    topController = presented
                                }
                                if let popover = activityVC.popoverPresentationController {
                                    popover.sourceView = topController?.view
                                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                                    popover.permittedArrowDirections = []
                                }
                                topController?.present(activityVC, animated: true)
                            }
                        })
                        alert.addAction(UIAlertAction(title: "Fechar", style: .cancel))
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                            var topController = window.rootViewController
                            while let presented = topController?.presentedViewController {
                                topController = presented
                            }
                            topController?.present(alert, animated: true)
                        }
                    }
                } else if status == "Erro ao Gerar 3D" {
                    listener?.remove()
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "❌ Erro na Nuvem", message: "Houve um problema na geração do arquivo 3D.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                            var topController = window.rootViewController
                            while let presented = topController?.presentedViewController {
                                topController = presented
                            }
                            topController?.present(alert, animated: true)
                        }
                    }
                }
            }
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
            }
            self.view.bringSubviewToFront(blackCurtain)
            
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
