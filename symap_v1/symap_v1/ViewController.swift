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

class ViewController: UIViewController, ARSCNViewDelegate, PKCanvasViewDelegate, UITextFieldDelegate {
    
    // CONSTANTES DE CALIBRAÇÃO CLÍNICA E FÍSICA
    enum CalibrationFactors {
        /// Origem (0.9653): Fator fixo que corrige o ínfimo desvio refracional do polímero da tela sobre a projeção infravermelha do LiDAR (Altura Pupilar).
        static let pupilHeight: Float = 0.9653
        
        /// Origem (0.98): Fator de Conforto (Comfort Factor). Representa a compensação de 2% de compressão biomecânica do material da armação (acetato/metal) sobre o tecido humano.
        static let faceWidthComfort: Float = 0.98
        
        /// Origem (0.980, 0.969, 0.977): Fatores empíricos de calibração espacial para a desprojeção de linhas 2D nativas sobre a profundidade 3D nas réguas da tela.
        static let manualHeight: Float = 0.980
        static let manualWidth: Float = 0.969
        static let manualDiagonal: Float = 0.977
    }
    
    // --- ELEMENTOS DE UI ---
    var sceneView: ARSCNView!
    
    // --- SISTEMA DE DESENHO (PencilKit) ---
    var canvasView: PKCanvasView!
    var drawingToolsContainer: UIView!
    var btnToggleDrawing: UIButton!
    var btnDrawRed: UIButton!
    var btnDrawBlack: UIButton!
    var btnDrawBlue: UIButton!
    var btnEraser: UIButton!
    var btnClearDrawing: UIButton!
    var isDrawingActive: Bool = false
    
    // GUIAS VISUAIS SUPERIORES (UX)
    var faceGuideLayer: CAShapeLayer!
    var topFeedbackLabel: UILabel!
    
    // Variáveis da Barra de Distância
    var distanceBarContainer: UIView?
    var distanceBarFill: UIView?
    var distanceInstructionLabel: UILabel?
    var distanceTimer: Timer?
    var distanceStabilityStart: Date?
    
    // --- FEATURE 1: SELETOR DE LENTES ---
    var lensTypeSegment: UISegmentedControl!
    var selectedLensType: String = "Visão Simples"
    
    // --- FEATURE 2: ESPELHO INTELIGENTE (COMPARAÇÃO) ---
    var comparisonImages: [UIImage] = []
    var btnAddToCompare: UIButton!
    var btnShowCompare: UIButton!
    var comparisonOverlay: UIView?
    
    // --- UI DE MEDIDAS ---
    var measurementsContainer: UIVisualEffectView!
    var measurementsLabel: UILabel!
    var rxEsfOD: String = "-"
    var rxCilOD: String = "-"
    var rxEixoOD: String = "-"
    var rxEsfOE: String = "-"
    var rxCilOE: String = "-"
    var rxEixoOE: String = "-"
    var rxEsfPertoOD: String = "-"
    var rxCilPertoOD: String = "-"
    var rxEixoPertoOD: String = "-"
    var rxEsfPertoOE: String = "-"
    var rxCilPertoOE: String = "-"
    var rxEixoPertoOE: String = "-"
    
    // Labels do Painel
    var lblDNPValue: UILabel!
    var lblOEValue: UILabel!
    var lblODValue: UILabel!
    var lblWidthValue: UILabel!
    var lblBridgeValue: UILabel!
    var lblHeightValue: UILabel!
    
    // UI de Nível
    var levelContainerView: UIView!
    var levelBubbleView: UIView!
    var levelTargetZone: UIView!
    var levelLabel: UILabel!
    var headLevelContainerView: UIView!
    var headLevelBubbleView: UIView!
    var headLevelTargetZone: UIView!
    var headLevelLabel: UILabel!
    
    // UI de Inclinação Frontal (Frente/Trás)
    var phonePitchContainerView: UIView!
    var phonePitchBubbleView: UIView!
    var phonePitchTargetZone: UIView!
    var phonePitchLabel: UILabel!
    var headPitchContainerView: UIView!
    var headPitchBubbleView: UIView!
    var headPitchTargetZone: UIView!
    var headPitchLabel: UILabel!
    
    // Rastreadores de Estabilidade
    var isPhonePitchLevel: Bool = false
    var isHeadPitchLevel: Bool = false
    var isPhoneLevel: Bool = false
    var isHeadLevel: Bool = false
    
    // UI de Contagem Regressiva
    var countdownLabel: UILabel!
    
    // UI DA RÉGUA DE ALTURA PUPILAR
    var heightLineView: UIView!
    var heightLineLabel: UILabel!
    
    // --- FERRAMENTA DE MEDIÇÃO MANUAL DA ARMAÇÃO ---
    var measurementTypeSegment: UISegmentedControl!
    var btnSaveManual: UIButton!
    var manualMeasureContainer: UIView!
    var manualHandleA: UIView!
    var manualHandleB: UIView!
    var manualLineLayer: CAShapeLayer!
    var manualMeasureLabel: UILabel!
    
    // Variáveis Manuais
    var manualFrameHeight: Float = 0.0
    var manualFrameWidth: Float = 0.0
    var manualFrameDiagonal: Float = 0.0
    var currentManualMode: Int = 0
    
    // Memória do PDF e "Fake Freeze"
    var savedFrontalSnapshot: UIImage?
    var freezeOverlayImageView: UIImageView?
    
    // Botões Principais
    var tutorialButton: UIButton!
    var startCaptureButton: UIButton!
    var captureButton: UIButton!
    var menuButton: UIButton!
    
    // Botão de Guias AR
    var btnToggleGuides: UIButton!
    var logoutButton: UIButton!
    
    // --- ESTADO DO SISTEMA ---
        var faceNode: SCNNode?
        var glassesNode: SCNNode?
        var currentCloudModel: CloudGlassModel?
        var glassesYOffset: Float = 0.02
        var isFrozen: Bool = false
        var smoothHeadRoll: Float = 0.0
        var isAuthorized: Bool = false
        var isDataCollectionEnabled: Bool = false
    
    
    // ESTADO DAS GUIAS VISUAIS AR (MÁSCARA TECH)
    var isGuidesActive: Bool = false
    var techMaskNode: SCNNode?
    var pupilLineNode: SCNNode?
    var bridgeLineNode: SCNNode?
    var bridgeLeftArrow: SCNNode?
    var bridgeRightArrow: SCNNode?
    var templeLineNode: SCNNode?
    var templeLeftArrow: SCNNode?
    var templeRightArrow: SCNNode?
    
    let motionManager = CMMotionManager()
    var countdownTimer: Timer?
    var countdownValue: Int = 3
    var isCaptureSessionActive: Bool = false
    var stabilityStartTime: Date?
    var lastFaceDetectionTime: TimeInterval = 0
    var isFaceDetected: Bool {
        return (Date().timeIntervalSince1970 - lastFaceDetectionTime) < 0.5
    }
    
    // Cache de Posição
    var lastLeftEyeWorldPos: SCNVector3?
    var lastRightEyeWorldPos: SCNVector3?
    var pupillaryHeight: Float = 0.0
    var verticalPupilDiff: Float = 0.0
    
    // --- MAPEAMENTO VISUAL (HEAD-MOVER VS EYE-MOVER) ---
    var btnVisionMap: UIButton!
    var isMappingVision: Bool = false
    var visionMappingView: ARSCNView?
    var visionMapDot: UIView?
    var mappingInstructionBox: UIView?
    var headMoveScore: Float = 0.0
    var eyeMoveScore: Float = 0.0
    var visionBehaviorResult: String = "Pendente"
    
    // Tutorial
    var tutorialStepIndex = 0
    var tutorialOverlay: UIView?
    var tutorialLabel: UILabel?
    var dimmingView: UIView?
    var tutorialNextButton: UIButton?
    var tutorialArrowView: UIView?
    
    // --- MEDIDAS ---
    var dnpTotal: Float = 0.0
    var dnpEsq: Float = 0.0
    var dnpDir: Float = 0.0
    var dnpPertoTotal: Float = 0.0
    var dnpPertoEsq: Float = 0.0
    var dnpPertoDir: Float = 0.0
    
    var faceWidth: Float = 0.0
    var faceWidthLeft: Float = 0.0
    var faceWidthRight: Float = 0.0
    var noseBridgeWidth: Float = 0.0
    var faceShape: String = "Calculando..."
    var frameSuggestion: String = "..."
    var patientGender: String = "Prefiro não informar"
    var jawWidth: Float = 0.0
    
    var sessionStartTime: Date?
    var nasalProfile: String = "Plano"
    
    var patientName: String = "Paciente Não Identificado"
    var patientCPF: String = "000.000.000-00"
    
    // --- LGPD E CONSENTIMENTO BIOMÉTRICO ---
    var hasGivenLGPDConsent: Bool = false
    var lgpdOverlay: UIView?
    var lgpdCheckbox: UIButton!
    var lgpdConfirmButton: UIButton!
    var isLgpdChecked: Bool = false
    
    var lgpdScrollObservation: NSKeyValueObservation? // Memória do observador de rolagem
    var isPdfGenerated: Bool = false // Trava de segurança do resumo clínico
    
    // =========================================================
    // COFRE DE MEMÓRIA
    // =========================================================
    var safeFaceCache: SCNNode?
    var safeCameraCache: SCNNode?
    var safeSnapshotCache: UIImage?
    var originalBackgroundCache: Any?
    var originalCameraNodeCache: SCNNode?
    
    // --- WIZARD (PASSOS DE APROVAÇÃO E RECEITA) ---
    var approvalContainer: UIView!
    var capturedImageView: UIImageView!
    var prescriptionWizardContainer: UIView!
    var wizardLensSegment: UISegmentedControl!
    var wizardPertoContainer: UIView!
    var pertoModeSegment: UISegmentedControl!
    
    var wEsfOD: UITextField!, wCilOD: UITextField!, wEixoOD: UITextField!
    var wEsfOE: UITextField!, wCilOE: UITextField!, wEixoOE: UITextField!
    var wEsfPertoOD: UITextField!, wCilPertoOD: UITextField!, wEixoPertoOD: UITextField!
    var wEsfPertoOE: UITextField!, wCilPertoOE: UITextField!, wEixoPertoOE: UITextField!
    var summaryContainer: UIView!
    var isMappingVisionCompleted: Bool = false
    
    // --- ESTADO DO SISTEMA ---
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        let successFeedback = UINotificationFeedbackGenerator()
        let speechSynthesizer = AVSpeechSynthesizer()

        func warmupVoiceEngine() {
            // 🔴 MÁGICA: Pré-aquece o motor de voz silenciosamente (Volume 0) para remover o atraso inicial
            let utterance = AVSpeechUtterance(string: " ")
            utterance.volume = 0
            speechSynthesizer.speak(utterance)
        }

