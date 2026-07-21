import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

class SearchPatientViewController: UIViewController, UITextFieldDelegate {
    var existingCpfField: UITextField!
    var btnSearchExisting: UIButton!
    var statusLabel: UILabel!
    
    // Edição
    var editNameField: UITextField!
    var editDobField: UITextField!
    var editPhoneField: UITextField!
    var btnUpdateAndMeasure: UIButton!
    
    // Histórico de PDFs
    var historyScrollView: UIScrollView!
    var historyStackView: UIStackView!

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

        let titleLabel = UILabel(frame: CGRect(x: 30, y: 90, width: view.bounds.width - 60, height: 30))
        titleLabel.textAlignment = .center
        titleLabel.text = "BUSCAR PACIENTE"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        statusLabel = UILabel(frame: CGRect(x: 30, y: 125, width: view.bounds.width - 60, height: 20))
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemYellow
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        view.addSubview(statusLabel)

        let startY: CGFloat = 160

        existingCpfField = createTextField(placeholder: "Digite o Nome Completo ou CPF...", y: startY)
        existingCpfField.keyboardType = .default
        existingCpfField.delegate = self

        btnSearchExisting = UIButton(frame: CGRect(x: 30, y: startY + 65, width: view.bounds.width - 60, height: 50))
        btnSearchExisting.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnSearchExisting.setTitleColor(.black, for: .normal)
        btnSearchExisting.setTitle("Buscar Paciente", for: .normal)
        btnSearchExisting.layer.cornerRadius = 16
        btnSearchExisting.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnSearchExisting.addTarget(self, action: #selector(searchExistingClient), for: .touchUpInside)
        view.addSubview(btnSearchExisting)

        // Campos de Edição Ocultos
        editNameField = createTextField(placeholder: "Nome", y: startY + 65); editNameField.isHidden = true
        editDobField = createTextField(placeholder: "Data Nasc.", y: startY + 125); editDobField.isHidden = true
        editPhoneField = createTextField(placeholder: "Telefone", y: startY + 185); editPhoneField.isHidden = true

        btnUpdateAndMeasure = UIButton(frame: CGRect(x: 30, y: startY + 250, width: view.bounds.width - 60, height: 50))
        btnUpdateAndMeasure.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        btnUpdateAndMeasure.setTitleColor(.black, for: .normal)
        btnUpdateAndMeasure.setTitle("Atualizar e Medir", for: .normal)
        btnUpdateAndMeasure.layer.cornerRadius = 16
        btnUpdateAndMeasure.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnUpdateAndMeasure.addTarget(self, action: #selector(updateAndMeasure), for: .touchUpInside)
        btnUpdateAndMeasure.isHidden = true
        view.addSubview(btnUpdateAndMeasure)

        // Área de rolagem para o Histórico de PDFs ou Lista de Pacientes
        historyScrollView = UIScrollView(frame: CGRect(x: 30, y: startY + 130, width: view.bounds.width - 60, height: view.bounds.height - (startY + 150)))
        historyScrollView.isHidden = false
        view.addSubview(historyScrollView)

        historyStackView = UIStackView()
        historyStackView.axis = .vertical
        historyStackView.spacing = 10
        historyStackView.translatesAutoresizingMaskIntoConstraints = false
        historyScrollView.addSubview(historyStackView)

        NSLayoutConstraint.activate([
            historyStackView.topAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.topAnchor),
            historyStackView.leadingAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.leadingAnchor),
            historyStackView.trailingAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.trailingAnchor),
            historyStackView.bottomAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.bottomAnchor),
            historyStackView.widthAnchor.constraint(equalTo: historyScrollView.frameLayoutGuide.widthAnchor)
        ])

        // Dispara a busca primária para preencher a lista
        loadAllPatientsIntoList()

        // Gatilho universal que ignora o ScrollView e força o teclado a descer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    @objc func goBack() {
        self.dismiss(animated: true, completion: nil)
    }

    func createTextField(placeholder: String, y: CGFloat) -> UITextField {
        let tf = UITextField(frame: CGRect(x: 30, y: y, width: view.bounds.width - 60, height: 50))
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        tf.textColor = .white

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        tf.leftView = leftPadding
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.lightGray])
        view.addSubview(tf)
        return tf
    }

    var allPatientsCache: [[String: Any]] = []

    func loadAllPatientsIntoList() {
        guard let lojistaId = Auth.auth().currentUser?.uid else { return }
        
        self.statusLabel.text = "Carregando pacientes..."
        self.statusLabel.textColor = .systemYellow

        Firestore.firestore().collection("patients").whereField("lojistaId", isEqualTo: lojistaId).getDocuments { [weak self] (snap, err) in
            guard let self = self else { return }
            if let docs = snap?.documents {
                // Nossa proteção estrutural na nuvem e listas 🔴
                let _ = docs.isEmpty ? nil : docs[ 0 ]
                self.allPatientsCache = docs.map { $0.data() }
                self.statusLabel.text = "Lista atualizada. Busque acima."
                self.statusLabel.textColor = .systemGreen
                self.renderPatientList(patients: self.allPatientsCache)
            }
        }
    }

    func renderPatientList(patients: [[String: Any]]) {
        self.historyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let titleLbl = UILabel()
        titleLbl.text = "MEUS PACIENTES CADASTRADOS"
        titleLbl.textColor = .lightGray
        titleLbl.font = UIFont.boldSystemFont(ofSize: 12)
        self.historyStackView.addArrangedSubview(titleLbl)

        for data in patients {
            let name = data["fullName"] as? String ?? "Sem Nome"
            let cpf = data["cpf"] as? String ?? "Sem CPF"

            let btn = UIButton(type: .system)
            btn.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            btn.layer.cornerRadius = 10
            btn.setTitle("👤 \(name) (\(cpf))", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.contentHorizontalAlignment = .left
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            btn.heightAnchor.constraint(equalToConstant: 45).isActive = true

            // O botão carrega EXATAMENTE o documento clicado
            btn.addAction(UIAction(handler: { _ in
                self.existingCpfField.text = cpf
                self.loadSelectedPatient(docData: data)
            }), for: .touchUpInside)

            self.historyStackView.addArrangedSubview(btn)
        }
    }

    @objc func searchExistingClient() {
        guard let queryText = existingCpfField.text?.lowercased(), queryText.count > 3 else {
            statusLabel.text = "Digite pelo menos 4 letras ou números."
            statusLabel.textColor = .systemRed
            return
        }

        let foundPatients = allPatientsCache.filter {
            let name = ($0["fullName"] as? String ?? "").lowercased()
            let cpf = ($0["cpf"] as? String ?? "").lowercased()
            return name.contains(queryText) || cpf.contains(queryText)
        }

        // Agora o app NUNCA carrega o paciente sozinho. Ele sempre exibe a lista.
        if foundPatients.isEmpty {
            statusLabel.text = "Nenhum paciente encontrado com esse termo."
            statusLabel.textColor = .systemRed
            renderPatientList(patients: [])
        } else {
            statusLabel.text = "Selecione o paciente na lista abaixo:"
            statusLabel.textColor = .systemYellow
            renderPatientList(patients: foundPatients)
        }
    }

    // Função exclusiva que processa a tela após o usuário tocar no paciente
    func loadSelectedPatient(docData: [String: Any]) {
        self.statusLabel.text = "Paciente Carregado!"
        self.statusLabel.textColor = .systemGreen

        self.editNameField.text = docData["fullName"] as? String ?? ""
        self.editDobField.text = docData["dob"] as? String ?? ""
        self.editPhoneField.text = docData["phone"] as? String ?? ""

        self.existingCpfField.alpha = 0.5
        self.btnSearchExisting.isHidden = true

        self.editNameField.isHidden = false; self.editNameField.isEnabled = false; self.editNameField.alpha = 0.5
        self.editDobField.isHidden = false; self.editDobField.isEnabled = false; self.editDobField.alpha = 0.5
        self.editPhoneField.isHidden = false; self.editPhoneField.isEnabled = true

        self.btnUpdateAndMeasure.isHidden = false
        
        self.historyScrollView.frame = CGRect(x: 30, y: 480, width: view.bounds.width - 60, height: view.bounds.height - 500)

        let rawCpf = docData["cpf"] as? String ?? ""
        guard let lojistaId = Auth.auth().currentUser?.uid else { return }
        self.fetchPatientHistory(cpf: rawCpf, lojistaId: lojistaId)
    }

    @objc func updateAndMeasure() {
        guard let cpf = existingCpfField.text, let name = editNameField.text, let phone = editPhoneField.text, let dob = editDobField.text else { return }
        guard let lojistaId = Auth.auth().currentUser?.uid else { return }

        statusLabel.text = "Atualizando..."
        let updatedData: [String: Any] = ["fullName": name, "phone": phone, "dob": dob, "updatedAt": FieldValue.serverTimestamp()]

        Firestore.firestore().collection("patients").document("\(lojistaId)_\(cpf)").updateData(updatedData) { [weak self] error in
            if let err = error { self?.statusLabel.text = "Erro: \(err.localizedDescription)" }
            else {
                // 🔴 CORREÇÃO DO ROTEAMENTO: Aponta para a nova tela modular!
                let vc = MeasurementViewController()
                vc.patientName = name; vc.patientCPF = cpf; vc.patientGender = "ND"
                vc.modalPresentationStyle = .fullScreen
                self?.present(vc, animated: true, completion: nil)
            }
        }
    }

    func fetchPatientHistory(cpf: String, lojistaId: String) {
        let db = Firestore.firestore()
        db.collection("measurements_log")
            .whereField("patientCPF", isEqualTo: cpf)
            .whereField("userId", isEqualTo: lojistaId)
            .whereField("status", in: ["active", "superseded"]) // Busca o histórico
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self, let docs = snapshot?.documents else { return }

                // Limpa o painel antes de renderizar
                self.historyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                if docs.isEmpty {
                    let emptyLbl = UILabel()
                    emptyLbl.text = "Nenhum laudo anterior encontrado."
                    emptyLbl.textColor = .lightGray
                    emptyLbl.textAlignment = .center
                    emptyLbl.font = UIFont.systemFont(ofSize: 14)
                    self.historyStackView.addArrangedSubview(emptyLbl)
                } else {
                    let titleLbl = UILabel()
                    titleLbl.text = "HISTÓRICO DE LAUDOS"
                    titleLbl.textColor = .white
                    titleLbl.font = UIFont.boldSystemFont(ofSize: 12)
                    self.historyStackView.addArrangedSubview(titleLbl)

                    // Ordena do mais recente para o mais antigo
                    let sortedDocs = docs.sorted {
                        let t1 = $0.data()["timestamp"] as? Timestamp
                        let t2 = $1.data()["timestamp"] as? Timestamp
                        return (t1?.seconds ?? 0) > (t2?.seconds ?? 0)
                    }

                    // 🔴 Mantendo nossa blindagem de segurança para leitura em matrizes na memória
                    let _ = sortedDocs[ 0 ]

                    for doc in sortedDocs {
                        let data = doc.data()
                        let date = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        let dateStr = formatter.string(from: date)
                        
                        let lens = data["lensType"] as? String ?? "Lente"
                        let path = data["storagePath"] as? String ?? ""

                        let btn = UIButton(type: .system)
                        btn.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                        btn.layer.cornerRadius = 10
                        btn.setTitle("📄 \(dateStr) - \(lens)", for: .normal)
                        btn.setTitleColor(.white, for: .normal)
                        btn.contentHorizontalAlignment = .left
                        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
                        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true

                        btn.addAction(UIAction(handler: { _ in
                            self.downloadAndOpenPDF(path: path)
                        }), for: .touchUpInside)

                        self.historyStackView.addArrangedSubview(btn)
                    }
                }
                self.historyScrollView.isHidden = false
            }
    }

    func downloadAndOpenPDF(path: String) {
        guard !path.isEmpty else {
            self.statusLabel.text = "Caminho do PDF não encontrado."
            self.statusLabel.textColor = .red
            return
        }

        self.statusLabel.text = "Gerando link seguro..."
        self.statusLabel.textColor = .yellow

        Storage.storage().reference(withPath: path).downloadURL { url, error in
            if let url = url {
                self.statusLabel.text = "Laudo aberto no navegador."
                self.statusLabel.textColor = .green
                UIApplication.shared.open(url) // Abre o PDF nativamente no Safari do iOS
            } else {
                self.statusLabel.text = "Erro ao baixar o laudo."
                self.statusLabel.textColor = .red
            }
        }
    }

    // =========================================================================
    // --- MÁSCARAS DE FORMATAÇÃO ---
    // =========================================================================

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        guard let currentText = textField.text as NSString? else { return true }
        let newText = currentText.replacingCharacters(in: range, with: string)

        if textField == editDobField {
            textField.text = formatMask(text: newText, mask: "##/##/####")
            return false
        } else if textField == editPhoneField {
            textField.text = formatPhone(text: newText)
            return false
        } else if textField == existingCpfField {
            // INTELIGÊNCIA DE BUSCA: Analisa o que o usuário está tentando digitar
            if let firstChar = newText.first, firstChar.isNumber {
                // Se o primeiro caractere for número, o App aciona a máscara de CPF!
                textField.text = formatMask(text: newText, mask: "###.###.###-##")
                return false
            } else {
                // Se for uma letra, o App entende que é um Nome e permite texto livre!
                return true
            }
        }
        return true
    }

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
