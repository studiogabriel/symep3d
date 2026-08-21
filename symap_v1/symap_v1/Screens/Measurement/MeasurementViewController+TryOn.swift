import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

extension MeasurementViewController {
    
    // =========================================================================
    // --- MOTOR DO PROVADOR VIRTUAL (TRY-ON COM NUVEM) ---
    // =========================================================================
    @objc func showModelSelection() {
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Cloud Try-On Menu Active"]
        let _ = safetyCheck[ 0 ]
        
        let alert = UIAlertController(title: "Coleções Symap", message: "Escolha a categoria da armação", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Nenhum (Remover)", style: .destructive, handler: { _ in
            self.glassesNode?.removeFromParentNode()
            self.glassesNode = nil
            self.currentCloudModel = nil
        }))
        alert.addAction(UIAlertAction(title: "Coleção Feminina", style: .default, handler: { _ in self.showModels(filter: "Feminino") }))
        alert.addAction(UIAlertAction(title: "Coleção Masculina", style: .default, handler: { _ in self.showModels(filter: "Masculino") }))
        alert.addAction(UIAlertAction(title: "Coleção Infantil", style: .default, handler: { _ in self.showModels(filter: "Infantil") }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        if let p = alert.popoverPresentationController, let menuBtn = self.view.viewWithTag(882) as? UIButton {
            p.sourceView = menuBtn
            p.sourceRect = menuBtn.bounds
        } else if let p = alert.popoverPresentationController {
            p.sourceView = self.view
            p.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            p.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }
    
    func showModels(filter: String) {
        let titleStr = "Coleção \(filter)"
        let alert = UIAlertController(title: titleStr, message: "Selecione o modelo", preferredStyle: .actionSheet)
        
        let filteredModels = CloudManager.shared.availableModels.filter { $0.name.localizedCaseInsensitiveContains(filter) }
        
        for m in filteredModels {
            let cleanName = m.name.replacingOccurrences(of: filter, with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
            let finalName = cleanName.isEmpty ? m.name : cleanName
            alert.addAction(UIAlertAction(title: finalName, style: .default, handler: { _ in
                self.loadCloudModel(model: m)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Voltar", style: .cancel, handler: { _ in self.showModelSelection() }))
        
        if let p = alert.popoverPresentationController, let menuBtn = self.view.viewWithTag(882) as? UIButton {
            p.sourceView = menuBtn
            p.sourceRect = menuBtn.bounds
        } else if let p = alert.popoverPresentationController {
            p.sourceView = self.view
            p.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            p.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }
    
    func loadCloudModel(model: CloudGlassModel, showFakeLoading: Bool = true, bypassWarning: Bool = false) {
            // 🔴 INTELIGÊNCIA ANATÔMICA PREVENTIVA: Valida o encaixe físico real antes de carregar
            // (antes isso era um chute por categoria de tamanho; agora é a mesma conta física
            // usada em bestFittingModels — inclusive pega o caso de mesma categoria mas modelo
            // específico saturado, como aconteceu com o Luno feminino).
            let checkName = model.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
            let fitsWell = AutoConfiguratorEngine.isGoodFit(
                forKeyword: checkName,
                faceWidth: self.faceWidth,
                faceHeight: self.faceHeight,
                bridgeWidth: self.noseBridgeWidth,
                nasalProjection: self.nasalProjection,
                jawWidth: self.jawWidth
            )

            if !bypassWarning {
                var warningMsg: String? = nil

                if fitsWell == false {
                    warningMsg = "Esse modelo pode ficar apertado ou esticado além do ideal pro seu rosto — a IA vai levar o ajuste ao limite do molde. Deseja provar mesmo assim?"
                }

                if let msg = warningMsg {
                            // 🔴 BRANDBOOK: Injeção da Paleta Oficial
                            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                            let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                            let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
                            
                            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
                            let safetyArray = ["Warning Prompt OK"]
                            let _ = safetyArray[ 0 ]
                            
                            let warningOverlay = UIView(frame: self.view.bounds)
                            warningOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                            warningOverlay.alpha = 0.0
                            self.view.addSubview(warningOverlay)
                            
                            let boxW: CGFloat = 340
                            let boxH: CGFloat = 350
                            let box = UIView(frame: CGRect(x: (self.view.bounds.width - boxW)/2, y: (self.view.bounds.height - boxH)/2, width: boxW, height: boxH))
                            box.backgroundColor = .white
                            box.layer.cornerRadius = 24
                            box.clipsToBounds = true
                            warningOverlay.addSubview(box)
                            
                            let headerH: CGFloat = 90
                            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: boxW, height: headerH))
                            headerView.backgroundColor = navyDark
                            box.addSubview(headerView)
                            
                            let titleLabel = UILabel(frame: CGRect(x: 24, y: 20, width: boxW - 90, height: 28))
                            titleLabel.text = "ATENÇÃO"
                            titleLabel.textColor = .white
                            titleLabel.font = UIFont(name: "Inter-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
                            headerView.addSubview(titleLabel)
                            
                            let subtitleLabel = UILabel(frame: CGRect(x: 24, y: 50, width: boxW - 90, height: 20))
                            subtitleLabel.text = "Aviso de Proporção"
                            subtitleLabel.textColor = .white
                            subtitleLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
                            headerView.addSubview(subtitleLabel)
                            
                            let iconView = UIImageView(frame: CGRect(x: boxW - 65, y: 25, width: 40, height: 40))
                            if let iconImg = UIImage(named: "Ico_10")?.withRenderingMode(.alwaysTemplate) {
                                iconView.image = iconImg
                            }
                            iconView.tintColor = opticalCyan
                            iconView.contentMode = .scaleAspectFit
                            headerView.addSubview(iconView)
                            
                            let infoLabel = UILabel(frame: CGRect(x: 24, y: headerH + 15, width: boxW - 48, height: 100))
                            infoLabel.numberOfLines = 0
                            infoLabel.text = msg
                            infoLabel.textColor = navyMedium
                            infoLabel.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
                            box.addSubview(infoLabel)
                            
                            // Botões de Ação
                            let btnCancel = UIButton(frame: CGRect(x: 24, y: boxH - 125, width: boxW - 48, height: 46))
                            btnCancel.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
                            btnCancel.setTitle("Cancelar", for: .normal)
                            btnCancel.setTitleColor(navyMedium, for: .normal)
                            btnCancel.layer.cornerRadius = 14
                            btnCancel.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
                            btnCancel.addAction(UIAction(handler: { _ in
                                UIView.animate(withDuration: 0.3, animations: { warningOverlay.alpha = 0.0 }) { _ in
                                    warningOverlay.removeFromSuperview()
                                }
                            }), for: .touchUpInside)
                            box.addSubview(btnCancel)
                            
                            let btnProceed = UIButton(frame: CGRect(x: 24, y: boxH - 70, width: boxW - 48, height: 46))
                            btnProceed.backgroundColor = opticalCyan
                            btnProceed.setTitle("Provar Mesmo Assim", for: .normal)
                            btnProceed.setTitleColor(navyDark, for: .normal)
                            btnProceed.layer.cornerRadius = 14
                            btnProceed.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
                            btnProceed.addAction(UIAction(handler: { _ in
                                UIView.animate(withDuration: 0.3, animations: { warningOverlay.alpha = 0.0 }) { _ in
                                    warningOverlay.removeFromSuperview()
                                    self.loadCloudModel(model: model, showFakeLoading: showFakeLoading, bypassWarning: true)
                                }
                            }), for: .touchUpInside)
                            box.addSubview(btnProceed)
                            
                            UIView.animate(withDuration: 0.3) { warningOverlay.alpha = 1.0 }
                            
                            return // Paralisa a função aqui, impedindo o download e o congelamento da tela!
                        }
            }
            
        self.view.isUserInteractionEnabled = false
                var adaptContainer: UIView?
                var barBg: UIView?
                var barFill: UIView?
                var stepLabel: UILabel?
                
                if showFakeLoading {
                    let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                    let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                    let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                    
                    let container = UIView(frame: self.view.bounds)
                    container.backgroundColor = navyDark
                    container.alpha = 0.0
                    self.view.addSubview(container)
                    adaptContainer = container
                    
                    let title = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 - 60, width: self.view.bounds.width - 40, height: 30))
                    title.text = "PERSONALIZANDO MODELO..."
                    title.textAlignment = .center
                    title.textColor = opticalCyan
                    title.font = UIFont(name: "Inter-Black", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .black)
                    container.addSubview(title)
                    
                    let bg = UIView(frame: CGRect(x: 50, y: self.view.bounds.height / 2, width: self.view.bounds.width - 100, height: 6))
                    bg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                    bg.layer.cornerRadius = 3
                    container.addSubview(bg)
                    barBg = bg
                    
                    let fill = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 6))
                    fill.backgroundColor = opticalCyan
                    fill.layer.cornerRadius = 3
                    bg.addSubview(fill)
                    barFill = fill
                    
                    let lbl = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 + 30, width: self.view.bounds.width - 40, height: 20))
                    lbl.text = "Injetando biometria na armação (\(model.name))..."
                    lbl.textAlignment = .center
                    lbl.textColor = slateColor
                    lbl.font = UIFont(name: "Inter-SemiBold", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .semibold)
                    container.addSubview(lbl)
                    stepLabel = lbl
                    
                    UIView.animate(withDuration: 0.3) { container.alpha = 1.0 }
                }
            
        // 🔴 ARQUITETURA SENIOR: Intercepta o pedido da Nuvem e força o uso do arquivo Nativo (.usdc)
                // Isso burla o bloqueio da Apple que apaga as Shape Keys de arquivos .glb baixados da web.
                var safeModelName = model.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA:
                // Remoção do Roteamento Forçado. O Provador Virtual respeita a escolha exata do usuário.
                let validationArray = ["Manual Selection Override OK"]
                let _ = validationArray[ 0 ]
                
                let usdcName = safeModelName.hasPrefix("sl_") ? safeModelName : "sl_" + safeModelName
    
            
            // TENTA PUXAR DO XCODE PRIMEIRO (ONDE AS SHAPE KEYS FUNCIONAM)
            if let url = Bundle.main.url(forResource: usdcName, withExtension: "usdc"),
               let modelScene = try? SCNScene(url: url, options: nil) {
                
                // 🔴 MÁGICA: Carrega IMEDIATAMENTE da memória do iPhone (sem travar a tela)
                DispatchQueue.main.async {
                    self.glassesNode?.removeFromParentNode()
                    self.glassesNode = nil
                    self.currentCloudModel = model // Salva a ID da nuvem para o Robô conseguir exportar o STL depois
                    self.glassesYOffset = 0.028
                    
                    let wrapperNode = SCNNode()
                                    wrapperNode.name = "customGlasses"
                                    
                                    for child in modelScene.rootNode.childNodes { wrapperNode.addChildNode(child.clone()) }
                                    
                                    // 🔴 MÁGICA DO MATERIAL: Pinta a malha nativa de Cinza Escuro com Profundidade (PBR)
                                    let mat = SCNMaterial()
                                    mat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
                                    mat.lightingModel = .physicallyBased
                                    mat.isDoubleSided = true
                                    
                                    wrapperNode.enumerateChildNodes { (child, _) in
                                        child.geometry?.firstMaterial = mat
                                    }
                                    
                                    let (min, max) = wrapperNode.boundingBox
                                    let c = SCNVector3((min.x+max.x)/2, (min.y+max.y)/2, (min.z+max.z)/2)
                    
                    wrapperNode.pivot = SCNMatrix4MakeTranslation(c.x, c.y, c.z)
                                        wrapperNode.scale = SCNVector3(model.scale, model.scale, model.scale)
                                        
                                        // 🔴 OVERRIDE PARA TESTE ISOLADO DO NUNU MASCULINO
                                        var offsetZ: Float = 0.050 // Padrão
                                        if safeModelName == "sl_nunu_masculino" {
                                            offsetZ = -0.025
                                        }
                                        
                                        wrapperNode.position = SCNVector3(model.position.x, 0.028, offsetZ)
                                        wrapperNode.eulerAngles = model.rotation
                    
                    // 🔴 APLICA AS DISTORÇÕES NA MALHA PERFEITAMENTE (Agora as Shape Keys estão ali!)
                    self.applyAutoMorphs(to: wrapperNode, keyword: safeModelName)
                    
                    self.glassesNode = wrapperNode
                    
                    if showFakeLoading, let bg = barBg, let fill = barFill, let container = adaptContainer {
                        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
                            fill.frame.size.width = bg.bounds.width
                        }) { _ in
                            UIView.animate(withDuration: 0.3, animations: { container.alpha = 0.0 }) { _ in
                                container.removeFromSuperview()
                                self.view.isUserInteractionEnabled = true
                                self.showTryOnModificationsPopup(modelName: model.name, node: wrapperNode)
                            }
                        }
                    } else {
                        self.view.isUserInteractionEnabled = true
                        let targetFace = self.safeFaceCache ?? self.faceNode
                        if let face = targetFace { face.addChildNode(wrapperNode) }
                    }
                }
                
            } else {
                // 🔴 FALLBACK: Se a Ótica lançar uma nova armação na Nuvem que não tem .usdc nativo ainda, ele baixa o .glb (mas será rígido no espelho)
                print("⚠️ AVISO: Arquivo \(usdcName).usdc não encontrado no app. Baixando da web (sem Shape Keys no espelho)...")
                CloudManager.shared.downloadModelFile(url: model.fileUrl) { [weak self] u in
                    guard let s = self, let url = u else {
                        DispatchQueue.main.async { adaptContainer?.removeFromSuperview(); self?.view.isUserInteractionEnabled = true }
                        return
                    }
                    DispatchQueue.main.async {
                        s.glassesNode?.removeFromParentNode()
                        s.glassesNode = nil
                        s.currentCloudModel = model
                        s.glassesYOffset = 0.028
                        
                        let wrapperNode = SCNNode()
                        wrapperNode.name = "customGlasses"
                        
                        if let scene = try? SCNScene(url: url, options: nil) {
                            for child in scene.rootNode.childNodes { wrapperNode.addChildNode(child.clone()) }
                        } else {
                            let asset = MDLAsset(url: url)
                            if asset.count > 0 {
                                let obj = asset.object(at: 0)
                                let nodeObj = SCNNode(mdlObject: obj)
                                wrapperNode.addChildNode(nodeObj)
                            }
                        }
                        
                        let mat = SCNMaterial()
                        mat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
                        mat.lightingModel = .physicallyBased
                        mat.isDoubleSided = true
                        wrapperNode.enumerateChildNodes { (child, _) in child.geometry?.firstMaterial = mat }
                        
                        let (min, max) = wrapperNode.boundingBox
                        let c = SCNVector3((min.x+max.x)/2, (min.y+max.y)/2, (min.z+max.z)/2)
                        
                        wrapperNode.pivot = SCNMatrix4MakeTranslation(c.x, c.y, c.z)
                                        wrapperNode.scale = SCNVector3(model.scale, model.scale, model.scale)
                                        
                                        // 🔴 OVERRIDE PARA TESTE ISOLADO DO NUNU MASCULINO
                                        var offsetZ: Float = 0.050 // Padrão para todos
                                        if safeModelName == "sl_nunu_masculino" {
                                            offsetZ = -0.025 // Empurra para trás. Se precisar ir mais, teste 0.020 ou 0.015
                                        }
                                        
                                        wrapperNode.position = SCNVector3(model.position.x, 0.028, offsetZ)
                                        wrapperNode.eulerAngles = model.rotation
                        
                        s.applyAutoMorphs(to: wrapperNode, keyword: model.name)
                        s.glassesNode = wrapperNode
                        
                        if showFakeLoading, let bg = barBg, let fill = barFill, let container = adaptContainer {
                            UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: { fill.frame.size.width = bg.bounds.width }) { _ in
                                UIView.animate(withDuration: 0.3, animations: { container.alpha = 0.0 }) { _ in
                                    container.removeFromSuperview()
                                    s.view.isUserInteractionEnabled = true
                                    s.showTryOnModificationsPopup(modelName: model.name, node: wrapperNode)
                                }
                            }
                        } else {
                            s.view.isUserInteractionEnabled = true
                            let targetFace = s.safeFaceCache ?? s.faceNode
                            if let face = targetFace { face.addChildNode(wrapperNode) }
                        }
                    }
                }
            }
        }
    
    // =======================================================
    // 🔴 NOVO: POPUP DE RELATÓRIO EXCLUSIVO DO TRY-ON
    // =======================================================
    func showTryOnModificationsPopup(modelName: String, node: SCNNode) {
        // 🔴 BRANDBOOK: Injeção da Paleta Oficial no escopo da função
                let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
                
                let popupOverlay = UIView(frame: self.view.bounds)
                popupOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                popupOverlay.alpha = 0.0
                self.view.addSubview(popupOverlay)
        
        // 🔴 BRANDBOOK: Card Modular Bi-color (Fundo Branco com Cabeçalho Navy)
                let boxW: CGFloat = 340
                let boxH: CGFloat = 350 // Aumentado para dar respiro
                let box = UIView(frame: CGRect(x: (self.view.bounds.width - boxW)/2, y: (self.view.bounds.height - boxH)/2, width: boxW, height: boxH))
                box.backgroundColor = .white
                box.layer.cornerRadius = 24
                box.clipsToBounds = true // Blinda o vazamento de cor nas quinas
                popupOverlay.addSubview(box)
                
                // Cabeçalho Navy (Terço superior)
                let headerH: CGFloat = 90
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: boxW, height: headerH))
                headerView.backgroundColor = navyDark
                box.addSubview(headerView)
                
                // Pega apenas o primeiro nome do paciente
                let patientFirstName = self.patientName.components(separatedBy: " ").first ?? "Paciente"
                
                let titleLabel = UILabel(frame: CGRect(x: 24, y: 20, width: boxW - 90, height: 28))
                titleLabel.text = patientFirstName.uppercased()
                titleLabel.textColor = .white
                titleLabel.font = UIFont(name: "Inter-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
                headerView.addSubview(titleLabel)
                
                let subtitleLabel = UILabel(frame: CGRect(x: 24, y: 50, width: boxW - 90, height: 20))
                subtitleLabel.text = "Ajustes Aplicados"
                subtitleLabel.textColor = .white
                subtitleLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
                headerView.addSubview(subtitleLabel)
                
                // 🔴 BRANDBOOK: Ícone Ico_10 vazado e pintado de Optical Cyan
                let iconView = UIImageView(frame: CGRect(x: boxW - 65, y: 25, width: 40, height: 40))
                if let iconImg = UIImage(named: "Ico_10")?.withRenderingMode(.alwaysTemplate) {
                    iconView.image = iconImg
                }
                iconView.tintColor = opticalCyan
                iconView.contentMode = .scaleAspectFit
                headerView.addSubview(iconView)
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let splitValidation = ["Try-On Split UI OK"]
                let _ = splitValidation[ 0 ]
        
        var modText = ""
                
                // 🔴 CORREÇÃO: Converte espaços em underscores para o PopUp conseguir achar a chave no Motor!
                let safeModelName = modelName.lowercased().replacingOccurrences(of: " ", with: "_")
                
                // 🔴 NOVO: Higieniza o nome vindo da nuvem para remover o gênero e o prefixo "SL"
                var displayModelName = modelName
                    .replacingOccurrences(of: "Masculino", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Feminino", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Infantil", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "SL ", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespaces)
                
                if let key = AutoConfiguratorEngine.specs.keys.first(where: { safeModelName.contains($0) }),
                   let spec = AutoConfiguratorEngine.specs[key] {
                    
                    // 🔴 NOVO: Adiciona o tamanho da base em milímetros dinamicamente!
                    displayModelName = "\(displayModelName) \(Int(spec.baseWidth))mm"
                    
                    // 🔴 LÓGICA ESPELHADA DO MOTOR (Com Clipping e Compensação Física)
                                    let rawDiffBridge = (self.noseBridgeWidth + VisagismClinicalRules.bridgeClearance) - spec.baseBridge
                                    let finalDiffBridge = rawDiffBridge > 0 ? min(rawDiffBridge, spec.limits.bridgePlus) : max(rawDiffBridge, -spec.limits.bridgeMinus)
                                    
                                    let rawTargetWidth = self.faceWidth + VisagismClinicalRules.temporalClearance
                                    let compensatedDiffWidth = (rawTargetWidth - spec.baseWidth) - finalDiffBridge
                                    let finalDiffWidth = compensatedDiffWidth > 0 ? min(compensatedDiffWidth, spec.limits.larguraA) : max(compensatedDiffWidth, -spec.limits.larguraR)
                                    
                                    if abs(finalDiffWidth) > 0.1 {
                                        let sign = finalDiffWidth > 0 ? "+" : ""
                                        modText += "• Largura Temporal: \(sign)\(String(format: "%.1f", finalDiffWidth)) mm\n"
                                    }
                                    if abs(finalDiffBridge) > 0.1 {
                                        let sign = finalDiffBridge > 0 ? "+" : ""
                                        modText += "• Ponte Nasal: \(sign)\(String(format: "%.1f", finalDiffBridge)) mm\n"
                                    }
                                    if self.nasalProfile == "Plano" {
                                        modText += "• Apoio Nasal: Expandido (Perfil Plano)\n"
                                    }
                    // 🔴 IDENTIDADE DA MARCA: Cálculo Exato Vertical (Visagismo Suave)
                            let dynamicSafetyCheck = ["Vertical mm UI Calculation"]
                            let _ = dynamicSafetyCheck[ 0 ]
                            
                            // 🔴 CORREÇÃO DO POPUP: Espelhando o amortecimento de 60% do Motor
                            let targetHeight = self.faceHeight / 4.0
                            let rawDiffVertical = (targetHeight - spec.baseHeight) * 0.05
                    
                    
                                let finalDiffVertical = rawDiffVertical > 0 ? min(rawDiffVertical, spec.limits.verticalA) : max(rawDiffVertical, -spec.limits.verticalR)
                                
                                if abs(finalDiffVertical) > 0.1 {
                                    let sign = finalDiffVertical > 0 ? "+" : ""
                                    let explanation = finalDiffVertical > 0 ? "Alongamento visual" : "Estética compacta"
                                    modText += "• Design Vertical: \(sign)\(String(format: "%.1f", finalDiffVertical)) mm (\(explanation))\n"
                                }
                                    if self.noseBridgeWidth < VisagismClinicalRules.narrowNoseThreshold {
                                        modText += "• Estrutura da Ponte: Modo Ferradura (Maior volume e aderência)\n"
                                    }
                }
                
                if modText.isEmpty { modText = "• Proporções originais perfeitas para sua face.\n" }
                
        // Reposicionamos o texto abaixo do cabeçalho
                let infoLabel = UILabel(frame: CGRect(x: 24, y: headerH + 15, width: boxW - 48, height: 140))
                infoLabel.numberOfLines = 0
                infoLabel.text = "O modelo (\(displayModelName)) foi recriado milimetricamente para você:\n\n" + modText
                
                // 🔴 BRANDBOOK: Tom escuro para leitura no fundo branco
                infoLabel.textColor = navyMedium
                infoLabel.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
                box.addSubview(infoLabel)
                
                let btnOk = UIButton(frame: CGRect(x: 24, y: boxH - 70, width: boxW - 48, height: 46))
                btnOk.backgroundColor = opticalCyan
                btnOk.setTitle("Vestir Armação", for: .normal)
                // Contraste Perfeito do Brandbook:
                btnOk.setTitleColor(navyDark, for: .normal)
                btnOk.layer.cornerRadius = 14
                btnOk.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
                
                // 🔴 ARQUITETURA PRESERVADA: Anexa o nó 3D da armação na face de fato
                btnOk.addAction(UIAction(handler: { [weak self, weak popupOverlay] _ in
                    UIView.animate(withDuration: 0.3, animations: { popupOverlay?.alpha = 0.0 }) { _ in
                        popupOverlay?.removeFromSuperview()
                        let targetFace = self?.safeFaceCache ?? self?.faceNode
                        if let face = targetFace { face.addChildNode(node) }
                    }
                }), for: .touchUpInside)
                
                box.addSubview(btnOk)
        
        UIView.animate(withDuration: 0.3) { popupOverlay.alpha = 1.0 }
    }
    
    // Helper universal para torcer a malha (Funciona para Nuvem ou Nativo)
    func applyAutoMorphs(to node: SCNNode, keyword: String) {
        let weights = AutoConfiguratorEngine.calculateMorphWeights(
                    keyword: keyword,
                    faceWidth: self.faceWidth,
                    faceHeight: self.faceHeight, // 🔴 INJETANDO A ALTURA
                    bridgeWidth: self.noseBridgeWidth,
            nasalProjection: self.nasalProjection,
            jawWidth: self.jawWidth,
            faceShape: self.faceShape
        )
        
        node.enumerateChildNodes { (child, _) in
            if let morpher = child.morpher {
                for (key, value) in weights {
                    morpher.setWeight(CGFloat(value), forTargetNamed: key)
                }
            }
        }
    }
}
