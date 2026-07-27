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
        // 1. EXPERIÊNCIA UX: TELA FAKE DE "ANALISANDO BIOMETRIA"
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
        
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
            progressBarFill.frame.size.width = progressBarBg.bounds.width * 0.4
        }) { _ in
            scanSteps.text = "Calculando proporções de visagismo..."
            UIView.animate(withDuration: 1.5, delay: 0.2, options: .curveEaseInOut, animations: {
                progressBarFill.frame.size.width = progressBarBg.bounds.width
            }) { _ in
                UIView.animate(withDuration: 0.3, animations: { loadingContainer.alpha = 0.0 }) { _ in
                    loadingContainer.removeFromSuperview()
                    self.showVisagismResults()
                }
            }
        }
    }
    
    // =======================================================
    // 2. A TELA DE VISAGISMO OFICIAL E PERSONALIZADA
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
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Seguro)
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
        
        // RESTAURADO: Câmera original perfeita para o Rosto Holográfico
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.01
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.20)
        holoScene.rootNode.addChildNode(cameraNode)
        visagismContainer.addSubview(holoView)
        
        let info = UITextView(frame: CGRect(x: 30, y: 350, width: view.bounds.width - 60, height: view.bounds.height - 480))
        info.backgroundColor = .clear
        info.textColor = .lightGray
        info.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        info.isEditable = false
        
        let patientFirstName = self.patientName.components(separatedBy: " ").first ?? "Paciente"
        let patientStats = """
        IDENTIFICAÇÃO BIOMÉTRICA DE \(patientFirstName.uppercased()):
        • Largura do Rosto: \(String(format: "%.1f", self.faceWidth)) mm
        • Base Nasal: \(String(format: "%.1f", self.noseBridgeWidth)) mm
        • Distância Pupilar: \(String(format: "%.1f", self.dnpTotal)) mm
        • Formato Mapeado: \(self.faceShape.uppercased())
        
        """
        
        let nomeDoModelo = self.recommendedAutoModel.capitalized
        let recommendationText = "\n\nBaseado na linha Studio Lebô indicamos o modelo \(nomeDoModelo)."
        
        let fullText = patientStats + self.frameSuggestion + recommendationText
        
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 10
        style.alignment = .justified
        
        let attrText = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: style
        ])
        
        let statRange = (fullText as NSString).range(of: patientStats)
        attrText.addAttribute(.foregroundColor, value: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), range: statRange)
        attrText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 13), range: statRange)
        
        let modelRange = (fullText as NSString).range(of: nomeDoModelo, options: .backwards)
        if modelRange.location != NSNotFound {
            attrText.addAttribute(.foregroundColor, value: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), range: modelRange)
            attrText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: modelRange)
        }
        
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
            self.safeFaceCache?.removeFromParentNode()
            self.safeFaceCache = nil
            
            // =======================================================
            // 3. EXPERIÊNCIA UX: FAKE LOADING DA MODELAGEM 3D
            // =======================================================
            let adaptContainer = UIView(frame: self.view.bounds)
            adaptContainer.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
            adaptContainer.alpha = 0.0
            self.view.addSubview(adaptContainer)
            
            let title = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 - 60, width: self.view.bounds.width - 40, height: 30))
            title.text = "PARAMETRIZANDO ARMAÇÃO 3D..."
            title.textAlignment = .center
            title.textColor = UIColor.systemPurple
            title.font = UIFont.systemFont(ofSize: 18, weight: .black)
            adaptContainer.addSubview(title)
            
            let barBg = UIView(frame: CGRect(x: 50, y: self.view.bounds.height / 2, width: self.view.bounds.width - 100, height: 6))
            barBg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            barBg.layer.cornerRadius = 3
            adaptContainer.addSubview(barBg)
            
            let barFill = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 6))
            barFill.backgroundColor = UIColor.systemPurple
            barFill.layer.cornerRadius = 3
            barBg.addSubview(barFill)
            
            let stepLabel = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 + 30, width: self.view.bounds.width - 40, height: 20))
            stepLabel.text = "Ajustando largura temporal com +2.0mm de folga..."
            stepLabel.textAlignment = .center
            stepLabel.textColor = .lightGray
            stepLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            adaptContainer.addSubview(stepLabel)
            
            UIView.animate(withDuration: 0.3) { adaptContainer.alpha = 1.0 }
            
            UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
                barFill.frame.size.width = barBg.bounds.width * 0.5
            }) { _ in
                stepLabel.text = "Ajustando ergonomia da ponte nasal..."
                UIView.animate(withDuration: 1.0, delay: 0.2, options: .curveEaseInOut, animations: {
                    barFill.frame.size.width = barBg.bounds.width
                }) { _ in
                    
                    UIView.animate(withDuration: 0.3, animations: { adaptContainer.alpha = 0.0 }) { _ in
                        adaptContainer.removeFromSuperview()
                        
                        // 🔴 CHAMA O NOVO POPUP DE RESULTADOS DEPOIS DO LOADING
                        self.showModificationsPopup()
                    }
                }
            }
        }
    }
    
    // =======================================================
    // 🔴 4. O NOVO POPUP MINIMALISTA (APENAS RELATÓRIO TÉCNICO)
    // =======================================================
    func showModificationsPopup() {
        let popupOverlay = UIView(frame: self.view.bounds)
        popupOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popupOverlay.alpha = 0.0
        self.view.addSubview(popupOverlay)
        
        // Diminuímos drasticamente a altura da caixa, pois o 3D foi removido
        let boxW: CGFloat = 340
        let boxH: CGFloat = 280
        let box = UIView(frame: CGRect(x: (self.view.bounds.width - boxW)/2, y: (self.view.bounds.height - boxH)/2, width: boxW, height: boxH))
        box.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        box.layer.cornerRadius = 24
        box.layer.borderWidth = 2
        box.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.6).cgColor
        popupOverlay.addSubview(box)
        
        let title = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 25))
        title.text = "AJUSTES DA ARMAÇÃO"
        title.textColor = .systemPurple
        title.font = UIFont.systemFont(ofSize: 18, weight: .black)
        title.textAlignment = .center
        box.addSubview(title)
        
        // 🔴 MÁGICA DOS DADOS: Calcula as proporções para exibir no relatório
                let keyword = self.recommendedAutoModel
                var modText = ""
                
                // 🔴 INTELIGÊNCIA ANATÔMICA: O PopUp avalia a largura do rosto para achar a matemática exata
                var safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
                let isLargeFace = self.faceWidth >= 135.0
                
                if safeKeyword == "luno" { safeKeyword = isLargeFace ? "luno_masculino" : "luno_feminino" }
                if safeKeyword == "nunu" { safeKeyword = isLargeFace ? "nunu_masculino" : "nunu_feminino" }
                if safeKeyword == "suki" { safeKeyword = isLargeFace ? "suki_masculino" : "suki_feminino" }
                if safeKeyword == "timbau" { safeKeyword = isLargeFace ? "timbau_masculino" : "timbau_feminino" }
                
                // 🔴 NOVO: Prepara o nome de exibição neutro
                var displayModelName = keyword.capitalized
                
                if let key = AutoConfiguratorEngine.specs.keys.first(where: { safeKeyword.contains($0) }),
                   let spec = AutoConfiguratorEngine.specs[key] {
                    
                    // 🔴 NOVO: Adiciona o tamanho da base em milímetros (ex: "Luno 140mm")
                    displayModelName = "\(keyword.capitalized) \(Int(spec.baseWidth))mm"
                    
                    // 🔴 Lendo os espaçamentos dinamicamente
                    let diffWidth = (self.faceWidth + VisagismClinicalRules.temporalClearance) - spec.baseWidth
                    let diffBridge = (self.noseBridgeWidth + VisagismClinicalRules.bridgeClearance) - spec.baseBridge
                    
                    if abs(diffWidth) > 0.1 {
                        let sign = diffWidth > 0 ? "+" : ""
                        modText += "• Largura Temporal: \(sign)\(String(format: "%.1f", diffWidth)) mm\n"
                    }
                    if abs(diffBridge) > 0.1 {
                        let sign = diffBridge > 0 ? "+" : ""
                        modText += "• Ponte Nasal: \(sign)\(String(format: "%.1f", diffBridge)) mm\n"
                    }
                    if self.nasalProfile == "Plano" {
                        modText += "• Apoio Nasal: Expandido (Perfil Plano)\n"
                    }
                    
                    if self.faceShape.contains("Longo") {
                        modText += "• Design Vertical: Aumentado (Equilibra a altura do rosto)\n"
                    } else if self.faceShape.contains("Redondo") {
                        modText += "• Design Vertical: Reduzido (Afina as proporções faciais)\n"
                    }
                    
                    if self.noseBridgeWidth < VisagismClinicalRules.narrowNoseThreshold {
                        modText += "• Estrutura da Ponte: Modo Ferradura (Maior volume e aderência)\n"
                    }
                }
                
                if modText.isEmpty { modText = "• Proporções originais perfeitas para sua face.\n" }
                
                // Texto descritivo exato das modificações reposicionado
                let infoLabel = UILabel(frame: CGRect(x: 20, y: 75, width: boxW - 40, height: 100))
                infoLabel.numberOfLines = 0
                infoLabel.text = "Modificações Anatômicas Aplicadas no Modelo (\(displayModelName)):\n\n" + modText
                infoLabel.textColor = .lightGray
                infoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                box.addSubview(infoLabel)
        
        let btnOk = UIButton(frame: CGRect(x: 30, y: boxH - 75, width: boxW - 60, height: 50))
        btnOk.backgroundColor = .systemPurple
        btnOk.setTitle("OK, Iniciar Medições", for: .normal)
        btnOk.setTitleColor(.white, for: .normal)
        btnOk.layer.cornerRadius = 14
        btnOk.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnOk.addTarget(self, action: #selector(dismissModificationsPopup(_:)), for: .touchUpInside)
        box.addSubview(btnOk)
        
        UIView.animate(withDuration: 0.3) { popupOverlay.alpha = 1.0 }
    }
    
    @objc func dismissModificationsPopup(_ sender: UIButton) {
        guard let popup = sender.superview?.superview else { return }
        
        UIView.animate(withDuration: 0.3, animations: { popup.alpha = 0.0 }) { _ in
            popup.removeFromSuperview()
            
            // Fim de Toda a Jornada Inicial: Acende a Câmera Viva
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            self.sceneView.session.run(config)
            
            self.startLevelMonitoring()
            self.topFeedbackLabel?.isHidden = false
            self.faceGuideLayer?.isHidden = false
            self.levelContainerView.isHidden = false
            self.phonePitchContainerView.isHidden = false
            self.startCaptureButton.isHidden = false
            self.startCaptureButton.setTitle("Iniciar Captura (Medição)", for: .normal)
            
            self.view.viewWithTag(882)?.isHidden = false
            self.view.viewWithTag(880)?.isHidden = false
            
            // Aplica o modelo com os parâmetros finais na face em tempo real
            self.applyRecommendedModel(modelIdOrName: self.recommendedAutoModel)
        }
    }
    
    func applyRecommendedModel(modelIdOrName: String) {
        // 🔴 1. INTELIGÊNCIA ANATÔMICA GLOBAL: Traduz o modelo pela proporção métrica antes de buscar!
                var safeModelName = modelIdOrName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
                let isLargeFace = self.faceWidth >= 135.0
                
                if safeModelName == "luno" { safeModelName = isLargeFace ? "luno_masculino" : "luno_feminino" }
                if safeModelName == "nunu" { safeModelName = isLargeFace ? "nunu_masculino" : "nunu_feminino" }
                if safeModelName == "suki" { safeModelName = isLargeFace ? "suki_masculino" : "suki_feminino" }
                if safeModelName == "timbau" { safeModelName = isLargeFace ? "timbau_masculino" : "timbau_feminino" }
            
            // 🔴 2. BUSCA NA NUVEM (Usando o nome já traduzido com gênero)
            if let cloudModel = CloudManager.shared.availableModels.first(where: {
                let cloudNameClean = $0.name.lowercased().replacingOccurrences(of: " ", with: "_")
                return cloudNameClean.contains(safeModelName)
            }) {
                // Se achou o óculos correto na nuvem, veste ele (sem tela de carregamento duplicada)
                self.loadCloudModel(model: cloudModel, showFakeLoading: false)
                
            } else {
                // 🔴 3. FALLBACK NATIVO (Se estiver offline, busca no Xcode)
                print("⚠️ AVISO: A IA recomendou a linha '\(safeModelName)', mas não achou na nuvem. Usando nativo.")
                
                let usdcName = "sl_" + safeModelName
                
                guard let url = Bundle.main.url(forResource: usdcName, withExtension: "usdc"),
                      let modelScene = try? SCNScene(url: url, options: nil) else { return }
                
                self.glassesNode?.removeFromParentNode()
                let wrapperNode = SCNNode()
                wrapperNode.name = "customGlasses"
                
                for child in modelScene.rootNode.childNodes { wrapperNode.addChildNode(child.clone()) }
                
                let (min, max) = wrapperNode.boundingBox
                wrapperNode.pivot = SCNMatrix4MakeTranslation((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
                wrapperNode.position = SCNVector3(0, 0.028, 0.050)
                
                // 🔴 CORREÇÃO VITAL: Agora enviamos o nome com o Gênero exato para o motor torcer a malha!
                self.applyAutoMorphs(to: wrapperNode, keyword: safeModelName)
                
                let targetFace = self.safeFaceCache ?? self.faceNode
                targetFace?.addChildNode(wrapperNode)
                self.glassesNode = wrapperNode
            }
        }
}
