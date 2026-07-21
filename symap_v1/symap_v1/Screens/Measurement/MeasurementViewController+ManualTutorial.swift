import UIKit

// =========================================================================
// 🔴 TELA 1: TUTORIAL GERAL DO MENU (Aberto automaticamente ou pelo botão "?")
// =========================================================================
class ManualMenuTutorialView: UIView {
    var onClose: (() -> Void)?
    var isDontShowChecked = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func setupUI() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = self.bounds; blur.alpha = 0.8
        self.addSubview(blur)
        
        // 🔴 CORREÇÃO UX: Aumentamos a altura (boxH: 520) para caber a checkbox
        let boxW: CGFloat = 340; let boxH: CGFloat = 520
        let box = UIView(frame: CGRect(x: (self.bounds.width - boxW)/2, y: (self.bounds.height - boxH)/2, width: boxW, height: boxH))
        box.backgroundColor = UIColor(white: 0.1, alpha: 1.0); box.layer.cornerRadius = 20
        box.layer.borderWidth = 1; box.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        self.addSubview(box)
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 25))
        titleLabel.text = "FERRAMENTAS MANUAIS"
        titleLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18); titleLabel.textAlignment = .center
        box.addSubview(titleLabel)
        
        let descLabel = UILabel(frame: CGRect(x: 20, y: 60, width: boxW - 40, height: 60))
        descLabel.text = "Selecione uma ferramenta no menu inferior, ajuste a marcação amarela e clique em 'Salvar Medida'."
        descLabel.textColor = .lightGray; descLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        descLabel.numberOfLines = 0; descLabel.textAlignment = .center
        box.addSubview(descLabel)
        
        // LISTA DE ÍCONES
        let icons = [
            ("scope", "Altura de Montagem (H)", "Mede do centro da pupila até a base da armação."),
            ("arrow.up.and.down", "Medida Vertical", "Altura interna total da lente."),
            ("arrow.left.and.right", "Medida Horizontal", "Largura interna total da lente."),
            ("arrow.up.right.and.arrow.down.left", "Medida Diagonal", "Maior distância transversal interna da lente."),
            ("magnifyingglass", "Lupa de Precisão", "Ao arrastar as réguas, a lupa aproxima o rosto em 2x."),
            ("checkmark.circle.fill", "Medida Salva", "O ícone da ferramenta muda quando o valor é salvo.")
        ]
        
        var startY: CGFloat = 135
        for item in icons {
            let iv = UIImageView(frame: CGRect(x: 20, y: startY, width: 24, height: 24))
            iv.image = UIImage(systemName: item.0); iv.tintColor = .white; iv.contentMode = .scaleAspectFit
            box.addSubview(iv)
            
            let lblT = UILabel(frame: CGRect(x: 55, y: startY, width: boxW - 70, height: 14))
            lblT.text = item.1; lblT.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            lblT.font = UIFont.boldSystemFont(ofSize: 12)
            box.addSubview(lblT)
            
            let lblD = UILabel(frame: CGRect(x: 55, y: startY + 14, width: boxW - 70, height: 28))
            lblD.text = item.2; lblD.textColor = .lightGray; lblD.font = UIFont.systemFont(ofSize: 10)
            lblD.numberOfLines = 2
            box.addSubview(lblD)
            startY += 45
        }
        
        // 🔴 NOVO: CHECKBOX DE ONBOARDING CONTEXTUAL
        let btnDontShow = UIButton(frame: CGRect(x: 20, y: boxH - 105, width: boxW - 40, height: 30))
        btnDontShow.setTitle(" Não mostrar este tutorial novamente", for: .normal)
        btnDontShow.setTitleColor(.lightGray, for: .normal)
        btnDontShow.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        isDontShowChecked = UserDefaults.standard.bool(forKey: "hideManualMenuTutorial")
        
        btnDontShow.setImage(UIImage(systemName: isDontShowChecked ? "checkmark.square.fill" : "square"), for: .normal)
        btnDontShow.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnDontShow.addTarget(self, action: #selector(toggleDontShow(_:)), for: .touchUpInside)
        box.addSubview(btnDontShow)
        
        let btnOk = UIButton(frame: CGRect(x: 20, y: boxH - 65, width: boxW - 40, height: 45))
        btnOk.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnOk.setTitle("Entendi", for: .normal); btnOk.setTitleColor(.black, for: .normal)
        btnOk.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16); btnOk.layer.cornerRadius = 12
        btnOk.addTarget(self, action: #selector(close), for: .touchUpInside)
        box.addSubview(btnOk)
    }
    
    @objc func toggleDontShow(_ sender: UIButton) {
        isDontShowChecked.toggle()
        sender.setImage(UIImage(systemName: isDontShowChecked ? "checkmark.square.fill" : "square"), for: .normal)
        UserDefaults.standard.set(isDontShowChecked, forKey: "hideManualMenuTutorial")
    }
    
    @objc func close() { onClose?() }
}