        func speakText(_ text: String) {
            let utterance = AVSpeechUtterance(string: text)
            
            // 🔴 Busca a voz Premium/Enhanced em Português para remover o tom robotizado
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let premiumVoice = voices.first(where: { $0.language == "pt-BR" && $0.quality == .enhanced }) {
                utterance.voice = premiumVoice
            } else if let premiumVoice2 = voices.first(where: { $0.language == "pt-BR" && $0.quality == .premium }) {
                utterance.voice = premiumVoice2
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
            }
            
            // Ajustes finos de humanização (Pitch levemente mais agudo/amigável)
            utterance.rate = 0.53
            utterance.pitchMultiplier = 1.05
            
            // 🔴 Para a fala anterior IMEDIATAMENTE para não "encavalar" e não gerar delay
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechSynthesizer.speak(utterance)
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupUI()
        setupDrawingSystem()
        setupHeightRulerUI()
        setupLevelUI()
        setupCountdownUI()
        setupManualMeasurementUI()
        setupLensSelectorUI()
        disableAppControls()
        verifyLicenseAndLoadModels()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
        
        // INICIA A CONSTRUÇÃO DOS PASSOS DO WIZARD
        setupWizardUI()
        warmupVoiceEngine()
            }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAuthorized {
            startARSession()
            startLevelMonitoring()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasGivenLGPDConsent {
            showLGPDModal()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        motionManager.stopDeviceMotionUpdates()
        resetCountdown()
    }
    
    func startARSession() {
        // 🔴 NOVO: Baixa a lista de armações da Ótica em segundo plano
        CloudManager.shared.fetchMyModels { _ in }
        self.sessionStartTime = Date()
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func startLevelMonitoring() {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                
                let gx = data.gravity.x
                let gy = data.gravity.y
                let gz = data.gravity.z
                
                var rollAngle: Double = 0.0
                
                // 🔴 INTELIGÊNCIA FÍSICA: Auto-detecta a orientação do hardware pelo vetor gravitacional puro.
                // Isso ignora travas de tela do iOS e foca exclusivamente na posição real do iPad no espaço.
                if abs(gx) > abs(gy) {
                    // O iPad está DEITADO na Horizontal (Landscape)
                    if gx > 0 {
                        // Câmera voltada para um dos lados
                        rollAngle = atan2(-gy, gx)
                    } else {
                        // Câmera voltada para o lado oposto
                        rollAngle = atan2(gy, -gx)
                    }
                } else {
                    // O iPad está EM PÉ na Vertical (Portrait)
                    if gy < 0 {
                        // Posição normal (Câmera para cima)
                        rollAngle = atan2(gx, -gy)
                    } else {
                        // Cabeça para baixo
                        rollAngle = atan2(-gx, gy)
                    }
                }
                
                // Atualiza a bolha lateral com o ângulo suavizado
                self.updatePhoneLevelUI(roll: rollAngle)
                
                // O eixo Z (Profundidade / Inclinação Frontal) é imune à rotação do aparelho,
                // então mantemos a leitura primária direta, sem modificações!
                let pitchAngle = gz
                self.updatePhonePitchUI(pitch: pitchAngle)
                
                self.checkCaptureStability()
            }
        }
    
    func updatePhoneLevelUI(roll: Double) {
        let threshold = 0.05
        let isLevel = abs(roll) < threshold
        self.isPhoneLevel = isLevel
        let maxTilt = 1.5
        let containerWidth = levelContainerView.bounds.width
        let center = containerWidth / 2
        let clampedRoll = min(max(roll, -maxTilt), maxTilt)
        let normalizedOffset = CGFloat(clampedRoll / maxTilt)
        let newX = center + (normalizedOffset * (center - 15))
        UIView.animate(withDuration: 0.1) {
            self.levelBubbleView.center.x = newX
            self.levelBubbleView.backgroundColor = isLevel ? .green : .red
            self.levelContainerView.layer.borderColor = isLevel ? UIColor.green.withAlphaComponent(0.5).cgColor : UIColor.red.withAlphaComponent(0.3).cgColor
        }
    }
    
    func updateHeadLevelUI(angle: Float) {
        let threshold: Float = 0.12
        let isLevel = abs(angle) < threshold
        self.isHeadLevel = isLevel
        let maxTilt: Float = 3.0
        let containerWidth = headLevelContainerView.bounds.width
        let center = containerWidth / 2
        let clampedAngle = min(max(angle, -maxTilt), maxTilt)
        let normalizedOffset = CGFloat(clampedAngle / maxTilt)
        let newX = center + (normalizedOffset * (center - 15))
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.headLevelBubbleView.center.x = newX
                self.headLevelBubbleView.backgroundColor = isLevel ? .green : .red
                self.headLevelContainerView.layer.borderColor = isLevel ? UIColor.green.withAlphaComponent(0.5).cgColor : UIColor.red.withAlphaComponent(0.3).cgColor
            }
        }
    }
    
    func updatePhonePitchUI(pitch: Double) {
        let threshold = 0.10
        let isLevel = abs(pitch) < threshold
        self.isPhonePitchLevel = isLevel
        let maxTilt = 1.0
        let containerWidth = phonePitchContainerView.bounds.width
        let center = containerWidth / 2
        let clampedPitch = min(max(pitch, -maxTilt), maxTilt)
        let normalizedOffset = CGFloat(clampedPitch / maxTilt)
        let newX = center + (normalizedOffset * (center - 15))
        UIView.animate(withDuration: 0.1) {
            self.phonePitchBubbleView.center.x = newX
            self.phonePitchBubbleView.backgroundColor = isLevel ? .green : .red
            self.phonePitchContainerView.layer.borderColor = isLevel ? UIColor.green.withAlphaComponent(0.5).cgColor : UIColor.red.withAlphaComponent(0.3).cgColor
        }
    }
    
    func updateHeadPitchUI(angle: Float) {
        let threshold: Float = 0.12
        let isLevel = abs(angle) < threshold
        self.isHeadPitchLevel = isLevel
        let maxTilt: Float = 0.5
        let containerWidth = headPitchContainerView.bounds.width
        let center = containerWidth / 2
        let clampedAngle = min(max(angle, -maxTilt), maxTilt)
        let normalizedOffset = CGFloat(clampedAngle / maxTilt)
        let newX = center + (normalizedOffset * (center - 15))
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.headPitchBubbleView.center.x = newX
                self.headPitchBubbleView.backgroundColor = isLevel ? .green : .red
                self.headPitchContainerView.layer.borderColor = isLevel ? UIColor.green.withAlphaComponent(0.5).cgColor : UIColor.red.withAlphaComponent(0.3).cgColor
            }
        }
    }
    
    // --- CAPTURA E ESTABILIDADE ---
    @objc func onStartCaptureTapped() {
        if isFrozen {
            toggleFreeze()
            return
        }
        isCaptureSessionActive = true
        stabilityStartTime = nil
        startCaptureButton.setTitle("Aguardando...", for: .normal)
        startCaptureButton.backgroundColor = .orange
        resetCountdown()
    }
    
    func checkCaptureStability() {
        guard isCaptureSessionActive, !isFrozen else { return }
        
        // 🔴 CORREÇÃO 3: Garante que o termômetro lateral exista no modo Captura
        if self.distanceBarContainer == nil {
            self.showDistanceBar()
        }
        self.distanceBarContainer?.isHidden = false
        self.distanceInstructionLabel?.isHidden = true // Ocultamos o texto lateral porque já usamos o letreiro do topo!
        
        var currentDistance: Float = 0.0
        if let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView {
            let cx = (lEye.x + rEye.x) / 2.0
            let cy = (lEye.y + rEye.y) / 2.0
            let cz = (lEye.z + rEye.z) / 2.0
            let camPos = cam.worldPosition
            currentDistance = sqrt(pow(camPos.x - cx, 2) + pow(camPos.y - cy, 2) + pow(camPos.z - cz, 2))
        }
        
        // --- MOTOR DO SENSOR LATERAL ---
        let targetDistance: Float = 0.375
        let diff = currentDistance - targetDistance
        let barH: CGFloat = 200
        let mappedY = CGFloat((diff * 500))
        var fillHeight = (barH / 2) - mappedY
        fillHeight = max(0, min(barH, fillHeight))
        
        let isDistancePerfect = currentDistance >= 0.35 && currentDistance <= 0.40
        let allConditionsMet = isPhoneLevel && isHeadLevel && isPhonePitchLevel && isHeadPitchLevel && isFaceDetected && isDistancePerfect
        
        DispatchQueue.main.async {
            // Animação da barra subindo e descendo conforme a distância
            UIView.animate(withDuration: 0.1) {
                self.distanceBarFill?.frame = CGRect(x: 0, y: barH - fillHeight, width: 20, height: fillHeight)
                if isDistancePerfect {
                    self.distanceBarFill?.backgroundColor = .systemGreen
                } else if currentDistance > 0.40 {
                    self.distanceBarFill?.backgroundColor = .systemOrange // Longe
                } else {
                    self.distanceBarFill?.backgroundColor = .systemRed // Perto
                }
            }
            
            // Avaliação de Estabilidade Tradicional
            if allConditionsMet {
                if self.stabilityStartTime == nil {
                    self.stabilityStartTime = Date()
                    self.topFeedbackLabel?.text = "PERFEITO! MANTENHA A POSICAO..."
                    self.topFeedbackLabel?.textColor = .green
                    self.faceGuideLayer?.strokeColor = UIColor.green.cgColor
                    self.startCaptureButton.setTitle("Aguardando...", for: .normal)
                    self.startCaptureButton.backgroundColor = .orange
                } else {
                    let elapsed = Date().timeIntervalSince(self.stabilityStartTime!)
                    if elapsed >= 1.0 { self.startCountdown() }
                }
            } else {
                self.stabilityStartTime = nil
                self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
                if self.countdownTimer != nil {
                    self.finishCountdownAndCapture(aborted: true)
                } else {
                    if !self.isFaceDetected {
                        self.topFeedbackLabel?.text = "ROSTO NÃO DETECTADO"
                        self.topFeedbackLabel?.textColor = .red
                    } else if currentDistance < 0.35 {
                        self.topFeedbackLabel?.text = "MUITO PERTO!\nAfaste o celular do rosto."
                        self.topFeedbackLabel?.textColor = .orange
                    } else if currentDistance > 0.40 {
                        self.topFeedbackLabel?.text = "MUITO LONGE!\nAproxime o celular do rosto."
                        self.topFeedbackLabel?.textColor = .orange
                    } else {
                        self.topFeedbackLabel?.text = "MANTENHA OS NIVEIS CENTRALIZADOS"
                        self.topFeedbackLabel?.textColor = .yellow
                    }
                    self.startCaptureButton.setTitle("Alinhando...", for: .normal)
                    self.startCaptureButton.backgroundColor = .orange
                }
            }
        }
    }
    
    func startCountdown() {
        if countdownTimer != nil { return }
        guard isCaptureSessionActive, !isFrozen else { return }
        countdownValue = 3
        DispatchQueue.main.async {
            self.countdownLabel.text = "\(self.countdownValue)"
            self.countdownLabel.isHidden = false
            self.startCaptureButton.setTitle("Capturando...", for: .normal)
            self.startCaptureButton.backgroundColor = .green
            
            self.topFeedbackLabel?.text = "MANTENHA A POSIÇÃO..."
            self.topFeedbackLabel?.textColor = .green
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if !self.isPhoneLevel || !self.isHeadLevel || !self.isPhonePitchLevel || !self.isHeadPitchLevel {
                self.finishCountdownAndCapture(aborted: true)
                return
            }
            self.countdownValue -= 1
            if self.countdownValue > 0 {
                self.countdownLabel.text = "\(self.countdownValue)"
                self.pulseAnimation(view: self.countdownLabel)
            } else {
                self.finishCountdownAndCapture(aborted: false)
            }
        }
    }
    
    func finishCountdownAndCapture(aborted: Bool) {
        isCaptureSessionActive = false
        stabilityStartTime = nil
        resetCountdown()
        if aborted {
            DispatchQueue.main.async {
                self.topFeedbackLabel?.text = "MOVEU! TENTE NOVAMENTE"
                self.topFeedbackLabel?.textColor = .red
                self.startCaptureButton.setTitle("Iniciar Captura", for: .normal)
                self.startCaptureButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
            }
        } else {
            DispatchQueue.main.async {
                let flash = UIView(frame: self.view.bounds)
                flash.backgroundColor = .white
                flash.alpha = 0.0
                self.view.addSubview(flash)
                UIView.animate(withDuration: 0.1, animations: { flash.alpha = 0.7 }) { _ in
                    UIView.animate(withDuration: 0.2) { flash.alpha = 0.0 } completion: { _ in flash.removeFromSuperview() }
                }
                
                // NOVO FLUXO WIZARD: Chama a Tela 1 (Aprovação) em vez de ir direto pro Freeze
                self.startApprovalStep()
            }
        }
    }
    func resetCountdown() {
        guard countdownTimer != nil else { return }
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = 3
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.countdownLabel.alpha = 0.0
            } completion: { _ in
                self.countdownLabel.isHidden = true
                self.countdownLabel.alpha = 1.0
            }
        }
    }
    
    
    func pulseAnimation(view: UIView) {
        UIView.animate(withDuration: 0.1, animations: { view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) }) { _ in
            UIView.animate(withDuration: 0.1) { view.transform = .identity }
        }
    }
    
    // --- SETUP UI ---
    func setupUI() {
        logoutButton = UIButton(frame: CGRect(x: view.bounds.width - 80, y: 40, width: 60, height: 35))
        logoutButton.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        logoutButton.setTitle("Sair", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.layer.cornerRadius = 8
        logoutButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        measurementsContainer = UIVisualEffectView(effect: blurEffect)
        measurementsContainer.frame = CGRect(x: 15, y: 80, width: view.bounds.width - 30, height: 130)
        measurementsContainer.layer.cornerRadius = 12
        measurementsContainer.clipsToBounds = true
        view.addSubview(measurementsContainer)
        
        measurementsLabel = UILabel(frame: measurementsContainer.bounds)
        measurementsLabel.textAlignment = .center
        measurementsLabel.textColor = .white
        measurementsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        measurementsLabel.numberOfLines = 0
        measurementsLabel.text = ""
        measurementsContainer.contentView.addSubview(measurementsLabel)
        
        let containerW = measurementsContainer.bounds.width
        let colW = containerW / 3
        
        func createInfoLabel(title: String, frame: CGRect) -> UILabel {
            let lblTitle = UILabel(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: 14))
            lblTitle.text = title.uppercased()
            lblTitle.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            lblTitle.textColor = UIColor.lightGray
            lblTitle.textAlignment = .center
            measurementsContainer.contentView.addSubview(lblTitle)
            let lblVal = UILabel(frame: CGRect(x: frame.minX, y: frame.minY + 14, width: frame.width, height: 22))
            lblVal.text = "--"
            lblVal.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
            lblVal.textColor = .white
            lblVal.textAlignment = .center
            measurementsContainer.contentView.addSubview(lblVal)
            return lblVal
        }
        
        lblDNPValue = createInfoLabel(title: "DNP TOTAL", frame: CGRect(x: 0, y: 15, width: colW, height: 40))
        lblOEValue = createInfoLabel(title: "OE", frame: CGRect(x: colW, y: 15, width: colW, height: 40))
        lblODValue = createInfoLabel(title: "OD", frame: CGRect(x: colW*2, y: 15, width: colW, height: 40))
        
        let div = UIView(frame: CGRect(x: 10, y: 65, width: containerW - 20, height: 1))
        div.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        measurementsContainer.contentView.addSubview(div)
        
        lblWidthValue = createInfoLabel(title: "LARGURA", frame: CGRect(x: 0, y: 75, width: colW, height: 40))
        lblBridgeValue = createInfoLabel(title: "PONTE", frame: CGRect(x: colW, y: 75, width: colW, height: 40))
        lblHeightValue = createInfoLabel(title: "ALTURA (H)", frame: CGRect(x: colW*2, y: 75, width: colW, height: 40))
        
        let btnY = view.bounds.height - 100
        let centerX = view.bounds.width / 2
        
        startCaptureButton = UIButton(frame: CGRect(x: centerX - 100, y: btnY - 90, width: 200, height: 55))
        startCaptureButton.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        startCaptureButton.setTitle("Iniciar Captura", for: .normal)
        startCaptureButton.setTitleColor(.white, for: .normal)
        startCaptureButton.layer.cornerRadius = 27.5
        startCaptureButton.layer.borderWidth = 2
        startCaptureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        startCaptureButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        startCaptureButton.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        startCaptureButton.layer.shadowOpacity = 0.4
        startCaptureButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        startCaptureButton.layer.shadowRadius = 8
        startCaptureButton.addTarget(self, action: #selector(onStartCaptureTapped), for: .touchUpInside)
        view.addSubview(startCaptureButton)
        
        captureButton = UIButton(frame: CGRect(x: centerX - 60, y: btnY, width: 120, height: 50))
        captureButton.backgroundColor = .systemBlue
        captureButton.layer.cornerRadius = 25
        captureButton.setTitle("Avançar", for: .normal)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        captureButton.addTarget(self, action: #selector(handleNextAfterManualMeasurements), for: .touchUpInside)
        captureButton.isHidden = true
        view.addSubview(captureButton)
        
        let buttonSize: CGFloat = 55
        let glassBackground = UIColor(white: 0.15, alpha: 0.85)
        
        func createSideButton(icon: String, action: Selector) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = glassBackground
            btn.layer.cornerRadius = buttonSize / 2
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            btn.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
            btn.addTarget(self, action: action, for: .touchUpInside)
            return btn
        }
        
        btnToggleGuides = createSideButton(icon: "ruler.fill", action: #selector(toggleGuides))
        btnToggleDrawing = createSideButton(icon: "pencil.tip.crop.circle", action: #selector(toggleDrawingPanel))
        btnToggleDrawing.isHidden = true
        btnAddToCompare = createSideButton(icon: "camera.viewfinder", action: #selector(addToComparison))
        btnAddToCompare.isHidden = true
        tutorialButton = createSideButton(icon: "book.fill", action: #selector(startTutorial))
        
        // 🔴 Botão do Provador Virtual (Try-On) alinhado e minimalista
                menuButton = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 192.5, width: 60, height: 60))
                menuButton.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
                menuButton.layer.cornerRadius = 30
                menuButton.layer.borderWidth = 1.5
                menuButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                
                // Ícone Minimalista Nativo da Apple (SF Symbols)
                let glassConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                menuButton.setImage(UIImage(systemName: "eyeglasses", withConfiguration: glassConfig), for: .normal)
                menuButton.tintColor = .white
                
                menuButton.addTarget(self, action: #selector(showModelSelection), for: .touchUpInside)
                view.addSubview(menuButton)
        
        // NOVO UX: Menu Inferior Limpo (Apenas Espelho Comparativo e Desenho Livre)
        let bottomToolsStack = UIStackView(arrangedSubviews: [btnAddToCompare, btnToggleDrawing])
        bottomToolsStack.axis = .horizontal
        bottomToolsStack.spacing = 25
        bottomToolsStack.distribution = .equalSpacing
        bottomToolsStack.translatesAutoresizingMaskIntoConstraints = false
        bottomToolsStack.isHidden = true // Esconde no Passo 1 e 2 da triagem
        view.addSubview(bottomToolsStack)
        
        NSLayoutConstraint.activate([
            bottomToolsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomToolsStack.bottomAnchor.constraint(equalTo: startCaptureButton.topAnchor, constant: -20)
        ])
        
        // APLICAÇÃO DE UX: Liga a máscara 3D por padrão e esconde métricas ao vivo
        isGuidesActive = true
        measurementsContainer.isHidden = true
        
        btnShowCompare = createSideButton(icon: "square.split.2x1.fill", action: #selector(showComparisonUI))
        btnShowCompare.tintColor = .white
        btnShowCompare.backgroundColor = .systemPink
        btnShowCompare.isHidden = true
        view.addSubview(btnShowCompare)
        
        // Mantemos apenas a âncora do botão de comparar
        NSLayoutConstraint.activate([
            btnShowCompare.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            btnShowCompare.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])
        
        // =======================================================
        // 🔴 NOVO UX: PAINEL DE AVISOS NO TOPO E MÁSCARA DO ROSTO
        // =======================================================
        topFeedbackLabel = UILabel(frame: CGRect(x: 20, y: 150, width: view.bounds.width - 40, height: 60))
        topFeedbackLabel.textAlignment = .center
        topFeedbackLabel.textColor = .yellow
        
        // 🔴 CORREÇÃO 1: Fonte em peso Regular (Normal) e sombra mais discreta
        topFeedbackLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        topFeedbackLabel.numberOfLines = 0
        topFeedbackLabel.layer.shadowColor = UIColor.black.cgColor
        topFeedbackLabel.layer.shadowRadius = 2.0
        topFeedbackLabel.layer.shadowOpacity = 0.6
        topFeedbackLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        topFeedbackLabel.text = "POSICIONE O ROSTO NA MARCAÇÃO"
        view.addSubview(topFeedbackLabel)
        
        // 🔴 CORREÇÃO 2: Ampliação significativa da área da máscara (de 200x280 para 260x380)
        let ovalW: CGFloat = 260
        let ovalH: CGFloat = 380
        let ovalX = (view.bounds.width - ovalW) / 2
        let ovalY = (view.bounds.height - ovalH) / 2 - 30
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW, height: ovalH))
        
        faceGuideLayer = CAShapeLayer()
        faceGuideLayer.path = ovalPath.cgPath
        faceGuideLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        faceGuideLayer.fillColor = UIColor.clear.cgColor
        faceGuideLayer.lineWidth = 3.0
        
        //CORREÇÃO 3: Padrão do tracejado restaurado corretamente
        faceGuideLayer.lineDashPattern = [1, 2]
        
        view.layer.insertSublayer(faceGuideLayer, below: topFeedbackLabel.layer)
    }
    
    func showMappingInstruction(title: String, description: String, action: Selector) {
            let boxW: CGFloat = 320
            // CORREÇÃO: Altura da caixa ampliada de 260 para 340 para comportar todo o texto
            let boxH: CGFloat = 340
            let boxY = (view.bounds.height - boxH) / 2
            let boxX = (view.bounds.width - boxW) / 2
            
            let box = UIView(frame: CGRect(x: boxX, y: boxY, width: boxW, height: boxH))
            box.layer.cornerRadius = 20
            box.layer.borderWidth = 1
            box.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            box.layer.shadowColor = UIColor.black.cgColor
            box.layer.shadowOpacity = 0.5
            box.layer.shadowRadius = 15
            
            let blur = UIBlurEffect(style: .systemThinMaterialDark)
            let blurView = UIVisualEffectView(effect: blur)
            blurView.frame = box.bounds
            blurView.layer.cornerRadius = 20
            blurView.clipsToBounds = true
            box.addSubview(blurView)
            
            let lblTitle = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 30))
            lblTitle.text = title
            lblTitle.textColor = .white
            lblTitle.font = UIFont.boldSystemFont(ofSize: 18)
            lblTitle.textAlignment = .center
            box.addSubview(lblTitle)
            
            //CORREÇÃO: Área de texto ampliada de 90 para 160 pixels de altura
            let lblDesc = UILabel(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 160))
            lblDesc.text = description
            lblDesc.textColor = .lightGray
            lblDesc.font = UIFont.systemFont(ofSize: 14)
            lblDesc.numberOfLines = 0
            lblDesc.textAlignment = .center
            box.addSubview(lblDesc)
            
            // CORREÇÃO: Botão empurrado mais para baixo (y: 250)
            let btnConfirm = UIButton(frame: CGRect(x: 40, y: 250, width: boxW - 80, height: 50))
            btnConfirm.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            btnConfirm.setTitle("Confirmar", for: .normal)
            btnConfirm.setTitleColor(.black, for: .normal)
            btnConfirm.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            btnConfirm.layer.cornerRadius = 25
            btnConfirm.addTarget(self, action: action, for: .touchUpInside)
            box.addSubview(btnConfirm)
            
            view.addSubview(box)
            mappingInstructionBox = box
            
            box.alpha = 0
            box.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3) {
                box.alpha = 1.0
                box.transform = .identity
            }
        }
    
    
        @objc func preparePhase1Alignment() {
            UIView.animate(withDuration: 0.2, animations: { self.mappingInstructionBox?.alpha = 0 }) { _ in
                self.mappingInstructionBox?.removeFromSuperview()

                // 🔴 CORREÇÃO 2: Reativa a Silhueta e os Sensores visuais iguais aos da captura original
                self.topFeedbackLabel?.isHidden = false
                self.faceGuideLayer?.isHidden = false
                self.levelContainerView.isHidden = false
                self.levelLabel.isHidden = false
                self.headLevelContainerView.isHidden = false
                self.headLevelLabel.isHidden = false
                self.phonePitchContainerView.isHidden = false
                self.phonePitchLabel.isHidden = false
                self.headPitchContainerView.isHidden = false
                self.headPitchLabel.isHidden = false

                self.isMappingVision = true
                self.headMoveScore = 0.0
                self.eyeMoveScore = 0.0
                
                self.startLevelMonitoring()
                self.checkVisionStabilityLoop(targetDistance: 0.40) // Inicia exigindo distância de longe
            }
        }

    func checkVisionStabilityLoop(targetDistance: Float) {
            self.distanceTimer?.invalidate()
            self.showDistanceBar()
            self.distanceBarContainer?.isHidden = false
            self.distanceInstructionLabel?.isHidden = true
            self.stabilityStartTime = nil

            self.distanceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                // 🔴 CORREÇÃO DO ERRO: Isolamos o unwrap da memória. Agora o 'self' é 100% seguro no restante da função!
                guard let self = self else { return }

                guard let cam = self.visionMappingView?.pointOfView,
                      let faceAnchor = self.visionMappingView?.session.currentFrame?.anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                    self.topFeedbackLabel?.text = "ROSTO NÃO DETECTADO"
                    self.topFeedbackLabel?.textColor = .red
                    self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
                    return
                }

                let leftEye = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)
                let rightEye = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
                let cx = (leftEye.columns.3.x + rightEye.columns.3.x) / 2.0
                let cy = (leftEye.columns.3.y + rightEye.columns.3.y) / 2.0
                let cz = (leftEye.columns.3.z + rightEye.columns.3.z) / 2.0
                let currentDistance = sqrt(pow(cam.worldPosition.x - cx, 2) + pow(cam.worldPosition.y - cy, 2) + pow(cam.worldPosition.z - cz, 2))

                let diff = currentDistance - targetDistance
                let barH: CGFloat = 200
                let mappedY = CGFloat((diff * 500))
                var fillHeight = (barH / 2) - mappedY
                fillHeight = max(0, min(barH, fillHeight))

                let isDistancePerfect = abs(diff) <= 0.03
                let allConditionsMet = self.isPhoneLevel && self.isHeadLevel && self.isPhonePitchLevel && self.isHeadPitchLevel && isDistancePerfect

                UIView.animate(withDuration: 0.1) {
                    self.distanceBarFill?.frame = CGRect(x: 0, y: barH - fillHeight, width: 20, height: fillHeight)
                    if isDistancePerfect {
                        self.distanceBarFill?.backgroundColor = .systemGreen
                    } else if diff > 0 {
                        self.distanceBarFill?.backgroundColor = .systemOrange // Longe
                    } else {
                        self.distanceBarFill?.backgroundColor = .systemRed // Perto
                    }
                }

                if allConditionsMet {
                    if self.stabilityStartTime == nil {
                        self.stabilityStartTime = Date()
                        self.topFeedbackLabel?.text = "PERFEITO! SEGURE FIRME..."
                        self.topFeedbackLabel?.textColor = .green
                        self.faceGuideLayer?.strokeColor = UIColor.green.cgColor
                    } else {
                        let elapsed = Date().timeIntervalSince(self.stabilityStartTime!)
                        if elapsed >= 1.0 {
                            timer.invalidate()
                            self.runVisionMappingCountdown(targetDistance: targetDistance)
                        }
                    }
                } else {
                    self.stabilityStartTime = nil
                    self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor

                    if currentDistance < targetDistance - 0.03 {
                        self.topFeedbackLabel?.text = "MUITO PERTO!\nAfaste o celular do rosto."
                        self.topFeedbackLabel?.textColor = .orange
                    } else if currentDistance > targetDistance + 0.03 {
                        self.topFeedbackLabel?.text = "MUITO LONGE!\nAproxime o celular do rosto."
                        self.topFeedbackLabel?.textColor = .orange
                    } else {
                        self.topFeedbackLabel?.text = "NIVELE AS BOLHAS VERDES NO CENTRO"
                        self.topFeedbackLabel?.textColor = .yellow
                    }
                }
            }
        }

    @objc func startVisionMappingFromWizard() {
            self.measurementsContainer.isHidden = true
            self.manualMeasureContainer.isHidden = true
            self.measurementTypeSegment.isHidden = true
            self.captureButton.isHidden = true
            self.startCaptureButton.isHidden = true
            self.heightLineView.isHidden = true
            if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) {
                bottomStack.isHidden = true
            }

            self.visionMappingView = ARSCNView(frame: self.view.bounds)
            self.visionMappingView?.delegate = self
            self.visionMappingView?.backgroundColor = .clear
            self.view.insertSubview(self.visionMappingView!, belowSubview: self.measurementsContainer)

            let config = ARFaceTrackingConfiguration()
            self.visionMappingView?.session.run(config)

            if visionMapDot == nil {
                let dot = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                dot.backgroundColor = .systemPink
                dot.layer.cornerRadius = 20
                dot.isHidden = true
                view.addSubview(dot)
                visionMapDot = dot
            }

            // 🔴 NOVO: A IA se apresenta por voz!
            self.speakText("Vamos mapear o seu comportamento visual. Por favor, confirme na tela e posicione o rosto na marcação.")

            self.showMappingInstruction(
                title: "FASE 1: Visão Periférica",
                description: "Vamos mapear o seu comportamento visual para lentes \(self.selectedLensType).\n\nAo confirmar, posicione seu rosto na marcação e nivele o celular. Após a contagem de 3 segundos, siga a bolinha rosa apenas com o olhar.",
                action: #selector(self.preparePhase1Alignment)
            )
        }

        func runVisionMappingCountdown(targetDistance: Float) {
            self.countdownValue = 3
            self.countdownLabel.text = "\(self.countdownValue)"
            self.countdownLabel.isHidden = false
            self.topFeedbackLabel?.text = "MANTENHA A POSIÇÃO..."
            self.topFeedbackLabel?.textColor = .green
            
            // 🔴 NOVO: Vibração de sucesso ao atingir o foco e Início da contagem!
            self.successFeedback.notificationOccurred(.success)

            self.distanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }

                if !self.isPhoneLevel || !self.isHeadLevel || !self.isPhonePitchLevel || !self.isHeadPitchLevel {
                    timer.invalidate()
                    self.countdownLabel.isHidden = true
                    self.topFeedbackLabel?.text = "MOVEU! REINICIANDO..."
                    self.topFeedbackLabel?.textColor = .red
                    self.faceGuideLayer?.strokeColor = UIColor.red.cgColor
                    
                    // 🔴 NOVO: Alerta de voz se o paciente se mexer
                    self.speakText("Você se moveu. Por favor, alinhe novamente.")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.checkVisionStabilityLoop(targetDistance: targetDistance)
                    }
                    return
                }

                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    self.countdownLabel.text = "\(self.countdownValue)"
                    self.pulseAnimation(view: self.countdownLabel)
                    
                    // 🔴 NOVO: Fala os números 3, 2, 1 acompanhados de pulso físico
                    self.speakText("\(self.countdownValue)")
                    self.impactFeedback.impactOccurred(intensity: 1.0)
                    
                } else {
                    timer.invalidate()
                    self.countdownLabel.isHidden = true
                    self.hideDistanceBar()

                    UIView.animate(withDuration: 0.3) {
                        self.topFeedbackLabel?.isHidden = true
                        self.faceGuideLayer?.isHidden = true
                        self.levelContainerView.isHidden = true
                        self.levelLabel.isHidden = true
                        self.headLevelContainerView.isHidden = true
                        self.headLevelLabel.isHidden = true
                        self.phonePitchContainerView.isHidden = true
                        self.phonePitchLabel.isHidden = true
                        self.headPitchContainerView.isHidden = true
                        self.headPitchLabel.isHidden = true
                    }

                    if targetDistance == 0.40 {
                        self.speakText("Siga a bolinha com o olhar, sem virar o pescoço.")
                        self.runPhase1Animation()
                    } else {
                        self.speakText("Acompanhe o trajeto de leitura.")
                        self.runPhase2Animation()
                    }
                }
            }
        }
        func runPhase1Animation() {
            let w = self.view.bounds.width
            let h = self.view.bounds.height
            guard let dot = self.visionMapDot else { return }

            dot.center = self.view.center
            dot.backgroundColor = .systemPink
            dot.isHidden = false

            UIView.animateKeyframes(withDuration: 18.0, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1) { dot.center = CGPoint(x: 50, y: 150) }
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.1) {
                    dot.center = CGPoint(x: w - 50, y: 150)
                    dot.backgroundColor = .systemCyan
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) { dot.center = CGPoint(x: w / 2, y: h - 200) }
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.1) {
                    dot.center = CGPoint(x: 50, y: h / 2)
                    dot.backgroundColor = .systemGreen
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2) { dot.center = CGPoint(x: w - 50, y: h / 2) }
                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.1) { dot.center = CGPoint(x: 50, y: h - 150) }
                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.1) {
                    dot.center = CGPoint(x: w - 50, y: h - 150)
                    dot.backgroundColor = .systemPurple
                }
                UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1) {
                    dot.center = self.view.center
                    dot.backgroundColor = .systemPink
                }
            }) { _ in
                dot.isHidden = true
                self.showMappingInstruction(
                    title: "FASE 2: Zona de Leitura",
                    description: "Ótimo! Agora vamos testar a convergência para perto.\n\nAproxime o celular (Radar de 30cm) e nivele os sensores novamente. Siga a bolinha na parte inferior da tela.",
                    action: #selector(self.preparePhase2Alignment)
                )
            }
        }

