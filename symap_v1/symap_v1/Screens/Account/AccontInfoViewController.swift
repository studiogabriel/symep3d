import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class AccountInfoViewController: UIViewController {
    
    var lblCompanyName: UILabel!
    var lblCnpj: UILabel!
    var lblLicense: UILabel!
    var lblUsageTime: UILabel!
    var lblReportsCount: UILabel!
    var lblPatientsCount: UILabel!
    var statusLabel: UILabel!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // 🔴 BRANDBOOK: Fundo oficial Navy (#0A1A3A)
            view.backgroundColor = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
            let safetyBrandCheck = ["Account Info Brandbook Active"]
            let _ = safetyBrandCheck[ 0 ]
            
            setupUI()
            fetchAccountData()
        }
        
        func setupUI() {
            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
            let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
            
            let btnBack = UIButton(frame: CGRect(x: 20, y: 50, width: 80, height: 40))
            btnBack.setTitle("← Voltar", for: .normal)
            btnBack.setTitleColor(opticalCyan, for: .normal)
            btnBack.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            btnBack.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            view.addSubview(btnBack)
            
            let titleLabel = UILabel(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: 30))
            titleLabel.textAlignment = .center
            titleLabel.text = "INFORMAÇÕES DA CONTA"
            titleLabel.font = UIFont(name: "Inter-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .black)
            titleLabel.textColor = .white
            view.addSubview(titleLabel)
            
            statusLabel = UILabel(frame: CGRect(x: 30, y: 135, width: view.bounds.width - 60, height: 20))
            statusLabel.textAlignment = .center
            statusLabel.textColor = slateColor
            statusLabel.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
            statusLabel.text = "Sincronizando com a nuvem..."
            view.addSubview(statusLabel)
        
        let panel = UIView(frame: CGRect(x: 30, y: 170, width: view.bounds.width - 60, height: 400))
        panel.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        panel.layer.cornerRadius = 20
        panel.layer.borderWidth = 1
        panel.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        view.addSubview(panel)
        
        // Variáveis de layout interno
        var currentY: CGFloat = 30
        let spacing: CGFloat = 55
        
            func createDataRow(title: String, icon: String) -> UILabel {
                        let imgView = UIImageView(frame: CGRect(x: 20, y: currentY, width: 20, height: 20))
                        imgView.image = UIImage(systemName: icon)
                        // 🔴 BRANDBOOK: Ícones com alto contraste no card
                        imgView.tintColor = opticalCyan
                        panel.addSubview(imgView)
                        
                        let titleLbl = UILabel(frame: CGRect(x: 50, y: currentY - 5, width: panel.bounds.width - 70, height: 15))
                        titleLbl.text = title.uppercased()
                        // 🔴 BRANDBOOK: Textos de apoio em Slate e Inter-Bold
                        titleLbl.textColor = slateColor
                        titleLbl.font = UIFont(name: "Inter-Bold", size: 10) ?? UIFont.boldSystemFont(ofSize: 10)
                        panel.addSubview(titleLbl)
                        
                        let valLbl = UILabel(frame: CGRect(x: 50, y: currentY + 12, width: panel.bounds.width - 70, height: 20))
                        valLbl.text = "Carregando..."
                        valLbl.textColor = .white
                        valLbl.font = UIFont(name: "Inter-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .medium)
                        panel.addSubview(valLbl)
                        
                        currentY += spacing
                        return valLbl
                    }
                    
                    lblCompanyName = createDataRow(title: "Nome da Ótica", icon: "building.2.fill")
                    lblCnpj = createDataRow(title: "CNPJ", icon: "doc.text.fill")
                    lblLicense = createDataRow(title: "Licença Válida Até", icon: "checkmark.seal.fill")
                    
                    let div = UIView(frame: CGRect(x: 20, y: currentY - 15, width: panel.bounds.width - 40, height: 1))
                    div.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                    panel.addSubview(div)
                    currentY += 10
                    
                    lblUsageTime = createDataRow(title: "Tempo de Uso no Aplicativo", icon: "clock.fill")
                    lblReportsCount = createDataRow(title: "Quantidade de Laudos Gerados", icon: "chart.bar.doc.horizontal")
                    lblPatientsCount = createDataRow(title: "Quantidade de Pacientes Cadastrados", icon: "person.2.fill")
                    
                    // Botão de Excluir Conta (Mantido em vermelho pela UX da Área de Risco)
                    let btnDelete = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 120, width: view.bounds.width - 60, height: 55))
                    btnDelete.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
                    btnDelete.setTitle("Excluir Conta Permanentemente", for: .normal)
                    btnDelete.setTitleColor(.systemRed, for: .normal)
                    btnDelete.layer.cornerRadius = 16
                    btnDelete.layer.borderWidth = 1
                    btnDelete.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
                    btnDelete.titleLabel?.font = UIFont(name: "Inter-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15)
                    btnDelete.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
                    view.addSubview(btnDelete)
                }
    
    func fetchAccountData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // 1. Busca os dados da Ótica
        db.collection("users").document(uid).getDocument { [weak self] (doc, err) in
            guard let self = self, let data = doc?.data() else { return }
            self.lblCompanyName.text = data["company"] as? String ?? "Não informado"
            self.lblCnpj.text = data["cnpj"] as? String ?? "Não informado"
            
            // Cálculo de Expiração baseado no plano
            if let createdAt = data["createdAt"] as? Timestamp {
                let plan = data["plan"] as? String ?? "mensal"
                var dateComp = DateComponents()
                if plan == "anual" { dateComp.year = 1 }
                else if plan == "semestral" { dateComp.month = 6 }
                else { dateComp.month = 1 }
                
                if let expDate = Calendar.current.date(byAdding: dateComp, to: createdAt.dateValue()) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    self.lblLicense.text = formatter.string(from: expDate)
                }
            } else {
                self.lblLicense.text = "Indisponível"
            }
        }
        
        // 2. Busca a quantidade de Pacientes
        db.collection("patients").whereField("lojistaId", isEqualTo: uid).getDocuments { [weak self] (snap, err) in
            let count = snap?.documents.count ?? 0
            self?.lblPatientsCount.text = "\(count) pacientes"
        }
        
        // 3. Busca os Laudos para contar volume e somar o tempo total de uso
                db.collection("measurements_log").whereField("userId", isEqualTo: uid).getDocuments { [weak self] (snap, err) in
                    guard let self = self, let docs = snap?.documents else { return }
                    
                    self.lblReportsCount.text = "\(docs.count) laudos"
                    
                    var totalSeconds = 0
                    for document in docs {
                        if let timeStr = document.data()["tempoAtendimento"] as? String {
                            let parts = timeStr.components(separatedBy: "m ")
                            if parts.count == 2 {
                                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA:
                                // Extração correta do índice zero com espaços para a matriz de minutos
                                let strMinutos: String = parts[ 0 ]
                                let strSegundos: String = parts[1]
                                
                                let minutes = Int(strMinutos) ?? 0
                                let seconds = Int(strSegundos.replacingOccurrences(of: "s", with: "")) ?? 0
                                totalSeconds += (minutes * 60) + seconds
                            }
                        }
                    }
                    
                    let hours = totalSeconds / 3600
                    let minutes = (totalSeconds % 3600) / 60
                    self.lblUsageTime.text = String(format: "%02d:%02d horas", hours, minutes)
                    self.statusLabel.text = "Dados sincronizados"
                    self.statusLabel.textColor = .systemGreen
                }
    }
    
    @objc func goBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 🔴 A função de Exclusão Blindada com a tipagem corrigida
    @objc func deleteAccountTapped() {
        let alert = UIAlertController(title: "Exclusão Definitiva", message: "Todos os seus pacientes, relatórios PDF e históricos serão apagados para sempre em conformidade com a LGPD. Deseja mesmo continuar?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Apagar Tudo", style: .destructive, handler: { _ in
            self.statusLabel.text = "Apagando dados na nuvem..."
            self.statusLabel.textColor = .red
            
            lazy var functions = Functions.functions()
            functions.httpsCallable("deleteMyData").call() { (result, error) in
                if let error = error {
                    self.statusLabel.text = "Erro: \(error.localizedDescription)"
                    return
                }
                
                if let data = result?.data as? [String: Any], let messages = data["messages"] as? [String], !messages.isEmpty {
                    // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA:
                    // Extração correta garantindo que recebemos uma 'String' única da matriz
                    let mensagemRetorno: String = messages[ 0 ]
                    
                    print("Sucesso LGPD: \(mensagemRetorno)")
                    self.statusLabel.text = mensagemRetorno
                    self.statusLabel.textColor = .systemGreen
                }
                
                // Aguarda um breve momento para o usuário ler o sucesso antes de deslogar
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    try? Auth.auth().signOut()
                    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

