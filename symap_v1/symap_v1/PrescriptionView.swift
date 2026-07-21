import UIKit

class PrescriptionView: UIView, UITextFieldDelegate {
    
    // O callback agora envia as 12 variáveis rigorosamente:
    // Longe: OD (esf, cil, eixo), OE (esf, cil, eixo)
    // Perto: OD (esf, cil, eixo), OE (esf, cil, eixo)
    var onConfirm: ((String, String, String, String, String, String, String, String, String, String, String, String) -> Void)?
    
    var isMultifocal: Bool
    
    // --- Campos da Visão de Longe ---
    var esfODField: UITextField!
    var cilODField: UITextField!
    var eixoODField: UITextField!
    var esfOEField: UITextField!
    var cilOEField: UITextField!
    var eixoOEField: UITextField!
    
    // --- Campos da Visão de Perto ---
    var esfPertoODField: UITextField?
    var cilPertoODField: UITextField?
    var eixoPertoODField: UITextField?
    var esfPertoOEField: UITextField?
    var cilPertoOEField: UITextField?
    var eixoPertoOEField: UITextField?
    
    init(frame: CGRect, isMultifocal: Bool) {
        self.isMultifocal = isMultifocal
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
    // Remove a cor sólida e adiciona o Glassmorphism (Vidro Escuro)
        self.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.bounds
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true
        self.insertSubview(blurView, at: 0)
        
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 15, width: self.bounds.width, height: 25))
        titleLabel.text = self.isMultifocal ? "Visão de Longe" : "Receita Clínica"
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.addSubview(titleLabel)
        
        let lblOD = UILabel(frame: CGRect(x: 20, y: 45, width: 140, height: 20))
        lblOD.text = "Olho Direito (longe)"
        lblOD.textColor = .white
        lblOD.font = UIFont.boldSystemFont(ofSize: 12)
        self.addSubview(lblOD)
        
        let lblOE = UILabel(frame: CGRect(x: 180, y: 45, width: 140, height: 20))
        lblOE.text = "Olho Esquerdo (Longe)"
        lblOE.textColor = .white
        lblOE.font = UIFont.boldSystemFont(ofSize: 12)
        self.addSubview(lblOE)
        
        // Desenhando os Campos de Longe
        esfODField = createField(x: 20, y: 70, placeholder: "ESF OD")
        cilODField = createField(x: 20, y: 110, placeholder: "CIL OD")
        eixoODField = createField(x: 20, y: 150, placeholder: "EIXO OD")
        
        esfOEField = createField(x: 180, y: 70, placeholder: "ESF OE")
        cilOEField = createField(x: 180, y: 110, placeholder: "CIL OE")
        eixoOEField = createField(x: 180, y: 150, placeholder: "EIXO OE")
        
        var btnY: CGFloat = 205 // Altura do botão se não for multifocal
        
        // 🔴 A MÁGICA: Desenhando os novos 6 campos se for Multifocal!
        if self.isMultifocal {
            let div = UIView(frame: CGRect(x: 20, y: 195, width: self.bounds.width - 40, height: 1))
            div.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            self.addSubview(div)
            
            let titlePerto = UILabel(frame: CGRect(x: 0, y: 205, width: self.bounds.width, height: 25))
            titlePerto.text = "Visão de Perto"
            titlePerto.textColor = .white
            titlePerto.textAlignment = .center
            titlePerto.font = UIFont.boldSystemFont(ofSize: 16)
            self.addSubview(titlePerto)
            
            let lblPertoOD = UILabel(frame: CGRect(x: 20, y: 235, width: 140, height: 20))
            lblPertoOD.text = "Olho Direito (Perto)"
            lblPertoOD.textColor = .white
            lblPertoOD.font = UIFont.boldSystemFont(ofSize: 12)
            self.addSubview(lblPertoOD)
            
            let lblPertoOE = UILabel(frame: CGRect(x: 180, y: 235, width: 140, height: 20))
            lblPertoOE.text = "Olho Esquerdo (Perto)"
            lblPertoOE.textColor = .white
            lblPertoOE.font = UIFont.boldSystemFont(ofSize: 12)
            self.addSubview(lblPertoOE)
            
            esfPertoODField = createField(x: 20, y: 260, placeholder: "ESF OD")
            cilPertoODField = createField(x: 20, y: 300, placeholder: "CIL OD")
            eixoPertoODField = createField(x: 20, y: 340, placeholder: "EIXO OD")
            
            esfPertoOEField = createField(x: 180, y: 260, placeholder: "ESF OE")
            cilPertoOEField = createField(x: 180, y: 300, placeholder: "CIL OE")
            eixoPertoOEField = createField(x: 180, y: 340, placeholder: "EIXO OE")
            
            btnY = 395 // Empurra o botão de salvar lá para baixo
        }
        
        let confirmBtn = UIButton(frame: CGRect(x: 20, y: btnY, width: self.bounds.width - 40, height: 45))
        confirmBtn.backgroundColor = .systemGreen
        confirmBtn.setTitle("Salvar Receita Completa", for: .normal)
        confirmBtn.layer.cornerRadius = 8
        confirmBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        self.addSubview(confirmBtn)
    }
    
    func createField(x: CGFloat, y: CGFloat, placeholder: String) -> UITextField {
            let tf = UITextField(frame: CGRect(x: x, y: y, width: 140, height: 35))
            tf.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            tf.textColor = .white
            tf.layer.cornerRadius = 6
            tf.borderStyle = .roundedRect
            tf.keyboardType = .numbersAndPunctuation // Teclado matemático
            tf.delegate = self // Habilita a formatação inteligente
            
            let attrPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            tf.attributedPlaceholder = attrPlaceholder
            self.addSubview(tf)
            return tf
        }
        
        // NOVA FUNÇÃO: Formatação inteligente ao terminar de digitar
        func textFieldDidEndEditing(_ textField: UITextField) {
            guard let text = textField.text, !text.isEmpty else { return }
            
            // Troca vírgula por ponto para evitar erros de cálculo
            let cleanText = text.replacingOccurrences(of: ",", with: ".")
            
            if let value = Float(cleanText) {
                // Se for Eixo (0 a 180), não coloca sinal. Se for Grau (Esf/Cil), coloca sinal + ou - com 2 casas decimais.
                if textField.placeholder?.contains("EIXO") == true {
                    textField.text = String(format: "%.0f°", value)
                } else {
                    let sign = value > 0 ? "+" : ""
                    textField.text = String(format: "%@%.2f", sign, value)
                }
            }
        }
    
    @objc func confirmTapped() {
        // Captura os dados de Longe
        let eOD = esfODField.text ?? ""
        let cOD = cilODField.text ?? ""
        let xOD = eixoODField.text ?? ""
        
        let eOE = esfOEField.text ?? ""
        let cOE = cilOEField.text ?? ""
        let xOE = eixoOEField.text ?? ""
        
        // Captura os dados de Perto (somente se eles existirem na interface)
        let peOD = self.isMultifocal ? (esfPertoODField?.text ?? "") : ""
        let pcOD = self.isMultifocal ? (cilPertoODField?.text ?? "") : ""
        let pxOD = self.isMultifocal ? (eixoPertoODField?.text ?? "") : ""
        
        let peOE = self.isMultifocal ? (esfPertoOEField?.text ?? "") : ""
        let pcOE = self.isMultifocal ? (cilPertoOEField?.text ?? "") : ""
        let pxOE = self.isMultifocal ? (eixoPertoOEField?.text ?? "") : ""
        
        // Envia as 12 matrizes de texto juntas para o motor central!
        onConfirm?(eOD, cOD, xOD, eOE, cOE, xOE, peOD, pcOD, pxOD, peOE, pcOE, pxOE)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    // Função nativa que detecta toques vazios na tela e recolhe o teclado
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.endEditing(true)
        }
}

