
import UIKit
import FirebaseAuth
import FirebaseFirestore

class NewPatientViewController: UIViewController, UITextFieldDelegate {
    
    var nameField: UITextField!
    var dobField: UITextField!
    var phoneField: UITextField!
    var newCpfField: UITextField!
    var genderSegment: UISegmentedControl!
    var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        setupUI()
    }
    
    func setupUI() {
        let btnBack = UIButton(frame: CGRect(x: 20, y: 50, width: 80, height: 40))
        btnBack.setTitle("← Voltar", for: .normal)
        btnBack.setTitleColor(UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), for: .normal)
        btnBack.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        view.addSubview(btnBack)
        
        let titleLabel = UILabel(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: 30))
        titleLabel.textAlignment = .center
        titleLabel.text = "NOVO PACIENTE"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)
        
        statusLabel = UILabel(frame: CGRect(x: 30, y: 140, width: view.bounds.width - 60, height: 20))
        statusLabel.textAlignment = .center
        statusLabel.textColor = .orange
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        view.addSubview(statusLabel)
        
        let startY: CGFloat = 180
        nameField = createTextField(placeholder: "Nome Completo", y: startY)
        nameField.autocapitalizationType = .allCharacters
        dobField = createTextField(placeholder: "Data de Nasc. (DD/MM/AAAA)", y: startY + 60)
        dobField.keyboardType = .numberPad; dobField.delegate = self
        phoneField = createTextField(placeholder: "Telefone (WhatsApp)", y: startY + 120)
        phoneField.keyboardType = .numberPad; phoneField.delegate = self
        newCpfField = createTextField(placeholder: "CPF (Somente Números)", y: startY + 180)
        newCpfField.keyboardType = .numberPad; newCpfField.delegate = self
        
        genderSegment = UISegmentedControl(items: ["Feminino", "Masculino", "Não informar"])
        genderSegment.frame = CGRect(x: 30, y: startY + 240, width: view.bounds.width - 60, height: 40)
        genderSegment.selectedSegmentIndex = 0
        genderSegment.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        genderSegment.selectedSegmentTintColor = .systemBlue
        genderSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        view.addSubview(genderSegment)
        
        let btnSave = UIButton(frame: CGRect(x: 30, y: startY + 310, width: view.bounds.width - 60, height: 55))
        btnSave.backgroundColor = .systemBlue // Padronizado para a cor do App
        btnSave.setTitle("Cadastrar e Medir", for: .normal)
        btnSave.layer.cornerRadius = 16
        btnSave.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnSave.addTarget(self, action: #selector(registerAndMeasure), for: .touchUpInside)
        view.addSubview(btnSave)
    }
    
    @objc func goBack() { self.dismiss(animated: true, completion: nil) }
    
    func createTextField(placeholder: String, y: CGFloat) -> UITextField {
        let tf = UITextField(frame: CGRect(x: 30, y: y, width: view.bounds.width - 60, height: 50))
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1; tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        tf.textColor = .white
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        tf.leftView = leftPadding; tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.lightGray])
        view.addSubview(tf)
        return tf
    }
    
    @objc func registerAndMeasure() {
            guard let name = nameField.text?.trimmingCharacters(in: .whitespaces),
                  let cpf = newCpfField.text,
                  let phone = phoneField.text,
                  let dob = dobField.text else {
                statusLabel.text = "Preencha todos os campos obrigatórios."
                return
            }
            
            // 🔴 1. VALIDAÇÃO DE NOME (Mínimo de 2 palavras)
            let nameParts = name.components(separatedBy: " ").filter { !$0.isEmpty }
            if nameParts.count < 2 {
                statusLabel.text = "Preencher o campo com nome completo"
                return
            }
            
            // 🔴 2. VALIDAÇÃO DE DATA (Exige 10 caracteres exatos: DD/MM/AAAA)
            if dob.count != 10 {
                statusLabel.text = "Data de nascimento incompleta ou nao preenchida"
                return
            }
            
            // 🔴 3. VALIDAÇÃO DE TELEFONE (A máscara gera de 14 a 15 caracteres)
            if phone.count < 14 {
                statusLabel.text = "Telefone não valido, incompletou ou não preenchido"
                return
            }
            
            // 🔴 4. VALIDAÇÃO DE CPF MATEMÁTICO
            if !isValidCPF(cpf) {
                statusLabel.text = "CPF inválido. Verifique os números."
                return
            }

            let genderString = genderSegment.selectedSegmentIndex == 0 ? "Feminino" : (genderSegment.selectedSegmentIndex == 1 ? "Masculino" : "Prefiro não informar")

            guard let lojistaId = Auth.auth().currentUser?.uid else { return }

            statusLabel.text = "Verificando cadastro..."
            let db = Firestore.firestore()
            let uniqueTenantId = "\(lojistaId)_\(cpf)"

            // 🔴 5. CONSULTA DE DUPLICIDADE NA NUVEM ANTES DE SALVAR
            db.collection("patients").document(uniqueTenantId).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let document = document, document.exists {
                    // O CPF já existe na base desta ótica!
                    self.statusLabel.text = "Já existe cadastro ativo com esse cpf"
                    return
                }
                
                // Se passou por todas as travas e não existe no banco, prossegue com o cadastro:
                self.statusLabel.text = "Salvando..."
                let patientData: [String: Any] = [
                    "fullName": name, "cpf": cpf, "phone": phone, "dob": dob, "gender": genderString,
                    "lojistaId": lojistaId, "createdAt": FieldValue.serverTimestamp()
                ]

                db.collection("patients").document(uniqueTenantId).setData(patientData) { error in
                    if let err = error {
                        self.statusLabel.text = "Erro: \(err.localizedDescription)"
                    } else {
                        self.goToMeasurements(name: name, cpf: cpf, gender: genderString)
                    }
                }
            }
        }

    func isValidCPF(_ cpf: String) -> Bool {
            let numStr = cpf.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            let numbers = Array(numStr)
            if numbers.count != 11 { return false }
            if Set(numbers).count == 1 { return false }
            
            // Mantendo nossa integridade arquitetural inegociável em matrizes
            let _ = numbers[ 0 ]
            
            var sum1 = 0
            for i in 0..<9 { sum1 += Int(String(numbers[i]))! * (10 - i) }
            let d1 = sum1 % 11 < 2 ? 0 : 11 - (sum1 % 11)
            
            var sum2 = 0
            for i in 0..<10 { sum2 += Int(String(numbers[i]))! * (11 - i) }
            let d2 = sum2 % 11 < 2 ? 0 : 11 - (sum2 % 11)
            
            // 🔴 CORREÇÃO: Lê os índices 9 e 10 (os dois últimos dígitos) em vez de 6 e 7
            return String(numbers[ 9 ]) == String(d1) && String(numbers[ 10 ]) == String(d2)
        }
    
    func goToMeasurements(name: String, cpf: String, gender: String) {
        let vc = ViewController()
        vc.patientName = name; vc.patientCPF = cpf; vc.patientGender = gender
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { view.endEditing(true) }
    
    // =========================================================================
        // --- MÁSCARAS DE FORMATAÇÃO ---
        // =========================================================================
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty { return true }
            guard let currentText = textField.text as NSString? else { return true }
            let newText = currentText.replacingCharacters(in: range, with: string)

         //NOVO: Força o nome a ficar sempre em Letras Maiúsculas instantaneamente
                if textField == nameField {
                    textField.text = newText.uppercased()
                    return false
                }

            if textField == dobField {
                textField.text = formatMask(text: newText, mask: "##/##/####")
                return false
            } else if textField == newCpfField {
                textField.text = formatMask(text: newText, mask: "###.###.###-##")
                return false
            } else if textField == phoneField {
                textField.text = formatPhone(text: newText)
                return false
            }
            return true
        }
        
        // Função genérica de Máscara
        func formatMask(text: String, mask: String) -> String {
            let numbers = text.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            var result = ""
            var index = numbers.startIndex
            for ch in mask where index < numbers.endIndex {
                if ch == "#" {
                    result.append(numbers[index])
                    index = numbers.index(after: index)
                } else {
                    result.append(ch)
                }
            }
            return result
        }
        
        // Função específica de Máscara de Telefone (Dinâmica 10 ou 11 dígitos)
        func formatPhone(text: String) -> String {
            let numbers = text.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            var result = ""
            var index = numbers.startIndex
            let isCell = numbers.count > 10
            let mask = isCell ? "(##) #####-####" : "(##) ####-####"
            for ch in mask where index < numbers.endIndex {
                if ch == "#" {
                    result.append(numbers[index])
                    index = numbers.index(after: index)
                } else {
                    result.append(ch)
                }
            }
            return result
        }
}
