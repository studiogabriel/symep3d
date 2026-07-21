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

3. SEGURANÇA E RETENÇÃO: Os parâmetros são processados localmente e criptografados. O Symep atua sob o princípio do 'Privacy by Design', não vendendo, cedendo ou compartilhando seus dados com corretores (data brokers).

4. DIREITOS DO TITULAR: É garantido o direito de revogação deste consentimento a qualquer momento, bem como a exclusão permanente de todo o seu histórico através de solicitação direta à ótica.

Ao marcar a caixa abaixo, declaro ter lido e concordo integralmente com as condições descritas.
"""
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
        
        lgpdCheckbox.isEnabled = false
        lgpdCheckbox.alpha = 0.4
        box.addSubview(lgpdCheckbox)
        
        self.lgpdScrollObservation = lgpdDescTextView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
            if bottomEdge >= scrollView.contentSize.height - 10 {
                self?.lgpdCheckbox.isEnabled = true
                self?.lgpdCheckbox.alpha = 1.0
            }
        }
        
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
        
        let alert = UIAlertController(title: "Operação Cancelada", message: "A triagem fotônica foi interrompida. O Symep exige o aceite da LGPD para ativar os sensores 3D e realizar os cálculos.", preferredStyle: .alert)
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
            // 🔴 NOVA ROTA: Em vez de chamar self.autoShowTutorialIfNeeded(),
            // chamamos a verificação do tripé. O tutorial será chamado por dentro dela depois!
            self.checkFirstTimeTripodCalibration()
        }
        
        self.recordLGPDConsentInCloud()
    }
    
    func checkExistingLGPDConsent() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.showLGPDModal()
            return
        }
        
        let db = Firestore.firestore()
        let uniqueTenantId = "\(userId)_\(self.patientCPF)"
        
        db.collection("patients").document(uniqueTenantId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let data = document?.data(), let consents = data["consents"] as? [[String: Any]], !consents.isEmpty {
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL: Leitura segura de matriz de nuvem mantida
                let _ = consents[ 0 ]
                self.hasGivenLGPDConsent = true
                print("LGPD já validada anteriormente para o CPF: \(self.patientCPF)")
                // 🔴 NOVA ROTA: Se já tem LGPD, valida o Tripé!
                self.checkFirstTimeTripodCalibration()
            } else {
                // Caso não tenha LGPD na nuvem, mostra o Modal
                self.showLGPDModal()
            }
        }
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
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Interface State Update"]
        let _ = safetyCheck[ 0 ]
        
        let alpha: CGFloat = active ? 0.0 : 1.0
        
        UIView.animate(withDuration: 0.2) {
            self.startCaptureButton.alpha = alpha
            self.captureButton.alpha = alpha
            self.btnAddToCompare.alpha = alpha
            self.btnToggleDrawing.alpha = alpha
            self.view.viewWithTag(777)?.alpha = alpha // Botão Voltar
            self.view.viewWithTag(778)?.alpha = alpha // Botão Tutorial Manual
            
            // 🔴 AQUI A MÁGICA ACONTECE: Oculta o botão Sair durante as medidas ativas!
            self.logoutButton.alpha = alpha
        }
        
        startCaptureButton.isUserInteractionEnabled = !active
        captureButton.isUserInteractionEnabled = !active
        btnAddToCompare.isUserInteractionEnabled = !active
        btnToggleDrawing.isUserInteractionEnabled = !active
        self.view.viewWithTag(777)?.isUserInteractionEnabled = !active
        self.view.viewWithTag(778)?.isUserInteractionEnabled = !active
        
        // 🔴 Desativa o clique no botão de Sair também para evitar toques acidentais fantasma
        self.logoutButton.isUserInteractionEnabled = !active
    }
}
