import UIKit
import FirebaseStorage
import FirebaseFirestore
import SceneKit
import SceneKit.ModelIO
import FirebaseAuth

// --- ESTRUTURAS DE BIOMETRIA E LIMITES ---
struct ModelLimits {
    let bridgePlus: Float
    let bridgeMinus: Float
    let nasal: Float
    let ferradura: Float
    let larguraR: Float
    let larguraA: Float
    let verticalR: Float
    let verticalA: Float
}

struct ModelSpec {
    let baseBridge: Float
    let baseWidth: Float
    let limits: ModelLimits
}

// --- BANCO DE DADOS DE MODELOS 3D ---
let localModelSpecs: [String: ModelSpec] = [
    "sl_luno_feminino": ModelSpec(
        baseBridge: 15.0,
        baseWidth: 130.0,
        limits: ModelLimits(
            bridgePlus: 5.0,
            bridgeMinus: 4.0,
            nasal: 2.0,
            ferradura: 2.0,
            larguraR: 2.0,
            larguraA: 2.5,
            verticalR: 1.0,
            verticalA: 2.0
        )
    ),
    
    "sl_nunu_feminino": ModelSpec(
        baseBridge: 16.0, // <-- Substitua pela Ponte original do Nunu
        baseWidth: 128.0,  // <-- Substitua pela Largura Frontal original do Nunu
        limits: ModelLimits(
            bridgePlus: 5.0, // Limite máximo para aumentar ponte
            bridgeMinus: 4.0, // Limite máximo para reduzir ponte
            nasal: 2.0,
            ferradura: 1.5,
            larguraR: 4.0, // Limite máximo para reduzir largura
            larguraA: 2.0, // Limite máximo para aumentar largura
            verticalR: 2.0,
            verticalA: 2.0
        )
    ),
    "sl_suki_feminino": ModelSpec(
        baseBridge: 15.0, // <-- Substitua pela Ponte original do Nunu
        baseWidth: 130.0,  // <-- Substitua pela Largura Frontal original do Nunu
        limits: ModelLimits(
            bridgePlus: 4.0, // Limite máximo para aumentar ponte
            bridgeMinus: 4.0, // Limite máximo para reduzir ponte
            nasal: 2.0,
            ferradura: 1.5,
            larguraR: 4.0, // Limite máximo para reduzir largura
            larguraA: 2.0, // Limite máximo para aumentar largura
            verticalR: 2.0,
            verticalA: 2.0
        )
    )
]


class ConfiguratorViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView!
    var closeButton: UIButton!
    var controlsPanel: UIView!
    var panelTitleLabel: UILabel!

    var modelSelector: UISegmentedControl!
    var currentModelName: String = "rayban_f"

    var scrollControls: UIScrollView!
    
    // --- SLIDERS OTIMIZADOS ---
    var bridgeSlider: UISlider!
    var nasalSlider: UISlider!
    var larguraSlider: UISlider!
    var verticalSlider: UISlider!
    var ferraduraSlider: UISlider!

    // --- VARIÁVEIS DO SWEET SPOT (Bi-direcionais) ---
    var idealBridge: Float = 0.0
    var idealWidth: Float = 0.0
    var idealNasal: Float = 0.0
    
    // Callbacks para enviar a personalização de volta ao Espelho Virtual
    var onApplyCustomization: (([String: Float], UIColor?, SCNNode?) -> Void)?
    var selectedColorForExport: UIColor?
    
    var sceneView: SCNView!
    var glassesNode: SCNNode?
    var patientFaceNode: SCNNode?

    var containerNode = SCNNode()
    var lastPanPoint: CGPoint = .zero
    var currentCameraZ: Float = 150.0
    
    // DADOS RECEBIDOS DO ARKIT
    var bridgeSize: Float = 0.0
    var leftWidth: Float = 0.0
    var rightWidth: Float = 0.0
    var nasalProfile: String = "Plano"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        setup3DScene()
        setupUI()
        applyModelSetup()
    }

    func setupUI() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        closeButton = UIButton(frame: CGRect(x: 20, y: 60, width: 40, height: 40))
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        let panelHeight = view.bounds.height * 0.45
        controlsPanel = UIView(frame: CGRect(x: 0, y: view.bounds.height - panelHeight, width: view.bounds.width, height: panelHeight))
        controlsPanel.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        controlsPanel.layer.cornerRadius = 25
        controlsPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        controlsPanel.layer.borderWidth = 1
        controlsPanel.layer.borderColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        view.addSubview(controlsPanel)

        panelTitleLabel = UILabel(frame: CGRect(x: 20, y: 15, width: controlsPanel.bounds.width - 40, height: 25))
        panelTitleLabel.text = "Personalização Técnica"
        panelTitleLabel.textColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
        panelTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        controlsPanel.addSubview(panelTitleLabel)

        let separator = UIView(frame: CGRect(x: 20, y: 45, width: controlsPanel.bounds.width - 40, height: 1))
        separator.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        controlsPanel.addSubview(separator)

        scrollControls = UIScrollView(frame: CGRect(x: 0, y: 60, width: controlsPanel.bounds.width, height: controlsPanel.bounds.height - 100))
        controlsPanel.addSubview(scrollControls)

        var currentY: CGFloat = 10

        func addSectionTitle(_ title: String) {
            let lbl = UILabel(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 20))
            lbl.text = title.uppercased()
            lbl.textColor = .lightGray
            lbl.font = UIFont.boldSystemFont(ofSize: 12)
            scrollControls.addSubview(lbl)
            currentY += 25
        }

        // Criação de Sliders de 1 Única Direção (0 a 1)
                func createUniSlider(title: String) -> UISlider {
                    let lbl = UILabel(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 15))
                    lbl.text = title; lbl.textColor = .white; lbl.font = UIFont.systemFont(ofSize: 12)
                    scrollControls.addSubview(lbl); currentY += 15
                    let slider = UISlider(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 30))
                    slider.minimumValue = 0; slider.maximumValue = 1; slider.value = 0
                    slider.minimumTrackTintColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
                    slider.addTarget(self, action: #selector(slidersChanged), for: .valueChanged)
                    scrollControls.addSubview(slider); currentY += 40
                    return slider
                }

                // Criação de Sliders Bi-direcionais (-1 a 1, centralizados)
                func createBiSlider(title: String) -> UISlider {
                    let lbl = UILabel(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 15))
                    lbl.text = title; lbl.textColor = .white; lbl.font = UIFont.systemFont(ofSize: 12)
                    scrollControls.addSubview(lbl); currentY += 15
                    let slider = UISlider(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 30))
                    slider.minimumValue = -1.0; slider.maximumValue = 1.0; slider.value = 0.0 // Começa exatamente no meio
                    slider.minimumTrackTintColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
                    slider.addTarget(self, action: #selector(slidersChanged), for: .valueChanged)
                    scrollControls.addSubview(slider); currentY += 40
                    return slider
                }

                addSectionTitle("Ponte e Nasal (Customização de conforto e precisão)")
                bridgeSlider = createBiSlider(title: "Ajuste de Ponte ( Reduzir ← Centro → Aumentar )")
                nasalSlider = createUniSlider(title: "Aumentar Apoio Nasal")

                addSectionTitle("Largura total (Boa acomodação)")
                larguraSlider = createBiSlider(title: "Ajuste de Largura ( Reduzir ← Centro → Aumentar )")

                addSectionTitle("Alturas (Personalização estética)")
                verticalSlider = createBiSlider(title: "Ajuste de Altura ( Reduzir ← Centro → Aumentar )")
                ferraduraSlider = createUniSlider(title: "Aumentar Ferradura")
        
        // --- NOVA PALETA DE CORES ---
                // Função auxiliar para desenhar os botões circulares
                func createColorPalette(colors: [UIColor], yPos: CGFloat) {
                    let btnSize: CGFloat = 35
                    let spacing: CGFloat = 15
                    var startX: CGFloat = 20
                    
                    for color in colors {
                        let btn = UIButton(frame: CGRect(x: startX, y: yPos, width: btnSize, height: btnSize))
                        btn.backgroundColor = color
                        btn.layer.cornerRadius = btnSize / 2 // Deixa redondo
                        btn.layer.borderWidth = 2
                        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                        btn.addTarget(self, action: #selector(colorPresetTapped(_:)), for: .touchUpInside)
                        scrollControls.addSubview(btn)
                        startX += btnSize + spacing
                    }
                }
                
                addSectionTitle("Cores Transparentes")
                let transparentColors: [UIColor] = [
                    UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.6),  // Blue
                    UIColor(red: 0.0, green: 0.47, blue: 0.43, alpha: 0.6), // Green Pine
                    UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.6),  // Yellow
                    UIColor(red: 0.5, green: 0.0, blue: 0.13, alpha: 0.6)   // Burgundy
                ]
                createColorPalette(colors: transparentColors, yPos: currentY)
                currentY += 55
                
                addSectionTitle("Cores Sólidas")
                let solidColors: [UIColor] = [
                    UIColor(red: 0.56, green: 0.27, blue: 0.52, alpha: 1.0), // Plum
                    UIColor.systemOrange, // Orange
                    UIColor.systemGreen,  // Green
                    UIColor.systemRed     // Red
                ]
                createColorPalette(colors: solidColors, yPos: currentY)
                currentY += 60


                // --- BOTÃO DE EXPORTAR EXISTENTE ---
                let exportBtn = UIButton(frame: CGRect(x: 20, y: currentY, width: controlsPanel.bounds.width - 40, height: 50))
                exportBtn.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
                exportBtn.setTitle("📥 Enviar para Produção", for: .normal)
                exportBtn.setTitleColor(.white, for: .normal)
                exportBtn.layer.cornerRadius = 12
                exportBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                exportBtn.addTarget(self, action: #selector(exportAndUploadSTL), for: .touchUpInside)
                scrollControls.addSubview(exportBtn)
                currentY += 80
                
                scrollControls.contentSize = CGSize(width: scrollControls.bounds.width, height: currentY)
    }

    func setup3DScene() {
        sceneView = SCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        view.insertSubview(sceneView, at: 0)

        sceneView.scene = SCNScene()
        sceneView.scene?.rootNode.addChildNode(containerNode)

        if let face = patientFaceNode {
            face.geometry?.firstMaterial?.cullMode = .back
            let innerFaceNode = face.clone()
            innerFaceNode.geometry = face.geometry?.copy() as? SCNGeometry
            let inMaterial = SCNMaterial()
            inMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.85)
            inMaterial.lightingModel = .constant
            inMaterial.cullMode = .front
            innerFaceNode.geometry?.firstMaterial = inMaterial
            face.addChildNode(innerFaceNode)
            containerNode.addChildNode(face)
        }

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 1.0
        cameraNode.camera?.zFar = 5000.0
        cameraNode.position = SCNVector3(0, 0, currentCameraZ)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handle3DPan(_:)))
        sceneView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handle3DPinch(_:)))
        sceneView.addGestureRecognizer(pinch)
    }


    // --- MÁGICA DO SWEET SPOT (Cálculo dos limites ideais) ---
    func applyModelSetup() {
            glassesNode?.removeFromParentNode()
            glassesNode = nil
            loadNativeModel(modelName: currentModelName)
            
            bridgeSlider.value = 0
            nasalSlider.value = 0
            ferraduraSlider.value = 0
            larguraSlider.value = 0
            verticalSlider.value = 0
            
            if let spec = localModelSpecs[currentModelName] {
                // Ponte
                let diffBridge = self.bridgeSize - spec.baseBridge
                if diffBridge > 0 {
                    self.idealBridge = min(1.0, diffBridge / spec.limits.bridgePlus)
                } else {
                    self.idealBridge = max(-1.0, diffBridge / spec.limits.bridgeMinus)
                }
                
                // Largura
                let totalPatientWidth = self.leftWidth + self.rightWidth
                let diffWidth = totalPatientWidth - spec.baseWidth
                if diffWidth > 0 {
                    self.idealWidth = min(1.0, diffWidth / spec.limits.larguraA)
                } else {
                    self.idealWidth = max(-1.0, diffWidth / spec.limits.larguraR)
                }
                
                // Nasal
                self.idealNasal = self.nasalProfile == "Plano" ? 0.7 : 0.0
            }
            slidersChanged()
        }

    func loadNativeModel(modelName: String) {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "usdc"),
              let modelScene = try? SCNScene(url: url, options: nil) else {
            print("⚠️ ERRO: Não achei o arquivo \(modelName).usdc.")
            return
        }

        let wrapperNode = SCNNode()
        for child in modelScene.rootNode.childNodes {
            wrapperNode.addChildNode(child.clone())
        }
        glassesNode = wrapperNode

        wrapperNode.enumerateChildNodes { (node, _) in
            if let morpher = node.morpher {
                let nomes = morpher.targets.compactMap { $0.name }
                print("🟢 NOMES EXATOS DO BLENDER: \(nomes)")
            }
        }

        let (min, max) = wrapperNode.boundingBox
        let centerX = (min.x + max.x) / 2
        let centerY = (min.y + max.y) / 2
        let centerZ = (min.z + max.z) / 2
        wrapperNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY, centerZ)
        wrapperNode.eulerAngles = SCNVector3(0, 0, 0)
        
        containerNode.addChildNode(wrapperNode)
        wrapperNode.position = SCNVector3(0, 0, 0)
        activityIndicator?.stopAnimating()
    }

    @objc func closeTapped() {
            sendCustomizationsBack()
            self.dismiss(animated: true, completion: nil)
        }

    // --- CORES DA IA E ATUALIZAÇÃO DA TELA ---
    @objc func slidersChanged() {
            // Desmembrando a barra Bi-direcional para o formato do Blender
            let sPonte = bridgeSlider.value > 0 ? CGFloat(bridgeSlider.value) : 0
            let sPonteM = bridgeSlider.value < 0 ? CGFloat(abs(bridgeSlider.value)) : 0
            
            let sLarguraA = larguraSlider.value > 0 ? CGFloat(larguraSlider.value) : 0
            let sLarguraR = larguraSlider.value < 0 ? CGFloat(abs(larguraSlider.value)) : 0
            
            let sVerticalA = verticalSlider.value > 0 ? CGFloat(verticalSlider.value) : 0
            let sVerticalR = verticalSlider.value < 0 ? CGFloat(abs(verticalSlider.value)) : 0
            
            let sNasal = CGFloat(nasalSlider.value)
            let sFerradura = CGFloat(ferraduraSlider.value)

            // Função Inteligente de Cor para Sliders Centrais (-1 a 1)
            func updateBiSliderColor(slider: UISlider, idealValue: Float) {
                let current = Float(slider.value)
                
                if idealValue == 0.0 {
                    slider.minimumTrackTintColor = abs(current) > 0.1 ? .red : UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
                    return
                }
                // Se o usuário empurrar para o lado oposto do que o rosto precisa
                if (current > 0 && idealValue < 0) || (current < 0 && idealValue > 0) {
                    slider.minimumTrackTintColor = .red
                    return
                }
                // Verifica o encaixe
                let diff = abs(current - idealValue)
                if diff < 0.08 {
                    slider.minimumTrackTintColor = .green
                } else if abs(current) > abs(idealValue) {
                    slider.minimumTrackTintColor = .red // Passou do limite ideal
                } else {
                    slider.minimumTrackTintColor = .orange // Caminhando para o ideal
                }
            }

            // Função Clássica para Sliders Comuns (0 a 1)
            func updateUniSliderColor(slider: UISlider, idealValue: Float) {
                let current = Float(slider.value)
                if idealValue == 0.0 {
                    slider.minimumTrackTintColor = current > 0.1 ? .red : UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
                } else {
                    let diff = abs(current - idealValue)
                    if diff < 0.08 { slider.minimumTrackTintColor = .green }
                    else if current > idealValue { slider.minimumTrackTintColor = .red }
                    else { slider.minimumTrackTintColor = .orange }
                }
            }

            updateBiSliderColor(slider: bridgeSlider, idealValue: idealBridge)
            updateBiSliderColor(slider: larguraSlider, idealValue: idealWidth)
            updateUniSliderColor(slider: nasalSlider, idealValue: idealNasal)

            glassesNode?.enumerateChildNodes { (node, stop) in
                if let morpher = node.morpher {
                    morpher.setWeight(sPonte, forTargetNamed: "Ponte")
                    morpher.setWeight(sPonteM, forTargetNamed: "Ponte_m")
                    morpher.setWeight(sNasal, forTargetNamed: "Nasal")
                    morpher.setWeight(sFerradura, forTargetNamed: "Ferradura")
                    morpher.setWeight(sLarguraR, forTargetNamed: "Largura_r")
                    morpher.setWeight(sLarguraA, forTargetNamed: "Largura_a")
                    morpher.setWeight(sVerticalR, forTargetNamed: "Vertical_r")
                    morpher.setWeight(sVerticalA, forTargetNamed: "Vertical_a")
                }
            }
        }

    @objc func colorPresetTapped(_ sender: UIButton) {
            guard let selectedColor = sender.backgroundColor else { return }
            self.selectedColorForExport = selectedColor
            
            // Efeito Visual de "Botão Selecionado"
            for view in scrollControls.subviews {
                if let btn = view as? UIButton, btn.layer.cornerRadius == 17.5 { // 17.5 é metade de 35 (nosso btnSize)
                    btn.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                    btn.transform = .identity
                }
            }
            sender.layer.borderColor = UIColor.white.cgColor
            sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)

            // Aplica a física de cor no 3D
            glassesNode?.enumerateChildNodes { (node, _) in
                if let material = node.geometry?.firstMaterial {
                    material.diffuse.contents = selectedColor
                    
                    // Mágica para o acetato transparente funcionar perfeitamente
                    if selectedColor.cgColor.alpha < 1.0 {
                        material.transparencyMode = .dualLayer
                        material.isDoubleSided = true
                    } else {
                        material.transparencyMode = .default
                        material.isDoubleSided = false
                    }
                }
            }
        }

    @objc func exportAndUploadSTL() {
        let alert = UIAlertController(title: "Processando Pedido...", message: "Enviando parâmetros para a Nuvem. O arquivo 3D será gerado automaticamente pelo servidor.", preferredStyle: .alert)
        present(alert, animated: true)

        let fileName = "pedido_trueye_\(Int(Date().timeIntervalSince1970)).stl"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true) {
                self.saveOrderLinkToFirestore(fileName: fileName)

                let successAlert = UIAlertController(title: "Sucesso!", message: "Pedido enviado para a nuvem! O laboratório receberá o modelo 3D em instantes.", preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.sendCustomizationsBack() // <--- Envia as medidas de volta
                            self.dismiss(animated: true, completion: nil)
                        })
                        self.present(successAlert, animated: true)
            }
        }
    }

    func saveOrderLinkToFirestore(fileName: String) {
            guard let user = Auth.auth().currentUser else { return }

        let edicoesShapeKeys: [String: Float] = [
                "Ponte": bridgeSlider.value > 0 ? bridgeSlider.value : 0,
                "Ponte_m": bridgeSlider.value < 0 ? abs(bridgeSlider.value) : 0,
                "Nasal": nasalSlider.value,
                "Ferradura": ferraduraSlider.value,
                "Largura_r": larguraSlider.value < 0 ? abs(larguraSlider.value) : 0,
                "Largura_a": larguraSlider.value > 0 ? larguraSlider.value : 0,
                "Vertical_r": verticalSlider.value < 0 ? abs(verticalSlider.value) : 0,
                "Vertical_a": verticalSlider.value > 0 ? verticalSlider.value : 0
            ]

            let data: [String: Any] = [
                "userId": user.uid,
                "stlUrl": "gerando_na_nuvem...",
                "stlFileName": fileName,
                "timestamp": FieldValue.serverTimestamp(),
                "status": "Processando na Nuvem",
                "modeloBase": currentModelName,
                "edicoesLaboratorio": edicoesShapeKeys,
                "biometrics": [
                    "bridge": bridgeSize,
                    "leftWidth": leftWidth,
                    "rightWidth": rightWidth
                ]
            ]

            // 1. Envia os dados para a Nuvem
            let docRef = Firestore.firestore().collection("orders_stl").addDocument(data: data)
            
            // 2. Fica escutando a resposta do Robô
            var listener: ListenerRegistration?
            listener = docRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot, document.exists,
                      let dados = document.data() else { return }
                
                let status = dados["status"] as? String ?? ""
                
                // 3. O Robô terminou de gerar o .STL!
                if status == "Concluído" {
                    let stlUrl = dados["stlUrl"] as? String ?? ""
                    listener?.remove() // Desliga o ouvinte
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "✅ Arquivo 3D Pronto!",
                            message: "O servidor finalizou a modelagem. O arquivo STL da fábrica está pronto para download.",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "Compartilhar Link", style: .default) { _ in
                            guard let url = URL(string: stlUrl) else { return }
                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            
                            // 🔴 MÁGICA: Acha a tela exata que o usuário está olhando agora
                            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                                
                                var topController = window.rootViewController
                                while let presented = topController?.presentedViewController {
                                    topController = presented
                                }
                                
                                // Ajuste obrigatório para iPad não quebrar
                                if let popover = activityVC.popoverPresentationController {
                                    popover.sourceView = topController?.view
                                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                                    popover.permittedArrowDirections = []
                                }
                                
                                topController?.present(activityVC, animated: true)
                            }
                        })
                        
                        alert.addAction(UIAlertAction(title: "Fechar", style: .cancel))
                        
                        // 🔴 MÁGICA: Apresenta o alerta verde na tela atual
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

    @objc func handle3DPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        if gesture.state == .began { lastPanPoint = .zero }

        let deltaX = Float(translation.x - lastPanPoint.x)
        let deltaY = Float(translation.y - lastPanPoint.y)
        lastPanPoint = translation

        if gesture.numberOfTouches == 2 {
            let moveSensitivity: Float = 0.35
            containerNode.position.x += deltaX * moveSensitivity
            containerNode.position.y -= deltaY * moveSensitivity
        } else {
            let rotationSensitivity: Float = 0.008
            containerNode.eulerAngles.y += deltaX * rotationSensitivity
            var newX = containerNode.eulerAngles.x + (deltaY * rotationSensitivity)
            newX = max(-.pi/2, min(.pi/2, newX))
            containerNode.eulerAngles.x = newX
        }
    }

    @objc func handle3DPinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let zoomSensitivity: Float = 100.0
            let delta = Float(1.0 - gesture.scale) * zoomSensitivity
            currentCameraZ += delta
            currentCameraZ = max(10.0, min(400.0, currentCameraZ))
            sceneView.pointOfView?.position.z = currentCameraZ
            gesture.scale = 1.0
        }
    }
    
    func sendCustomizationsBack() {
        let edicoesShapeKeys: [String: Float] = [
                "Ponte": bridgeSlider.value > 0 ? bridgeSlider.value : 0,
                "Ponte_m": bridgeSlider.value < 0 ? abs(bridgeSlider.value) : 0,
                "Nasal": nasalSlider.value,
                "Ferradura": ferraduraSlider.value,
                "Largura_r": larguraSlider.value < 0 ? abs(larguraSlider.value) : 0,
                "Largura_a": larguraSlider.value > 0 ? larguraSlider.value : 0,
                "Vertical_r": verticalSlider.value < 0 ? abs(verticalSlider.value) : 0,
                "Vertical_a": verticalSlider.value > 0 ? verticalSlider.value : 0
            ]
            
            self.onApplyCustomization?(edicoesShapeKeys, selectedColorForExport, self.glassesNode)
        }
    
}

