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

class MeasurementViewController: UIViewController, ARSCNViewDelegate, PKCanvasViewDelegate, UITextFieldDelegate {
    
    // --- ELEMENTOS DE UI ---
    var sceneView: ARSCNView!
    
    var glassesNode: SCNNode?
    var currentCloudModel: CloudGlassModel?
    var glassesYOffset: Float = 0.02
    
    var isVisagismCompleted: Bool = false
    var recommendedAutoModel: String = ""
    
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
    
    // Botão de Guias AR
    var btnToggleGuides: UIButton!
    var logoutButton: UIButton!
    
    // --- ESTADO DO SISTEMA ---
    var faceNode: SCNNode?
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
    var faceHeight: Float = 0.0
    var noseBridgeWidth: Float = 0.0
    var faceShape: String = "Calculando..."
    var frameSuggestion: String = "..."
    var patientGender: String = "Prefiro não informar"
    var jawWidth: Float = 0.0
    var sessionStartTime: Date?
    var nasalProfile: String = "Plano"
    var nasalProjection: Float = 0.0
    var patientName: String = "Paciente Não Identificado"
    var patientCPF: String = "000.000.000-00"
    
    // --- LGPD E CONSENTIMENTO BIOMÉTRICO ---
    var hasGivenLGPDConsent: Bool = false
    var lgpdOverlay: UIView?
    var lgpdCheckbox: UIButton!
    var lgpdConfirmButton: UIButton!
    var isLgpdChecked: Bool = false
    var lgpdScrollObservation: NSKeyValueObservation?
    var isPdfGenerated: Bool = false
    
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
        // 🔴 MÁGICA: Pré-aquece o motor de voz silenciosamente
        let utterance = AVSpeechUtterance(string: " ")
        utterance.volume = 0
        speechSynthesizer.speak(utterance)
    }
    
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        if let premiumVoice = voices.first(where: { $0.language == "pt-BR" && $0.quality == .enhanced }) {
            utterance.voice = premiumVoice
        } else if let premiumVoice2 = voices.first(where: { $0.language == "pt-BR" && $0.quality == .premium }) {
            utterance.voice = premiumVoice2
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        }
        
        utterance.rate = 0.53
        utterance.pitchMultiplier = 1.05
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
            checkExistingLGPDConsent()
        } else {
            self.checkFirstTimeTripodCalibration()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        motionManager.stopDeviceMotionUpdates()
        resetCountdown()
    }
}