// =========================================================================
// 🔴 TELA 2: TUTORIAL PASSO A PASSO (Aberto automaticamente ao medir)
// =========================================================================
class SingleStepManualTutorialView: UIView {
    var stepMode: Int
    var onClose: (() -> Void)?
    var isDontShowChecked = false
    
    override init(frame: CGRect) { self.stepMode = 1; super.init(frame: frame) }
    
    init(step: Int, frame: CGRect) {
        self.stepMode = step
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func setupUI() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = self.bounds; blur.alpha = 0.8; self.addSubview(blur)
        
        let boxW: CGFloat = 340; let boxH: CGFloat = 410
        let box = UIView(frame: CGRect(x: (self.bounds.width - boxW)/2, y: (self.bounds.height - boxH)/2, width: boxW, height: boxH))
        box.backgroundColor = UIColor(white: 0.1, alpha: 1.0); box.layer.cornerRadius = 20
        box.layer.borderWidth = 1; box.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        self.addSubview(box)
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 25, width: boxW - 40, height: 25))
        titleLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18); titleLabel.textAlignment = .center
        box.addSubview(titleLabel)
        
        let imgContainer = UIView(frame: CGRect(x: 20, y: 65, width: boxW - 40, height: 160))
        imgContainer.backgroundColor = UIColor(white: 0.05, alpha: 1.0); imgContainer.layer.cornerRadius = 16
        imgContainer.clipsToBounds = true
        box.addSubview(imgContainer)
        
        let glassesIcon = UIImageView(frame: CGRect(x: (imgContainer.bounds.width - 200)/2, y: (imgContainer.bounds.height - 100)/2, width: 200, height: 100))
        glassesIcon.image = UIImage(systemName: "eyeglasses"); glassesIcon.tintColor = UIColor(white: 0.8, alpha: 1.0)
        glassesIcon.contentMode = .scaleAspectFit; imgContainer.addSubview(glassesIcon)
        
        let measureLine = UIView(); measureLine.backgroundColor = .yellow; imgContainer.addSubview(measureLine)
        let point1 = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)); point1.backgroundColor = .yellow; point1.layer.cornerRadius = 5; imgContainer.addSubview(point1)
        let point2 = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)); point2.backgroundColor = .yellow; point2.layer.cornerRadius = 5; imgContainer.addSubview(point2)
        
        let descLabel = UILabel(frame: CGRect(x: 20, y: 235, width: boxW - 40, height: 70))
        descLabel.textColor = .lightGray; descLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descLabel.numberOfLines = 0; descLabel.textAlignment = .center
        box.addSubview(descLabel)
        
        // 🔴 CHECKBOX - Onboarding Contextual
        let btnDontShow = UIButton(frame: CGRect(x: 20, y: 310, width: boxW - 40, height: 30))
        btnDontShow.setTitle(" Não mostrar esta dica novamente", for: .normal)
        btnDontShow.setTitleColor(.lightGray, for: .normal)
        btnDontShow.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        isDontShowChecked = UserDefaults.standard.bool(forKey: "hideManualStep\(stepMode)")
        
        btnDontShow.setImage(UIImage(systemName: isDontShowChecked ? "checkmark.square.fill" : "square"), for: .normal)
        btnDontShow.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnDontShow.addTarget(self, action: #selector(toggleDontShow(_:)), for: .touchUpInside)
        box.addSubview(btnDontShow)
        
        let btnOk = UIButton(frame: CGRect(x: 20, y: 350, width: boxW - 40, height: 45))
        btnOk.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnOk.setTitle("Entendi", for: .normal); btnOk.setTitleColor(.black, for: .normal)
        btnOk.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16); btnOk.layer.cornerRadius = 12
        btnOk.addTarget(self, action: #selector(close), for: .touchUpInside)
        box.addSubview(btnOk)
        
        // --- ANIMAÇÕES MILIMÉTRICAS APROVEITADAS ---
        let cx = glassesIcon.frame.midX + 46;  let cy = glassesIcon.frame.midY
        
        switch stepMode {
        case 1: // Altura de Montagem
            titleLabel.text = "1. ALTURA DE MONTAGEM (H)"
            descLabel.text = "Ajuste a linha na base INFERIOR INTERNA da armação. Ela ira medir a distancia do centro da sua pupila a base da armação."
            measureLine.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            point1.isHidden = true; point2.isHidden = true
            measureLine.frame = CGRect(x: cx - 40, y: cy + 40, width: 80, height: 2)
            let anim = CABasicAnimation(keyPath: "position.y")
            anim.fromValue = measureLine.layer.position.y
            anim.toValue = measureLine.layer.position.y - 15
            anim.duration = 2.0; anim.autoreverses = true; anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            measureLine.layer.add(anim, forKey: "scanAnim")
            
        case 2: // Vertical
            titleLabel.text = "2. MEDIDA VERTICAL"
            descLabel.text = "Arraste as setas amarelas para o limite superior e inferior INTERNO da lente. Este passo nos fornecera informacoes do tamanho total vertical da sua lente."
            measureLine.frame = CGRect(x: cx - 3, y: cy - 23, width: 2, height: 46)
            point1.center = CGPoint(x: cx - 2, y: cy - 23); point2.center = CGPoint(x: cx - 2, y: cy + 23)
            
        case 3: // Horizontal
            titleLabel.text = "3. MEDIDA HORIZONTAL"
            descLabel.text = "Arraste as setas para as extremidades laterais INTERNAS da lente. Este passo nos fornecera informacoes do tamanho total horizontal da sua lente."
            measureLine.frame = CGRect(x: cx - 24, y: cy - 1, width: 44, height: 2)
            point1.center = CGPoint(x: cx - 24, y: cy); point2.center = CGPoint(x: cx + 20, y: cy)
            
        case 4: // Diagonal
            titleLabel.text = "4. MEDIDA DIAGONAL MAIOR"
            descLabel.text = "Identifique visualmente e arraste as setas para a maior distância na parte INTERNA do aro.ste passo nos fornecera informacoes do tamanho total do bloco necessario para fabricacao da sua lente."
            measureLine.frame = CGRect(x: cx - 26, y: cy - 1, width: 40, height: 2)
            let radius: CGFloat = 20.0
            let dx = radius * cos(-CGFloat.pi/6);  let dy = radius * sin(-CGFloat.pi/6)
            measureLine.transform = CGAffineTransform(rotationAngle: -.pi/6)
            point1.center = CGPoint(x: cx - 6 - dx, y: cy - dy); point2.center = CGPoint(x: cx - 6 + dx, y: cy + dy)
            
        default: break
        }
    }
    
    @objc func toggleDontShow(_ sender: UIButton) {
        isDontShowChecked.toggle()
        sender.setImage(UIImage(systemName: isDontShowChecked ? "checkmark.square.fill" : "square"), for: .normal)
        UserDefaults.standard.set(isDontShowChecked, forKey: "hideManualStep\(stepMode)")
    }
    
    @objc func close() { onClose?() }
}

extension MeasurementViewController {
    
    // Chamado EXCLUSIVAMENTE ao clicar no botão (?) das ferramentas manuais
    @objc func showManualMeasurementTutorial() {
        let tut = ManualMenuTutorialView(frame: self.view.bounds)
        tut.onClose = { [weak tut] in
            UIView.animate(withDuration: 0.3, animations: { tut?.alpha = 0 }) { _ in tut?.removeFromSuperview() }
        }
        tut.alpha = 0
        self.view.addSubview(tut)
        UIView.animate(withDuration: 0.3) { tut.alpha = 1.0 }
    }
    
    // 🔴 NOVO: Função de Inteligência que decide se o Menu Manual deve subir automaticamente
    @objc func autoShowManualMenuTutorialIfNeeded() {
        let hideTutorial = UserDefaults.standard.bool(forKey: "hideManualMenuTutorial")
        if !hideTutorial {
            // Leve atraso para dar tempo da tela de edição (Freeze) terminar a transição
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.showManualMeasurementTutorial()
            }
        }
    }
}
