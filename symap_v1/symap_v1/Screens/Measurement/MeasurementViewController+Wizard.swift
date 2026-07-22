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
    func setupWizardUI() {
        let darkBg = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA: Blindagem de matrizes
        let safetyCheck = ["Wizard UI Ativa"]
        let _ = safetyCheck[ 0 ]

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

        // =========================================================================
        // 🔴 NOVO: BOTÃO DE CÂMERA (OCR DE RECEITA) - INSERIDO NA INTERFACE
        // =========================================================================
        let btnScanRx = UIButton(frame: CGRect(x: 30, y: 175, width: view.bounds.width - 60, height: 45))
        btnScanRx.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        btnScanRx.setTitle("📸 Escanear Receita Inteligente", for: .normal)
        btnScanRx.setTitleColor(UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), for: .normal)
        btnScanRx.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScanRx.layer.cornerRadius = 12
        btnScanRx.layer.borderWidth = 1
        btnScanRx.layer.borderColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.4).cgColor
        btnScanRx.addTarget(self, action: NSSelectorFromString("scanPrescriptionTapped"), for: .touchUpInside)
        prescriptionWizardContainer.addSubview(btnScanRx)

        let instrRx = UILabel(frame: CGRect(x: 30, y: 235, width: view.bounds.width - 60, height: 20))
        instrRx.text = "Ou adicione os dados da receita manualmente:"
        instrRx.textColor = .lightGray
        instrRx.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        instrRx.textAlignment = .center
        prescriptionWizardContainer.addSubview(instrRx)

        let longeLabel = UILabel(frame: CGRect(x: 30, y: 260, width: view.bounds.width - 60, height: 20))
        longeLabel.text = "VISÃO DE LONGE (OD / OE)"
        longeLabel.textColor = .lightGray
        longeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        prescriptionWizardContainer.addSubview(longeLabel)

        let fieldW = (view.bounds.width - 90) / 3

        func createWField(x: CGFloat, y: CGFloat, ph: String) -> UITextField {
            let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 40))
            tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            tf.textColor = .white; tf.layer.cornerRadius = 8; tf.layer.borderWidth = 1; tf.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            tf.attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: UIColor.gray])
            tf.textAlignment = .center; tf.keyboardType = .numbersAndPunctuation; tf.delegate = self
            prescriptionWizardContainer.addSubview(tf)
            return tf
        }

        wEsfOD = createWField(x: 30, y: 285, ph: "ESF OD")
        wCilOD = createWField(x: 30 + fieldW + 15, y: 285, ph: "CIL OD")
        wEixoOD = createWField(x: 30 + (fieldW + 15)*2, y: 285, ph: "EIXO OD")
        wEsfOE = createWField(x: 30, y: 335, ph: "ESF OE")
        wCilOE = createWField(x: 30 + fieldW + 15, y: 335, ph: "CIL OE")
        wEixoOE = createWField(x: 30 + (fieldW + 15)*2, y: 335, ph: "EIXO OE")

        wizardPertoContainer = UIView(frame: CGRect(x: 0, y: 390, width: view.bounds.width, height: 190))
        wizardPertoContainer.isHidden = true
        prescriptionWizardContainer.addSubview(wizardPertoContainer)

        let pertoLabel = UILabel(frame: CGRect(x: 30, y: 0, width: view.bounds.width - 60, height: 20))
        pertoLabel.text = "VISÃO DE PERTO (OD / OE)"
        pertoLabel.textColor = .lightGray
        pertoLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        wizardPertoContainer.addSubview(pertoLabel)

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
            let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 40))
            tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            tf.textColor = .white; tf.layer.cornerRadius = 8; tf.layer.borderWidth = 1; tf.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            tf.attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: UIColor.gray])
            tf.textAlignment = .center; tf.keyboardType = .numbersAndPunctuation; tf.delegate = self
            wizardPertoContainer.addSubview(tf)
            return tf
        }

        wEsfPertoOD = createPField(x: 30, y: 80, ph: "ADIÇÃO OD")
        wCilPertoOD = createPField(x: 30 + fieldW + 15, y: 80, ph: "CIL OD")
        wEixoPertoOD = createPField(x: 30 + (fieldW + 15)*2, y: 80, ph: "EIXO OD")
        wEsfPertoOE = createPField(x: 30, y: 130, ph: "ADIÇÃO OE")
        wCilPertoOE = createPField(x: 30 + fieldW + 15, y: 130, ph: "CIL OE")
        wEixoPertoOE = createPField(x: 30 + (fieldW + 15)*2, y: 130, ph: "EIXO OE")

        wCilPertoOD.isHidden = true
        wEixoPertoOD.isHidden = true
        wCilPertoOE.isHidden = true
        wEixoPertoOE.isHidden = true

        let btnBackToPhoto = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 165, width: view.bounds.width - 60, height: 50))
        btnBackToPhoto.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        btnBackToPhoto.setTitle("← Voltar para a Foto", for: .normal)
        btnBackToPhoto.setTitleColor(.white, for: .normal)
        btnBackToPhoto.layer.cornerRadius = 15
        btnBackToPhoto.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btnBackToPhoto.addTarget(self, action: #selector(backToApprovalScreen), for: .touchUpInside)
        prescriptionWizardContainer.addSubview(btnBackToPhoto)

        let btnNext = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
        btnNext.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnNext.setTitle("Avançar para Medições Manuais", for: .normal)
        btnNext.setTitleColor(.black, for: .normal)
        btnNext.layer.cornerRadius = 15
        btnNext.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnNext.addTarget(self, action: #selector(finishWizardAndShowTools), for: .touchUpInside)
        prescriptionWizardContainer.addSubview(btnNext)

        let legendLabel = UILabel(frame: CGRect(x: 30, y: view.bounds.height - 235, width: view.bounds.width - 60, height: 60))
        legendLabel.numberOfLines = 0
        legendLabel.textAlignment = .center
        legendLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        legendLabel.textColor = UIColor.lightGray.withAlphaComponent(0.8)
        legendLabel.text = "GLOSSÁRIO CLÍNICO:\nESF: Esférico (Grau) | CIL: Cilíndrico (Astigmatismo)\nEIXO: Posição (0° a 180°) | ADIÇÃO: Grau extra para leitura\nOD: Olho Direito | OE: Olho Esquerdo"
        prescriptionWizardContainer.addSubview(legendLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideWizardKeyboard))
        prescriptionWizardContainer.addGestureRecognizer(tapGesture)
    }

    // --- LÓGICA DO FLUXO DO WIZARD ---
        func startApprovalStep() {
            sceneView.session.pause()
            motionManager.stopDeviceMotionUpdates()
            
            let snap = sceneView.snapshot()
            self.safeFaceCache = self.faceNode?.clone()
            self.safeSnapshotCache = snap
            self.savedFrontalSnapshot = snap
            capturedImageView.image = snap
            
            levelContainerView.isHidden = true ; levelLabel.isHidden = true
            headLevelContainerView.isHidden = true ; headLevelLabel.isHidden = true
            phonePitchContainerView.isHidden = true ; phonePitchLabel.isHidden = true
            headPitchContainerView.isHidden = true ; headPitchLabel.isHidden = true
            distanceBarContainer?.isHidden = true
            topFeedbackLabel?.isHidden = true
            faceGuideLayer?.isHidden = true
            startCaptureButton.isHidden = true
            
            // 🔴 CORREÇÃO: Esconde TODOS os controles laterais e botões fantasmas!
            self.tutorialButton.isHidden = true
            self.view.viewWithTag(880)?.isHidden = true // Tripé
            self.view.viewWithTag(882)?.isHidden = true // Try-On (Óculos)
            self.view.viewWithTag(777)?.isHidden = true
            self.view.viewWithTag(778)?.isHidden = true
            self.logoutButton.transform = .identity
            
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
                
                self.levelContainerView.isHidden = false ; self.levelLabel.isHidden = false
                self.headLevelContainerView.isHidden = false ; self.headLevelLabel.isHidden = false
                self.phonePitchContainerView.isHidden = false ; self.phonePitchLabel.isHidden = false
                self.headPitchContainerView.isHidden = false ; self.headPitchLabel.isHidden = false
                
                self.topFeedbackLabel?.isHidden = false ; self.faceGuideLayer?.isHidden = false
                
                // 🔴 CORREÇÃO: Devolve os botões essenciais da tela Viva!
                self.view.viewWithTag(777)?.isHidden = true
                self.view.viewWithTag(778)?.isHidden = true
                self.view.viewWithTag(880)?.isHidden = false // Devolve Tripé
                self.view.viewWithTag(882)?.isHidden = false // Devolve Try-On
                self.tutorialButton.isHidden = false
                self.logoutButton.transform = .identity
                
                self.startCaptureButton.isHidden = false
                self.startCaptureButton.setTitle("Iniciar Captura", for: .normal)
                self.startCaptureButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)
                self.startCaptureButton.setTitleColor(.black, for: .normal)
                self.startCaptureButton.layer.shadowOpacity = 0
                
                self.manualFrameWidth = 0.0
                self.manualFrameHeight = 0.0
                self.manualFrameDiagonal = 0.0
                self.pupillaryHeight = 0.0
                self.currentManualMode = 0
                if let segment = self.measurementTypeSegment {
                    segment.selectedSegmentIndex = 0
                    self.updateSegmentTitles()
                }
            }
        }

    @objc func hideWizardKeyboard() {
        self.view.endEditing(true)
    }

    @objc func approveImage() {
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

        if let btnNext = prescriptionWizardContainer.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.backgroundColor == UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) }) {
            if selectedLensType == "Multifocal" || selectedLensType == "Bifocal" || selectedLensType == "Ocupacional" {
                btnNext.setTitle("Avançar para Mapeamento Clínico", for: .normal)
            } else {
                btnNext.setTitle("Avançar para Medições Manuais", for: .normal)
            }
        }
    }

    @objc func toggleNearVisionMode() {
        let isCompleteMode = pertoModeSegment.selectedSegmentIndex == 1

        wCilPertoOD.isHidden = !isCompleteMode
        wEixoPertoOD.isHidden = !isCompleteMode
        wCilPertoOE.isHidden = !isCompleteMode
        wEixoPertoOE.isHidden = !isCompleteMode

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

        let isCompleteMode = pertoModeSegment.selectedSegmentIndex == 1
        if isCompleteMode {
            self.rxEsfPertoOD = wEsfPertoOD.text?.isEmpty == false ? wEsfPertoOD.text! : "-"
            self.rxCilPertoOD = wCilPertoOD.text?.isEmpty == false ? wCilPertoOD.text! : "-"
            self.rxEixoPertoOD = wEixoPertoOD.text?.isEmpty == false ? wEixoPertoOD.text! : "-"
            self.rxEsfPertoOE = wEsfPertoOE.text?.isEmpty == false ? wEsfPertoOE.text! : "-"
            self.rxCilPertoOE = wCilPertoOE.text?.isEmpty == false ? wCilPertoOE.text! : "-"
            self.rxEixoPertoOE = wEixoPertoOE.text?.isEmpty == false ? wEixoPertoOE.text! : "-"
        } else {
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

    @objc func backToApprovalScreen() {
        UIView.animate(withDuration: 0.3, animations: {
            self.prescriptionWizardContainer.alpha = 0
        }) { _ in
            self.prescriptionWizardContainer.isHidden = true
            self.approvalContainer.isHidden = false
            UIView.animate(withDuration: 0.3) { self.approvalContainer.alpha = 1.0 }
        }
    }
}
