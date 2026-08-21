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
            // 🔴 BRANDBOOK: Injeção das Tintas Oficiais para a Interface do Wizard
            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
            let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0)
            let navyDarkBase = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 0.85)
            let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
            let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)

            // ----------------------------------------------------
            // TELA 1: APROVAÇÃO DA FOTO
            // ----------------------------------------------------
            approvalContainer = UIView(frame: view.bounds)
            approvalContainer.backgroundColor = navyDark
            approvalContainer.isHidden = true
            view.addSubview(approvalContainer)
            
            capturedImageView = UIImageView(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: view.bounds.height - 350))
            capturedImageView.contentMode = .scaleAspectFill
            capturedImageView.layer.cornerRadius = 20
            capturedImageView.clipsToBounds = true
            capturedImageView.layer.borderWidth = 2
            capturedImageView.layer.borderColor = opticalCyan.withAlphaComponent(0.3).cgColor
            approvalContainer.addSubview(capturedImageView)
            
            let rulesLabel = UILabel(frame: CGRect(x: 30, y: capturedImageView.frame.maxY + 20, width: view.bounds.width - 60, height: 90))
            rulesLabel.numberOfLines = 0
            rulesLabel.textColor = slateColor
            rulesLabel.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
            rulesLabel.text = "Critérios Clínicos de Aprovação:\n1. Não deve haver reflexos ou distorção na lente.\n2. Rosto reto e natural, sem inclinação do queixo.\n3. Os dois olhos devem estar 100% visíveis e abertos."
            approvalContainer.addSubview(rulesLabel)
            
            let btnReset = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: (view.bounds.width/2) - 40, height: 55))
            btnReset.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            btnReset.setTitle("← Refazer (Reset)", for: .normal)
            btnReset.setTitleColor(.systemRed, for: .normal)
            btnReset.layer.cornerRadius = 16
            btnReset.layer.borderWidth = 1
            btnReset.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
            btnReset.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnReset.addTarget(self, action: #selector(rejectAndReset), for: .touchUpInside)
            approvalContainer.addSubview(btnReset)
            
            let btnApprove = UIButton(frame: CGRect(x: view.bounds.width/2 + 10, y: view.bounds.height - 100, width: (view.bounds.width/2) - 40, height: 55))
            btnApprove.backgroundColor = opticalCyan
            btnApprove.setTitle("Aprovar Imagem", for: .normal)
            btnApprove.setTitleColor(navyDark, for: .normal)
            btnApprove.layer.cornerRadius = 16
            btnApprove.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnApprove.layer.shadowOpacity = 0 // Regra 8 do Brandbook: Sombras banidas!
            btnApprove.addTarget(self, action: #selector(approveImage), for: .touchUpInside)
            approvalContainer.addSubview(btnApprove)
            
            // ----------------------------------------------------
            // TELA 2: SELEÇÃO DE LENTE E RECEITA CLÍNICA
            // ----------------------------------------------------
            prescriptionWizardContainer = UIView(frame: view.bounds)
            prescriptionWizardContainer.backgroundColor = navyDark
            prescriptionWizardContainer.isHidden = true
            view.addSubview(prescriptionWizardContainer)
            
            let titleRx = UILabel(frame: CGRect(x: 30, y: 50, width: view.bounds.width - 60, height: 30))
            titleRx.textAlignment = .center
            titleRx.attributedText = NSAttributedString(string: "TIPO DE LENTE E RECEITA", attributes: [
                .font: UIFont(name: "Inter-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .black),
                .foregroundColor: offWhite,
                .kern: 1.5
            ])
            prescriptionWizardContainer.addSubview(titleRx)
            
            let instrLens = UILabel(frame: CGRect(x: 30, y: 90, width: view.bounds.width - 60, height: 20))
            instrLens.text = "Escolha o tipo de lente desejada:"
            instrLens.textColor = slateColor
            instrLens.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
            instrLens.textAlignment = .center
            prescriptionWizardContainer.addSubview(instrLens)
            
            wizardLensSegment = UISegmentedControl(items: ["Visão Simples", "Multifocal", "Bifocal", "Ocupacional"])
            wizardLensSegment.frame = CGRect(x: 15, y: 120, width: view.bounds.width - 30, height: 40)
            wizardLensSegment.selectedSegmentIndex = 0
            wizardLensSegment.backgroundColor = navyDarkBase
            wizardLensSegment.selectedSegmentTintColor = opticalCyan
            
            let normalAttr = [NSAttributedString.Key.foregroundColor: slateColor]
            let selectedAttr = [
                NSAttributedString.Key.foregroundColor: navyDark,
                NSAttributedString.Key.font: UIFont(name: "Inter-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
            ]
            wizardLensSegment.setTitleTextAttributes(normalAttr, for: .normal)
            wizardLensSegment.setTitleTextAttributes(selectedAttr, for: .selected)
            wizardLensSegment.addTarget(self, action: #selector(wizardLensChanged), for: .valueChanged)
            prescriptionWizardContainer.addSubview(wizardLensSegment)
            
            let btnScanRx = UIButton(frame: CGRect(x: 30, y: 175, width: view.bounds.width - 60, height: 45))
            btnScanRx.backgroundColor = navyMedium.withAlphaComponent(0.4)
            btnScanRx.setTitle("📸 Escanear Receita Inteligente", for: .normal)
            btnScanRx.setTitleColor(opticalCyan, for: .normal)
            btnScanRx.titleLabel?.font = UIFont(name: "Inter-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
            btnScanRx.layer.cornerRadius = 12
            btnScanRx.layer.borderWidth = 1.5
            btnScanRx.layer.borderColor = opticalCyan.withAlphaComponent(0.4).cgColor
            btnScanRx.layer.shadowOpacity = 0
            btnScanRx.addTarget(self, action: NSSelectorFromString("scanPrescriptionTapped"), for: .touchUpInside)
            prescriptionWizardContainer.addSubview(btnScanRx)
            
            let instrRx = UILabel(frame: CGRect(x: 30, y: 235, width: view.bounds.width - 60, height: 20))
            instrRx.text = "Ou adicione os dados da receita manualmente:"
            instrRx.textColor = slateColor
            instrRx.font = UIFont(name: "Inter-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
            instrRx.textAlignment = .center
            prescriptionWizardContainer.addSubview(instrRx)
            
            let longeLabel = UILabel(frame: CGRect(x: 30, y: 260, width: view.bounds.width - 60, height: 20))
            longeLabel.text = "VISÃO DE LONGE (OD / OE)"
            longeLabel.textColor = slateColor
            longeLabel.font = UIFont(name: "Inter-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
            prescriptionWizardContainer.addSubview(longeLabel)
            
            let fieldW = (view.bounds.width - 90) / 3
            
            func createWField(x: CGFloat, y: CGFloat, ph: String) -> UITextField {
                let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 40))
                tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                tf.textColor = .white
                tf.layer.cornerRadius = 12
                tf.layer.borderWidth = 1
                tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
                tf.font = UIFont(name: "Inter-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
                tf.textAlignment = .center
                tf.keyboardType = .numbersAndPunctuation
                tf.delegate = self
                
                tf.attributedPlaceholder = NSAttributedString(
                    string: ph,
                    attributes: [
                        .foregroundColor: slateColor,
                        .font: UIFont(name: "Inter-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
                    ]
                )
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
            pertoLabel.textColor = slateColor
            pertoLabel.font = UIFont(name: "Inter-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
            wizardPertoContainer.addSubview(pertoLabel)
            
            pertoModeSegment = UISegmentedControl(items: ["Somente Adição (ADD)", "Receita Completa"])
            pertoModeSegment.frame = CGRect(x: 30, y: 30, width: view.bounds.width - 60, height: 35)
            pertoModeSegment.selectedSegmentIndex = 0
            pertoModeSegment.backgroundColor = navyDarkBase
            pertoModeSegment.selectedSegmentTintColor = opticalCyan
            pertoModeSegment.setTitleTextAttributes(normalAttr, for: .normal)
            pertoModeSegment.setTitleTextAttributes(selectedAttr, for: .selected)
            pertoModeSegment.addTarget(self, action: #selector(toggleNearVisionMode), for: .valueChanged)
            wizardPertoContainer.addSubview(pertoModeSegment)
            
            func createPField(x: CGFloat, y: CGFloat, ph: String) -> UITextField {
                let tf = UITextField(frame: CGRect(x: x, y: y, width: fieldW, height: 40))
                tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                tf.textColor = .white
                tf.layer.cornerRadius = 12
                tf.layer.borderWidth = 1
                tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
                tf.font = UIFont(name: "Inter-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
                tf.textAlignment = .center
                tf.keyboardType = .numbersAndPunctuation
                tf.delegate = self
                
                tf.attributedPlaceholder = NSAttributedString(
                    string: ph,
                    attributes: [
                        .foregroundColor: slateColor,
                        .font: UIFont(name: "Inter-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
                    ]
                )
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
            btnBackToPhoto.backgroundColor = navyMedium.withAlphaComponent(0.4)
            btnBackToPhoto.setTitle("← Voltar para a Foto", for: .normal)
            btnBackToPhoto.setTitleColor(.white, for: .normal)
            btnBackToPhoto.layer.cornerRadius = 16
            btnBackToPhoto.layer.borderWidth = 1.5
            btnBackToPhoto.layer.borderColor = opticalCyan.withAlphaComponent(0.4).cgColor
            btnBackToPhoto.titleLabel?.font = UIFont(name: "Inter-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15)
            btnBackToPhoto.addTarget(self, action: #selector(backToApprovalScreen), for: .touchUpInside)
            prescriptionWizardContainer.addSubview(btnBackToPhoto)
            
            let btnNext = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 55))
            btnNext.backgroundColor = opticalCyan
            btnNext.setTitle("Avançar para Medições Manuais", for: .normal)
            btnNext.setTitleColor(navyDark, for: .normal)
            btnNext.layer.cornerRadius = 16
            btnNext.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnNext.layer.shadowOpacity = 0
            btnNext.addTarget(self, action: #selector(finishWizardAndShowTools), for: .touchUpInside)
            prescriptionWizardContainer.addSubview(btnNext)
            
            let legendLabel = UILabel(frame: CGRect(x: 30, y: view.bounds.height - 235, width: view.bounds.width - 60, height: 60))
            legendLabel.numberOfLines = 0
            legendLabel.textAlignment = .center
            legendLabel.font = UIFont(name: "Inter-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .medium)
            legendLabel.textColor = slateColor
            legendLabel.text = "GLOSSÁRIO CLÍNICO:\nESF: Esférico (Grau) | CIL: Cilíndrico (Astigmatismo)\nEIXO: Posição (0° a 180°) | ADIÇÃO: Grau extra para leitura\nOD: Olho Direito | OE: Olho Esquerdo"
            prescriptionWizardContainer.addSubview(legendLabel)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideWizardKeyboard))
            prescriptionWizardContainer.addGestureRecognizer(tapGesture)
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL (Índice Seguro)
            let wizardValidation = ["Wizard Design Standard OK"]
            let _ = wizardValidation[ 0 ]
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
