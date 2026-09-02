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
            
            // 🔴 BRANDBOOK: Injeção das Tintas Oficiais para a Tela de Resumo
            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
            let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
            let navyDarkBase = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 0.85)
            let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
            let vibrantViolet = UIColor(red: 0.525, green: 0.353, blue: 0.898, alpha: 1.0)
            let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)
            
            if summaryContainer == nil {
                summaryContainer = UIView(frame: view.bounds)
                // Fundo imponente em Navy Oficial
                summaryContainer.backgroundColor = navyDark
                view.addSubview(summaryContainer)
            }
            summaryContainer.subviews.forEach { $0.removeFromSuperview() }
            
            summaryContainer.isHidden = false
            summaryContainer.alpha = 0
            
            let title = UILabel(frame: CGRect(x: 20, y: 55, width: view.bounds.width - 40, height: 30))
            title.textAlignment = .center
            title.attributedText = NSAttributedString(string: "RESUMO CLÍNICO", attributes: [
                .font: UIFont(name: "Inter-Bold", size: 22) ?? UIFont.systemFont(ofSize: 22, weight: .black),
                .foregroundColor: offWhite,
                .kern: 1.5
            ])
            summaryContainer.addSubview(title)
            
            let holoView = SCNView(frame: CGRect(x: 40, y: 95, width: view.bounds.width - 80, height: 230))
            // Glassmorphism suave com fundo Navy translúcido no box 3D
            holoView.backgroundColor = navyDarkBase
            holoView.layer.cornerRadius = 16
            holoView.clipsToBounds = true
            holoView.layer.borderWidth = 1.5
            holoView.layer.borderColor = opticalCyan.withAlphaComponent(0.3).cgColor
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
                        holoMaterial.diffuse.contents = opticalCyan.withAlphaComponent(0.8)
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
                
                // 1. EXTRAÇÃO BLINDADA DO ÓCULOS (Baking de Geometria)
                // 🔴 REVERTIDO: clone() compartilha a MESMA geometria/morpher que ainda está
                // "vivo" na cena AR original — renderizar o mesmo morpher simultaneamente em dois
                // SCNView (sceneView + holoView) causou corrupção visual. flattenedClone() volta
                // pro modelo base (menos correto), mas é seguro. Ver conversa antes de tentar de
                // novo — a correção certa precisa assar as posições de vértice já deformadas numa
                // geometria nova e independente, não reusar o morpher ao vivo.
                if let customGlasses = originalFace.childNodes.first(where: { $0.name == "customGlasses" }) {
                    let bakedGlasses = customGlasses.flattenedClone()
                    bakedGlasses.name = "customGlasses"
                    bakedGlasses.isHidden = false
                    presentationNode.addChildNode(bakedGlasses)
                }
            }
            
            presentationNode.position = SCNVector3(0, 0, 0)
            holoScene.rootNode.addChildNode(presentationNode)
            
            // 🔴 CURA DA LENTE E DA PERSPECTIVA (Câmera Retrato)
            let cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.zNear = 0.01
            camera.usesOrthographicProjection = false
            camera.fieldOfView = 12
            
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 1.2)
            holoScene.rootNode.addChildNode(cameraNode)
            
            summaryContainer.addSubview(holoView)
            
            // 🔴 AJUSTE DE ÓRBITA DA CÂMERA
            holoView.defaultCameraController.target = SCNVector3(0, 0, -0.06)
            
            let techDesc = UILabel(frame: CGRect(x: 20, y: 325, width: view.bounds.width - 40, height: 110))
            techDesc.numberOfLines = 0
            techDesc.textAlignment = .center
            techDesc.textColor = opticalCyan
            
            let descText = "GÊMEO DIGITAL BIOMÉTRICO (IA)\nO holograma acima é a reconstrução volumétrica exata da sua face gerada por infravermelhos. Com precisão matemática, eliminamos o erro na medição das suas lentes.\n\nCOMO MANIPULAR O SEU ROSTO 3D:\nRotacionar: Arraste com 1 dedo. | Zoom: Pinça com 2 dedos.\nMover: Arraste com 2 dedos juntos na tela."
            
            let descParagraph = NSMutableParagraphStyle()
            descParagraph.lineSpacing = 3
            descParagraph.alignment = .center
            techDesc.attributedText = NSAttributedString(string: descText, attributes: [
                .font: UIFont(name: "Inter-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .medium),
                .paragraphStyle: descParagraph
            ])
            summaryContainer.addSubview(techDesc)
            
            // 🔴 REDESIGN (2026-09): antes era um único UITextView com tudo empilhado — trocado
            // por accordion (mesmo padrão de showVisagismResults, ver +UIHelpers.swift) pra não
            // sobrecarregar a tela com informação toda junta. Identidade do paciente fica sempre
            // visível (não vale esconder atrás de um clique); o resto vira cards retráteis.
            let identityLabel = UILabel(frame: CGRect(x: 20, y: 440, width: view.bounds.width - 40, height: 36))
            identityLabel.numberOfLines = 2
            identityLabel.textAlignment = .center
            identityLabel.attributedText = NSAttributedString(string: "👤 \(self.patientName)   👓 \(self.selectedLensType)", attributes: [
                .font: UIFont(name: "Inter-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: offWhite
            ])
            summaryContainer.addSubview(identityLabel)

            let scrollTop: CGFloat = 482
            let scrollHeight = max(100, (view.bounds.height - 200) - scrollTop)
            let scrollView = UIScrollView(frame: CGRect(x: 20, y: scrollTop, width: view.bounds.width - 40, height: scrollHeight))
            scrollView.showsVerticalScrollIndicator = false
            scrollView.backgroundColor = .clear
            summaryContainer.addSubview(scrollView)

            let summaryStack = UIStackView()
            summaryStack.axis = .vertical
            summaryStack.spacing = 12
            summaryStack.distribution = .fill
            summaryStack.alignment = .fill
            summaryStack.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(summaryStack)

            NSLayoutConstraint.activate([
                summaryStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                summaryStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                summaryStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                summaryStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                summaryStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
            ])

            // Card: Medidas Faciais (começa aberto — validação clínica instantânea)
            let facialText = """
            • DNP Total: \(self.f(self.dnpTotal)) mm
            • Ponte: \(self.f(self.noseBridgeWidth)) mm
            • Largura do Rosto: \(self.f(self.faceWidth)) mm
            • Altura do Rosto: \(self.f(self.faceHeight)) mm
            """
            let facialCard = makeAccordionCard(title: "Medidas Faciais", text: facialText, startExpanded: true, stackToRelayout: summaryStack)
            summaryStack.addArrangedSubview(facialCard)

            // Card: Encaixe do modelo recomendado — barras de % de capacidade usada por eixo,
            // em vez de só o número em mm (mais rápido de escanear, e alerta visual natural
            // quando um eixo está perto do limite físico do molde).
            let fitKeyword = self.recommendedAutoModelKey.isEmpty ? self.recommendedAutoModel : self.recommendedAutoModelKey
            if !fitKeyword.isEmpty, let fit = AutoConfiguratorEngine.fitDetails(forKeyword: fitKeyword, faceWidth: self.faceWidth, faceHeight: self.faceHeight, bridgeWidth: self.noseBridgeWidth, nasalProjection: self.nasalProjection, jawWidth: self.jawWidth, eyeToCheekClearance: self.eyeToCheekClearance, eyeToCheekClearanceValid: self.eyeToCheekClearanceValid, currentGlassesLensWidth: self.currentGlassesLensWidth, currentGlassesBridge: self.currentGlassesBridge) {
                let widthPercent = fit.weights["Largura_a"] ?? fit.weights["Largura_d"] ?? 0
                let bridgePercent = fit.weights["Ponte_a"] ?? fit.weights["Ponte_d"] ?? 0
                let verticalPercent = fit.weights["Vertical_a"] ?? fit.weights["Vertical_d"] ?? 0

                let widthBar = makeCapacityBar(label: "Largura Temporal", percent: widthPercent, valueText: "\(fit.appliedWidthDiff >= 0 ? "+" : "")\(self.f(fit.appliedWidthDiff)) mm")
                let bridgeBar = makeCapacityBar(label: "Ponte Nasal", percent: bridgePercent, valueText: "\(fit.appliedBridgeDiff >= 0 ? "+" : "")\(self.f(fit.appliedBridgeDiff)) mm")
                let verticalBar = makeCapacityBar(label: "Vertical", percent: verticalPercent, valueText: "\(fit.appliedVerticalDiff >= 0 ? "+" : "")\(self.f(fit.appliedVerticalDiff)) mm")
                let barsStack = makeCapacityBarsStack([widthBar, bridgeBar, verticalBar])

                let fitModelName = self.recommendedAutoModel.isEmpty ? "Recomendado" : self.recommendedAutoModel
                let fitCard = makeAccordionCard(title: "Encaixe do Modelo (\(fitModelName))", contentView: barsStack, startExpanded: true, stackToRelayout: summaryStack)
                summaryStack.addArrangedSubview(fitCard)
            }

            // Card: Medidas da Armação (Manual)
            let frameText = """
            • Altura de Montagem (H): \(self.f(self.pupillaryHeight)) mm
            • Lente Horizontal: \(self.f(self.manualFrameWidth)) mm
            • Lente Vertical: \(self.f(self.manualFrameHeight)) mm
            • Diagonal da Lente: \(self.f(self.manualFrameDiagonal)) mm
            """
            let frameCard = makeAccordionCard(title: "Medidas da Armação (Manual)", text: frameText, startExpanded: false, stackToRelayout: summaryStack)
            summaryStack.addArrangedSubview(frameCard)

            // Card: Receita
            let rxText = """
            • Visão Longe OD: \(self.rxEsfOD) | \(self.rxCilOD) | \(self.rxEixoOD)
            • Visão Longe OE: \(self.rxEsfOE) | \(self.rxCilOE) | \(self.rxEixoOE)
            """
            let rxCard = makeAccordionCard(title: "Receita", text: rxText, startExpanded: false, stackToRelayout: summaryStack)
            summaryStack.addArrangedSubview(rxCard)

            // Card: Comportamento Visual (IA)
            let behaviorCard = makeAccordionCard(title: "Comportamento Visual (IA)", text: self.visionBehaviorResult, startExpanded: false, stackToRelayout: summaryStack)
            summaryStack.addArrangedSubview(behaviorCard)

            let btnPDF = UIButton()
            btnPDF.backgroundColor = opticalCyan
            btnPDF.setTitle("Gerar Laudo PDF", for: .normal)
            btnPDF.setTitleColor(navyDark, for: .normal)
            btnPDF.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnPDF.layer.cornerRadius = 16
            btnPDF.layer.shadowOpacity = 0 // Regra 8 do Brandbook: Sem efeitos tridimensionais ou sombras!
            btnPDF.addTarget(self, action: #selector(executePDFGeneration), for: .touchUpInside)
            
            let btnReset = UIButton()
            btnReset.backgroundColor = navyMedium.withAlphaComponent(0.4)
            btnReset.setTitle("Refazer", for: .normal)
            btnReset.setTitleColor(offWhite, for: .normal)
            btnReset.titleLabel?.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
            btnReset.layer.cornerRadius = 12
            btnReset.addTarget(self, action: #selector(resetToStartMeasure), for: .touchUpInside)
            
            let btnHome = UIButton()
            btnHome.backgroundColor = navyMedium.withAlphaComponent(0.4)
            btnHome.setTitle("Painel", for: .normal)
            btnHome.setTitleColor(offWhite, for: .normal)
            btnHome.titleLabel?.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
            btnHome.layer.cornerRadius = 12
            btnHome.addTarget(self, action: #selector(returnToTriagem), for: .touchUpInside)
            
            let btnExit = UIButton()
            btnExit.backgroundColor = navyMedium.withAlphaComponent(0.4)
            btnExit.setTitle("Encerrar", for: .normal)
            btnExit.setTitleColor(offWhite, for: .normal)
            btnExit.titleLabel?.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
            btnExit.layer.cornerRadius = 12
            btnExit.addTarget(self, action: #selector(exitAppFully), for: .touchUpInside)
            
            let bottomStack = UIStackView(arrangedSubviews: [btnReset, btnHome, btnExit])
            bottomStack.axis = .horizontal
            bottomStack.spacing = 10
            bottomStack.distribution = .fillEqually
            
            // 🔴 BRANDBOOK: Botão de Exportação 3D em Vibrant Violet com texto Off-White
            let btnExport3D = UIButton()
            btnExport3D.backgroundColor = vibrantViolet
            btnExport3D.setTitle("📥 Exportar Armação Personalizada", for: .normal)
            btnExport3D.setTitleColor(offWhite, for: .normal)
            btnExport3D.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnExport3D.layer.cornerRadius = 16
            btnExport3D.layer.shadowOpacity = 0 // Regra 8 do Brandbook: Sem sombras!
            btnExport3D.addTarget(self, action: #selector(exportCustomGlasses), for: .touchUpInside)
            
            let masterStack = UIStackView(arrangedSubviews: [btnExport3D, btnPDF, bottomStack])
            masterStack.axis = .vertical
            masterStack.spacing = 12
            masterStack.distribution = .fillEqually
            masterStack.frame = CGRect(x: 30, y: view.bounds.height - 190, width: view.bounds.width - 60, height: 160)
            summaryContainer.addSubview(masterStack)
            
            UIView.animate(withDuration: 0.3) { self.summaryContainer.alpha = 1.0 }
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Seguro)
            let layoutValidation = ["Summary Design Master OK"]
            let _ = layoutValidation[ 0 ]
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
            
            // Pega o nome do óculos atual, ou a chave completa do ranking (com linha), ou por
            // último a keyword bare do visagismo — nessa ordem de confiança.
            let rawModelName = self.currentCloudModel?.name ?? (self.recommendedAutoModelKey.isEmpty ? self.recommendedAutoModel : self.recommendedAutoModelKey)

            // 🔴 CORREÇÃO DO ERRO NA NUVEM: Padroniza o nome para buscar o arquivo exato no servidor!
            // Transforma "SL Suki Feminino" em "sl_suki_feminino" para o Storage encontrar
            var modelBaseName = rawModelName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")

            // Fallback de segurança para garantir que a nuvem ache os arquivos com o prefixo exato antigo
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                let safetyCheck = ["Anatomic 3-Zone Routing"]
                let _ = safetyCheck[ 0 ]

                // 🔴 INTELIGÊNCIA ANATÔMICA (3 ESCALAS): Infantil, Feminino e Masculino
                // Só reconstrói a linha pela largura quando modelBaseName chegou "cru" (sem linha,
                // ex.: veio do fallback bare recommendedAutoModel) — nunca sobrescreve uma linha
                // que já veio explícita (do currentCloudModel ou recommendedAutoModelKey).
                let alreadyHasLine = ["_infantil", "_feminino", "_masculino"].contains { modelBaseName.hasSuffix($0) }
                if !alreadyHasLine, ["luno", "nunu", "suki", "timbau"].contains(modelBaseName) {
                    let sizeLine = AutoConfiguratorEngine.sizeLineSuffix(forFaceWidth: self.faceWidth)
                    modelBaseName = "sl_\(modelBaseName)_\(sizeLine)"
                } else if alreadyHasLine, !modelBaseName.hasPrefix("sl_") {
                    // Só prefixa se ainda não tiver — currentCloudModel?.name (ex.: "SL Nunu
                    // Masculino") já vem com "sl_" embutido; só recommendedAutoModelKey (ex.:
                    // "nunu_masculino") não tem. Prefixar de novo aqui duplicava pra
                    // "sl_sl_nunu_masculino", que a Cloud Function não acha no Storage.
                    modelBaseName = "sl_\(modelBaseName)"
                }
            
        // Solicita as chaves matemáticas ao Motor!
        let edicoesShapeKeys = AutoConfiguratorEngine.calculateMorphWeights(
                    keyword: rawModelName,
                    faceWidth: self.faceWidth,
                    faceHeight: self.faceHeight, // 🔴 INJETANDO A ALTURA
                    bridgeWidth: self.noseBridgeWidth,
                    nasalProjection: self.nasalProjection,
                    jawWidth: self.jawWidth,
                    faceShape: self.faceShape, // 🔴 Motor agora sabe o formato do rosto!
                    eyeToCheekClearance: self.eyeToCheekClearance,
                    eyeToCheekClearanceValid: self.eyeToCheekClearanceValid,
                    currentGlassesLensWidth: self.currentGlassesLensWidth,
                    currentGlassesBridge: self.currentGlassesBridge
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
                    "rightWidth": self.faceWidthRight,
                    "faceWidth": self.faceWidth,
                    "faceHeight": self.faceHeight,
                    "nasalProjection": self.nasalProjection
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
            self.currentGlassesLensWidth = nil
            self.currentGlassesBridge = nil
            self.currentGlassesHaste = nil
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
