import UIKit
import Vision
import AVFoundation
import FirebaseFunctions

// =========================================================================
// 🔴 SCANNER DE ALTA PRECISÃO: ESTABILIDADE + ROI CROP + GEMINI CLOUD (FIX)
// =========================================================================
class RxScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onPrescriptionFound: ((ParsedPrescription) -> Void)?
    
    let cutoutView = UIView()
    let instructionLabel = UILabel()
    var isCapturing = true
    var framesHoldingSteady = 0
    let requiredSteadyFrames = 15 // Trava de 1.5 segundos
    var bestResult: ParsedPrescription?
    
    // Recorte matemático da área de leitura
    var visionROI: CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Live Rx Scanner Cloud Init"]
        let _ = safetyCheck[ 0 ]
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            if let connection = videoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        if let previewConnection = previewLayer.connection {
            if previewConnection.isVideoMirroringSupported {
                previewConnection.automaticallyAdjustsVideoMirroring = false
                previewConnection.isVideoMirrored = true
            }
        }
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func setupUI() {
        let overlayLayer = CAShapeLayer()
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        
        let path = UIBezierPath(rect: view.bounds)
        let cutoutWidth: CGFloat = view.bounds.width - 60
        let cutoutHeight: CGFloat = 200
        let cutoutRect = CGRect(x: 30, y: (view.bounds.height - cutoutHeight) / 2 - 50, width: cutoutWidth, height: cutoutHeight)
        
        path.append(UIBezierPath(roundedRect: cutoutRect, cornerRadius: 16))
        overlayLayer.path = path.cgPath
        view.layer.addSublayer(overlayLayer)
        
        cutoutView.frame = cutoutRect
        cutoutView.layer.cornerRadius = 16
        cutoutView.layer.borderWidth = 3
        cutoutView.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        view.addSubview(cutoutView)
        
        let radarLine = UIView(frame: CGRect(x: 10, y: 10, width: cutoutWidth - 20, height: 2))
        radarLine.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        radarLine.layer.shadowColor = UIColor.systemGreen.cgColor
        radarLine.layer.shadowRadius = 8
        radarLine.layer.shadowOpacity = 1.0
        cutoutView.addSubview(radarLine)
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            radarLine.frame.origin.y = cutoutHeight - 10
        }
        
        instructionLabel.frame = CGRect(x: 20, y: cutoutRect.maxY + 30, width: view.bounds.width - 40, height: 60)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 2
        instructionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        instructionLabel.text = "Escaneamento de Alta Precisão\nEnquadre APENAS os graus no quadro."
        view.addSubview(instructionLabel)
        
        let btnCancel = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
        btnCancel.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        btnCancel.setTitle("Cancelar", for: .normal)
        btnCancel.setTitleColor(.white, for: .normal)
        btnCancel.layer.cornerRadius = 16
        btnCancel.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(btnCancel)
        
        // CÁLCULO FÍSICO DO CROP: Restringe o Apple Vision à caixa
        DispatchQueue.main.async {
            let normalizedRect = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.cutoutView.frame)
            self.visionROI = CGRect(x: normalizedRect.minX,
                                    y: 1.0 - normalizedRect.maxY,
                                    width: normalizedRect.width,
                                    height: normalizedRect.height)
        }
    }
    
    @objc func cancelTapped() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
        self.dismiss(animated: true)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCapturing, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self, let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            
            var extractedText = ""
            for obs in observations {
                let candidates = obs.topCandidates(1)
                if !candidates.isEmpty {
                    // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
                    let topCandidate = candidates[ 0 ]
                    extractedText += topCandidate.string + "\n"
                }
            }
            
            // O motor local julga apenas se há "dioptrias" na foto para acender a barra amarela
            let localParsed = PrescriptionParserEngine.parse(rawText: extractedText)
            
            if localParsed.isValid {
                self.framesHoldingSteady += 1
                if self.bestResult == nil {
                    self.bestResult = localParsed
                }
                
                DispatchQueue.main.async {
                    self.cutoutView.layer.borderColor = UIColor.systemYellow.cgColor
                    if self.framesHoldingSteady < 8 {
                        self.instructionLabel.text = "Dados detectados!\nSegure firme..."
                        self.instructionLabel.textColor = .systemYellow
                    } else {
                        self.instructionLabel.text = "Focando dioptrias...\nNão mova o papel!"
                        self.instructionLabel.textColor = .systemOrange
                    }
                }
                
                // 🔴 MOMENTO DA CAPTURA E CHAMADA DO GEMINI
                if self.framesHoldingSteady >= self.requiredSteadyFrames, let finalLocalParsed = self.bestResult {
                    self.isCapturing = false // Trava o scanner local
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.captureSession.stopRunning()
                    }
                    
                    DispatchQueue.main.async {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                        self.cutoutView.layer.borderColor = UIColor.systemGreen.cgColor
                        self.instructionLabel.text = "Consultando Inteligência Artificial..."
                        self.instructionLabel.textColor = .systemGreen
                        
                        // 🔴 1. RAIO-X REATIVADO PARA O XCODE!
                        print("☁️ ENVIANDO PARA NUVEM (CROP):\n\(extractedText)")
                        
                        let functions = Functions.functions()
                        functions.httpsCallable("parsePrescriptionWithAI").call(["text": extractedText]) { result, error in
                            DispatchQueue.main.async {
                                if let err = error {
                                    print("⚠️ Erro na Nuvem: \(err.localizedDescription)")
                                    self.instructionLabel.text = "Erro na IA. Usando leitura local..."
                                    self.dismiss(animated: true) { self.onPrescriptionFound?(finalLocalParsed) }
                                    return
                                }
                                
                                if let data = result?.data as? [String: Any] {
                                    // 🔴 2. EXIBE A RESPOSTA EXATA DO GEMINI
                                    print("🧠 RESPOSTA DO GEMINI: \(data)")
                                    var cloudParsed = finalLocalParsed
                                    
                                    // 🔴 3. O SEGREDO ESTÁ AQUI: Só substitui o valor local se o Gemini devolveu algo VÁLIDO!
                                    if let val = data["esfOD"] as? String, !val.isEmpty { cloudParsed.esfOD = val }
                                    if let val = data["cilOD"] as? String, !val.isEmpty { cloudParsed.cilOD = val }
                                    if let val = data["eixoOD"] as? String, !val.isEmpty { cloudParsed.eixoOD = val }
                                    if let val = data["esfOE"] as? String, !val.isEmpty { cloudParsed.esfOE = val }
                                    if let val = data["cilOE"] as? String, !val.isEmpty { cloudParsed.cilOE = val }
                                    if let val = data["eixoOE"] as? String, !val.isEmpty { cloudParsed.eixoOE = val }
                                    
                                    self.dismiss(animated: true) { self.onPrescriptionFound?(cloudParsed) }
                                } else {
                                    self.dismiss(animated: true) { self.onPrescriptionFound?(finalLocalParsed) }
                                }
                            }
                        }
                    }
                }
            } else {
                if self.framesHoldingSteady > 0 {
                    self.framesHoldingSteady = 0
                    self.bestResult = nil
                    DispatchQueue.main.async {
                        self.cutoutView.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
                        self.instructionLabel.text = "Escaneamento de Alta Precisão\nEnquadre APENAS os graus no quadro."
                        self.instructionLabel.textColor = .white
                    }
                }
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = false
        
        // APLICA O CROP NA LENTE DA CÂMERA
        if self.visionROI != .zero {
            request.regionOfInterest = self.visionROI
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
}

extension MeasurementViewController {
    @objc func scanPrescriptionTapped() {
        view.endEditing(true)
        
        let emptyValue = ""
        self.wEsfOD?.text = emptyValue
        self.wCilOD?.text = emptyValue
        self.wEixoOD?.text = emptyValue
        self.wEsfOE?.text = emptyValue
        self.wCilOE?.text = emptyValue
        self.wEixoOE?.text = emptyValue
        
        let fields = [self.wEsfOD, self.wCilOD, self.wEixoOD, self.wEsfOE, self.wCilOE, self.wEixoOE]
        fields.forEach { $0?.backgroundColor = UIColor(white: 1.0, alpha: 0.05) }
        
        let scannerVC = RxScannerViewController()
        scannerVC.modalPresentationStyle = .fullScreen
        scannerVC.modalTransitionStyle = .crossDissolve
        scannerVC.onPrescriptionFound = { [weak self] parsedData in
            self?.applyParsedPrescription(parsedData)
        }
        self.present(scannerVC, animated: true)
    }
    
    private func applyParsedPrescription(_ parsed: ParsedPrescription) {
        let flashColor = UIColor.systemGreen.withAlphaComponent(0.4)
        
        func fillField(_ field: UITextField?, with value: String) {
            guard let f = field, !value.isEmpty else { return }
            f.text = value
            
            UIView.animate(withDuration: 0.2, animations: {
                f.backgroundColor = flashColor
                f.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }) { _ in
                UIView.animate(withDuration: 0.4) {
                    f.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                    f.transform = .identity
                }
            }
        }
        
        fillField(self.wEsfOD, with: parsed.esfOD)
        fillField(self.wCilOD, with: parsed.cilOD)
        fillField(self.wEixoOD, with: parsed.eixoOD)
        fillField(self.wEsfOE, with: parsed.esfOE)
        fillField(self.wCilOE, with: parsed.cilOE)
        fillField(self.wEixoOE, with: parsed.eixoOE)
        
        self.speakText("Receita importada. Por favor, confira os dados na tela.")
    }
}
