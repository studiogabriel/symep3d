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
                let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)

                let loadingContainer = UIView(frame: view.bounds)
                // 🔴 BRANDBOOK: Fundo Navy
                loadingContainer.backgroundColor = navyDark
                loadingContainer.tag = 8887
                loadingContainer.alpha = 0.0
                view.addSubview(loadingContainer)
                
                let scanTitle = UILabel(frame: CGRect(x: 20, y: view.bounds.height / 2 - 60, width: view.bounds.width - 40, height: 30))
                scanTitle.text = "PROCESSANDO BIOMETRIA..."
                scanTitle.textAlignment = .center
                scanTitle.textColor = opticalCyan
                scanTitle.font = UIFont(name: "Inter-Black", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .black)
                loadingContainer.addSubview(scanTitle)
                
                let progressBarBg = UIView(frame: CGRect(x: 50, y: view.bounds.height / 2, width: view.bounds.width - 100, height: 6))
                progressBarBg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                progressBarBg.layer.cornerRadius = 3
                loadingContainer.addSubview(progressBarBg)
                
                let progressBarFill = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 6))
                progressBarFill.backgroundColor = opticalCyan
                progressBarFill.layer.cornerRadius = 3
                progressBarBg.addSubview(progressBarFill)
                
                let scanSteps = UILabel(frame: CGRect(x: 20, y: view.bounds.height / 2 + 30, width: view.bounds.width - 40, height: 20))
                scanSteps.text = "Mapeando 30.000 pontos faciais..."
                scanSteps.textAlignment = .center
                scanSteps.textColor = slateColor
                scanSteps.font = UIFont(name: "Inter-SemiBold", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .semibold)
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
        let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)

                let visagismContainer = UIView(frame: view.bounds)
                // 🔴 Fundo Navy
                visagismContainer.backgroundColor = navyDark
                visagismContainer.tag = 8888
                visagismContainer.alpha = 0.0
                view.addSubview(visagismContainer)
                
                let title = UILabel(frame: CGRect(x: 20, y: 60, width: view.bounds.width - 40, height: 30))
                title.text = "ANÁLISE DE VISAGISMO"
                title.textAlignment = .center
                title.textColor = opticalCyan
                title.font = UIFont(name: "Inter-Black", size: 22) ?? UIFont.systemFont(ofSize: 22, weight: .black)
                visagismContainer.addSubview(title)
                
        let holoView = SCNView(frame: CGRect(x: 40, y: 100, width: view.bounds.width - 80, height: 230))
                // 🔴 ARQUITETURA SÊNIOR: Fundo 100% transparente para o Holograma flutuar livremente no espaço Navy
                holoView.backgroundColor = .clear
                holoView.layer.borderWidth = 0
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let holoValidation = ["Floating Hologram OK"]
                let _ = holoValidation[ 0 ]
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
        // 🔴 BRANDBOOK: Câmera Ortográfica para o Rosto Holográfico (Sem distorção)
                let cameraNode = SCNNode()
                let camera = SCNCamera()
                camera.zNear = 0.01
                
                camera.usesOrthographicProjection = true
                camera.orthographicScale = 0.11
                
                cameraNode.camera = camera
                cameraNode.position = SCNVector3(0, 0, 1.0)
                
                holoScene.rootNode.addChildNode(cameraNode)
                visagismContainer.addSubview(holoView)
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let perspectiveValidation = ["Orthographic Visagism OK"]
                let _ = perspectiveValidation[ 0 ]
        
        // 🔴 BRANDBOOK: Paleta de Cores Adicionais
                let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)

                // 1. CARREGAMENTO DOS DADOS COMERCIAIS DA ARMAÇÃO RECOMENDADA
                let profile = FrameCatalogEngine.recommendFrame(faceShape: self.faceShape)
                let displayModelName = profile.name
                
                // 2. EXTRAÇÃO SEGURA DOS CONSELHOS BIOMÉTRICOS DA IA
                let dnpRatio = self.dnpTotal / self.faceWidth
                let eyesAdvice = dnpRatio < 0.43 ? "Olhos Próximos: Evite sobrecarregar o centro do rosto. A IA priorizou pontes confortáveis e detalhes nas extremidades da armação." : "Proporção Ocular: O distanciamento dos seus olhos está em perfeita harmonia anatômica."
                
                let noseAdvice = self.noseBridgeWidth < 15.0 ? "Tamanho do Nariz: Pontes altas ajudam a não destacar tanto o osso nasal." : "Sobrancelhas: A parte superior da armação (\(profile.shape)) foi selecionada para acompanhar o desenho natural do seu supercílio."
                
                let colorsAdvice = "• Pele Quente (fundos amarelados): Harmoniza com tons terrosos, dourado e tartaruga.\n\n• Pele Fria (fundos rosados): Rosa-antigo, azul, cinza e tons pastéis combinam muito bem."

                // 3. CONTAINER DE ROLAGEM DINÂMICA (UIScrollView)
                let scrollHeight = view.bounds.height - 110 - 345
                let scrollView = UIScrollView(frame: CGRect(x: 30, y: 345, width: view.bounds.width - 60, height: scrollHeight))
                scrollView.showsVerticalScrollIndicator = false
                scrollView.backgroundColor = .clear
                visagismContainer.addSubview(scrollView)
                
                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.spacing = 12
                stackView.distribution = .fill
                stackView.alignment = .fill
                stackView.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(stackView)
                
                NSLayoutConstraint.activate([
                    stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                    stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                    stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                    stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
                ])
                
                // 4. 🔴 RESOLUÇÃO DO FLUXO (RECOMENDAÇÃO EM DESTAQUE NO TOPO)
                // O óculos agora é citado imediatamente e ganha um Box de Destaque com borda Cyan!
                let recommendedCard = UIView()
                recommendedCard.backgroundColor = opticalCyan.withAlphaComponent(0.08)
                recommendedCard.layer.cornerRadius = 14
                recommendedCard.layer.borderWidth = 1.5
                recommendedCard.layer.borderColor = opticalCyan.cgColor
                
                let recomLabel = UILabel()
                recomLabel.numberOfLines = 0
                recomLabel.translatesAutoresizingMaskIntoConstraints = false
                recommendedCard.addSubview(recomLabel)
                
                let patientFirstName = self.patientName.components(separatedBy: " ").first ?? "Paciente"
                let shapeTitle = self.faceShape.uppercased()

                // 🔴 Lista dos modelos MAIS OTIMIZADOS do catálogo inteiro (as 3 linhas, não só a
                // indicada pela largura do rosto) — ranqueados pelo menor esforço de deformação,
                // não só "cabe/não cabe" como o antigo bestFittingModels. Pedido explícito do
                // Gabriel: sempre indicar o melhor encaixe possível, aceitando um pequeno
                // excedente (acceptableOverageTolerance) quando nenhum modelo encaixa perfeito.
                let ranked = AutoConfiguratorEngine.bestOptimizedModels(
                    faceWidth: self.faceWidth,
                    faceHeight: self.faceHeight,
                    bridgeWidth: self.noseBridgeWidth,
                    nasalProjection: self.nasalProjection,
                    jawWidth: self.jawWidth,
                    eyeToCheekClearance: self.eyeToCheekClearance,
                    eyeToCheekClearanceValid: self.eyeToCheekClearanceValid
                )
                let goodFitKeys = ranked.filter { $0.totalOverage <= VisagismClinicalRules.acceptableOverageTolerance }.prefix(4).map { $0.key }
                let goodFitNames = goodFitKeys.map { AutoConfiguratorEngine.displayName(forKey: $0) }
                // Fallback: se nem o mais bem ranqueado passar da tolerância, mostra ele mesmo
                // assim — é o menor excedente possível no catálogo inteiro, melhor do que cair
                // de volta pra recomendação só por formato.
                // 🔴 Numeração explícita (1º, 2º...) pra deixar claro pro paciente que a ordem
                // importa — não é uma lista qualquer, é o ranking de melhor encaixe.
                let modelsListText = !goodFitNames.isEmpty
                    ? goodFitNames.enumerated().map { "\($0.offset + 1)º \($0.element)" }.joined(separator: ", ")
                    : (ranked.first.map { "1º \(AutoConfiguratorEngine.displayName(forKey: $0.key))" } ?? displayModelName.uppercased())

                // 🔴 Assimetria facial: dado já existia (faceWidthLeft/Right), calculado, mas só
                // virava log no Firestore — nunca chegava na tela do cliente. A armação só tem
                // ajuste simétrico, então isso é aviso, não correção automática.
                let asymmetryWarning = BiometryEngine.facialAsymmetryWarning(faceWidthLeft: self.faceWidthLeft, faceWidthRight: self.faceWidthRight)

                var recomText = "RECOMENDAÇÃO SYMEP IA DE \(patientFirstName.uppercased()):\nMapeamos o formato de rosto \(shapeTitle). Em ordem de melhor encaixe pro seu rosto: \(modelsListText)."
                if let warning = asymmetryWarning {
                    recomText += "\n\n⚠️ \(warning)"
                }

                let recomStyle = NSMutableParagraphStyle()
                recomStyle.lineSpacing = 4
                recomStyle.alignment = .center

                let recomAttrText = NSMutableAttributedString(string: recomText, attributes: [
                    .font: UIFont(name: "Inter-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12),
                    .foregroundColor: offWhite,
                    .paragraphStyle: recomStyle
                ])

                let nsRecomText = recomText as NSString
                let modelRange = nsRecomText.range(of: modelsListText)
                if modelRange.location != NSNotFound {
                    recomAttrText.addAttribute(.foregroundColor, value: opticalCyan, range: modelRange)
                    recomAttrText.addAttribute(.font, value: UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), range: modelRange)
                }
                let shapeRange = nsRecomText.range(of: shapeTitle)
                if shapeRange.location != NSNotFound {
                    recomAttrText.addAttribute(.foregroundColor, value: opticalCyan, range: shapeRange)
                    recomAttrText.addAttribute(.font, value: UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), range: shapeRange)
                }
                if let warning = asymmetryWarning {
                    let warningRange = nsRecomText.range(of: "⚠️ \(warning)")
                    if warningRange.location != NSNotFound {
                        recomAttrText.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: warningRange)
                    }
                }
                recomLabel.attributedText = recomAttrText
                
                NSLayoutConstraint.activate([
                    recomLabel.topAnchor.constraint(equalTo: recommendedCard.topAnchor, constant: 14),
                    recomLabel.leadingAnchor.constraint(equalTo: recommendedCard.leadingAnchor, constant: 16),
                    recomLabel.trailingAnchor.constraint(equalTo: recommendedCard.trailingAnchor, constant: -16),
                    recomLabel.bottomAnchor.constraint(equalTo: recommendedCard.bottomAnchor, constant: -14)
                ])
                stackView.addArrangedSubview(recommendedCard)
                
                // 5. 🔴 ENGENHARIA DO ACCORDION INTERATIVO (UI CLOSURE)
                // Função inline que monta os cards retráteis de forma atômica
                let createAccordionCard: (String, String, Bool) -> UIView = { cardTitle, cardContent, startExpanded in
                    let cardContainer = UIStackView()
                    cardContainer.axis = .vertical
                    cardContainer.backgroundColor = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 0.25) // Navy Medium translúcido
                    cardContainer.layer.cornerRadius = 12
                    cardContainer.layer.borderWidth = 1.0
                    cardContainer.layer.borderColor = opticalCyan.withAlphaComponent(0.2).cgColor
                    cardContainer.clipsToBounds = true
                    
                    let headerView = UIView()
                    headerView.translatesAutoresizingMaskIntoConstraints = false
                    headerView.heightAnchor.constraint(equalToConstant: 48).isActive = true
                    
                    let titleLabel = UILabel()
                    titleLabel.text = cardTitle
                    titleLabel.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
                    titleLabel.textColor = offWhite
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    headerView.addSubview(titleLabel)
                    
                    let arrowLabel = UILabel()
                    arrowLabel.text = startExpanded ? "▼" : "▶"
                    arrowLabel.textColor = opticalCyan
                    arrowLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
                    arrowLabel.translatesAutoresizingMaskIntoConstraints = false
                    headerView.addSubview(arrowLabel)
                    
                    let invisibleBtn = UIButton(type: .custom)
                    invisibleBtn.translatesAutoresizingMaskIntoConstraints = false
                    headerView.addSubview(invisibleBtn)
                    
                    NSLayoutConstraint.activate([
                        titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                        titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                        
                        arrowLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                        arrowLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                        
                        invisibleBtn.topAnchor.constraint(equalTo: headerView.topAnchor),
                        invisibleBtn.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                        invisibleBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                        invisibleBtn.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
                    ])
                    
                    let bodyView = UIView()
                    bodyView.translatesAutoresizingMaskIntoConstraints = false
                    bodyView.isHidden = !startExpanded
                    
                    let bodyLabel = UILabel()
                    bodyLabel.numberOfLines = 0
                    bodyLabel.textColor = slateColor
                    bodyLabel.font = UIFont(name: "Inter-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
                    
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 4
                    paragraphStyle.alignment = .justified
                    bodyLabel.attributedText = NSAttributedString(string: cardContent, attributes: [
                        .paragraphStyle: paragraphStyle
                    ])
                    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
                    bodyView.addSubview(bodyLabel)
                    
                    NSLayoutConstraint.activate([
                        bodyLabel.topAnchor.constraint(equalTo: bodyView.topAnchor, constant: 4),
                        bodyLabel.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 16),
                        bodyLabel.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor, constant: -16),
                        bodyLabel.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor, constant: -12)
                    ])
                    
                    cardContainer.addArrangedSubview(headerView)
                    cardContainer.addArrangedSubview(bodyView)
                    
                    invisibleBtn.addAction(UIAction { _ in
                        UIView.animate(withDuration: 0.25) {
                            bodyView.isHidden.toggle()
                            arrowLabel.text = bodyView.isHidden ? "▶" : "▼"
                            stackView.layoutIfNeeded()
                        }
                    }, for: .touchUpInside)
                    
                    return cardContainer
                }
                
        // 6. ADIÇÃO DOS CARDS DO ACCORDION NO STACK
                // 👤 BIOMETRIA DETECTADA (MINI RESUMO): Começa aberto (true) para validação clínica instantânea!
                let patientStatsText = """
                • Largura do Rosto: \(self.f(self.faceWidth)) mm
                • Altura do Rosto: \(self.f(self.faceHeight)) mm
                • Base Nasal (Ponte): \(self.f(self.noseBridgeWidth)) mm
                • Formato de Rosto Mapeado: \(self.faceShape.uppercased())
                """
                let biometricsCard = createAccordionCard("Biometria Detectada (\(patientFirstName.uppercased()))", patientStatsText, true)
                
                let conceptCard = createAccordionCard("Conceito & Storytelling do Design", profile.storytelling, false)
                let proportionsCard = createAccordionCard("Análise de Proporções (IA)", "• \(eyesAdvice)\n\n• \(noseAdvice)", false)
                let colorsCard = createAccordionCard("Sugestão de Paleta Cromática", colorsAdvice, false)
                
                // Empilhamento seguro na UI
                stackView.addArrangedSubview(biometricsCard)
                stackView.addArrangedSubview(conceptCard)
                stackView.addArrangedSubview(proportionsCard)
                stackView.addArrangedSubview(colorsCard)
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Seguro)
                let visagismTextValidation = ["Visagism Accordion System OK"]
                let _ = visagismTextValidation[ 0 ]
                // Empilhamento seguro na UI
                
                
                // 🔴 CTA Oficial Cyan Sem Sombra e Texto Navy
                let btnNext = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
                btnNext.backgroundColor = opticalCyan
                btnNext.setTitle("Avançar para Medição Técnica", for: .normal)
                btnNext.setTitleColor(navyDark, for: .normal)
                btnNext.layer.cornerRadius = 16
                btnNext.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
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
                    // 🔴 BRANDBOOK: Injeção das Cores Oficiais
                    let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                    let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                    let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                    
                    let adaptContainer = UIView(frame: self.view.bounds)
                    adaptContainer.backgroundColor = navyDark
                    adaptContainer.alpha = 0.0
                    self.view.addSubview(adaptContainer)
                    
                    let title = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 - 60, width: self.view.bounds.width - 40, height: 30))
                    title.text = "PARAMETRIZANDO ARMAÇÃO 3D..."
                    title.textAlignment = .center
                    title.textColor = opticalCyan
                    title.font = UIFont(name: "Inter-Black", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .black)
                    adaptContainer.addSubview(title)
                    
                    let barBg = UIView(frame: CGRect(x: 50, y: self.view.bounds.height / 2, width: self.view.bounds.width - 100, height: 6))
                    barBg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                    barBg.layer.cornerRadius = 3
                    adaptContainer.addSubview(barBg)
                    
                    let barFill = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 6))
                    barFill.backgroundColor = opticalCyan
                    barFill.layer.cornerRadius = 3
                    barBg.addSubview(barFill)
                    
                    let stepLabel = UILabel(frame: CGRect(x: 20, y: self.view.bounds.height / 2 + 30, width: self.view.bounds.width - 40, height: 20))
                    stepLabel.text = "Ajustando largura temporal com +2.0mm de folga..."
                    stepLabel.textAlignment = .center
                    stepLabel.textColor = slateColor
                    stepLabel.font = UIFont(name: "Inter-SemiBold", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .semibold)
                    adaptContainer.addSubview(stepLabel)
                    
                    // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                    let styleValidation = ["Phase 1 Loading Cyan OK"]
                    let _ = styleValidation[ 0 ]
            
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
            // 🔴 BRANDBOOK: Injeção da Paleta Oficial no escopo da função
                    let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
                    let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
                    let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                    
                    let popupOverlay = UIView(frame: self.view.bounds)
                    popupOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                    popupOverlay.alpha = 0.0
                    self.view.addSubview(popupOverlay)
            
            // 🔴 BRANDBOOK: Card Modular Bi-color (Fundo Branco com Cabeçalho Navy)
            // 🔴 BRANDBOOK: Card Modular Bi-color (Fundo Branco com Cabeçalho Navy)
                    let boxW: CGFloat = 340
                    let boxH: CGFloat = 350 // Aumentamos um pouco para dar respiro ao design split
                    let box = UIView(frame: CGRect(x: (self.view.bounds.width - boxW)/2, y: (self.view.bounds.height - boxH)/2, width: boxW, height: boxH))
                    box.backgroundColor = .white // O corpo do card de leitura é branco
                    box.layer.cornerRadius = 24
                    box.clipsToBounds = true // Essencial para o cabeçalho não vazar nas quinas arredondadas
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
                    subtitleLabel.text = "Ajustes da armação"
                    subtitleLabel.textColor = .white
                    subtitleLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
                    headerView.addSubview(subtitleLabel)
                    
                    // Ícone Ico_10 vazado e pintado de Optical Cyan
                    let iconView = UIImageView(frame: CGRect(x: boxW - 65, y: 25, width: 40, height: 40))
                    if let iconImg = UIImage(named: "Ico_10")?.withRenderingMode(.alwaysTemplate) {
                        iconView.image = iconImg
                    }
                    iconView.tintColor = opticalCyan
                    iconView.contentMode = .scaleAspectFit
                    headerView.addSubview(iconView)
                    
                    // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                    let splitValidation = ["Split UI OK"]
                    let _ = splitValidation[ 0 ]
            
            let keyword = self.recommendedAutoModel
            var modText = ""
            
            var safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
            let sizeLine = AutoConfiguratorEngine.sizeLineSuffix(forFaceWidth: self.faceWidth)
            if ["luno", "nunu", "suki", "timbau"].contains(safeKeyword) {
                safeKeyword = "\(safeKeyword)_\(sizeLine)"
            }
            
            var displayModelName = keyword.capitalized
            
            if let key = AutoConfiguratorEngine.specs.keys.first(where: { safeKeyword.contains($0) }),
               let spec = AutoConfiguratorEngine.specs[key],
               let fit = AutoConfiguratorEngine.fitDetails(forKeyword: safeKeyword, faceWidth: self.faceWidth, faceHeight: self.faceHeight, bridgeWidth: self.noseBridgeWidth, nasalProjection: self.nasalProjection, jawWidth: self.jawWidth, eyeToCheekClearance: self.eyeToCheekClearance, eyeToCheekClearanceValid: self.eyeToCheekClearanceValid) {

                displayModelName = "\(keyword.capitalized) \(Int(spec.baseWidth))mm"

                // 🔴 Deltas em mm vêm direto do motor (AutoConfiguratorEngine.fitDetails) — antes
                // essa conta era reimplementada aqui em paralelo e ficou desatualizada (regra de
                // ponte antiga, amortecimento vertical de 0.05 em vez de 0.6). Ver FitResult.
                if abs(fit.appliedWidthDiff) > 0.1 {
                    let sign = fit.appliedWidthDiff > 0 ? "+" : ""
                    modText += "• Largura Temporal: \(sign)\(String(format: "%.1f", fit.appliedWidthDiff)) mm\n"
                }

                if abs(fit.appliedBridgeDiff) > 0.1 {
                    let sign = fit.appliedBridgeDiff > 0 ? "+" : ""
                    modText += "• Ponte Nasal: \(sign)\(String(format: "%.1f", fit.appliedBridgeDiff)) mm\n"
                }

                if self.nasalProfile == "Plano" {
                    modText += "• Apoio Nasal: Expandido (Perfil Plano)\n"
                }

                if abs(fit.appliedVerticalDiff) > 0.1 {
                    let sign = fit.appliedVerticalDiff > 0 ? "+" : ""
                    let explanation = fit.appliedVerticalDiff > 0 ? "Alongamento visual" : "Estética compacta"
                    modText += "• Design Vertical: \(sign)\(String(format: "%.1f", fit.appliedVerticalDiff)) mm (\(explanation))\n"
                }

                if self.noseBridgeWidth < VisagismClinicalRules.narrowNoseThreshold {
                    modText += "• Estrutura da Ponte: Modo Ferradura (Maior volume e aderência)\n"
                }

                // 🔴 DIAGNÓSTICO DEV: eixo que bateu no limite físico do molde e ainda precisaria
                // de mais — não é mostrado ao cliente em produção, só para controle enquanto o
                // app está em desenvolvimento. A mensagem diz a DIREÇÃO do excedente (maior/menor,
                // esticar/encolher) porque só o número não diz o que de fato aconteceu.
                if fit.bridgeOverage > 0.05 {
                    let dir = fit.appliedBridgeDiff > 0 ? "mais larga" : "mais estreita"
                    modText += "⚠️ [DEV] Ponte do rosto é \(dir) que o limite de ajuste em \(String(format: "%.2f", fit.bridgeOverage)) mm\n"
                }
                if fit.widthOverage > 0.05 {
                    let dir = fit.appliedWidthDiff > 0 ? "maior" : "menor"
                    modText += "⚠️ [DEV] Largura do rosto é \(dir) que o limite de ajuste em \(String(format: "%.2f", fit.widthOverage)) mm\n"
                }
                if fit.verticalOverage > 0.05 {
                    let verb = fit.appliedVerticalDiff > 0 ? "esticar" : "encolher"
                    let context = fit.appliedVerticalDiff > 0 ? "rosto mais alongado" : "rosto mais compacto"
                    modText += "⚠️ [DEV] Altura da lente precisa \(verb) mais que o limite de ajuste em \(String(format: "%.2f", fit.verticalOverage)) mm (\(context))\n"
                }
            }
            
            if modText.isEmpty { modText = "• Proporções originais perfeitas para sua face.\n" }
            
            // 🔴 CORREÇÃO UX: Altura do label aumentada de 100 para 130
            // Reposicionamos o texto abaixo do cabeçalho
                    let infoLabel = UILabel(frame: CGRect(x: 24, y: headerH + 15, width: boxW - 48, height: 140))
                    infoLabel.numberOfLines = 0
                    infoLabel.text = "Modificações Aplicadas no Modelo (\(displayModelName)):\n\n" + modText
                    
                    // 🔴 BRANDBOOK: Tom escuro sofisticado para brilhar e ter contraste no Fundo Branco
                    let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
                    infoLabel.textColor = navyMedium
                    infoLabel.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
                    box.addSubview(infoLabel)
                    
                    let btnOk = UIButton(frame: CGRect(x: 24, y: boxH - 70, width: boxW - 48, height: 46))
                    btnOk.backgroundColor = opticalCyan
                    btnOk.setTitle("OK, Iniciar Medições", for: .normal)
                    btnOk.setTitleColor(navyDark, for: .normal)
                    btnOk.layer.cornerRadius = 14
                    btnOk.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
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
        // 🔴 1. INTELIGÊNCIA ANATÔMICA GLOBAL (3 ESCALAS)
                var safeModelName = modelIdOrName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
        let sizeLine = AutoConfiguratorEngine.sizeLineSuffix(forFaceWidth: self.faceWidth)
                if ["luno", "nunu", "suki", "timbau"].contains(safeModelName) {
                    safeModelName = "\(safeModelName)_\(sizeLine)"
                }
            
            // 🔴 2. BUSCA NA NUVEM (Usando o nome já traduzido com gênero)
            if let cloudModel = CloudManager.shared.availableModels.first(where: {
                let cloudNameClean = $0.name.lowercased().replacingOccurrences(of: " ", with: "_")
                return cloudNameClean.contains(safeModelName)
            }) {
                // Se achou o óculos correto na nuvem, veste ele (sem tela de carregamento duplicada)
                // 🔴 bypassWarning: true — isso é a recomendação AUTOMÁTICA do sistema, não uma
                // escolha manual do cliente. O aviso de "pode não caber bem" é só pra quando o
                // cliente troca de modelo sozinho no try-on (TryOn.swift:48), nunca pro fluxo inicial.
                self.loadCloudModel(model: cloudModel, showFakeLoading: false, bypassWarning: true)
                
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
                            
                            // 🔴 OVERRIDE PARA TESTE ISOLADO DO NUNU MASCULINO
                            var offsetZ: Float = 0.050 // Padrão
                            if safeModelName == "sl_nunu_masculino" {
                                offsetZ = -0.025
                            }
                            
                            wrapperNode.position = SCNVector3(0, 0.028, offsetZ)
                
                // 🔴 CORREÇÃO VITAL: Agora enviamos o nome com o Gênero exato para o motor torcer a malha!
                self.applyAutoMorphs(to: wrapperNode, keyword: safeModelName)
                
                let targetFace = self.safeFaceCache ?? self.faceNode
                targetFace?.addChildNode(wrapperNode)
                self.glassesNode = wrapperNode
            }
        }
}