@objc func preparePhase2Alignment() {
        UIView.animate(withDuration: 0.2, animations: { self.mappingInstructionBox?.alpha = 0 }) { _ in
            self.mappingInstructionBox?.removeFromSuperview()
            
            self.topFeedbackLabel?.isHidden = false
            self.faceGuideLayer?.isHidden = false
            self.levelContainerView.isHidden = false
            self.levelLabel.isHidden = false
            self.headLevelContainerView.isHidden = false
            self.headLevelLabel.isHidden = false
            self.phonePitchContainerView.isHidden = false
            self.phonePitchLabel.isHidden = false
            self.headPitchContainerView.isHidden = false
            self.headPitchLabel.isHidden = false
            
            // 🔴 NOVO UX: Amplia a máscara suavemente para comportar o rosto a 30cm (Perto)
            let ovalW_perto: CGFloat = 330
            let ovalH_perto: CGFloat = 460
            let ovalX = (self.view.bounds.width - ovalW_perto) / 2
            let ovalY = (self.view.bounds.height - ovalH_perto) / 2 - 30
            let newPath = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW_perto, height: ovalH_perto))
            
            let anim = CABasicAnimation(keyPath: "path")
            anim.toValue = newPath.cgPath
            anim.duration = 0.5
            anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.faceGuideLayer?.add(anim, forKey: "pathAnim")
            self.faceGuideLayer?.path = newPath.cgPath
            
            self.checkVisionStabilityLoop(targetDistance: 0.30) // Inicia exigindo distância de perto
        }
    }

        func runPhase2Animation() {
            let w = self.view.bounds.width
            let h = self.view.bounds.height
            guard let dot = self.visionMapDot else { return }

            dot.center = CGPoint(x: 60, y: h - 250)
            dot.backgroundColor = .systemOrange
            dot.isHidden = false

            UIView.animateKeyframes(withDuration: 12.0, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: h - 250) }
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.05) { dot.center = CGPoint(x: 60, y: h - 180) }
                UIView.addKeyframe(withRelativeStartTime: 0.30, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: h - 180) }
                UIView.addKeyframe(withRelativeStartTime: 0.55, relativeDuration: 0.05) { dot.center = CGPoint(x: 60, y: h - 110) }
                UIView.addKeyframe(withRelativeStartTime: 0.60, relativeDuration: 0.25) { dot.center = CGPoint(x: w - 60, y: h - 110) }
                UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.15) { dot.center = self.view.center }
            }) { _ in
                self.finishVisionMappingSequence()
            }
        }
    

        
    
    // --- RADAR BIOMÉTRICO (DISTÂNCIA FOCAL) ---
    func showDistanceBar() {
        if distanceBarContainer == nil {
            let barW: CGFloat = 20
            let barH: CGFloat = 200
            let container = UIView(frame: CGRect(x: 30, y: (view.bounds.height - barH) / 2, width: barW, height: barH))
            container.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
            container.layer.cornerRadius = barW / 2
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            container.clipsToBounds = false
            let fill = UIView(frame: CGRect(x: 0, y: barH, width: barW, height: 0))
            fill.backgroundColor = .red
            fill.layer.cornerRadius = barW / 2
            container.addSubview(fill)
            let targetZone = UIView(frame: CGRect(x: -5, y: (barH / 2) - 15, width: barW + 10, height: 30))
            targetZone.layer.borderWidth = 2
            targetZone.layer.borderColor = UIColor.green.cgColor
            targetZone.layer.cornerRadius = 6
            container.addSubview(targetZone)
            let lbl = UILabel(frame: CGRect(x: 65, y: (view.bounds.height / 2) - 15, width: 250, height: 30))
            lbl.textColor = .white
            lbl.font = UIFont.boldSystemFont(ofSize: 14)
            lbl.layer.shadowColor = UIColor.black.cgColor
            lbl.layer.shadowRadius = 2
            lbl.layer.shadowOpacity = 0.8
            lbl.layer.shadowOffset = CGSize(width: 1, height: 1)
            view.addSubview(container)
            view.addSubview(lbl)
            distanceBarContainer = container
            distanceBarFill = fill
            distanceInstructionLabel = lbl
        }
        distanceBarContainer?.isHidden = false
        distanceInstructionLabel?.isHidden = false
        distanceBarFill?.frame = CGRect(x: 0, y: 200, width: 20, height: 0)
    }
    
    func hideDistanceBar() {
        distanceBarContainer?.isHidden = true
        distanceInstructionLabel?.isHidden = true
    }
    
    
    // --- RENDERER ---
    func setupScene() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor else { return nil }
        faceNode = SCNNode()
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)
        let maskNode = SCNNode(geometry: faceGeometry)
        maskNode.geometry?.firstMaterial?.colorBufferWriteMask = []
        faceNode?.addChildNode(maskNode)
        if let fn = faceNode {
            setupTechMask(on: fn)
        }
        return faceNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if renderer === self.visionMappingView {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
            self.lastFaceDetectionTime = Date().timeIntervalSince1970
            let headPitch = faceAnchor.transform.columns.2.y
            self.updateHeadPitchUI(angle: headPitch)
            let leftEye = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform).columns.3
            let rightEye = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform).columns.3
            let lEyeScreen = renderer.projectPoint(SCNVector3(leftEye.x, leftEye.y, leftEye.z))
            let rEyeScreen = renderer.projectPoint(SCNVector3(rightEye.x, rightEye.y, rightEye.z))
            let rawHeadRoll = atan2(Float(lEyeScreen.y - rEyeScreen.y), Float(lEyeScreen.x - rEyeScreen.x))
            self.smoothHeadRoll = (self.smoothHeadRoll * 0.95) + (rawHeadRoll * 0.05)
            self.updateHeadLevelUI(angle: self.smoothHeadRoll)
            if self.isMappingVision {
                let headYaw = abs(faceAnchor.transform.columns.2.x)
                let headPitchAct = abs(faceAnchor.transform.columns.2.y)
                let eyeYaw = abs(faceAnchor.leftEyeTransform.columns.2.x)
                let eyePitch = abs(faceAnchor.leftEyeTransform.columns.2.y)
                self.headMoveScore += (headYaw + headPitchAct)
                self.eyeMoveScore += (eyeYaw + eyePitch)
            }
            return
        }
        
        self.lastFaceDetectionTime = Date().timeIntervalSince1970
        if isFrozen { return }
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        if node.childNodes.count > 0 {
            // Preservando a diretriz de leitura segura de matrizes
            if let faceGeometry = node.childNodes[ 0 ].geometry as? ARSCNFaceGeometry {
                faceGeometry.update(from: faceAnchor.geometry)
            }
        }
        
        let leftM = faceAnchor.leftEyeTransform
        let rightM = faceAnchor.rightEyeTransform
        let lCenter = simd_make_float3(leftM.columns.3)
        let rCenter = simd_make_float3(rightM.columns.3)
        
        self.dnpEsq = abs(lCenter.x) * 1000
        self.dnpDir = abs(rCenter.x) * 1000
        self.dnpTotal = self.dnpEsq + self.dnpDir
        self.verticalPupilDiff = (lCenter.y - rCenter.y) * 1000
        
        let eyeRadius: Float = 0.012
        let lGaze = simd_make_float3(leftM.columns.2)
        let rGaze = simd_make_float3(rightM.columns.2)
        let lPupil = lCenter + (lGaze * eyeRadius)
        let rPupil = rCenter + (rGaze * eyeRadius)
        self.dnpPertoEsq = abs(lPupil.x) * 1000
        self.dnpPertoDir = abs(rPupil.x) * 1000
        self.dnpPertoTotal = self.dnpPertoEsq + self.dnpPertoDir
        
        let lPos = lCenter
        let rPos = rCenter
        let leftEyeWorldTransform = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)
        let rightEyeWorldTransform = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
        self.lastLeftEyeWorldPos = SCNVector3(leftEyeWorldTransform.columns.3.x, leftEyeWorldTransform.columns.3.y, leftEyeWorldTransform.columns.3.z)
        self.lastRightEyeWorldPos = SCNVector3(rightEyeWorldTransform.columns.3.x, rightEyeWorldTransform.columns.3.y, rightEyeWorldTransform.columns.3.z)
        
        if isGuidesActive, let line = pupilLineNode {
            let dy = lPos.y - rPos.y
            let dx = lPos.x - rPos.x
            let angle = atan2(dy, abs(dx))
            line.eulerAngles.z = Float.pi / 2 + angle
        }
        
        if self.isMappingVision {
            let headYaw = abs(faceAnchor.transform.columns.2.x)
            let headPitchAct = abs(faceAnchor.transform.columns.2.y)
            let eyeYaw = abs(leftM.columns.2.x)
            let eyePitch = abs(leftM.columns.2.y)
            self.headMoveScore += (headYaw + headPitchAct)
            self.eyeMoveScore += (eyeYaw + eyePitch)
        }
        
        if let lEyePos = self.lastLeftEyeWorldPos, let rEyePos = self.lastRightEyeWorldPos {
            let lEyeScreen = sceneView.projectPoint(lEyePos)
            let rEyeScreen = sceneView.projectPoint(rEyePos)
            let deltaY = Float(lEyeScreen.y - rEyeScreen.y)
            let deltaX = Float(lEyeScreen.x - rEyeScreen.x)
            let rawHeadRoll = atan2(deltaY, deltaX)
            let alpha: Float = 0.05
            self.smoothHeadRoll = (self.smoothHeadRoll * (1.0 - alpha)) + (rawHeadRoll * alpha)
            self.updateHeadLevelUI(angle: self.smoothHeadRoll)
            let headPitch = faceAnchor.transform.columns.2.y
            self.updateHeadPitchUI(angle: headPitch)
        }
        
        let verts = faceAnchor.geometry.vertices
        let eyeLevelY = (lPos.y + rPos.y) / 2.0
        let eyeDepthZ = (lPos.z + rPos.z) / 2.0
        let maxDepthLimit = eyeDepthZ - 0.010
        let searchYMin = eyeLevelY
        let searchYMax = eyeLevelY + 0.030
        let maxWidthLimit: Float = 0.085
        var minX: Float = 100;    var maxX: Float = -100
        var minY: Float = 100;    var maxY: Float = -100
        var minNX: Float = 100;   var maxNX: Float = -100
        var minJawX: Float = 100;  var maxJawX: Float = -100
        var maxNoseZ: Float = -100
        
        let bridgeHeightY = eyeLevelY + 0.000
        let jawLevelY = eyeLevelY - 0.065
        
        for v in verts {
            if v.y < minY { minY = v.y };     if v.y > maxY { maxY = v.y }
            if v.z > maxNoseZ { maxNoseZ = v.z }
            if v.y >= searchYMin && v.y <= searchYMax {
                if v.z > maxDepthLimit && abs(v.x) < maxWidthLimit {
                    if v.x < minX { minX = v.x }
                    if v.x > maxX { maxX = v.x }
                }
            }
            if abs(v.y - bridgeHeightY) < 0.002 && abs(v.x) < 0.010 {
                if v.x < minNX { minNX = v.x }
                if v.x > maxNX { maxNX = v.x }
            }
            // Varredura da Mandíbula (Para Visagismo)
            if abs(v.y - jawLevelY) < 0.010 && v.z > maxDepthLimit {
                if v.x < minJawX { minJawX = v.x }
                if v.x > maxJawX { maxJawX = v.x }
            }
        }
        //  Aplicação da Constante de Calibração de Conforto (Enum)
        self.faceWidthRight = (abs(minX) * 1000) * CalibrationFactors.faceWidthComfort
        self.faceWidthLeft = (maxX * 1000) * CalibrationFactors.faceWidthComfort
        self.faceWidth = self.faceWidthLeft + self.faceWidthRight
        
        
        if minNX < maxNX { self.noseBridgeWidth = (maxNX - minNX) * 1000 }
        let projNasal = (maxNoseZ - eyeDepthZ) * 1000
        self.nasalProfile = projNasal > 20.0 ? "Proeminente" : "Plano"
        if minJawX < maxJawX {
            self.jawWidth = (maxJawX - minJawX) * 1000
        }
        let faceHeight = (maxY - minY) * 1000
        analyzeVisagisme(width: self.faceWidth, height: faceHeight, bridge: self.noseBridgeWidth, jaw: self.jawWidth)
        
        let currentBridgeY = bridgeHeightY
        let currentTempleY = eyeLevelY + 0.025
        let finalMinX = minX
        let finalMaxX = maxX
        let finalMinNX = minNX
        let finalMaxNX = maxNX
        
        DispatchQueue.main.async {
            self.updateLabels()
            self.templeLineNode?.position.y = currentTempleY
            self.templeLeftArrow?.position.y = currentTempleY
            self.templeRightArrow?.position.y = currentTempleY
            if finalMinX < finalMaxX {
                self.templeLeftArrow?.position.x = finalMinX
                self.templeRightArrow?.position.x = finalMaxX
            }
            let widthMeters = finalMaxX - finalMinX
            self.templeLineNode?.position.x = (finalMinX + finalMaxX) / 2
            self.templeLineNode?.scale.y = widthMeters
            self.bridgeLineNode?.position.y = currentBridgeY
            self.bridgeLeftArrow?.position.y = currentBridgeY
            self.bridgeRightArrow?.position.y = currentBridgeY
            if finalMinNX < finalMaxNX {
                self.bridgeLeftArrow?.position.x = finalMinNX
                self.bridgeRightArrow?.position.x = finalMaxNX
                let bridgeWidthMeters = finalMaxNX - finalMinNX
                self.bridgeLineNode?.position.x = (finalMinNX + finalMaxNX) / 2
                self.bridgeLineNode?.scale.y = bridgeWidthMeters
            }
        }
    }
    
    @objc func toggleFreeze() {
            isFrozen.toggle()
            
            if isFrozen {
                self.topFeedbackLabel?.isHidden = true
                self.faceGuideLayer?.isHidden = true
                
                // =======================================================
                // 🔴 ETAPA: FOTO CAPTURADA (Modo de Edição Manual)
                // =======================================================
                sceneView.session.pause()
                motionManager.stopDeviceMotionUpdates()
                isCaptureSessionActive = false
                resetCountdown()
                
                // 1. Limpa os Sensores de Nível da Tela e Radares
                levelContainerView.isHidden = true
                menuButton.isHidden = true
                levelLabel.isHidden = true
                headLevelContainerView.isHidden = true
                headLevelLabel.isHidden = true
                phonePitchContainerView.isHidden = true
                phonePitchLabel.isHidden = true
                headPitchContainerView.isHidden = true
                headPitchLabel.isHidden = true
                self.distanceBarContainer?.isHidden = true
                
                // 2. Altera o botão principal para o comando "Voltar Etapa"
                startCaptureButton.setTitle("← Voltar Etapa (Refazer)", for: .normal)
                startCaptureButton.backgroundColor = .red
                
                // 3. Revela as Ferramentas Manuais e o Botão Avançar
                measurementsContainer.isHidden = false // Medidas só aparecem após o congelamento
                captureButton.isHidden = false
                measurementTypeSegment.isHidden = false
                
                // 4. Revela o Menu Inferior (Compare e Desenho Livre)
                if let bottomStack = view.subviews.first(where: { $0 is UIStackView }) {
                    bottomStack.isHidden = false
                }
                
                // NOTA: O btnVisionMap foi removido desta etapa. O Mapeamento agora é chamado no "Avançar"!
                
            } else {
                self.topFeedbackLabel?.isHidden = false
                self.topFeedbackLabel?.text = "POSICIONE O ROSTO NA MARCAÇÃO"
                self.topFeedbackLabel?.textColor = .yellow
                self.faceGuideLayer?.isHidden = false
                self.faceGuideLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
                
                // 🔴 CORREÇÃO UX: Restaura a máscara para a distância padrão de Longe (40cm) no início!
                let ovalW: CGFloat = 260
                let ovalH: CGFloat = 380
                let ovalX = (self.view.bounds.width - ovalW) / 2
                let ovalY = (self.view.bounds.height - ovalH) / 2 - 30
                self.faceGuideLayer?.path = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW, height: ovalH)).cgPath
            
                        
                // =======================================================
                // 🔴 ETAPAS 1 e 2: MODO CÂMERA AO VIVO / CONTAGEM
                // =======================================================
               
                savedFrontalSnapshot = nil
                freezeOverlayImageView?.isHidden = true
                
                if let origBg = self.originalBackgroundCache {
                    self.sceneView.scene.background.contents = origBg
                }
                if let origCam = self.originalCameraNodeCache {
                    self.sceneView.pointOfView = origCam
                }
                self.sceneView.isPlaying = false
                
                // BLINDAGEM DE MEMÓRIA: Extração e limpeza segura de matrizes
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
                
                let config = ARFaceTrackingConfiguration()
                config.isLightEstimationEnabled = true
                sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
                startLevelMonitoring()
                
                // 1. Reativa os Sensores de Nível
                levelContainerView.isHidden = false
                levelLabel.isHidden = false
                headLevelContainerView.isHidden = false
                headLevelLabel.isHidden = false
                phonePitchContainerView.isHidden = false
                phonePitchLabel.isHidden = false
                headPitchContainerView.isHidden = false
                headPitchLabel.isHidden = false
                
                // 2. ESCONDE O PAINEL DE MEDIDAS PARA NÃO DISTRAIR O USUÁRIO
                measurementsContainer.isHidden = true
                
                // 3. Esconde Menu Inferior e Ferramentas Secundárias
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
                
                // 4. Prepara o botão para a Etapa 1
                startCaptureButton.isHidden = false
                menuButton.isHidden = false
                startCaptureButton.setTitle("Iniciar Captura", for: .normal)
                startCaptureButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
                
                // 5. Garante que a Máscara 3D sempre apareça nesta fase
                isGuidesActive = true
                techMaskNode?.isHidden = false
                btnToggleGuides.backgroundColor = UIColor.systemBlue
            }
        }
    
    func analyzeVisagisme(width: Float, height: Float, bridge: Float, jaw: Float) {
        let ratio = height / width
        let dnpRatio = self.dnpTotal / width
        var shape = ""
        var advice = ""
        var avoid = ""
        if ratio > 1.45 {
            shape = "Longo / Retangular"
            advice = "Rostos alongados precisam de armações que 'quebrem' a extensão do rosto. O ideal são óculos com grande altura vertical (Oversized, Aviador clássico ou Wayfarer alto) para equilibrar as proporções."
            avoid = "Evite armações muito estreitas (baixas) ou retangulares finas, pois elas criarão a ilusão de que o rosto é ainda mais longo."
        } else if ratio > 1.30 {
            shape = "Oval / Equilibrado"
            advice = "Considerado o formato mais versátil. As proporções matemáticas do rosto são muito equilibradas, permitindo usar quase qualquer estilo. Armações levemente mais largas que a parte mais larga do seu rosto terão um encaixe perfeito."
            avoid = "Evite apenas armações extremamente pequenas ou desproporcionais que possam apagar as suas feições naturais."
        } else if ratio < 1.15 {
            shape = "Redondo / Curto"
            advice = "Rostos mais curtos ou circulares precisam de contraste. Beneficiam-se fortemente de armações com linhas retas e ângulos marcados (quadradas, retangulares e hexagonais) para afinar e alongar visualmente o rosto."
            avoid = "Evite armações redondas ou ovais pequenas, pois elas acentuam a simetria circular do rosto."
        } else {
            shape = "Coração / Diamante"
            advice = "O rosto possui um maxilar mais fino ou ângulos fortes. Armações ovais, redondas ou estilo 'gatinho' (cat-eye) são ideais para suavizar as linhas inferiores. Modelos sem aro na parte de baixo (Nylor) também vestem incrivelmente bem."
            avoid = "Evite armações pesadas demais ou com ângulos muito retos e grossos na parte inferior."
        }
        var bridgeAdvice = ""
        if bridge < 15.0 {
            bridgeAdvice = "\n\n👃 PONTE (\(f(bridge))mm): Estreita. Sugerimos armações em acetato com ponte 'fechadura' (keyhole) para dar a ilusão de um nariz mais largo, ou metais com plaquetas para garantir aderência."
        } else if bridge > 19.0 {
            bridgeAdvice = "\n\n👃 PONTE (\(f(bridge))mm): Larga. O ideal são armações de metal com plaquetas ajustáveis ou acetatos com ponte rebaixada e espessa para vestir confortavelmente sem marcar a pele."
        } else {
            bridgeAdvice = "\n\n👃 PONTE (\(f(bridge))mm): Padrão. O distanciamento nasal é ideal. A vasta maioria das armações com apoio anatômico terá um encaixe excelente e confortável."
        }
        var eyesAdvice = ""
        if dnpRatio < 0.43 {
            eyesAdvice = "\n\n👁️ OLHOS: Próximos. Dica óptica de Ouro: Escolha armações com a ponte (centro) em cores claras ou transparentes, e detalhes chamativos nas bordas externas (hastes) para 'afastar' visualmente os olhos."
        } else if dnpRatio > 0.49 {
            eyesAdvice = "\n\n👁️ OLHOS: Afastados. Dica óptica de Ouro: Armações com pontes escuras, grossas ou bem marcadas no centro ajudam a 'aproximar' visualmente a distância entre os olhos, trazendo harmonia."
        }
        self.faceShape = shape
        self.frameSuggestion = advice + " " + avoid + bridgeAdvice + eyesAdvice
    }
    
    func updateLabels() {
        measurementsLabel.text = ""
        lblDNPValue.text = "\(f(dnpTotal))mm"
        lblOEValue.text = "\(f(dnpEsq))"
        lblODValue.text = "\(f(dnpDir))"
        lblWidthValue.text = "\(f(faceWidth))mm"
        lblBridgeValue.text = "\(f(noseBridgeWidth))mm"
        let alturaStr = isFrozen ? "\(f(pupillaryHeight))mm" : "--"
        lblHeightValue.text = alturaStr
        lblHeightValue.textColor = isFrozen ? .green : .white
    }
    
    func f(_ value: Float) -> String { return String(format: "%.1f", value) }
    
    func verifyLicenseAndLoadModels() {
        guard Auth.auth().currentUser != nil else { self.dismiss(animated: true, completion: nil); return }
        self.measurementsLabel.text = "Verificando..."
        self.checkDeviceLicense { authorized, message in
            DispatchQueue.main.async {
                if authorized { self.isAuthorized = true; self.startARSession(); self.startLevelMonitoring(); self.enableAppControls(); }
                else { self.isAuthorized = false; self.sceneView.session.pause(); self.measurementsLabel.text = "BLOQUEADO:\n\(message ?? "Acesso negado.")"; self.measurementsContainer.backgroundColor = UIColor.red.withAlphaComponent(0.9); self.disableAppControls() }
            }
        }
    }
    
    func checkDeviceLicense(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else { completion(false, "Usuário não encontrado"); return }
        let db = Firestore.firestore()
        let currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let adminEmail = "gabriel@symap.com"
        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { [weak self] (document, error) in
            if let d = document, d.exists {
                let data = d.data()
                let app = data?["approved"] as? Bool ?? false
                let adm = adminEmail.contains(user.email ?? "")
                self?.isDataCollectionEnabled = data?["saveMeasurements"] as? Bool ?? false
                if !app && !adm { completion(false, "Em análise."); return }
                if adm { completion(true, nil); return }
                if let dev = data?["deviceId"] as? String {
                    if dev == currentDeviceID { completion(true, nil) } else { completion(false, "Conta ativa em outro dispositivo.") }
                } else { db.collection("users").document(user.uid).updateData(["deviceId": currentDeviceID]); completion(true, nil) }
            } else {
                userRef.setData([
                    "email": user.email ?? "",
                    "deviceId": currentDeviceID,
                    "approved": false,
                    "saveMeasurements": false,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                completion(false, "Registro recebido.")
            }
        }
    }
    
    @objc func logoutTapped() {
        try? Auth.auth().signOut()
        // Redireciona para o Login limpando a memória da sessão atual
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        self.view.window?.rootViewController = loginVC
    }
    
    @objc func handlePanGesture(_ g: UIPanGestureRecognizer) {
        guard isFrozen, let line = heightLineView, !line.isHidden, heightLineView.isUserInteractionEnabled else { return }
        let t = g.translation(in: view)
        line.center.y = max(100, min(view.bounds.height-100, line.center.y + t.y))
        g.setTranslation(.zero, in: view)
        calculatePupilHeight()
    }
    
    @objc func calculatePupilHeight() {
        guard let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView else { return }
        let ep = sceneView.projectPoint(lEye)
        let redLineY = Float(heightLineView.center.y)
        if redLineY < ep.y {
            pupillaryHeight = 0.0
            heightLineLabel.text = "H: 0.0 mm"
            return
        }
        let cx = (lEye.x + rEye.x) / 2.0
        let cy = (lEye.y + rEye.y) / 2.0
        let cz = (lEye.z + rEye.z) / 2.0
        let camPos = cam.worldPosition
        let dirX = camPos.x - cx
        let dirY = camPos.y - cy
        let dirZ = camPos.z - cz
        let distance = sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
        let frameZPos = SCNVector3(cx + (dirX / distance) * 0.015, cy + (dirY / distance) * 0.015, cz + (dirZ / distance) * 0.015)
        let frameScreenZ = sceneView.projectPoint(frameZPos).z
        let p3DEye = sceneView.unprojectPoint(SCNVector3(ep.x, ep.y, frameScreenZ))
        
        let p3DLine = sceneView.unprojectPoint(SCNVector3(ep.x, redLineY, frameScreenZ))
        
        let rawHMm = sqrt(pow(p3DLine.x - p3DEye.x, 2) + pow(p3DLine.y - p3DEye.y, 2) + pow(p3DLine.z - p3DEye.z, 2)) * 1000.0
        
        // plicação da Constante de Calibração (Enum)
        let hMm = rawHMm * CalibrationFactors.pupilHeight
        
        pupillaryHeight = hMm
        heightLineLabel.text = String(format: "H: %.1f mm", hMm)
        updateLabels()
    }
    
    
    
    
    func saveMeasurementToCloud(storagePath: String?) {
        guard isDataCollectionEnabled else { print("Coleta desativada."); return }
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let menorDNP = min(dnpEsq, dnpDir)
        let dcg = manualFrameWidth + noseBridgeWidth
        let edMax = max(manualFrameDiagonal, manualFrameWidth, manualFrameHeight)
        let descentracao = abs(dcg - (menorDNP * 2))
        let mbs = edMax > 0 ? (edMax + descentracao + 2.0) : 0.0
        var blocoComercial = mbs > 0 ? ceil(mbs / 5.0) * 5.0 : 0.0
        if blocoComercial > 0 && blocoComercial < 65.0 { blocoComercial = 65.0 }
        
        let tempoAtendimento = sessionStartTime != nil ? Int(Date().timeIntervalSince(sessionStartTime!)) : 0
        let tempoStr = "\(tempoAtendimento / 60)m \(tempoAtendimento % 60)s"
        let diffLateral = abs(faceWidthLeft - faceWidthRight)
        let ladoMaior = faceWidthLeft > faceWidthRight ? "Esq" : "Dir"
        let assimetriaStr = diffLateral > 1.5 ? "\(ladoMaior) +\(f(diffLateral))mm" : "Simétrico"
        let corEscolhida = UserDefaults.standard.string(forKey: "lastColor") ?? "Fábrica"
        let horaAtendimento = Calendar.current.component(.hour, from: Date())
        
        let measurementData: [String: Any] = [
            "userId": user.uid,
            "userEmail": user.email ?? "unknown",
            "timestamp": FieldValue.serverTimestamp(),
            "deviceModel": UIDevice.current.model,
            "dnpTotal": dnpTotal,
            "dnpLeft": dnpEsq,
            "dnpRight": dnpDir,
            "dnpPertoTotal": dnpPertoTotal,
            "dnpPertoLeft": dnpPertoEsq,
            "dnpPertoRight": dnpPertoDir,
            "faceWidth": faceWidth,
            "bridgeWidth": noseBridgeWidth,
            "pupilHeight": pupillaryHeight,
            "verticalDiff": verticalPupilDiff,
            "faceShape": faceShape,
            "lensType": selectedLensType,
            "observations": patientName,
            "patientCPF": patientCPF,
            "genderPrediction": patientGender,
            "manualHeight": manualFrameHeight,
            "manualWidth": manualFrameWidth,
            "manualDiagonal": manualFrameDiagonal,
            "jawWidth": jawWidth,
            "mbs": mbs,
            "blocoIdeal": blocoComercial,
            "tempoAtendimento": tempoStr,
            "corEscolhida": corEscolhida,
            "perfilNasal": nasalProfile,
            "assimetriaLateral": assimetriaStr,
            "horaAtendimento": horaAtendimento
        ]
        
        var finalData = measurementData
        if let pathFinal = storagePath {
            finalData["storagePath"] = pathFinal
        }
        finalData["status"] = "active"
        
        let logRef = db.collection("measurements_log")
        logRef.whereField("userId", isEqualTo: user.uid)
            .whereField("patientCPF", isEqualTo: patientCPF)
            .whereField("status", in: ["active", ""])
            .getDocuments { (snapshot, error) in
                
                let batch = db.batch()
                
                if let docs = snapshot?.documents, !docs.isEmpty {
                    // Preservando a diretriz inegociável de leitura de matrizes
                    let laudoAntigoBase = docs[ 0 ]
                    print("Arquivando versão anterior. ID Base: \(laudoAntigoBase.documentID)")
                    
                    for doc in docs {
                        batch.updateData(["status": "superseded"], forDocument: doc.reference)
                    }
                }
                
                let newDocRef = logRef.document()
                batch.setData(finalData, forDocument: newDocRef)
                
                batch.commit { err in
                    if let err = err {
                        print("Erro crítico no versionamento: \(err.localizedDescription)")
                    } else {
                        print("Nova versão do laudo gravada e ativada com sucesso!")
                    }
                }
            }
        
        let auditData: [String: Any] = [
            "actor": user.uid,
            "action": "GENERATE_REPORT",
            "target": user.uid,
            "payload": ["patientCpf": patientCPF, "lensType": selectedLensType],
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("audit_log").addDocument(data: auditData) { err in
            if let err = err { print("Falha ao registrar Audit Log: \(err)") }
        }
    }
    
   
    
    func showLocalShareSheet(pdfData: Data) {
        let vc = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        if let p = vc.popoverPresentationController { p.sourceView = captureButton }
        present(vc, animated: true)
    }
    
    func createPDF(image: UIImage) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let meta = [kCGPDFContextCreator: "Symap 3D Pro", kCGPDFContextAuthor: "System"]
        format.documentInfo = meta as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8), format: format)
        return renderer.pdfData { (context) in
            func desenharCabecalhoWhiteLabel(titulo: String) {
                let techBlack = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
                let techCyan = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                techBlack.setFill(); context.cgContext.fill(CGRect(x: 0, y: 0, width: 595.2, height: 90))
                if let logoImg = UIImage(named: "Branco") {
                    logoImg.draw(in: CGRect(x: 30, y: 20, width: 50, height: 50))
                    "ÓTICA PARCEIRA".draw(at: CGPoint(x: 90, y: 35), withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .heavy), .foregroundColor: UIColor.white, .kern: 1.5])
                } else {
                    "SYMAP 3D".draw(at: CGPoint(x: 30, y: 25), withAttributes: [.font: UIFont.systemFont(ofSize: 26, weight: .heavy), .foregroundColor: UIColor.white, .kern: 2.0])
                }
                titulo.draw(at: CGPoint(x: 30, y: 70), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 12) ?? UIFont.systemFont(ofSize: 12), .foregroundColor: techCyan])
            }
            
            let cgContext = context.cgContext
            let techBlack = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            let techCyan = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            let techTextMain = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            let techLine = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            let esfOD = Float(rxEsfOD.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let cilOD = Float(rxCilOD.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let esfOE = Float(rxEsfOE.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let cilOE = Float(rxCilOE.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let eeOD = esfOD + (cilOD / 2.0)
            let eeOE = esfOE + (cilOE / 2.0)
            let maiorEE = abs(eeOD) > abs(eeOE) ? eeOD : eeOE
            
            // =========================================================================
            // 📄 PÁGINA 1: ANÁLISE BIOMÉTRICA E VISAGISMO
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()
            desenharCabecalhoWhiteLabel(titulo: "RELATÓRIO DE ANÁLISE BIOMÉTRICA")
            desenharCabecalhoWhiteLabel(titulo: "RELATÓRIO DE ANÁLISE BIOMÉTRICA")
                    DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short).draw(at: CGPoint(x: 400, y: 35), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray])
                    
                    // Caixas agora começam na margem esquerda (30) e ocupam a largura total (535)
                    let colX: CGFloat = 30.0
                    var cy: CGFloat = 120.0
                    let boxW: CGFloat = 535.0
            
            func drawTechBox(title: String, height: CGFloat, content: () -> Void) {
                let rect = CGRect(x: colX, y: cy, width: boxW, height: height)
                UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: colX, y: cy+5, width: 4, height: height-10), cornerRadius: 2).fill()
                title.uppercased().draw(at: CGPoint(x: colX + 12, y: cy + 8), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor.gray])
                content()
                cy += height + 12
            }
            
            drawTechBox(title: "Distância Pupilar (DNP)", height: 85) {
                let valFont = UIFont(name: "Courier-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
                let labelFont = UIFont.systemFont(ofSize: 10)
                let totalFont = UIFont.boldSystemFont(ofSize: 16)
                let nearFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
                let cxOE = colX + 80.0;   let cxOD = colX + boxW - 80.0;   let cxTotal = colX + boxW / 2.0;   let startY = cy + 18.0
                func drawCentered(_ text: String, font: UIFont, color: UIColor, cx: CGFloat, y: CGFloat) {  let size = text.size(withAttributes: [.font: font]); text.draw(at: CGPoint(x: cx - size.width/2, y: y), withAttributes: [.font: font, .foregroundColor: color]) }
                drawCentered("OE", font: labelFont, color: .gray, cx: cxOE, y: startY)
                drawCentered("TOTAL (LONGE)", font: labelFont, color: .gray, cx: cxTotal, y: startY)
                drawCentered("OD", font: labelFont, color: .gray, cx: cxOD, y: startY)
                let valY = startY + 14.0
                drawCentered("\(self.f(self.dnpEsq))", font: valFont, color: techBlack, cx: cxOE, y: valY)
                drawCentered("\(self.f(self.dnpTotal)) mm", font: totalFont, color: techCyan, cx: cxTotal, y: valY + 2)
                drawCentered("\(self.f(self.dnpDir))", font: valFont, color: techBlack, cx: cxOD, y: valY)
                let nearY = valY + 30.0
                drawCentered("LEITURA (PERTO): \(self.f(self.dnpPertoTotal)) mm  (OE: \(self.f(self.dnpPertoEsq)) | OD: \(self.f(self.dnpPertoDir)))", font: nearFont, color: .darkGray, cx: cxTotal, y: nearY)
            }
            
            drawTechBox(title: "Análise Biométrica Avançada", height: 115) {
                let col1X = colX + 30;   let col2X = colX + 280;   var localY = cy + 22;   let rowH: CGFloat = 26
                func drawMetric(label: String, value: String, x: CGFloat, y: CGFloat, highlight: Bool = false) {
                    label.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
                    let fontSize: CGFloat = value.count > 18 ? 10 : 14
                    value.draw(at: CGPoint(x: x, y: y+12), withAttributes: [.font: UIFont(name: "Courier", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize), .foregroundColor: highlight ? techCyan : techTextMain])
                }
                drawMetric(label: "LARGURA FACE", value: "\(self.f(self.faceWidth)) mm", x: col1X, y: localY)
                drawMetric(label: "LARGURA PONTE", value: "\(self.f(self.noseBridgeWidth)) mm", x: col2X, y: localY)
                localY += rowH
                let alt = self.isFrozen ? "\(self.f(self.pupillaryHeight)) mm" : "N/A"
                drawMetric(label: "ALTURA PUPILAR (H)", value: alt, x: col1X, y: localY)
                let diffVal = abs(self.verticalPupilDiff) < 0.5 ? "SIMÉTRICO (\(self.f(abs(self.verticalPupilDiff)))mm)" : (self.verticalPupilDiff > 0 ? "OE MAIS ALTO" : "OD MAIS ALTO")
                drawMetric(label: "DISPARIDADE VERTICAL", value: diffVal, x: col2X, y: localY)
                localY += rowH
                drawMetric(label: "FORMATO DETECTADO", value: self.faceShape, x: col1X, y: localY)
            }
            
            if self.manualFrameHeight > 0 || self.manualFrameWidth > 0 || self.manualFrameDiagonal > 0 {
                drawTechBox(title: "Medidas da Armação (Manual)", height: 75) {
                    var manualY = cy + 22
                    let attrFont = UIFont(name: "Courier", size: 11) ?? UIFont.boldSystemFont(ofSize: 14)
                    if self.manualFrameHeight > 0 { "ALT. LENTE (H): \(self.f(self.manualFrameHeight))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                    if self.manualFrameWidth > 0 { "LARG. LENTE (W): \(self.f(self.manualFrameWidth))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                    if self.manualFrameDiagonal > 0 { "DIAGONAL (Ø): \(self.f(self.manualFrameDiagonal))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                }
            }
            
            
            let visY = cy
            let orderY: CGFloat = 690.0
            let visH: CGFloat = orderY - visY - 15.0
            let visRect = CGRect(x: 30, y: visY, width: 535, height: visH)
            UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: visRect, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: visY, width: 6, height: visH), cornerRadius: 6).fill()
            "CONSULTORIA DE ESTILO E VISAGISMO (IA)".draw(at: CGPoint(x: 50, y: visY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
            "TAMANHO RECOMENDADO:".draw(at: CGPoint(x: 50, y: visY + 35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.gray])
            let sizeRec = self.faceWidth < 128 ? "PEQUENO (S)" : (self.faceWidth < 140 ? "MÉDIO (M)" : "GRANDE (L)")
            let hasteRec = self.faceWidth < 128 ? "Haste 130-135mm" : (self.faceWidth < 140 ? "Haste 140mm" : "Haste 145mm+")
            "\(sizeRec) - \(hasteRec)".draw(at: CGPoint(x: 50, y: visY + 50), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techCyan])
            
            var extraTips = ""
            if self.faceShape.contains("Longo") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Para rostos alongados, hastes com detalhes contrastantes ou armações mais grossas ajudam a 'cortar' o rosto horizontalmente, adicionando uma agradável largura visual. Cores degradê (escuras na parte superior e translúcidas na inferior) também encurtam perfeitamente a extensão do rosto. Aposte em pontes mais baixas no nariz."
            } else if self.faceShape.contains("Oval") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Com proporções já geometricamente ideais, você tem total liberdade na escolha! Brinque com texturas ousadas, peças em acetato translúcido e designs hiper-geométricos. Apenas certifique-se de que a largura total da armação empate de forma exata com a parte mais larga do seu rosto para manter a simetria orgânica."
            } else if self.faceShape.contains("Redondo") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: O segredo clínico aqui é criar linhas de expressão estruturadas artificiais. Armações retangulares e poligonais farão seu rosto parecer imediatamente mais afinado e comprido. Hastes presas na parte superior da armação elevam o centro de gravidade e destacam com força o seu olhar."
            } else {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Para maxilares afinados, chame atenção para o topo. Cores fortes na barra superior (como o estilo Clubmaster/Browline) elevam a expressão. Recomendamos manter a metade inferior da lente limpa, utilizando preferencialmente o estilo Nylor (fio de nylon) para não sobrecarregar as maçãs do rosto com acetato."
            }
            let fullVisagismText = self.frameSuggestion + extraTips
            let textRect = CGRect(x: 50, y: visY + 75, width: 495, height: visH - 90)
            let style = NSMutableParagraphStyle(); style.alignment = .justified; style.lineSpacing = 5
            let attrStr = NSAttributedString(string: fullVisagismText, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: techTextMain, .paragraphStyle: style])
            attrStr.draw(in: textRect)
            
            let orderRect = CGRect(x: 30, y: orderY, width: 535, height: 90)
            UIColor(white: 0.95, alpha: 1.0).setFill(); UIBezierPath(roundedRect: orderRect, cornerRadius: 6).fill()
            "ESPECIFICAÇÕES DO PEDIDO".draw(at: CGPoint(x: 45, y: orderY+12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
            "TIPO DE LENTE:".draw(at: CGPoint(x: 45, y: orderY+35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            self.selectedLensType.uppercased().draw(at: CGPoint(x: 45, y: orderY+48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techCyan])
            "NOME DO PACIENTE / CPF:".draw(at: CGPoint(x: 240, y: orderY+35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            let notes = "\(self.patientName) (\(self.patientCPF))"
            notes.draw(at: CGPoint(x: 240, y: orderY+48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techTextMain])
            let footerY = orderRect.maxY + 15
            let line = UIBezierPath(); line.move(to: CGPoint(x: 30, y: footerY)); line.addLine(to: CGPoint(x: 565, y: footerY)); UIColor.lightGray.setStroke(); line.lineWidth = 0.5; line.stroke()
            "RELATÓRIO GERADO PELO SISTEMA | SYMAP 3D v2.2 | BIOMETRIA SEGURA".draw(at: CGPoint(x: 30, y: footerY + 10), withAttributes: [.font: UIFont(name: "Courier", size: 9) ?? UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            
            // =========================================================================
            // 📄 PÁGINA 2: GABARITO DE BLOQUEIO E MONTAGEM
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()
            desenharCabecalhoWhiteLabel(titulo: "GABARITO DE BLOQUEIO E DESCENTRAÇÃO (1:1)")
            let h = self.pupillaryHeight
            var seloCor: UIColor = .clear;  var seloTitulo = "";  var seloDesc = ""
            if h >= 21.0 { seloCor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0); seloTitulo = "✅ APROVADO: CORREDOR MULTIFOCAL LONGO (14mm+)"; seloDesc = "Excelente espaço vertical. Proporciona amplo campo de visão para leitura e transição suave." }
            else if h >= 16.0 { seloCor = UIColor.systemOrange; seloTitulo = "⚠️ ATENÇÃO: CORREDOR MULTIFOCAL CURTO (11 a 13mm)"; seloDesc = "Montagem requer precisão milimétrica. O campo de visão de perto (leitura) será mais estreito." }
            else if h > 0.0 { seloCor = UIColor.red; seloTitulo = "❌ ALERTA CRÍTICO: INCOMPATÍVEL COM LENTES MULTIFOCAIS"; seloDesc = "Altura pupilar muito baixa (\(self.f(h))mm). A área de leitura será cortada fisicamente pela máquina facetadora." }
            else { seloCor = UIColor.gray; seloTitulo = "ℹ️ LAUDO DE MULTIFOCAL: AGUARDANDO MEDIÇÃO"; seloDesc = "Utilize a ferramenta de Altura (H) na tela principal para gerar a recomendação do corredor." }
            let seloRect = CGRect(x: 30, y: 110, width: 535, height: 45)
            seloCor.withAlphaComponent(0.08).setFill(); UIBezierPath(roundedRect: seloRect, cornerRadius: 8).fill()
            seloCor.setStroke();  let seloBorder = UIBezierPath(roundedRect: seloRect, cornerRadius: 8); seloBorder.lineWidth = 1.5; seloBorder.stroke()
            seloTitulo.draw(at: CGPoint(x: 45, y: 118), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: seloCor])
            seloDesc.draw(at: CGPoint(x: 45, y: 135), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: techBlack])
            
            let dcgMetade = (self.manualFrameWidth + self.noseBridgeWidth) / 2.0
            let mm: CGFloat = 2.83465
            let yCentroBlocos: CGFloat = 330.0;  let xDereito: CGFloat = 160.0;  let xEsquerdo: CGFloat = 595.2 - 160.0
            
            func desenharBlocoMateriaPrima(cx: CGFloat, cy: CGFloat, dnpOlho: Float, titulo: String) {
                        cgContext.saveGState()
                        let textY = cy - ((75.0 / 2.0) * mm) - 50.0
                        titulo.draw(at: CGPoint(x: cx - 75, y: textY), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .heavy), .foregroundColor: techBlack])
                        "GABARITO TÉCNICO VIRTUAL".draw(at: CGPoint(x: cx - 65, y: textY + 22), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: techCyan])
                        
                        let raioBlocoBase = (75.0 / 2.0) * mm
                        UIColor.lightGray.withAlphaComponent(0.8).setStroke(); cgContext.setLineWidth(0.5); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
                        cgContext.move(to: CGPoint(x: cx, y: cy - raioBlocoBase - 35)); cgContext.addLine(to: CGPoint(x: cx, y: cy + raioBlocoBase + 35))
                        cgContext.move(to: CGPoint(x: cx - raioBlocoBase - 35, y: cy)); cgContext.addLine(to: CGPoint(x: cx + raioBlocoBase + 35, y: cy)); cgContext.strokePath()
                        
                        let axisFont = UIFont.systemFont(ofSize: 9, weight: .bold)
                        "90°".draw(at: CGPoint(x: cx - 8, y: cy - raioBlocoBase + 15), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])
                        "0°".draw(at: CGPoint(x: cx + raioBlocoBase + 10, y: cy + 4), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])
                        "180°".draw(at: CGPoint(x: cx - raioBlocoBase - 30, y: cy + 4), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])
                        
                        cgContext.setLineDash(phase: 0, lengths: [])
                        let rectBloco = CGRect(x: cx - raioBlocoBase, y: cy - raioBlocoBase, width: raioBlocoBase * 2, height: raioBlocoBase * 2)
                        UIColor.white.withAlphaComponent(0.9).setFill(); cgContext.fillEllipse(in: rectBloco)
                        techCyan.setStroke(); cgContext.setLineWidth(2.0); cgContext.strokeEllipse(in: rectBloco)
                        
                        let raioUtil = raioBlocoBase - (5.0 * mm)
                        if raioUtil > 0 { let rectUtil = CGRect(x: cx - raioUtil, y: cy - raioUtil, width: raioUtil * 2, height: raioUtil * 2); techCyan.withAlphaComponent(0.3).setStroke(); cgContext.setLineWidth(1.0); cgContext.setLineDash(phase: 0, lengths: [2.0, 4.0]); cgContext.strokeEllipse(in: rectUtil) }
                        
                        cgContext.setLineDash(phase: 0, lengths: [])
                        UIColor.lightGray.setStroke(); cgContext.setLineWidth(0.5)
                        cgContext.move(to: CGPoint(x: cx - 15, y: cy)); cgContext.addLine(to: CGPoint(x: cx + 15, y: cy))
                        cgContext.move(to: CGPoint(x: cx, y: cy - 15)); cgContext.addLine(to: CGPoint(x: cx, y: cy + 15)); cgContext.strokePath()
                        
                        let shiftDNP = (dcgMetade - dnpOlho) * Float(mm)
                        let alturaValida = self.pupillaryHeight >= 10.0 && self.pupillaryHeight <= 40.0
                        let shiftAltura = alturaValida ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) * Float(mm) : 0.0
                        let direcaoInvertida: CGFloat = titulo.contains("OD") ? 1.0 : -1.0
                        let cxOtico = cx + (CGFloat(shiftDNP) * direcaoInvertida)
                        let cyOtico = cy - CGFloat(shiftAltura)
                        
                        // Cruz de Montagem
                        UIColor.red.setStroke(); cgContext.setLineWidth(1.5); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
                        cgContext.move(to: CGPoint(x: cxOtico, y: cyOtico - 25)); cgContext.addLine(to: CGPoint(x: cxOtico, y: cyOtico + 25))
                        cgContext.move(to: CGPoint(x: cxOtico - 25, y: cyOtico)); cgContext.addLine(to: CGPoint(x: cxOtico + 25, y: cyOtico)); cgContext.strokePath()
                        cgContext.setLineDash(phase: 0, lengths: []); UIColor.red.setFill(); cgContext.fillEllipse(in: CGRect(x: cxOtico - 3.5, y: cyOtico - 3.5, width: 7, height: 7))
                        
                        let textoMira = alturaValida ? "CENTRO" : "ALTURA (H) NÃO MEDIDA"
                        textoMira.draw(at: CGPoint(x: cxOtico + 8, y: cyOtico + 5), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.red])

                        // =======================================================
                        // 🔴 NOVO: GABARITO DE MARCAÇÕES A LASER DA LENTE MULTIFOCAL
                        // =======================================================
                        let laserDist = 17.0 * CGFloat(mm) // Distância padrão internacional de 17mm a partir do centro
                        let laserLeftX = cxOtico - laserDist
                        let laserRightX = cxOtico + laserDist

                        UIColor.gray.withAlphaComponent(0.8).setStroke()
                        cgContext.setLineWidth(0.8)
                        let radiusLaser: CGFloat = 2.0

                        // Círculos invisíveis (Laser)
                        cgContext.strokeEllipse(in: CGRect(x: laserLeftX - radiusLaser, y: cyOtico - radiusLaser, width: radiusLaser * 2, height: radiusLaser * 2))
                        cgContext.strokeEllipse(in: CGRect(x: laserRightX - radiusLaser, y: cyOtico - radiusLaser, width: radiusLaser * 2, height: radiusLaser * 2))

                        // Legenda Nasal (N) e Temporal (T) inteligente por olho
                        let txtNasal = titulo.contains("OD") ? "N" : "T"
                        let txtTemp = titulo.contains("OD") ? "T" : "N"
                        txtNasal.draw(at: CGPoint(x: laserLeftX - 8, y: cyOtico - 3), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 5), .foregroundColor: UIColor.gray])
                        txtTemp.draw(at: CGPoint(x: laserRightX + 4, y: cyOtico - 3), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 5), .foregroundColor: UIColor.gray])
                        
                        cgContext.restoreGState()
                    }
            desenharBlocoMateriaPrima(cx: xDereito, cy: yCentroBlocos, dnpOlho: self.dnpDir, titulo: "LENTE DIREITA (OD)")
            desenharBlocoMateriaPrima(cx: xEsquerdo, cy: yCentroBlocos, dnpOlho: self.dnpEsq, titulo: "LENTE ESQUERDA (OE)")
            let labY: CGFloat = 530
            let rectLab = CGRect(x: 30, y: labY, width: 535, height: 160)
            UIColor.white.setFill(); UIBezierPath(roundedRect: rectLab, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: labY, width: 4, height: 160), cornerRadius: 6).fill()
            "INSTRUÇÕES DE BLOQUEIO E LEITURA".draw(at: CGPoint(x: 45, y: labY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])
            let deltaX_OD = dcgMetade - self.dnpDir
            let deltaX_OE = dcgMetade - self.dnpEsq
            let deltaY = self.pupillaryHeight > 0 ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) : 0.0
            let decentracaoObliquaOD = sqrt(pow(deltaX_OD, 2) + pow(deltaY, 2))
            let decentracaoObliquaOE = sqrt(pow(deltaX_OE, 2) + pow(deltaY, 2))
            let maxDecentration = max(decentracaoObliquaOD, decentracaoObliquaOE)
            let edEfetivo = self.manualFrameDiagonal > 0 ? (self.manualFrameDiagonal + (maxDecentration * 2.0)) : 0.0
            let labFont = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
            let lblFont = UIFont.systemFont(ofSize: 10)
            var lh = labY + 45
            let col1X: CGFloat = 45;  let val1X: CGFloat = 175
            "DNP LONGE (OD / OE):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.dnpDir)) / \(self.f(self.dnpEsq))".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); lh += 22
            "DNP PERTO (OD / OE):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.dnpPertoDir)) / \(self.f(self.dnpPertoEsq))".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techCyan]); lh += 22
            "ALTURA PUPILAR (H):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.pupillaryHeight)) mm".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); lh += 22
            UIColor.lightGray.withAlphaComponent(0.3).setStroke()
            cgContext.setLineWidth(1.0); cgContext.move(to: CGPoint(x: 290, y: labY + 45)); cgContext.addLine(to: CGPoint(x: 290, y: labY + 105)); cgContext.strokePath()
            var rh = labY + 45
            let col2X: CGFloat = 310;  let val2X: CGFloat = 430
            "COORDENADA EIXO X:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ΔX: \(self.f(deltaX_OD)) / \(self.f(deltaX_OE))".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); rh += 22
            "COORDENADA EIXO Y:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ΔY: \(self.f(deltaY)) mm".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); rh += 22
            "DIÂMETRO EFETIVO:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ED MÁX: \(self.f(edEfetivo)) mm".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack])
            
            if self.manualFrameWidth > 0 && self.manualFrameDiagonal > 0 {
                let boxMontY = labY + 160 + 15
                let boxMontH: CGFloat = 80
                let rectMont = CGRect(x: 30, y: boxMontY, width: 535, height: boxMontH)
                UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: rectMont, cornerRadius: 6).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: boxMontY, width: 4, height: boxMontH), cornerRadius: 6).fill()
                "DADOS DE MONTAGEM E LABORATÓRIO".draw(at: CGPoint(x: 45, y: boxMontY + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
                let menorDNP = min(dnpEsq, dnpDir)
                let dcg = manualFrameWidth + noseBridgeWidth
                let edMax = max(manualFrameDiagonal, manualFrameWidth, manualFrameHeight)
                let descentracao = abs(dcg - (menorDNP * 2))
                let mbs = edMax > 0 ? (edMax + descentracao + 2.0) : 0.0
                var blocoComercial = mbs > 0 ? ceil(mbs / 5.0) * 5.0 : 0.0
                if blocoComercial > 0 && blocoComercial < 65.0 { blocoComercial = 65.0 }
                let attrFontMont = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
                "DCG TOTAL DA ARMAÇÃO: \(self.f(dcg)) mm".draw(at: CGPoint(x: 45, y: boxMontY + 35), withAttributes: [.font: attrFontMont, .foregroundColor: techTextMain])
                "DNP MÉDIA DA ARMAÇÃO: \(self.f(dcg / 2.0)) mm".draw(at: CGPoint(x: 45, y: boxMontY + 55), withAttributes: [.font: attrFontMont, .foregroundColor: techCyan])
                "DIÂMETRO EXATO (MBS): \(self.f(mbs)) mm".draw(at: CGPoint(x: 310, y: boxMontY + 35), withAttributes: [.font: attrFontMont, .foregroundColor: techTextMain])
                "TAMANHO BLOCO IDEAL:  \(Int(blocoComercial)) mm".draw(at: CGPoint(x: 310, y: boxMontY + 55), withAttributes: [.font: attrFontMont, .foregroundColor: techCyan])
            }
            UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
            cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
            "IMPRIMIR SEMPRE EM ESCALA 100% (SEM AJUSTAR À PÁGINA) MANTENDO PROPORÇÃO 1:1 A4".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.red])
            
            // =========================================================================
            // 📄 PÁGINA 3: MAPEAMENTO DE COMPORTAMENTO VISUAL (IA)
            // =========================================================================
            
            // INTELIGÊNCIA: Só imprime a página 3 inteira se NÃO for Visão Simples
            if self.selectedLensType != "Visão Simples" {
                
                context.beginPage()
                cgContext.saveGState()
                cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
                for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
                for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
                cgContext.strokePath()
                cgContext.restoreGState()
                desenharCabecalhoWhiteLabel(titulo: "LAUDO DE COMPORTAMENTO VISUAL (IA)")
                let p3BoxY: CGFloat = 120.0
                let p3BoxH: CGFloat = 190.0
                let rectP3 = CGRect(x: 30, y: p3BoxY, width: 535, height: p3BoxH)
                UIColor.white.setFill(); UIBezierPath(roundedRect: rectP3, cornerRadius: 8).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: p3BoxY, width: 6, height: p3BoxH), cornerRadius: 8).fill()
                "DIAGNÓSTICO COMPORTAMENTAL DE RASTREAMENTO OCULAR:".draw(at: CGPoint(x: 50, y: p3BoxY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.gray])
                let diagColor = self.visionBehaviorResult.contains("Cabeça") ? UIColor.systemOrange : UIColor.systemBlue
                self.visionBehaviorResult.uppercased().draw(at: CGPoint(x: 50, y: p3BoxY + 35), withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .heavy), .foregroundColor: diagColor])
                var recText = ""
                if self.visionBehaviorResult.contains("Cabeça") { recText = "O paciente utiliza predominantemente a rotação do pescoço (cervical) para focar em objetos nas áreas periféricas e na transição para a zona de leitura.\n\n✔️ RECOMENDAÇÃO TÉCNICA:\nLentes multifocais com corredor progressivo Suave (Soft Design). Campos visuais periféricos moderados são bem tolerados, uma vez que o paciente naturalmente centraliza a cabeça em direção ao alvo." }
                else if self.visionBehaviorResult.contains("Olhos") { recText = "O paciente utiliza predominantemente a rotação do globo ocular para focar em objetos periféricos e buscar a zona de leitura, mantendo a cabeça estática.\n\n✔️ RECOMENDAÇÃO TÉCNICA:\nLentes multifocais de Altíssima Performance (Hard Design / Freeform Avançado). É estritamente necessário fornecer zonas periféricas extremamente largas e livre de aberrações, pois o paciente varre as bordas da lente." }
                else { recText = "Mapeamento interativo não realizado nesta sessão.\n\nRecomendamos a execução do teste na tela principal para gerar precisão clínica no desenho da lente multifocal." }
                let pStyle = NSMutableParagraphStyle(); pStyle.alignment = .justified; pStyle.lineSpacing = 5
                let attrRec = NSAttributedString(string: recText, attributes: [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: techTextMain, .paragraphStyle: pStyle])
                attrRec.draw(in: CGRect(x: 50, y: p3BoxY + 75, width: 490, height: 100))
                
                let chartY = p3BoxY + p3BoxH + 20
                let chartH: CGFloat = 300
                let chartW: CGFloat = 535
                let chartRect = CGRect(x: 30, y: chartY, width: chartW, height: chartH)
                UIColor.white.setFill(); UIBezierPath(roundedRect: chartRect, cornerRadius: 8).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: chartY, width: 6, height: chartH), cornerRadius: 8).fill()
                "MAPA TOPOGRÁFICO DE COMPORTAMENTO VISUAL".draw(at: CGPoint(x: 50, y: chartY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
                let p3PlotCX = chartRect.midX
                let p3PlotCY = chartY + 160
                let topoRadius: CGFloat = 95.0
                
                cgContext.saveGState()
                cgContext.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: UIColor.black.withAlphaComponent(0.2).cgColor)
                let bgCircle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: topoRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                UIColor.white.setFill()
                bgCircle.fill()
                cgContext.setShadow(offset: .zero, blur: 0, color: nil)
                bgCircle.addClip()
                
                let colors = [
                    UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0).cgColor
                ] as CFArray
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.25, 0.5, 0.75, 1.0])!
                cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), startRadius: 0, endCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), endRadius: topoRadius, options: [])
                cgContext.restoreGState()
                
                cgContext.saveGState()
                UIColor.white.withAlphaComponent(0.6).setStroke()
                cgContext.setLineWidth(0.5)
                for i in 1...4 {
                    let r = (topoRadius / 4.0) * CGFloat(i)
                    let circle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    circle.stroke()
                }
                for angle in stride(from: 0, to: 360, by: 30) {
                    let rad = CGFloat(angle) * .pi / 180.0
                    cgContext.move(to: CGPoint(x: p3PlotCX, y: p3PlotCY))
                    cgContext.addLine(to: CGPoint(x: p3PlotCX + topoRadius * cos(rad), y: p3PlotCY + topoRadius * sin(rad)))
                }
                cgContext.strokePath()
                UIColor.white.setStroke()
                cgContext.setLineWidth(1.0)
                cgContext.move(to: CGPoint(x: p3PlotCX - topoRadius, y: p3PlotCY))
                cgContext.addLine(to: CGPoint(x: p3PlotCX + topoRadius, y: p3PlotCY))
                cgContext.move(to: CGPoint(x: p3PlotCX, y: p3PlotCY - topoRadius))
                cgContext.addLine(to: CGPoint(x: p3PlotCX, y: p3PlotCY + topoRadius))
                cgContext.strokePath()
                cgContext.restoreGState()
                
                techBlack.setStroke()
                let borderCircle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: topoRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                borderCircle.lineWidth = 2.0
                borderCircle.stroke()
                
                let fontAxis = UIFont.systemFont(ofSize: 9, weight: .bold)
                "Rotação Cervical (Head) ➔".draw(at: CGPoint(x: p3PlotCX + topoRadius + 15, y: p3PlotCY - 5), withAttributes: [.font: fontAxis, .foregroundColor: UIColor.systemOrange])
                "Rotação Ocular (Eye) ➔".draw(at: CGPoint(x: p3PlotCX - 50, y: p3PlotCY - topoRadius - 20), withAttributes: [.font: fontAxis, .foregroundColor: techCyan])
                
                let totalScore = max(self.headMoveScore + self.eyeMoveScore, 0.001)
                let pctEye = CGFloat(self.eyeMoveScore / totalScore)
                let pctHead = CGFloat(self.headMoveScore / totalScore)
                let offsetX = (pctHead - 0.5) * 2.0 * topoRadius * 0.8
                let offsetY = (pctEye - 0.5) * 2.0 * topoRadius * 0.8
                let pointX = p3PlotCX + offsetX
                let pointY = p3PlotCY - offsetY
                
                cgContext.saveGState()
                UIColor.black.setStroke()
                cgContext.setLineWidth(2.0)
                cgContext.move(to: CGPoint(x: pointX - 10, y: pointY))
                cgContext.addLine(to: CGPoint(x: pointX + 10, y: pointY))
                cgContext.move(to: CGPoint(x: pointX, y: pointY - 10))
                cgContext.addLine(to: CGPoint(x: pointX, y: pointY + 10))
                cgContext.strokePath()
                UIColor.white.setFill()
                cgContext.fillEllipse(in: CGRect(x: pointX - 4, y: pointY - 4, width: 8, height: 8))
                UIColor.black.setFill()
                cgContext.fillEllipse(in: CGRect(x: pointX - 2, y: pointY - 2, width: 4, height: 4))
                let lblBox = CGRect(x: pointX + 12, y: pointY - 20, width: 95, height: 18)
                techBlack.setFill(); UIBezierPath(roundedRect: lblBox, cornerRadius: 4).fill()
                "FOCO DO PACIENTE".draw(at: CGPoint(x: pointX + 15, y: pointY - 17), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.white])
                cgContext.restoreGState()
                
                let scaleX = p3PlotCX - topoRadius - 65
                let scaleY = p3PlotCY - 50
                let scaleW: CGFloat = 10
                let scaleH: CGFloat = 100
                cgContext.saveGState()
                let scalePath = UIBezierPath(roundedRect: CGRect(x: scaleX, y: scaleY, width: scaleW, height: scaleH), cornerRadius: 4)
                scalePath.addClip()
                cgContext.drawLinearGradient(gradient, start: CGPoint(x: scaleX, y: scaleY), end: CGPoint(x: scaleX, y: scaleY + scaleH), options: [])
                cgContext.restoreGState()
                techBlack.setStroke()
                let scaleBorder = UIBezierPath(roundedRect: CGRect(x: scaleX, y: scaleY, width: scaleW, height: scaleH), cornerRadius: 4)
                scaleBorder.lineWidth = 1.0
                scaleBorder.stroke()
                "Alta Intens.".draw(at: CGPoint(x: scaleX - 15, y: scaleY - 15), withAttributes: [.font: UIFont.systemFont(ofSize: 7, weight: .bold), .foregroundColor: UIColor.red])
                "Baixa Intens.".draw(at: CGPoint(x: scaleX - 15, y: scaleY + scaleH + 5), withAttributes: [.font: UIFont.systemFont(ofSize: 7, weight: .bold), .foregroundColor: UIColor.blue])
                
                let explY = chartY + chartH + 15
                let explRect = CGRect(x: 30, y: explY, width: 535, height: 135)
                UIColor(white: 0.97, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: explRect, cornerRadius: 8).fill()
                techCyan.setFill()
                UIBezierPath(roundedRect: CGRect(x: 30, y: explY, width: 4, height: 135), cornerRadius: 8).fill()
                "💡 ENTENDENDO O SEU MAPA TOPOGRÁFICO:".draw(at: CGPoint(x: 45, y: explY + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: techCyan])
                var mapExplanation = ""
                if self.visionBehaviorResult.contains("Cabeça") {
                    mapExplanation = "A mira no gráfico acima revela a sua assinatura visual. O seu ponto de foco cruzou o eixo horizontal, confirmando que você é um 'Movimentador de Cabeça'. Isso significa que, para olhar para as laterais, você instintivamente vira o pescoço em vez de usar a visão periférica dos olhos. Lentes multifocais padrão costumam proporcionar uma adaptação incrivelmente fácil e natural para a sua fisiologia."
                } else if self.visionBehaviorResult.contains("Olhos") {
                    mapExplanation = "A mira no gráfico acima revela a sua assinatura visual. O seu ponto de foco cruzou o eixo vertical, confirmando que você é um 'Movimentador de Olhos'. Você possui o hábito de mover os olhos para explorar os cantos da armação enquanto mantém a cabeça estática. O seu perfil visual exige a confecção de lentes com tecnologia Freeform Avançada, garantindo bordas panorâmicas perfeitamente limpas."
                } else {
                    mapExplanation = "Mapeamento topográfico pendente. O paciente ainda não realizou o rastreamento interativo com o sensor infravermelho TrueDepth para gerar a mira de foco visual."
                }
                let styleMap = NSMutableParagraphStyle()
                styleMap.alignment = .justified
                styleMap.lineSpacing = 4
                let attrExpl = NSAttributedString(string: mapExplanation, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: techTextMain, .paragraphStyle: styleMap])
                attrExpl.draw(in: CGRect(x: 45, y: explY + 32, width: 505, height: 100))
                
                UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
                cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
                "ANEXO EXCLUSIVO PARA O CONSULTOR ÓPTICO - SYMAP 3D v2.2".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
            }
            
            // =========================================================================
            // 📄 PÁGINA 4: PRESCRIÇÃO CLÍNICA E ENGENHARIA ÓPTICA
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()
            desenharCabecalhoWhiteLabel(titulo: "PRESCRIÇÃO CLÍNICA E ENGENHARIA ÓPTICA")
            let p4BoxY: CGFloat = 120.0
            let isMultiLocal_P4 = self.selectedLensType == "Multifocal"
            let recRect_P4 = CGRect(x: 30, y: p4BoxY, width: 535, height: isMultiLocal_P4 ? 190 : 120)
            UIColor.white.setFill(); UIBezierPath(roundedRect: recRect_P4, cornerRadius: 8).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: p4BoxY, width: 6, height: recRect_P4.height), cornerRadius: 8).fill()
            "DADOS DA PRESCRIÇÃO OFTALMOLÓGICA".draw(at: CGPoint(x: 50, y: p4BoxY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
            
            var rxY_P4 = p4BoxY + 45
            "VISÃO DE LONGE:".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
            rxY_P4 += 20
            "OD ➔ ESF: \(self.rxEsfOD)  |  CIL: \(self.rxCilOD)  |  EIXO: \(self.rxEixoOD)".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])
            rxY_P4 += 25
            "OE ➔ ESF: \(self.rxEsfOE)  |  CIL: \(self.rxCilOE)  |  EIXO: \(self.rxEixoOE)".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])
            
            let insetOD_P4 = self.dnpDir - self.dnpPertoDir
            let insetOE_P4 = self.dnpEsq - self.dnpPertoEsq
            if isMultiLocal_P4 {
                rxY_P4 += 35
                "VISÃO DE PERTO (ADIÇÃO) E INSET:".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
                rxY_P4 += 20
                "OD ➔ ESF: \(self.rxEsfPertoOD)  |  CIL: \(self.rxCilPertoOD)  |  EIXO: \(self.rxEixoPertoOD)  |  INSET: \(self.f(insetOD_P4))mm".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), .foregroundColor: techCyan])
                rxY_P4 += 25
                "OE ➔ ESF: \(self.rxEsfPertoOE)  |  CIL: \(self.rxCilPertoOE)  |  EIXO: \(self.rxEixoPertoOE)  |  INSET: \(self.f(insetOE_P4))mm".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), .foregroundColor: techCyan])
            }
            
            let dcgMetade_P4 = (self.manualFrameWidth + self.noseBridgeWidth) / 2.0
            let deltaX_OD_P4 = dcgMetade_P4 - self.dnpDir
            let deltaX_OE_P4 = dcgMetade_P4 - self.dnpEsq
            let deltaY_P4 = self.pupillaryHeight > 0 ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) : 0.0
            let decentracaoObliquaOD_P4 = sqrt(pow(deltaX_OD_P4, 2) + pow(deltaY_P4, 2))
            let decentracaoObliquaOE_P4 = sqrt(pow(deltaX_OE_P4, 2) + pow(deltaY_P4, 2))
            let maxDecentration_P4 = max(decentracaoObliquaOD_P4, decentracaoObliquaOE_P4)
            let edEfetivo_P4 = self.manualFrameDiagonal > 0 ? (self.manualFrameDiagonal + (maxDecentration_P4 * 2.0)) : 0.0
            let alertY_P4 = p4BoxY + recRect_P4.height + 20
            let prismaCalculado_P4 = (maxDecentration_P4 / 10.0) * abs(maiorEE)
            let alertRect_P4 = CGRect(x: 30, y: alertY_P4, width: 535, height: 40)
            
            if prismaCalculado_P4 > 0.5 && maiorEE != 0.0 {
                UIColor.red.withAlphaComponent(0.1).setFill(); UIBezierPath(roundedRect: alertRect_P4, cornerRadius: 4).fill()
                "⚠️ ALERTA PRISMÁTICO CRÍTICO:".draw(at: CGPoint(x: 45, y: alertY_P4 + 8), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.red])
                "O paciente sofrerá um desvio de \(self.f(prismaCalculado_P4)) Δ (Prismas) devido à descentração de \(self.f(maxDecentration_P4))mm.".draw(at: CGPoint(x: 45, y: alertY_P4 + 22), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.red])
            } else {
                UIColor.green.withAlphaComponent(0.1).setFill(); UIBezierPath(roundedRect: alertRect_P4, cornerRadius: 4).fill()
                "✅ MONTAGEM SEGURA: Efeito prismático induzido está sob controle (\(self.f(prismaCalculado_P4)) Δ).".draw(at: CGPoint(x: 45, y: alertY_P4 + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor(red: 0, green: 0.6, blue: 0, alpha: 1.0)])
            }
            
            let graphY_P4 = alertY_P4 + 60
            let graphH_P4: CGFloat = 340
            let rectGraph_P4 = CGRect(x: 30, y: graphY_P4, width: 535, height: graphH_P4)
            UIColor.white.setFill(); UIBezierPath(roundedRect: rectGraph_P4, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: graphY_P4, width: 6, height: graphH_P4), cornerRadius: 6).fill()
            "TOPOGRAFIA ÓPTICA E COMPORTAMENTO FÍSICO".draw(at: CGPoint(x: 45, y: graphY_P4 + 10), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
            
            let plotX_P4: CGFloat = 45
            let plotY_P4: CGFloat = graphY_P4 + 35
            let plotW_P4: CGFloat = 490
            let plotH_P4: CGFloat = 170
            cgContext.saveGState()
            cgContext.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
            cgContext.setLineWidth(0.5)
            for i in 0...4 {
                let yPos_P4 = plotY_P4 + (plotH_P4 / 4) * CGFloat(i)
                cgContext.move(to: CGPoint(x: plotX_P4, y: yPos_P4)); cgContext.addLine(to: CGPoint(x: plotX_P4 + plotW_P4, y: yPos_P4))
            }
            for i in 0...4 {
                let xPos_P4 = plotX_P4 + (plotW_P4 / 4) * CGFloat(i)
                cgContext.move(to: CGPoint(x: xPos_P4, y: plotY_P4)); cgContext.addLine(to: CGPoint(x: xPos_P4, y: plotY_P4 + plotH_P4))
            }
            cgContext.strokePath()
            let graphCX_P4 = plotX_P4 + plotW_P4 / 2
            let graphCY_P4 = plotY_P4 + plotH_P4 / 2
            let pathCorredor_P4 = UIBezierPath()
            pathCorredor_P4.move(to: CGPoint(x: graphCX_P4, y: plotY_P4))
            pathCorredor_P4.addCurve(to: CGPoint(x: graphCX_P4 - 25, y: plotY_P4 + plotH_P4), controlPoint1: CGPoint(x: graphCX_P4, y: plotY_P4 + plotH_P4 * 0.4), controlPoint2: CGPoint(x: graphCX_P4 - 25, y: plotY_P4 + plotH_P4 * 0.6))
            UIColor.systemBlue.setStroke(); pathCorredor_P4.lineWidth = 2.0; pathCorredor_P4.stroke()
            let pathPrisma_P4 = UIBezierPath()
            pathPrisma_P4.move(to: CGPoint(x: plotX_P4, y: plotY_P4 + 10))
            pathPrisma_P4.addQuadCurve(to: CGPoint(x: plotX_P4 + plotW_P4, y: plotY_P4 + 10), controlPoint: CGPoint(x: graphCX_P4, y: plotY_P4 + plotH_P4 + 50))
            UIColor.red.setStroke(); pathPrisma_P4.lineWidth = 1.5; cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0]); pathPrisma_P4.stroke()
            let pathCurva_P4 = UIBezierPath()
            pathCurva_P4.move(to: CGPoint(x: plotX_P4 + 15, y: graphCY_P4 + 10))
            pathCurva_P4.addQuadCurve(to: CGPoint(x: plotX_P4 + plotW_P4 - 15, y: graphCY_P4 + 10), controlPoint: CGPoint(x: graphCX_P4, y: plotY_P4 - 15))
            UIColor(red: 0, green: 0.7, blue: 0, alpha: 1.0).setStroke(); pathCurva_P4.lineWidth = 1.5; cgContext.setLineDash(phase: 0, lengths: [2.0, 2.0]); pathCurva_P4.stroke()
            cgContext.setLineDash(phase: 0, lengths: [])
            cgContext.restoreGState()
            
            let legY_P4: CGFloat = plotY_P4 + plotH_P4 + 25
            let legTitleFont_P4 = UIFont.systemFont(ofSize: 9, weight: .bold)
            let legDescFont_P4 = UIFont.systemFont(ofSize: 8)
            func desenharLegendaLocal(titulo: String, desc: String, cor: UIColor, dash: [CGFloat], x: CGFloat, y: CGFloat) {
                cgContext.saveGState()
                cor.setStroke(); cgContext.setLineWidth(2.0); cgContext.setLineDash(phase: 0, lengths: dash)
                cgContext.move(to: CGPoint(x: x, y: y + 4)); cgContext.addLine(to: CGPoint(x: x + 18, y: y + 4))
                cgContext.strokePath()
                cgContext.restoreGState()
                titulo.draw(at: CGPoint(x: x + 25, y: y), withAttributes: [.font: legTitleFont_P4, .foregroundColor: techBlack])
                desc.draw(at: CGPoint(x: x + 25, y: y + 12), withAttributes: [.font: legDescFont_P4, .foregroundColor: UIColor.gray])
            }
            desenharLegendaLocal(titulo: "Corredor Progressivo", desc: "Senoide de Convergência", cor: .systemBlue, dash: [], x: 45, y: legY_P4)
            desenharLegendaLocal(titulo: "Estresse Prismático", desc: "Distorção de borda", cor: .red, dash: [4.0, 4.0], x: 220, y: legY_P4)
            desenharLegendaLocal(titulo: "Curvatura Base", desc: "Arco do Menisco", cor: UIColor(red: 0, green: 0.7, blue: 0, alpha: 1.0), dash: [2.0, 2.0], x: 380, y: legY_P4)
            
            var curvaBaseIdeal_P4: Float = 0.0
            if maiorEE > 0 { curvaBaseIdeal_P4 = maiorEE + 6.0 } else if maiorEE < 0 { curvaBaseIdeal_P4 = (maiorEE / 2.0) + 6.0 }
            let raioLente_P4 = edEfetivo_P4 / 2.0
            var indiceRefracao_P4: Float = 1.50
            var nomeMaterial_P4 = "CR-39 / Resina Comum"
            if abs(maiorEE) > 6.0 {
                indiceRefracao_P4 = 1.74; nomeMaterial_P4 = "Alto Índice (1.74)"
            } else if abs(maiorEE) > 4.0 {
                indiceRefracao_P4 = 1.67; nomeMaterial_P4 = "Resina Média (1.67)"
            } else if abs(maiorEE) > 2.0 {
                indiceRefracao_P4 = 1.59; nomeMaterial_P4 = "Policarbonato (1.59)"
            }
            let espessuraBorda_P4 = (abs(maiorEE) * pow(raioLente_P4, 2)) / (2000.0 * (indiceRefracao_P4 - 1.0))
            var engY_P4 = legY_P4 + 45
            "-> ENGENHARIA ÓPTICA APLICADA:".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .black), .foregroundColor: techCyan])
            engY_P4 += 18
            if maiorEE != 0.0 {
                "Curva Base Recomendada (Sagitta): \(self.f(curvaBaseIdeal_P4))".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
                engY_P4 += 16
                "Espessura Máxima Estimada (\(nomeMaterial_P4)): \(self.f(espessuraBorda_P4)) mm".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
            } else {
                "Aguardando preenchimento da receita para calcular Sagitta e Curva Base.".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray])
            }
            
            UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
            cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
            "IMPRIMIR SEMPRE EM ESCALA 100% (SEM AJUSTAR À PÁGINA) MANTENDO PROPORÇÃO 1:1 A4".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.red])
        }
    }
    
    @objc func startTutorial() {
        tutorialStepIndex = 0
        if tutorialOverlay == nil {
            tutorialOverlay = UIView(frame: view.bounds); tutorialOverlay?.isUserInteractionEnabled = true
            dimmingView = UIView(frame: view.bounds); dimmingView?.backgroundColor = UIColor.black.withAlphaComponent(0.9); dimmingView?.isUserInteractionEnabled = false; tutorialOverlay?.addSubview(dimmingView!)
            tutorialArrowView = createArrowView(); tutorialOverlay?.addSubview(tutorialArrowView!)
            let skp = UIButton(frame: CGRect(x:view.bounds.width-90, y:50, width:70, height:35)); skp.setTitle("Pular", for:.normal); skp.backgroundColor = .gray; skp.layer.cornerRadius=8; skp.addTarget(self, action: #selector(endTutorial), for:.touchUpInside); tutorialOverlay?.addSubview(skp)
            let nxt = UIButton(frame: CGRect(x:(view.bounds.width-120)/2, y:view.bounds.height/2+160, width:120, height:40)); nxt.setTitle("Próximo", for:.normal); nxt.backgroundColor = UIColor(red:0.2, green:0.6, blue:1, alpha:1); nxt.layer.cornerRadius=20; nxt.addTarget(self, action: #selector(nextTutorialStep), for:.touchUpInside); tutorialOverlay?.addSubview(nxt)
            tutorialLabel = UILabel(frame: CGRect(x:20, y:view.bounds.height/2+10, width:view.bounds.width-40, height:140)); tutorialLabel?.numberOfLines=0; tutorialLabel?.textColor = .white; tutorialLabel?.textAlignment = .center; tutorialLabel?.font = UIFont.boldSystemFont(ofSize:18); tutorialLabel?.adjustsFontSizeToFitWidth=true; tutorialLabel?.minimumScaleFactor = 0.5; tutorialOverlay?.addSubview(tutorialLabel!)
            view.addSubview(tutorialOverlay!)
        }
        tutorialOverlay?.isHidden = false
        showTutorialStep(); animateArrow()
    }
    
    func createArrowView() -> UIView {   let v=UIView(frame:CGRect(x:0,y:0,width:40,height:40)); let p=UIBezierPath(); p.move(to:CGPoint(x:0,y:0)); p.addLine(to:CGPoint(x:40,y:0)); p.addLine(to:CGPoint(x:20,y:35)); p.close(); let l=CAShapeLayer(); l.path=p.cgPath; l.fillColor=UIColor.white.cgColor; v.layer.addSublayer(l); return v }
    
    func animateArrow() {   let a=CABasicAnimation(keyPath:"transform.translation.y"); a.fromValue = -5; a.toValue = 5; a.duration=0.8; a.autoreverses=true; a.repeatCount = .infinity; tutorialArrowView?.layer.add(a, forKey:"bob") }
    
    @objc func nextTutorialStep() { tutorialStepIndex+=1; if tutorialStepIndex>=4 { endTutorial() } else { showTutorialStep() } }
    
    func showTutorialStep() {
        var tf=CGRect.zero; var txt=""; var dir="down"
        switch tutorialStepIndex {
        case 0: tf=levelLabel.frame.union(levelContainerView.frame).insetBy(dx:-20,dy:-20); txt="1. NÍVEL DO CELULAR\nMantenha o celular reto. A bolha deve ficar verde no centro."; dir="down"
        case 1: tf=headLevelLabel.frame.union(headLevelContainerView.frame).insetBy(dx:-20,dy:-20); txt="2. INCLINAÇÃO DA CABEÇA\nAlinhe sua cabeça. Olhe para frente até esta bolha ficar verde."; dir="down"
        case 2: tf=startCaptureButton.frame; txt="3. INICIAR CAPTURA\nToque para começar. O sistema aguarda 1 segundo de estabilidade antes de capturar."; dir="up"
        case 3: tf=btnToggleGuides.frame; txt="4. GUIAS VISUAIS\nToque aqui para ver a máscara biométrica."; dir="up"
        default: break
        }
        tutorialLabel?.text = txt
        if let arr = tutorialArrowView { if dir=="down" { arr.transform = .identity; arr.center = CGPoint(x:tf.midX, y:tf.minY-30) } else { arr.transform = CGAffineTransform(rotationAngle: .pi); arr.center = CGPoint(x:tf.midX, y:tf.maxY+30) } }
        let p = UIBezierPath(rect: view.bounds); p.append(UIBezierPath(roundedRect: (tutorialStepIndex>=2 ? tf.insetBy(dx:-10,dy:-10) : tf), cornerRadius: 15)); p.usesEvenOddFillRule=true; let m = CAShapeLayer(); m.path = p.cgPath; m.fillRule = .evenOdd; dimmingView?.layer.mask = m
    }
    
    @objc func endTutorial() { tutorialOverlay?.isHidden = true }
    
    // --- LENTES SETUP ---
    func setupLensSelectorUI() {
        let items = ["Visão Simples", "Multifocal", "Bifocal", "Ocupacional"]
        lensTypeSegment = UISegmentedControl(items: items)
        let instrY = measurementsContainer.frame.maxY + 15
        lensTypeSegment.frame = CGRect(x: 15, y: instrY, width: view.bounds.width - 30, height: 35)
        lensTypeSegment.selectedSegmentIndex = 0
        lensTypeSegment.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        lensTypeSegment.selectedSegmentTintColor = UIColor.systemBlue
        let normalAttr = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let selectedAttr = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        lensTypeSegment.setTitleTextAttributes(normalAttr, for: .normal)
        lensTypeSegment.setTitleTextAttributes(selectedAttr, for: .selected)
        lensTypeSegment.addTarget(self, action: #selector(lensTypeChanged), for: .valueChanged)
        lensTypeSegment.isHidden = true
        view.addSubview(lensTypeSegment)
    }
    
    @objc func lensTypeChanged() {
        selectedLensType = lensTypeSegment.titleForSegment(at: lensTypeSegment.selectedSegmentIndex) ?? "Visão Simples"
    }
    
    // --- DESENHO SETUP ---
    func setupDrawingSystem() {
        canvasView = PKCanvasView(frame: view.bounds)
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.isHidden = true
        view.insertSubview(canvasView, aboveSubview: sceneView)
        let paletteW: CGFloat = 320
        let paletteH: CGFloat = 60
        let btnY = view.bounds.height - 100
        let bottomButtonY = btnY + 10
        let gap: CGFloat = 15
        let buttonSize: CGFloat = 60
        let pencilY = bottomButtonY - (buttonSize + gap)
        drawingToolsContainer = UIView(frame: CGRect(x: 100, y: pencilY, width: paletteW, height: paletteH))
        drawingToolsContainer.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        drawingToolsContainer.layer.cornerRadius = 30
        drawingToolsContainer.layer.borderWidth = 1
        drawingToolsContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        drawingToolsContainer.isHidden = true
        drawingToolsContainer.alpha = 0.0
        view.addSubview(drawingToolsContainer)
        let btnSize: CGFloat = 44
        let btnSpacing = (paletteW - (btnSize * 5)) / 6
        let toolY: CGFloat = (paletteH - btnSize) / 2
        func createColorBtn(color: UIColor, index: Int, action: Selector) -> UIButton {
            let x = btnSpacing + CGFloat(index) * (btnSize + btnSpacing)
            let b = UIButton(frame: CGRect(x: x, y: toolY, width: btnSize, height: btnSize))
            b.backgroundColor = color; b.layer.cornerRadius = btnSize/2; b.layer.borderWidth = 2; b.layer.borderColor = UIColor.white.cgColor
            b.addTarget(self, action: action, for: .touchUpInside)
            return b
        }
        btnDrawRed = createColorBtn(color: .red, index: 0, action: #selector(setToolRed))
        btnDrawBlack = createColorBtn(color: .black, index: 1, action: #selector(setToolBlack))
        btnDrawBlue = createColorBtn(color: .blue, index: 2, action: #selector(setToolBlue))
        btnEraser = UIButton(frame: CGRect(x: btnSpacing + 3 * (btnSize + btnSpacing), y: toolY, width: btnSize, height: btnSize))
        btnEraser.backgroundColor = .gray; btnEraser.setTitle("🧹", for: .normal); btnEraser.layer.cornerRadius = btnSize/2
        btnEraser.addTarget(self, action: #selector(setToolEraser), for: .touchUpInside)
        btnClearDrawing = UIButton(frame: CGRect(x: btnSpacing + 4 * (btnSize + btnSpacing), y: toolY, width: btnSize, height: btnSize))
        btnClearDrawing.backgroundColor = .darkGray; btnClearDrawing.setTitle("🗑️", for: .normal); btnClearDrawing.layer.cornerRadius = btnSize/2
        btnClearDrawing.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        drawingToolsContainer.addSubview(btnDrawRed); drawingToolsContainer.addSubview(btnDrawBlack); drawingToolsContainer.addSubview(btnDrawBlue)
        drawingToolsContainer.addSubview(btnEraser); drawingToolsContainer.addSubview(btnClearDrawing)
    }
    
    @objc func activateDrawingMode() {
        isDrawingActive = true; canvasView.isHidden = false; canvasView.isUserInteractionEnabled = true
        btnToggleDrawing.backgroundColor = UIColor.systemGray; btnToggleDrawing.transform = .identity
        UIView.animate(withDuration: 0.2) { self.drawingToolsContainer.alpha = 0.0; self.drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0) } completion: { _ in self.drawingToolsContainer.isHidden = true }
    }
    
    @objc func setToolRed() { canvasView.tool = PKInkingTool(.marker, color: .red, width: 5); highlightBtn(btnDrawRed); activateDrawingMode() }
    @objc func setToolBlack() { canvasView.tool = PKInkingTool(.marker, color: .black, width: 5); highlightBtn(btnDrawBlack); activateDrawingMode() }
    @objc func setToolBlue() { canvasView.tool = PKInkingTool(.marker, color: .blue, width: 5); highlightBtn(btnDrawBlue); activateDrawingMode() }
    @objc func setToolEraser() { canvasView.tool = PKEraserTool(.bitmap); highlightBtn(btnEraser); activateDrawingMode() }
    @objc func clearCanvas() { canvasView.drawing = PKDrawing() }
    
    func highlightBtn(_ sender: UIButton) { let buttons = [btnDrawRed, btnDrawBlack, btnDrawBlue, btnEraser]; buttons.forEach { $0?.transform = .identity; $0?.alpha = 0.6 }; sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2); sender.alpha = 1.0 }
    
    @objc func toggleDrawingPanel() {
        if isDrawingActive {
            isDrawingActive = false; canvasView.isUserInteractionEnabled = false
            btnToggleDrawing.backgroundColor = UIColor(white: 0.2, alpha: 0.9); btnToggleDrawing.transform = .identity
            drawingToolsContainer.isHidden = true; drawingToolsContainer.alpha = 0.0
        } else {
            if drawingToolsContainer.isHidden {
                drawingToolsContainer.isHidden = false; drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0); drawingToolsContainer.alpha = 0.0
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) { self.drawingToolsContainer.transform = .identity; self.drawingToolsContainer.alpha = 1.0 }
            } else {
                UIView.animate(withDuration: 0.2, animations: { self.drawingToolsContainer.alpha = 0.0; self.drawingToolsContainer.transform = CGAffineTransform(translationX: -20, y: 0) }) { _ in self.drawingToolsContainer.isHidden = true }
            }
        }
    }
    
    // =========================================================================
    // --- MANUAL MEASUREMENT (UNIFICADO COM RÉGUA AMARELA) ---
    // =========================================================================
    func setupManualMeasurementUI() {
        let iconOff = UIImage(systemName: "xmark.circle")!
        let iconMont = UIImage(systemName: "scope")!
        let iconVert = UIImage(systemName: "arrow.up.and.down")!
        let iconHoriz = UIImage(systemName: "arrow.left.and.right")!
        let iconDiag = UIImage(systemName: "arrow.up.right.and.arrow.down.left")!
        
        measurementTypeSegment = UISegmentedControl(items: [iconOff, iconMont, iconVert, iconHoriz, iconDiag])
        
        //  CORREÇÃO UX: Subimos o menu eliminando o espaço vazio da antiga seleção de lentes
        let instrY = measurementsContainer.frame.maxY + 15
        
        measurementTypeSegment.frame = CGRect(x: 15, y: instrY, width: view.bounds.width - 30, height: 35)
        measurementTypeSegment.selectedSegmentIndex = 0
        measurementTypeSegment.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        measurementTypeSegment.selectedSegmentTintColor = UIColor.systemGreen
        
        let normalAttr = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let selectedAttr = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        
        measurementTypeSegment.setTitleTextAttributes(normalAttr, for: .normal)
        measurementTypeSegment.setTitleTextAttributes(selectedAttr, for: .selected)
        measurementTypeSegment.addTarget(self, action: #selector(measurementTypeChanged), for: .valueChanged)
        measurementTypeSegment.isHidden = true
        view.addSubview(measurementTypeSegment)
        
        manualMeasureContainer = UIView(frame: view.bounds)
        manualMeasureContainer.isUserInteractionEnabled = true
        manualMeasureContainer.backgroundColor = .clear
        manualMeasureContainer.isHidden = true
        view.addSubview(manualMeasureContainer)
        
        manualLineLayer = CAShapeLayer()
        manualLineLayer.strokeColor = UIColor.yellow.cgColor
        manualLineLayer.lineWidth = 2.0
        manualLineLayer.fillColor = UIColor.yellow.cgColor
        manualMeasureContainer.layer.addSublayer(manualLineLayer)
        
        manualHandleA = createHandle(text: "A", color: .yellow)
        manualHandleB = createHandle(text: "B", color: .yellow)
        
        manualMeasureContainer.addSubview(manualHandleA)
        manualMeasureContainer.addSubview(manualHandleB)
        
        manualMeasureLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 25))
        manualMeasureLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        manualMeasureLabel.textColor = .yellow
        manualMeasureLabel.textAlignment = .center
        manualMeasureLabel.font = UIFont.boldSystemFont(ofSize: 14)
        manualMeasureLabel.layer.cornerRadius = 5
        manualMeasureLabel.clipsToBounds = true
        manualMeasureContainer.addSubview(manualMeasureLabel)
        
        btnSaveManual = UIButton(frame: CGRect(x: (view.bounds.width - 160)/2, y: view.bounds.height - 150, width: 160, height: 50))
        btnSaveManual.backgroundColor = UIColor.green.withAlphaComponent(0.95)
        btnSaveManual.setTitle("Salvar Medida", for: .normal)
        btnSaveManual.setTitleColor(.white, for: .normal)
        btnSaveManual.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnSaveManual.layer.cornerRadius = 25
        btnSaveManual.layer.borderWidth = 2
        btnSaveManual.layer.borderColor = UIColor.white.cgColor
        btnSaveManual.addTarget(self, action: #selector(saveManualMeasurement), for: .touchUpInside)
        btnSaveManual.isHidden = true
        view.addSubview(btnSaveManual)
    }
    // =========================================================================
    // ARRASTE DA RÉGUA MANUAL (RESTAURADO)
    // =========================================================================
    @objc func handleManualPan(_ gesture: UIPanGestureRecognizer) {
            guard let v = gesture.view else { return }
            let t = gesture.translation(in: view)
            v.center = CGPoint(x: v.center.x + t.x, y: v.center.y + t.y)
            gesture.setTranslation(.zero, in: view)
            
            if currentManualMode == 2 {
                if v == manualHandleA { manualHandleB.center.x = manualHandleA.center.x }
                else if v == manualHandleB { manualHandleA.center.x = manualHandleB.center.x }
            } else if currentManualMode == 3 {
                if v == manualHandleA { manualHandleB.center.y = manualHandleA.center.y }
                else if v == manualHandleB { manualHandleA.center.y = manualHandleB.center.y }
            }
            
            // 🔴 NOVO: Vibração física de alta precisão ao movimentar a régua!
            impactFeedback.impactOccurred(intensity: 0.4)
            
            updateManualMeasurement()
        }
    
    @objc func measurementTypeChanged() {
        let index = measurementTypeSegment.selectedSegmentIndex
        if index == 0 { saveManualMeasurement() } else { startManualMeasurement(mode: index) }
    }
    
    func updateSegmentTitles() {
        let iconMont = pupillaryHeight > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "scope")!
        let iconVert = manualFrameHeight > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.up.and.down")!
        let iconHoriz = manualFrameWidth > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.left.and.right")!
        let iconDiag = manualFrameDiagonal > 0 ? UIImage(systemName: "checkmark.circle.fill")! : UIImage(systemName: "arrow.up.right.and.arrow.down.left")!
        measurementTypeSegment.setImage(iconMont, forSegmentAt: 1)
        measurementTypeSegment.setImage(iconVert, forSegmentAt: 2)
        measurementTypeSegment.setImage(iconHoriz, forSegmentAt: 3)
        measurementTypeSegment.setImage(iconDiag, forSegmentAt: 4)
    }
    // =========================================================================
    // INICIA A MEDIÇÃO MANUAL (Limpo: Sem os antigos pantoHandles)
    // =========================================================================
    func startManualMeasurement(mode: Int) {
            currentManualMode = mode
            btnSaveManual.isHidden = false
            // 🔴 Trava o seletor para obrigar o clique no Salvar Medida
            measurementTypeSegment.isEnabled = false
            updateManualInterface(active: true)
            if !drawingToolsContainer.isHidden { toggleDrawingPanel() }
            let cx = view.bounds.midX
            let cy = view.bounds.midY
            manualMeasureContainer.isHidden = true
            heightLineView.isHidden = true
            heightLineView.isUserInteractionEnabled = false
            if mode == 1 {
                heightLineView.isHidden = false
                heightLineView.isUserInteractionEnabled = true
                heightLineView.alpha = 1.0
                if pupillaryHeight == 0 {
                    heightLineView.center.y = cy + 50
                    calculatePupilHeight()
                }
            } else if mode >= 2 && mode <= 4 {
                manualMeasureContainer.isHidden = false
                if mode == 2 {
                    manualHandleA.center = CGPoint(x: cx, y: cy - 40); manualHandleB.center = CGPoint(x: cx, y: cy + 40)
                } else if mode == 3 {
                    manualHandleA.center = CGPoint(x: cx - 60, y: cy); manualHandleB.center = CGPoint(x: cx + 60, y: cy)
                } else if mode == 4 {
                    manualHandleA.center = CGPoint(x: cx - 50, y: cy - 40); manualHandleB.center = CGPoint(x: cx + 50, y: cy + 40)
                }
                updateManualMeasurement()
            }
        }

        @objc func saveManualMeasurement() {
            manualMeasureContainer.isHidden = true
            heightLineView.isHidden = true
            heightLineView.isUserInteractionEnabled = false
            btnSaveManual.isHidden = true
            currentManualMode = 0
            // 🔴 Libera o seletor novamente
            measurementTypeSegment.isEnabled = true
            if measurementTypeSegment.selectedSegmentIndex != 0 {
                measurementTypeSegment.selectedSegmentIndex = 0
            }
            updateManualInterface(active: false)
            updateSegmentTitles()
            btnSaveManual.setTitle("Salvar Medida", for: .normal)
        }
    // =========================================================================
    // ATUALIZA A RÉGUA EM TEMPO REAL (Limpo: Bloco if == 99 totalmente removido)
    // =========================================================================
    func updateManualMeasurement() {
        let p1 = manualHandleA.center; let p2 = manualHandleB.center
        let path = UIBezierPath()
        path.move(to: p1); path.addLine(to: p2)
        
        let angle = atan2(p2.y - p1.y, p2.x - p1.x)
        let arrowSize: CGFloat = 10.0
        
        path.move(to: p1); path.addLine(to: CGPoint(x: p1.x + arrowSize * cos(angle + .pi/6), y: p1.y + arrowSize * sin(angle + .pi/6)))
        path.move(to: p1); path.addLine(to: CGPoint(x: p1.x + arrowSize * cos(angle - .pi/6), y: p1.y + arrowSize * sin(angle - .pi/6)))
        path.move(to: p2); path.addLine(to: CGPoint(x: p2.x + arrowSize * cos(angle + .pi - .pi/6), y: p2.y + arrowSize * sin(angle + .pi - .pi/6)))
        path.move(to: p2); path.addLine(to: CGPoint(x: p2.x + arrowSize * cos(angle + .pi + .pi/6), y: p2.y + arrowSize * sin(angle + .pi + .pi/6)))
        
        manualLineLayer.path = path.cgPath
        
        let labelY = measurementTypeSegment.frame.maxY + 10
        let labelW: CGFloat = 120
        let labelX = view.bounds.width - labelW - 20
        manualMeasureLabel.frame = CGRect(x: labelX, y: labelY, width: labelW, height: 30)
        
        if let lEye = lastLeftEyeWorldPos, let rEye = lastRightEyeWorldPos, let cam = sceneView.pointOfView {
            let cx = (lEye.x + rEye.x) / 2.0
            let cy = (lEye.y + rEye.y) / 2.0
            let cz = (lEye.z + rEye.z) / 2.0
            let camPos = cam.worldPosition
            
            let dirX = camPos.x - cx
            let dirY = camPos.y - cy
            let dirZ = camPos.z - cz
            let distance = sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
            
            let frameZPos = SCNVector3(
                cx + (dirX / distance) * 0.015,
                cy + (dirY / distance) * 0.015,
                cz + (dirZ / distance) * 0.015
            )
            
            let frameScreenZ = sceneView.projectPoint(frameZPos).z
            let p3DA = sceneView.unprojectPoint(SCNVector3(Float(p1.x), Float(p1.y), frameScreenZ))
            let p3DB = sceneView.unprojectPoint(SCNVector3(Float(p2.x), Float(p2.y), frameScreenZ))
            let rawDistMm = sqrt(pow(p3DB.x - p3DA.x, 2) + pow(p3DB.y - p3DA.y, 2) + pow(p3DB.z - p3DA.z, 2)) * 1000.0
            
            var distMm: Float = 0.0
            
            // Aplicação das Constantes de Calibração (Enum)
            if currentManualMode == 2 {
                distMm = rawDistMm * CalibrationFactors.manualHeight
                manualFrameHeight = distMm
            } else if currentManualMode == 3 {
                distMm = rawDistMm * CalibrationFactors.manualWidth
                manualFrameWidth = distMm
            } else if currentManualMode == 4 {
                distMm = rawDistMm * CalibrationFactors.manualDiagonal
                manualFrameDiagonal = distMm
            } else if currentManualMode == 1 {
                distMm = rawDistMm * CalibrationFactors.pupilHeight
                pupillaryHeight = distMm
                updateLabels()
            }
            
            manualMeasureLabel.text = String(format: "%.1f mm", distMm)
        }
    }
    // =========================================================================
    // --- ESPELHO INTELIGENTE (COMPARAÇÃO) E UI HELPERS ---
    // =========================================================================
    @objc func addToComparison() {
        // Trava de limite de memória: Máximo de 10 fotos na galeria
        if comparisonImages.count >= 10 {
            let alert = UIAlertController(title: "Limite Atingido", message: "Limite atingido, remova alguma.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        let snap = sceneView.snapshot()
        comparisonImages.append(snap)
        
        let flash = UIView(frame: view.bounds)
        flash.backgroundColor = .white
        flash.alpha = 0.5
        view.addSubview(flash)
        
        UIView.animate(withDuration: 0.2) {
            flash.alpha = 0.0
        } completion: { _ in
            flash.removeFromSuperview()
        }
        
        if comparisonImages.count > 0 {
            btnShowCompare.isHidden = false
            btnShowCompare.setTitle("\(comparisonImages.count)", for: .normal)
        }
    }
    
    @objc func showComparisonUI() {
        guard comparisonImages.count > 0 else { return }
        comparisonOverlay = UIView(frame: view.bounds)
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        comparisonOverlay?.addSubview(blurView)
        
        let closeBtn = UIButton(frame: CGRect(x: view.bounds.width - 60, y: 40, width: 40, height: 40))
        closeBtn.setTitle("X", for: .normal)
        closeBtn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeBtn.layer.cornerRadius = 20
        closeBtn.addTarget(self, action: #selector(closeComparison), for: .touchUpInside)
        comparisonOverlay?.addSubview(closeBtn)
        
        let clearBtn = UIButton(frame: CGRect(x: 20, y: 40, width: 120, height: 40))
        clearBtn.setTitle("Limpar Tudo", for: .normal)
        clearBtn.setTitleColor(.systemRed, for: .normal)
        clearBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        clearBtn.addTarget(self, action: #selector(clearComparisons), for: .touchUpInside)
        comparisonOverlay?.addSubview(clearBtn)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 120, width: view.bounds.width, height: view.bounds.height - 180))
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        
        let cardW = view.bounds.width * 0.8
        let cardH = cardW * 1.4
        let spacing = view.bounds.width * 0.1
        var xOffset = spacing
        
        for (i, img) in comparisonImages.enumerated() {
            let cardView = UIView(frame: CGRect(x: xOffset, y: 20, width: cardW, height: cardH))
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.5
            cardView.layer.shadowRadius = 20
            cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
            
            let iv = UIImageView(frame: cardView.bounds)
            iv.image = img
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 24
            iv.clipsToBounds = true
            cardView.addSubview(iv)
            
            let lbl = UILabel(frame: CGRect(x: 0, y: cardH + 20, width: cardW, height: 30))
            lbl.text = "OPÇÃO \(i + 1)"
            lbl.textColor = .white
            lbl.textAlignment = .center
            lbl.font = UIFont.systemFont(ofSize: 16, weight: .black)
            cardView.addSubview(lbl)
            
            //  NOVO: Botão de Lixeira Individual
            let deleteBtn = UIButton(frame: CGRect(x: cardW - 55, y: 15, width: 40, height: 40))
            deleteBtn.setTitle("X - Descartar", for: .normal)
            deleteBtn.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            deleteBtn.layer.cornerRadius = 20
            deleteBtn.tag = i // Atrela o índice da imagem ao botão
            deleteBtn.addTarget(self, action: #selector(deleteSingleComparison(_:)), for: .touchUpInside)
            cardView.addSubview(deleteBtn)
            
            scrollView.addSubview(cardView)
            xOffset += view.bounds.width
        }
        
        scrollView.contentSize = CGSize(width: xOffset - spacing, height: cardH + 50)
        comparisonOverlay?.addSubview(scrollView)
        view.addSubview(comparisonOverlay!)
    }
    
    @objc func closeComparison() { comparisonOverlay?.removeFromSuperview(); comparisonOverlay = nil }
    
    @objc func clearComparisons() { comparisonImages.removeAll(); btnShowCompare.isHidden = true; closeComparison() }
    
    //  NOVA LÓGICA: Exclusão individual atrelada ao índice da lixeira
    @objc func deleteSingleComparison(_ sender: UIButton) {
        let indexToRemove = sender.tag
        
        if indexToRemove >= 0 && indexToRemove < comparisonImages.count {
            // Remove cirurgicamente a foto da matriz
            comparisonImages.remove(at: indexToRemove)
            
            if comparisonImages.isEmpty {
                // Se era a última foto, fecha o espelho e esconde o botão
                btnShowCompare.isHidden = true
                closeComparison()
            } else {
                // Atualiza o contador na tela principal
                btnShowCompare.setTitle("\(comparisonImages.count)", for: .normal)
                
                // Reconstrói a interface para recalcular os índices e posicionamentos
                closeComparison()
                showComparisonUI()
            }
        }
    }
    
    func createHandle(text: String = "", color: UIColor = .yellow) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleManualPan(_:)))
        v.addGestureRecognizer(pan)
        let lbl = UILabel(frame: CGRect(x: 15, y: -5, width: 30, height: 20))
        lbl.text = text
        lbl.textColor = color
        lbl.textAlignment = .center
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.tag = 999
        lbl.isHidden = true
        v.addSubview(lbl)
        return v
    }
    
    func setupHeightRulerUI() {
        let width = view.bounds.width; let centerY = view.bounds.height / 2
        heightLineView = UIView(frame: CGRect(x: 0, y: centerY + 50, width: width, height: 2)); heightLineView.backgroundColor = UIColor.red.withAlphaComponent(0.8); heightLineView.isHidden = true
        let hitArea = UIView(frame: CGRect(x: 0, y: -20, width: width, height: 42)); hitArea.backgroundColor = .clear; heightLineView.addSubview(hitArea)
        heightLineLabel = UILabel(frame: CGRect(x: 20, y: -25, width: 150, height: 20)); heightLineLabel.text = "H: 0.0mm"; heightLineLabel.textColor = .red; heightLineLabel.font = UIFont.boldSystemFont(ofSize: 14); heightLineLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5); heightLineView.addSubview(heightLineLabel); view.addSubview(heightLineView)
    }
    
    func setupLevelUI() {
        let containerY: CGFloat = 80.0
        let padding: CGFloat = 15
        let colWidth = (view.bounds.width - (padding * 3)) / 2
        let height: CGFloat = 12
        
        func createSensor(title: String, x: CGFloat, y: CGFloat) -> (UILabel, UIView, UIView, UIView) {
            // 🔴 CORREÇÃO 2: Acessibilidade - Fonte maior, branca e com sombra profunda
            let lbl = UILabel(frame: CGRect(x: x, y: y, width: colWidth, height: 18))
            lbl.text = title
            lbl.font = UIFont.systemFont(ofSize: 11, weight: .black)
            lbl.textColor = .white
            lbl.textAlignment = .center
            lbl.layer.shadowColor = UIColor.black.cgColor
            lbl.layer.shadowRadius = 2.0
            lbl.layer.shadowOpacity = 0.8
            lbl.layer.shadowOffset = CGSize(width: 1, height: 1)
            view.addSubview(lbl)
            
            let container = UIView(frame: CGRect(x: x, y: y + 22, width: colWidth, height: height))
            container.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
            container.layer.cornerRadius = height / 2
            container.layer.borderWidth = 1; container.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            container.clipsToBounds = true
            view.addSubview(container)
            
            let target = UIView(frame: CGRect(x: (colWidth - 25) / 2, y: 0, width: 25, height: height))
            target.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            target.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            target.layer.borderWidth = 0.5
            container.addSubview(target)
            
            let bubble = UIView(frame: CGRect(x: (colWidth - 10) / 2, y: (height - 10) / 2, width: 10, height: 10))
            bubble.backgroundColor = .red; bubble.layer.cornerRadius = 5
            container.addSubview(bubble)
            
            return (lbl, container, target, bubble)
        }
        
        let leftX = padding
        let rightX = padding * 2 + colWidth
        
        let phoneLat = createSensor(title: "CELULAR (LATERAL)", x: leftX, y: containerY)
        levelLabel = phoneLat.0; levelContainerView = phoneLat.1; levelTargetZone = phoneLat.2; levelBubbleView = phoneLat.3
        
        let headLat = createSensor(title: "CABEÇA (LATERAL)", x: rightX, y: containerY)
        headLevelLabel = headLat.0; headLevelContainerView = headLat.1; headLevelTargetZone = headLat.2; headLevelBubbleView = headLat.3
        
        let row2Y = containerY + 45
        let phoneFront = createSensor(title: "CELULAR (FRENTE/TRÁS)", x: leftX, y: row2Y)
        phonePitchLabel = phoneFront.0; phonePitchContainerView = phoneFront.1; phonePitchTargetZone = phoneFront.2; phonePitchBubbleView = phoneFront.3
        
        let headFront = createSensor(title: "CABEÇA (FRENTE/TRÁS)", x: rightX, y: row2Y)
        headPitchLabel = headFront.0; headPitchContainerView = headFront.1; headPitchTargetZone = headFront.2; headPitchBubbleView = headFront.3
    }
    
    func setupCountdownUI() {
        let size: CGFloat = 160
        countdownLabel = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
        countdownLabel.center = view.center
        countdownLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 70, weight: .bold)
        countdownLabel.textColor = .white
        countdownLabel.textAlignment = .center
        countdownLabel.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        countdownLabel.layer.cornerRadius = size / 2
        countdownLabel.clipsToBounds = true
        countdownLabel.layer.borderWidth = 4
        countdownLabel.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        countdownLabel.isHidden = true
        view.addSubview(countdownLabel)
    }
    
    // =========================================================================
    // GUIAS AR DA MÁSCARA 3D
    // =========================================================================
    @objc func toggleGuides() {
        isGuidesActive.toggle();
        if isGuidesActive {
            btnToggleGuides.backgroundColor = UIColor.systemBlue;
            techMaskNode?.isHidden = false
        } else {
            btnToggleGuides.backgroundColor = UIColor(white: 0.2, alpha: 0.9);
            techMaskNode?.isHidden = true
        }
    }
    
    func setupTechMask(on faceNode: SCNNode) {
        let container = SCNNode(); container.position = SCNVector3(0, 0, 0.06); faceNode.addChildNode(container); self.techMaskNode = container
        container.isHidden = true
        let frameGeo = SCNBox(width: 0.18, height: 0.24, length: 0.001, chamferRadius: 0.0); let frameMat = SCNMaterial(); frameMat.diffuse.contents = UIColor.white.withAlphaComponent(0.4); frameMat.lightingModel = .constant; frameMat.fillMode = .lines; frameGeo.firstMaterial = frameMat; let frameNode = SCNNode(geometry: frameGeo); frameNode.position = SCNVector3(0, 0.01, 0); container.addChildNode(frameNode)
        let pupilGeo = SCNCylinder(radius: 0.0015, height: 0.12); pupilGeo.firstMaterial?.diffuse.contents = UIColor.cyan; pupilGeo.firstMaterial?.lightingModel = .constant; pupilLineNode = SCNNode(geometry: pupilGeo); pupilLineNode?.eulerAngles.z = .pi / 2; pupilLineNode?.position.y = 0.02; container.addChildNode(pupilLineNode!)
        let centerGeo = SCNCylinder(radius: 0.001, height: 0.20); centerGeo.firstMaterial?.diffuse.contents = UIColor.magenta; centerGeo.firstMaterial?.lightingModel = .constant; let centerNode = SCNNode(geometry: centerGeo); container.addChildNode(centerNode)
        let mouthGeo = SCNCylinder(radius: 0.001, height: 0.08); mouthGeo.firstMaterial?.diffuse.contents = UIColor.systemGreen; mouthGeo.firstMaterial?.lightingModel = .constant; let mouthNode = SCNNode(geometry: mouthGeo); mouthNode.eulerAngles.z = .pi / 2; mouthNode.position.y = -0.03; container.addChildNode(mouthNode)
        let earGeo = SCNCylinder(radius: 0.001, height: 0.18); earGeo.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.6); earGeo.firstMaterial?.lightingModel = .constant; let earNode = SCNNode(geometry: earGeo); earNode.eulerAngles.z = .pi / 2; earNode.position.y = 0.0; container.addChildNode(earNode)
        let noseGeo = SCNCylinder(radius: 0.001, height: 0.06); noseGeo.firstMaterial?.diffuse.contents = UIColor.orange; noseGeo.firstMaterial?.lightingModel = .constant; let noseNode = SCNNode(geometry: noseGeo); noseNode.eulerAngles.z = .pi / 2; noseNode.position.y = -0.015; container.addChildNode(noseNode)
        let chinGeo = SCNCylinder(radius: 0.001, height: 0.06); chinGeo.firstMaterial?.diffuse.contents = UIColor.purple; chinGeo.firstMaterial?.lightingModel = .constant; let chinNode = SCNNode(geometry: chinGeo); chinNode.eulerAngles.z = .pi / 2; chinNode.position.y = -0.07; container.addChildNode(chinNode)
        let boxGeo = SCNBox(width: 0.14, height: 0.06, length: 0.001, chamferRadius: 0); boxGeo.firstMaterial?.diffuse.contents = UIColor.clear; let wireMat = SCNMaterial(); wireMat.diffuse.contents = UIColor.green.withAlphaComponent(0.8); wireMat.fillMode = .lines; wireMat.lightingModel = .constant; boxGeo.firstMaterial = wireMat; let boxNode = SCNNode(geometry: boxGeo); boxNode.position.y = 0.02; container.addChildNode(boxNode)
        let templeGeo = SCNCylinder(radius: 0.0005, height: 1.0)
        templeGeo.firstMaterial?.diffuse.contents = UIColor.yellow
        templeLineNode = SCNNode(geometry: templeGeo)
        templeLineNode?.eulerAngles.z = .pi / 2
        container.addChildNode(templeLineNode!)
        let coneGeoY = SCNCone(topRadius: 0, bottomRadius: 0.0015, height: 0.004)
        coneGeoY.firstMaterial?.diffuse.contents = UIColor.yellow
        templeLeftArrow = SCNNode(geometry: coneGeoY)
        templeLeftArrow?.eulerAngles.z = -Float.pi / 2
        container.addChildNode(templeLeftArrow!)
        templeRightArrow = SCNNode(geometry: coneGeoY)
        templeRightArrow?.eulerAngles.z = Float.pi / 2
        container.addChildNode(templeRightArrow!)
        let bridgeGeoRuler = SCNCylinder(radius: 0.0005, height: 1.0)
        bridgeGeoRuler.firstMaterial?.diffuse.contents = UIColor.orange
        bridgeLineNode = SCNNode(geometry: bridgeGeoRuler)
        bridgeLineNode?.eulerAngles.z = .pi / 2
        container.addChildNode(bridgeLineNode!)
        let coneGeo = SCNCone(topRadius: 0, bottomRadius: 0.0015, height: 0.004)
        coneGeo.firstMaterial?.diffuse.contents = UIColor.orange
        bridgeLeftArrow = SCNNode(geometry: coneGeo)
        bridgeLeftArrow?.eulerAngles.z = -Float.pi / 2
        container.addChildNode(bridgeLeftArrow!)
        bridgeRightArrow = SCNNode(geometry: coneGeo)
        bridgeRightArrow?.eulerAngles.z = Float.pi / 2
        container.addChildNode(bridgeRightArrow!)
    }
    
    // =========================================================================
    // MODAL DE CONSENTIMENTO LGPD E GRAVAÇÃO EM NUVEM
    // =========================================================================
    func showLGPDModal() {
        if lgpdOverlay != nil { return }
        lgpdOverlay = UIView(frame: view.bounds)
        lgpdOverlay?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        lgpdOverlay?.alpha = 0.0
        let boxW: CGFloat = 340
        let boxH: CGFloat = 380
        let box = UIView(frame: CGRect(x: (view.bounds.width - boxW) / 2, y: (view.bounds.height - boxH) / 2, width: boxW, height: boxH))
        box.layer.cornerRadius = 20
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = box.bounds
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        box.addSubview(blurView)
        
        let lblTitle = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 30))
        lblTitle.text = "TERMO DE CONSENTIMENTO LGPD"
        lblTitle.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        lblTitle.font = UIFont.boldSystemFont(ofSize: 16)
        lblTitle.textAlignment = .center
        box.addSubview(lblTitle)
        
        let termText = """
                Em estrita conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018), ao prosseguir, o titular dos dados (ou seu responsável legal) manifesta seu consentimento livre, informado e inequívoco para a captura e tratamento de suas medidas biométricas faciais.

                1. NATUREZA DA COLETA: O sistema utiliza sensores infravermelhos (LiDAR/TrueDepth) exclusivamente para extrair vetores tridimensionais (DNP, Altura Pupilar, Largura da Face). A plataforma NÃO realiza reconhecimento facial contínuo e NÃO armazena fotografias do seu rosto no laudo final.

                2. FINALIDADE ESTRITA: Os dados matemáticos são utilizados única e exclusivamente para a engenharia clínica e confecção de lentes oftálmicas sob medida, assegurando a máxima precisão da sua saúde visual.

                3. SEGURANÇA E RETENÇÃO: Os parâmetros são processados localmente e criptografados. A Symap 3D atua sob o princípio do 'Privacy by Design', não vendendo, cedendo ou compartilhando seus dados com corretores (data brokers).

                4. DIREITOS DO TITULAR: É garantido o direito de revogação deste consentimento a qualquer momento, bem como a exclusão permanente de todo o seu histórico através de solicitação direta à ótica.

                Ao marcar a caixa abaixo, declaro ter lido e concordo integralmente com as condições descritas.
                """
        // 🔴 NOVO: Área de texto rolável com barra
                let lgpdDescTextView = UITextView(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 160))
                lgpdDescTextView.text = termText
                lgpdDescTextView.textColor = .lightGray
                lgpdDescTextView.font = UIFont.systemFont(ofSize: 13)
                lgpdDescTextView.isEditable = false
                lgpdDescTextView.backgroundColor = .clear
                lgpdDescTextView.showsVerticalScrollIndicator = true
                box.addSubview(lgpdDescTextView)
                
                isLgpdChecked = false
                lgpdCheckbox = UIButton(frame: CGRect(x: 20, y: 240, width: boxW - 40, height: 40))
                lgpdCheckbox.setTitle(" Li e concordo com a captura", for: .normal)
                lgpdCheckbox.setTitleColor(.white, for: .normal)
                lgpdCheckbox.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
                lgpdCheckbox.contentHorizontalAlignment = .left
                lgpdCheckbox.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                lgpdCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
                lgpdCheckbox.addTarget(self, action: #selector(toggleLgpdCheckbox), for: .touchUpInside)
                
                // 🔴 BLOQUEIO: O botão nasce desativado e opaco
                lgpdCheckbox.isEnabled = false
                lgpdCheckbox.alpha = 0.4
                box.addSubview(lgpdCheckbox)
                
                // 🔴 INTELIGÊNCIA DE ROLAGEM: Só destrava ao ler tudo!
                self.lgpdScrollObservation = lgpdDescTextView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                    let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
                    if bottomEdge >= scrollView.contentSize.height - 10 {
                        self?.lgpdCheckbox.isEnabled = true
                        self?.lgpdCheckbox.alpha = 1.0
                    }
                }
                
                // Proteção: se a tela for grande e não houver barra de rolagem, destrava de imediato.
                DispatchQueue.main.async {
                    if lgpdDescTextView.contentSize.height <= lgpdDescTextView.bounds.height {
                        self.lgpdCheckbox.isEnabled = true
                        self.lgpdCheckbox.alpha = 1.0
                    }
                }
        
        let btnCancel = UIButton(frame: CGRect(x: 20, y: 300, width: 140, height: 50))
        btnCancel.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        btnCancel.setTitle("Cancelar", for: .normal)
        btnCancel.setTitleColor(.white, for: .normal)
        btnCancel.layer.cornerRadius = 25
        btnCancel.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btnCancel.addTarget(self, action: #selector(cancelLGPD), for: .touchUpInside)
        box.addSubview(btnCancel)
        
        lgpdConfirmButton = UIButton(frame: CGRect(x: 180, y: 300, width: 140, height: 50))
        lgpdConfirmButton.backgroundColor = .gray
        lgpdConfirmButton.setTitle("Concordar", for: .normal)
        lgpdConfirmButton.setTitleColor(.white, for: .normal)
        lgpdConfirmButton.layer.cornerRadius = 25
        lgpdConfirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        lgpdConfirmButton.isEnabled = false
        lgpdConfirmButton.addTarget(self, action: #selector(acceptLGPD), for: .touchUpInside)
        box.addSubview(lgpdConfirmButton)
        
        lgpdOverlay?.addSubview(box)
        view.addSubview(lgpdOverlay!)
        UIView.animate(withDuration: 0.3) {
            self.lgpdOverlay?.alpha = 1.0
        }
    }
    
    @objc func toggleLgpdCheckbox() {
        isLgpdChecked.toggle()
        let iconName = isLgpdChecked ? "checkmark.square.fill" : "square"
        lgpdCheckbox.setImage(UIImage(systemName: iconName), for: .normal)
        lgpdConfirmButton.isEnabled = isLgpdChecked
        lgpdConfirmButton.backgroundColor = isLgpdChecked ? UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) : .gray
    }
    
    @objc func cancelLGPD() {
        UIView.animate(withDuration: 0.2, animations: {
            self.lgpdOverlay?.alpha = 0.0
        }) { _ in
            self.lgpdOverlay?.removeFromSuperview()
            self.lgpdOverlay = nil
        }
        let alert = UIAlertController(title: "Operação Cancelada", message: "A triagem fotônica foi interrompida. A Symap 3D exige o aceite da LGPD para ativar os sensores 3D e realizar os cálculos.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.sceneView.session.pause()
            self?.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
    }
    
    @objc func acceptLGPD() {
        hasGivenLGPDConsent = true
        UIView.animate(withDuration: 0.2, animations: {
            self.lgpdOverlay?.alpha = 0.0
        }) { _ in
            self.lgpdOverlay?.removeFromSuperview()
            self.lgpdOverlay = nil
        }
        self.recordLGPDConsentInCloud()
    }
    
    func recordLGPDConsentInCloud() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let uniqueTenantId = "\(userId)_\(patientCPF)"
        let consentData: [String: Any] = [
            "version": "v1.0",
            "policyReference": "Política de Privacidade e Termos - Maio 2026",
            "timestamp": Date(),
            "agreed": true,
            "deviceModel": UIDevice.current.model
        ]
        let patientRef = db.collection("patients").document(uniqueTenantId)
        patientRef.updateData([
            "consents": FieldValue.arrayUnion([consentData])
        ]) { error in
            if let error = error {
                print("⚠️ Aviso LGPD: Erro ao injetar o log de consentimento: \(error.localizedDescription)")
            } else {
                print("✅ Sucesso: Aceite da LGPD gravado.")
            }
        }
    }
    // =========================================================================
    // --- CONTROLES DE ESTADO DA INTERFACE ---
    // =========================================================================
    func disableAppControls() {
        captureButton.isEnabled = false
        sceneView.alpha = 0.2
    }
    
    func enableAppControls() {
        captureButton.isEnabled = true
        sceneView.alpha = 1.0
    }
    
    func updateManualInterface(active: Bool) {
        let alpha: CGFloat = active ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) {
            self.startCaptureButton.alpha = alpha
            self.captureButton.alpha = alpha
            self.btnAddToCompare.alpha = alpha
            self.btnToggleDrawing.alpha = alpha
        }
        startCaptureButton.isUserInteractionEnabled = !active
        captureButton.isUserInteractionEnabled = !active
        btnAddToCompare.isUserInteractionEnabled = !active
        btnToggleDrawing.isUserInteractionEnabled = !active
    }
    
    // =========================================================================
    // --- MÁGICA DE UX: WIZARD DE CAPTURA EM 3 ETAPAS ---
    // =========================================================================
    func setupWizardUI() {
        let darkBg = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        // ----------------------------------------------------
        // TELA 1: APROVAÇÃO DA FOTO
        // ----------------------------------------------------
        approvalContainer = UIView(frame: view.bounds)
        approvalContainer.backgroundColor = darkBg
        approvalContainer.isHidden = true
        view.addSubview(approvalContainer)
        
        capturedImageView = UIImageView(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: view.bounds.height - 350))
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.layer.cornerRadius = 20
        capturedImageView.clipsToBounds = true
        capturedImageView.layer.borderWidth = 2
        capturedImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        approvalContainer.addSubview(capturedImageView)
        
        let rulesLabel = UILabel(frame: CGRect(x: 30, y: capturedImageView.frame.maxY + 20, width: view.bounds.width - 60, height: 90))
        rulesLabel.numberOfLines = 0
        rulesLabel.textColor = .lightGray
        rulesLabel.font = UIFont.systemFont(ofSize: 13)
        rulesLabel.text = "Critérios Clínicos de Aprovação:\n1. Não deve haver reflexos ou distorção na lente.\n2. Rosto reto e natural, sem inclinação do queixo.\n3. Os dois olhos devem estar 100% visíveis e abertos."
        approvalContainer.addSubview(rulesLabel)
        
        let btnReset = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: (view.bounds.width/2) - 40, height: 55))
        btnReset.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        btnReset.setTitle("← Refazer (Reset)", for: .normal)
        btnReset.setTitleColor(.systemRed, for: .normal)
        btnReset.layer.cornerRadius = 15
        btnReset.layer.borderWidth = 1
        btnReset.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.5).cgColor
        btnReset.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnReset.addTarget(self, action: #selector(rejectAndReset), for: .touchUpInside)
        approvalContainer.addSubview(btnReset)
        
        let btnApprove = UIButton(frame: CGRect(x: view.bounds.width/2 + 10, y: view.bounds.height - 100, width: (view.bounds.width/2) - 40, height: 55))
        btnApprove.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnApprove.setTitle("Aprovar Imagem", for: .normal)
        btnApprove.setTitleColor(.black, for: .normal)
        btnApprove.layer.cornerRadius = 15
        btnApprove.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnApprove.addTarget(self, action: #selector(approveImage), for: .touchUpInside)
        approvalContainer.addSubview(btnApprove)
        
        // ----------------------------------------------------
                // TELA 2: SELEÇÃO DE LENTE E RECEITA CLÍNICA
                // ----------------------------------------------------
                prescriptionWizardContainer = UIView(frame: view.bounds)
                prescriptionWizardContainer.backgroundColor = darkBg
                prescriptionWizardContainer.isHidden = true
                view.addSubview(prescriptionWizardContainer)
                
                let titleRx = UILabel(frame: CGRect(x: 30, y: 50, width: view.bounds.width - 60, height: 30))
                titleRx.text = "TIPO DE LENTE E RECEITA"
                titleRx.textAlignment = .center
                titleRx.font = UIFont.systemFont(ofSize: 20, weight: .black)
                titleRx.textColor = .white
                prescriptionWizardContainer.addSubview(titleRx)
                
                // NOVO TEXTO: Escolha o tipo de lente
                let instrLens = UILabel(frame: CGRect(x: 30, y: 90, width: view.bounds.width - 60, height: 20))
                instrLens.text = "Escolha o tipo de lente desejada:"
                instrLens.textColor = .lightGray
                instrLens.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                instrLens.textAlignment = .center
                prescriptionWizardContainer.addSubview(instrLens)
                
                wizardLensSegment = UISegmentedControl(items: ["Visão Simples", "Multifocal", "Bifocal", "Ocupacional"])
                wizardLensSegment.frame = CGRect(x: 15, y: 120, width: view.bounds.width - 30, height: 40)
                wizardLensSegment.selectedSegmentIndex = 0
                wizardLensSegment.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                wizardLensSegment.selectedSegmentTintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                wizardLensSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                wizardLensSegment.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 12)], for: .selected)
                wizardLensSegment.addTarget(self, action: #selector(wizardLensChanged), for: .valueChanged)
                prescriptionWizardContainer.addSubview(wizardLensSegment)
                
                // NOVO TEXTO: Adicione aqui os dados da receita
                let instrRx = UILabel(frame: CGRect(x: 30, y: 180, width: view.bounds.width - 60, height: 20))
                instrRx.text = "Adicione aqui os dados da sua receita:"
                instrRx.textColor = .lightGray
                instrRx.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                instrRx.textAlignment = .center
                prescriptionWizardContainer.addSubview(instrRx)
                
                let longeLabel = UILabel(frame: CGRect(x: 30, y: 215, width: view.bounds.width - 60, height: 20))
                longeLabel.text = "VISÃO DE LONGE (OD / OE)"
                longeLabel.textColor = .lightGray
                longeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                prescriptionWizardContainer.addSubview(longeLabel)
                
                let fieldW = (view.bounds.width - 90) / 3
                func createWField(x: CGFloat, y: CGFloat, ph: String) -> UITextField {
                    let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 45))
                    tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                    tf.textColor = .white; tf.layer.cornerRadius = 8; tf.layer.borderWidth = 1; tf.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                    tf.attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: UIColor.gray])
                    tf.textAlignment = .center; tf.keyboardType = .numbersAndPunctuation; tf.delegate = self
                    prescriptionWizardContainer.addSubview(tf)
                    return tf
                }
                
                wEsfOD = createWField(x: 30, y: 245, ph: "ESF OD")
                wCilOD = createWField(x: 30 + fieldW + 15, y: 245, ph: "CIL OD")
                wEixoOD = createWField(x: 30 + (fieldW + 15)*2, y: 245, ph: "EIXO OD")
                wEsfOE = createWField(x: 30, y: 300, ph: "ESF OE")
                wCilOE = createWField(x: 30 + fieldW + 15, y: 300, ph: "CIL OE")
                wEixoOE = createWField(x: 30 + (fieldW + 15)*2, y: 300, ph: "EIXO OE")
                
        // 🔴 RESTAURAÇÃO E MELHORIA: Contêiner de Perto ligeiramente maior para caber o novo seletor
                wizardPertoContainer = UIView(frame: CGRect(x: 0, y: 360, width: view.bounds.width, height: 190))
                wizardPertoContainer.isHidden = true
                prescriptionWizardContainer.addSubview(wizardPertoContainer)
                
                let pertoLabel = UILabel(frame: CGRect(x: 30, y: 0, width: view.bounds.width - 60, height: 20))
                pertoLabel.text = "VISÃO DE PERTO (OD / OE)"
                pertoLabel.textColor = .lightGray
                pertoLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                wizardPertoContainer.addSubview(pertoLabel)

                // 🔴 O SELETOR INTELIGENTE: Alterna entre os dois métodos médicos
                pertoModeSegment = UISegmentedControl(items: ["Somente Adição (ADD)", "Receita Completa"])
                pertoModeSegment.frame = CGRect(x: 30, y: 30, width: view.bounds.width - 60, height: 35)
                pertoModeSegment.selectedSegmentIndex = 0
                pertoModeSegment.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                pertoModeSegment.selectedSegmentTintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                pertoModeSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                pertoModeSegment.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 12)], for: .selected)
                pertoModeSegment.addTarget(self, action: #selector(toggleNearVisionMode), for: .valueChanged)
                wizardPertoContainer.addSubview(pertoModeSegment)
                
                func createPField(x: CGFloat, y: CGFloat, ph: String) -> UITextField {
                    let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 45))
                    tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                    tf.textColor = .white; tf.layer.cornerRadius = 8; tf.layer.borderWidth = 1; tf.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                    tf.attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: UIColor.gray])
                    tf.textAlignment = .center; tf.keyboardType = .numbersAndPunctuation; tf.delegate = self
                    wizardPertoContainer.addSubview(tf)
                    return tf
                }
                
                // 🔴 OS 6 CAMPOS (Empurrados 80 pixels para baixo para dar espaço ao seletor)
                wEsfPertoOD = createPField(x: 30, y: 80, ph: "ADIÇÃO OD")
                wCilPertoOD = createPField(x: 30 + fieldW + 15, y: 80, ph: "CIL OD")
                wEixoPertoOD = createPField(x: 30 + (fieldW + 15)*2, y: 80, ph: "EIXO OD")
                
                wEsfPertoOE = createPField(x: 30, y: 135, ph: "ADIÇÃO OE")
                wCilPertoOE = createPField(x: 30 + fieldW + 15, y: 135, ph: "CIL OE")
                wEixoPertoOE = createPField(x: 30 + (fieldW + 15)*2, y: 135, ph: "EIXO OE")
                
                // Inicia no modo simplificado (escondendo Cilíndrico e Eixo)
                wCilPertoOD.isHidden = true
                wEixoPertoOD.isHidden = true
                wCilPertoOE.isHidden = true
                wEixoPertoOE.isHidden = true
                
                let btnNext = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
                btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                btnNext.setTitle("Avançar para Medições Manuais", for: .normal)
                btnNext.setTitleColor(.black, for: .normal)
                btnNext.layer.cornerRadius = 15
                btnNext.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnNext.addTarget(self, action: #selector(finishWizardAndShowTools), for: .touchUpInside)
                prescriptionWizardContainer.addSubview(btnNext)
                
                // NOVO: Adicionando o Glossário Clínico para leigos
                let legendLabel = UILabel(frame: CGRect(x: 30, y: view.bounds.height - 180, width: view.bounds.width - 60, height: 60))
                legendLabel.numberOfLines = 0
                legendLabel.textAlignment = .center
                legendLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                legendLabel.textColor = UIColor.lightGray.withAlphaComponent(0.8)
                legendLabel.text = "GLOSSÁRIO CLÍNICO:\nESF: Esférico (Grau) | CIL: Cilíndrico (Astigmatismo)\nEIXO: Posição (0° a 180°) | ADIÇÃO: Grau extra para leitura\nOD: Olho Direito | OE: Olho Esquerdo"
                prescriptionWizardContainer.addSubview(legendLabel)

                // NOVO: Clique fora recolhe o teclado
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideWizardKeyboard))
                prescriptionWizardContainer.addGestureRecognizer(tapGesture)
            } // FIM DA FUNÇÃO setupWizardUI()
    
    // --- LÓGICA DO FLUXO DO WIZARD ---
        func startApprovalStep() {
            // Pausa a sessão e limpa os sensores da tela
            sceneView.session.pause()
            motionManager.stopDeviceMotionUpdates()
            
            let snap = sceneView.snapshot()
            
            //  NOVO: Clonamos a malha 3D autêntica do paciente para o Gêmeo Digital!
            self.safeFaceCache = self.faceNode?.clone()
            self.safeSnapshotCache = snap
            self.savedFrontalSnapshot = snap
            capturedImageView.image = snap
            
            levelContainerView.isHidden = true; levelLabel.isHidden = true
            headLevelContainerView.isHidden = true; headLevelLabel.isHidden = true
            phonePitchContainerView.isHidden = true; phonePitchLabel.isHidden = true
            headPitchContainerView.isHidden = true; headPitchLabel.isHidden = true
            distanceBarContainer?.isHidden = true
            topFeedbackLabel?.isHidden = true
            faceGuideLayer?.isHidden = true
            startCaptureButton.isHidden = true
            
            approvalContainer.isHidden = false
            approvalContainer.alpha = 0
            UIView.animate(withDuration: 0.3) { self.approvalContainer.alpha = 1.0 }
        }
    
    @objc func rejectAndReset() {
        UIView.animate(withDuration: 0.3, animations: { self.approvalContainer.alpha = 0 }) { _ in
            self.approvalContainer.isHidden = true
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            self.sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            self.startLevelMonitoring()
            
            self.levelContainerView.isHidden = false; self.levelLabel.isHidden = false
            self.headLevelContainerView.isHidden = false; self.headLevelLabel.isHidden = false
            self.phonePitchContainerView.isHidden = false; self.phonePitchLabel.isHidden = false
            self.headPitchContainerView.isHidden = false; self.headPitchLabel.isHidden = false
            self.topFeedbackLabel?.isHidden = false; self.faceGuideLayer?.isHidden = false
            self.startCaptureButton.isHidden = false
            self.startCaptureButton.setTitle("Iniciar Captura", for: .normal)
            self.startCaptureButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
        }
    }
    
    @objc func hideWizardKeyboard() {
            self.view.endEditing(true)
        }

        @objc func approveImage() {
            // 🔴 MÁGICA DE UX: A tela de receita aparece POR CIMA da foto, evitando a "piscada" do glitch!
            self.prescriptionWizardContainer.alpha = 0
            self.prescriptionWizardContainer.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.prescriptionWizardContainer.alpha = 1.0
            }) { _ in
                self.approvalContainer.isHidden = true
                self.approvalContainer.alpha = 0
            }
        }
    
    @objc func wizardLensChanged() {
        let idx = wizardLensSegment.selectedSegmentIndex
        wizardPertoContainer.isHidden = (idx == 0)
        selectedLensType = wizardLensSegment.titleForSegment(at: idx) ?? "Visão Simples"
    }
    
    @objc func toggleNearVisionMode() {
            let isCompleteMode = pertoModeSegment.selectedSegmentIndex == 1
            
            // Exibe ou oculta os campos de astigmatismo com base no modo selecionado
            wCilPertoOD.isHidden = !isCompleteMode
            wEixoPertoOD.isHidden = !isCompleteMode
            wCilPertoOE.isHidden = !isCompleteMode
            wEixoPertoOE.isHidden = !isCompleteMode
            
            // Altera de forma dinâmica o nome do Placeholder para guiar o lojista
            let placeholderOD = isCompleteMode ? "ESF OD" : "ADIÇÃO OD"
            let placeholderOE = isCompleteMode ? "ESF OE" : "ADIÇÃO OE"
            wEsfPertoOD.attributedPlaceholder = NSAttributedString(string: placeholderOD, attributes: [.foregroundColor: UIColor.gray])
            wEsfPertoOE.attributedPlaceholder = NSAttributedString(string: placeholderOE, attributes: [.foregroundColor: UIColor.gray])
        }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }
        let cleanText = text.replacingOccurrences(of: ",", with: ".")
        if let value = Float(cleanText) {
            if textField.placeholder?.contains("EIXO") == true {
                textField.text = String(format: "%.0f°", value)
            } else {
                let sign = value > 0 ? "+" : ""
                textField.text = String(format: "%@%.2f", sign, value)
            }
        }
    }
    
    @objc func finishWizardAndShowTools() {
            view.endEditing(true)
            self.rxEsfOD = wEsfOD.text?.isEmpty == false ? wEsfOD.text! : "-"
            self.rxCilOD = wCilOD.text?.isEmpty == false ? wCilOD.text! : "-"
            self.rxEixoOD = wEixoOD.text?.isEmpty == false ? wEixoOD.text! : "-"
            self.rxEsfOE = wEsfOE.text?.isEmpty == false ? wEsfOE.text! : "-"
            self.rxCilOE = wCilOE.text?.isEmpty == false ? wCilOE.text! : "-"
            self.rxEixoOE = wEixoOE.text?.isEmpty == false ? wEixoOE.text! : "-"
            
            // 🔴 ENGENHARIA LÓGICA: Verifica qual modo médico foi utilizado
            let isCompleteMode = pertoModeSegment.selectedSegmentIndex == 1
            
            if isCompleteMode {
                // MODO 2: Receita Completa. O sistema simplesmente captura as 6 caixas como o usuário digitou.
                self.rxEsfPertoOD = wEsfPertoOD.text?.isEmpty == false ? wEsfPertoOD.text! : "-"
                self.rxCilPertoOD = wCilPertoOD.text?.isEmpty == false ? wCilPertoOD.text! : "-"
                self.rxEixoPertoOD = wEixoPertoOD.text?.isEmpty == false ? wEixoPertoOD.text! : "-"
                
                self.rxEsfPertoOE = wEsfPertoOE.text?.isEmpty == false ? wEsfPertoOE.text! : "-"
                self.rxCilPertoOE = wCilPertoOE.text?.isEmpty == false ? wCilPertoOE.text! : "-"
                self.rxEixoPertoOE = wEixoPertoOE.text?.isEmpty == false ? wEixoPertoOE.text! : "-"
            } else {
                // MODO 1: Adição Simplificada. Transforma em ADD e clona os dados do Cilíndrico/Eixo
                self.rxEsfPertoOD = wEsfPertoOD.text?.isEmpty == false ? "ADD \(wEsfPertoOD.text!)" : "-"
                self.rxEsfPertoOE = wEsfPertoOE.text?.isEmpty == false ? "ADD \(wEsfPertoOE.text!)" : "-"
                
                self.rxCilPertoOD = self.rxCilOD
                self.rxEixoPertoOD = self.rxEixoOD
                self.rxCilPertoOE = self.rxCilOE
                self.rxEixoPertoOE = self.rxEixoOE
            }
            
            UIView.animate(withDuration: 0.3, animations: { self.prescriptionWizardContainer.alpha = 0 }) { _ in
                self.prescriptionWizardContainer.isHidden = true
                if self.selectedLensType == "Multifocal" || self.selectedLensType == "Bifocal" || self.selectedLensType == "Ocupacional" {
                    self.startVisionMappingFromWizard()
                } else {
                    self.visionBehaviorResult = "Mapeamento visual não se aplica"
                    self.isFrozen = false
                    self.toggleFreeze()
                }
            }
        }
    
        @objc func handleNextAfterManualMeasurements() {
            let requiresMapping = (selectedLensType == "Multifocal" || selectedLensType == "Bifocal" || selectedLensType == "Ocupacional")
            
            if requiresMapping && !isMappingVisionCompleted {
                startVisionMappingFromWizard()
            } else {
                showSummaryScreen()
            }
        }

       

        func finishVisionMappingSequence() {
            self.visionMapDot?.removeFromSuperview()
            self.visionMapDot = nil
            self.isMappingVision = false

            self.visionMappingView?.session.pause()
            self.visionMappingView?.removeFromSuperview()
            self.visionMappingView = nil
            self.motionManager.stopDeviceMotionUpdates()

            self.isMappingVisionCompleted = true

            if self.headMoveScore > self.eyeMoveScore * 0.8 {
                self.visionBehaviorResult = "Movimentador de Cabeça (Head-Mover)"
            } else {
                self.visionBehaviorResult = "Movimentador de Olhos (Eye-Mover)"
            }

            let alert = UIAlertController(title: "Mapeamento Clínico Concluído", message: "Resultado: \(self.visionBehaviorResult)\n\nO comportamento periférico foi capturado com sucesso.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Avançar para Medições", style: .default, handler: { _ in
                        // CORREÇÃO DO FLUXO: Agora ele chama a tela de edição na foto congelada!
                        self.isFrozen = false
                        self.toggleFreeze()
                    }))

                    self.present(alert, animated: true)
        }

            @objc func showSummaryScreen() {
            self.isPdfGenerated = false // 🔴 Reseta a trava do PDF sempre que entrar no resumo
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
                    
                    // 🔴 CORREÇÃO DO ZOOM: Câmera recuada para 45cm e destravada para não cortar o nariz!
                    let cameraNode = SCNNode()
                    let camera = SCNCamera()
                    camera.zNear = 0.01
                    cameraNode.camera = camera
                    cameraNode.position = SCNVector3(0, 0, 0.20)//zoom holograma
                    holoScene.rootNode.addChildNode(cameraNode)
                }
                summaryContainer.addSubview(holoView)
            
        // 🔴 TEXTO EXPLICATIVO DA TECNOLOGIA E MANUAL DE GESTOS (Expandido)
                let techDesc = UILabel(frame: CGRect(x: 20, y: 325, width: view.bounds.width - 40, height: 110))
                techDesc.numberOfLines = 0
                techDesc.textAlignment = .center
                techDesc.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                techDesc.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                techDesc.text = "GÊMEO DIGITAL BIOMÉTRICO (IA)\nO holograma acima não é uma foto, é a reconstrução volumétrica exata da sua face gerada por infravermelhos. Com 100% de precisão matemática, nós eliminamos o erro humano na medição das suas lentes.\n\n COMO MANIPULAR O SEU ROSTO 3D:\n Rotacionar: Arraste com 1 dedo. |  Zoom: Pinça com 2 dedos.\n Mover: Arraste com 2 dedos juntos na tela."
                summaryContainer.addSubview(techDesc)

                // 🔴 INFORMAÇÕES CLÍNICAS (Ajustado o Y para 440 para comportar o texto maior acima)
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
                        btnPDF.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Azul Ciano Padrão da Symap
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

                // NOVO: Botão de Modelo Personalizado (Configurador 3D)
                let btnCustomModel = UIButton()
                btnCustomModel.backgroundColor = UIColor.systemPurple
                btnCustomModel.setTitle("Modelo Personalizado", for: .normal)
                btnCustomModel.setTitleColor(.white, for: .normal)
                btnCustomModel.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnCustomModel.layer.cornerRadius = 12
                btnCustomModel.addTarget(self, action: #selector(openConfigurator), for: .touchUpInside)

                // Agrupador Master Vertical (Personalizado no topo, PDF no meio, as outras opções embaixo)
                let masterStack = UIStackView(arrangedSubviews: [btnCustomModel, btnPDF, bottomStack])
                masterStack.axis = .vertical
                masterStack.spacing = 12
                masterStack.distribution = .fillEqually

                // Altura ampliada e Y ajustado para caber o novo botão de personalização perfeitamente
                masterStack.frame = CGRect(x: 30, y: view.bounds.height - 190, width: view.bounds.width - 60, height: 160)
                summaryContainer.addSubview(masterStack)

            UIView.animate(withDuration: 0.3) { self.summaryContainer.alpha = 1.0 }
        }
    
    // =========================================================================
        // --- LÓGICA DE ABERTURA DO CONFIGURADOR (FLUXO UNIFICADO E PADRONIZADO) ---
        // =========================================================================
        @objc func openConfigurator() {
            // 1. VERIFICA SE O CLIENTE ESTÁ USANDO UM ÓCULOS NO TRY-ON
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

            // --- 4. CLONE DO ROSTO (HOLOGRAMA WIREFRAME) ---
            if self.faceNode?.childNodes.count ?? 0 > 0, let faceMeshNode = self.faceNode?.childNodes[ 0 ].clone() {
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

            // --- RECEBE A PERSONALIZAÇÃO DE VOLTA ---
            configVC.onApplyCustomization = { [weak self] (edits, newColor, customNode) in
                guard let self = self, let oldGlasses = self.glassesNode, let newNode = customNode?.clone() else { return }

                newNode.position = oldGlasses.position
                newNode.scale = oldGlasses.scale
                newNode.eulerAngles = oldGlasses.eulerAngles

                // 🎨 MÁGICA DA TEXTURA REALISTA
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

                oldGlasses.removeFromParentNode()
                self.faceNode?.addChildNode(newNode)
                self.glassesNode = newNode

                self.pupillaryHeight = 0.0
                self.manualFrameHeight = 0.0
                self.manualFrameWidth = 0.0
                self.manualFrameDiagonal = 0.0

                self.updateSegmentTitles()
                self.updateLabels()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    let alert = UIAlertController(title: "Armação Atualizada", message: "O design personalizado foi sincronizado com o rosto do cliente.\n\nComo a armação mudou de tamanho, por favor tire as medidas manuais (Altura de Montagem, Altura do Aro, Largura e Diagonal) novamente no novo formato para garantir a precisão do PDF.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK, Vou medir", style: .default, handler: { _ in
                                        // 1. Esconde a tela de Resumo Clínico suavemente
                                        UIView.animate(withDuration: 0.3, animations: {
                                            self.summaryContainer?.alpha = 0
                                        }) { _ in
                                            self.summaryContainer?.isHidden = true
                                            
                                            // 2. Revela a interface das réguas sobre a foto congelada
                                            self.measurementsContainer.isHidden = false
                                            self.measurementTypeSegment.isHidden = false
                                            self.captureButton.isHidden = false
                                            self.startCaptureButton.isHidden = false
                                            if let bottomStack = self.view.subviews.first(where: { $0 is UIStackView }) {
                                                bottomStack.isHidden = false
                                            }
                                            
                                            // 3. Reseta os cursores para forçar o lojista a clicar na nova medida
                                            self.currentManualMode = 0
                                            self.measurementTypeSegment.selectedSegmentIndex = 0
                                            self.manualMeasureContainer.isHidden = true
                                            self.heightLineView.isHidden = true
                                        }
                                    }))
                                    self.present(alert, animated: true)
                }
            }
            present(configVC, animated: true, completion: nil)
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
                                self.isPdfGenerated = true // 🔴 PDF Salvo com Sucesso! Libera os botões de saída
                                self.saveMeasurementToCloud(storagePath: internalPath)
                                self.showLocalShareSheet(pdfData: pdfData)
                            }
                        }
                    }
        }
    
    // =========================================================================
        // --- MOTOR DO PROVADOR VIRTUAL (TRY-ON) ---
        // =========================================================================
        @objc func showModelSelection() {
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
            
            if let p = alert.popoverPresentationController { p.sourceView = menuButton; p.sourceRect = menuButton.bounds }
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
            
            if let p = alert.popoverPresentationController { p.sourceView = menuButton; p.sourceRect = menuButton.bounds }
            present(alert, animated: true)
        }

        func loadCloudModel(model: CloudGlassModel) {
            CloudManager.shared.downloadModelFile(url: model.fileUrl) { [weak self] u in
                guard let s = self, let url = u else { return }
                DispatchQueue.main.async {
                    s.glassesNode?.removeFromParentNode()
                    s.glassesNode = nil
                    s.currentCloudModel = model
                    s.glassesYOffset = model.position.y
                    
                    let asset = MDLAsset(url: url)
                    if asset.count > 0 {
                        let obj = asset.object(at: 0)
                        let node = SCNNode(mdlObject: obj)
                        let mat = SCNMaterial()
                        mat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
                        mat.lightingModel = .physicallyBased
                        node.geometry?.firstMaterial = mat
                        
                        let (min, max) = node.boundingBox
                        let c = SCNVector3((min.x+max.x)/2, (min.y+max.y)/2, (min.z+max.z)/2)
                        node.pivot = SCNMatrix4MakeTranslation(c.x, c.y, c.z)
                        node.scale = SCNVector3(model.scale, model.scale, model.scale)
                        node.position = SCNVector3(model.position.x, s.glassesYOffset, model.position.z)
                        node.eulerAngles = model.rotation
                        
                        s.faceNode?.addChildNode(node)
                        s.glassesNode = node
                    }
                }
            }
        }

}

