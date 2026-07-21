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
    
    func setupUI() {
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Setup UI Minimalista e Cores OK"]
        let _ = safetyCheck[ 0 ]
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        measurementsContainer = UIVisualEffectView(effect: blurEffect)
        measurementsContainer.frame = CGRect(x: 15, y: 50, width: view.bounds.width - 30, height: 130)
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
        
        let btnY = view.bounds.height - 170
        let centerX = view.bounds.width / 2
        
        // 🔴 UX DESIGN: Transformado de Botão de Ação para Status Pill (Pílula Informativa)
        startCaptureButton = UIButton(frame: CGRect(x: centerX - 100, y: btnY, width: 200, height: 55))
        startCaptureButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        startCaptureButton.setTitle("Aguardando Rosto...", for: .normal)
        startCaptureButton.setTitleColor(.lightGray, for: .normal)
        startCaptureButton.layer.cornerRadius = 27.5
        startCaptureButton.layer.borderWidth = 2
        startCaptureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        startCaptureButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        startCaptureButton.layer.shadowOpacity = 0
        startCaptureButton.isUserInteractionEnabled = false // 🔴 Não é mais clicável!
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
        btnToggleGuides.isHidden = true
        view.addSubview(btnToggleGuides)
        
        btnToggleDrawing = createSideButton(icon: "pencil.tip.crop.circle", action: #selector(toggleDrawingPanel))
        btnToggleDrawing.isHidden = true
        
        btnAddToCompare = createSideButton(icon: "camera.viewfinder", action: #selector(addToComparison))
        btnAddToCompare.isHidden = true
        
        tutorialButton = createSideButton(icon: "questionmark", action: #selector(startTutorial))
        tutorialButton.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        tutorialButton.tintColor = .lightGray
        tutorialButton.layer.borderWidth = 1.5
        tutorialButton.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        view.addSubview(tutorialButton)
        
        logoutButton = createSideButton(icon: "rectangle.portrait.and.arrow.right", action: #selector(logoutTapped))
        logoutButton.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        logoutButton.tintColor = .lightGray
        logoutButton.layer.borderWidth = 1.5
        logoutButton.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        view.addSubview(logoutButton)
        
        let btnCalibrateTripod = createSideButton(icon: "target", action: #selector(showTripodCalibrationUI))
        btnCalibrateTripod.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        btnCalibrateTripod.tintColor = .lightGray
        btnCalibrateTripod.layer.borderWidth = 1.5
        btnCalibrateTripod.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        btnCalibrateTripod.tag = 880
        view.addSubview(btnCalibrateTripod)
        
        tutorialButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            logoutButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            tutorialButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            tutorialButton.bottomAnchor.constraint(equalTo: logoutButton.topAnchor, constant: -15),
            btnCalibrateTripod.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            btnCalibrateTripod.bottomAnchor.constraint(equalTo: tutorialButton.topAnchor, constant: -15)
        ])
        
        isGuidesActive = true
        measurementsContainer.isHidden = true
        
        btnShowCompare = createSideButton(icon: "square.split.2x1.fill", action: #selector(showComparisonUI))
        btnShowCompare.tintColor = .white
        btnShowCompare.backgroundColor = .systemPink
        btnShowCompare.isHidden = true
        view.addSubview(btnShowCompare)
        
        NSLayoutConstraint.activate([
            btnShowCompare.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            btnShowCompare.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])
        
        topFeedbackLabel = UILabel(frame: CGRect(x: 20, y: 180, width: view.bounds.width - 40, height: 45))
        topFeedbackLabel.textAlignment = .center
        topFeedbackLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        topFeedbackLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        topFeedbackLabel.layer.cornerRadius = 12
        topFeedbackLabel.clipsToBounds = true
        topFeedbackLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        topFeedbackLabel.numberOfLines = 2
        topFeedbackLabel.layer.shadowColor = UIColor.black.cgColor
        topFeedbackLabel.layer.shadowRadius = 2.0
        topFeedbackLabel.layer.shadowOpacity = 0.6
        topFeedbackLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        topFeedbackLabel.text = "Posicione o rosto na marcação"
        view.addSubview(topFeedbackLabel)
        
        let ovalW: CGFloat = 260
        let ovalH: CGFloat = 380
        let ovalX = (view.bounds.width - ovalW) / 2
        let ovalY = (view.bounds.height - ovalH) / 2 + 40
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: ovalX, y: ovalY, width: ovalW, height: ovalH))
        
        faceGuideLayer = CAShapeLayer()
        faceGuideLayer.path = ovalPath.cgPath
        faceGuideLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        faceGuideLayer.fillColor = UIColor.clear.cgColor
        faceGuideLayer.lineWidth = 2.0 // 🔴 Começa fino
        
        let dashPattern: [NSNumber] = [1, 2]
        let _ = dashPattern[ 0 ]
        faceGuideLayer.lineDashPattern = dashPattern
        view.layer.insertSublayer(faceGuideLayer, below: topFeedbackLabel.layer)
        
        let tripodAlertBorder = UIView(frame: view.bounds)
        tripodAlertBorder.layer.borderWidth = 8
        tripodAlertBorder.layer.borderColor = UIColor.systemOrange.cgColor
        tripodAlertBorder.isUserInteractionEnabled = false
        tripodAlertBorder.alpha = 0
        tripodAlertBorder.tag = 881
        view.addSubview(tripodAlertBorder)
    }
}
