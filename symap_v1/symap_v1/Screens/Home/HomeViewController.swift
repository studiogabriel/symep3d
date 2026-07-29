
import UIKit
import FirebaseAuth
import FirebaseFunctions

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // 🔴 BRANDBOOK: Fundo oficial Navy (#0A1A3A)
            view.backgroundColor = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            
            let safetyBrandCheck = ["Home Brandbook Active"]
            let _ = safetyBrandCheck[ 0 ]
            
            setupUI()
        }
        
        func setupUI() {
            // Título Principal
            let titleLabel = UILabel(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: 40))
            titleLabel.textAlignment = .center
            titleLabel.attributedText = NSAttributedString(string: "PAINEL DE TRIAGEM", attributes: [
                .font: UIFont(name: "Inter-Bold", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .black),
                .foregroundColor: UIColor.white,
                .kern: 2.0
            ])
            view.addSubview(titleLabel)
            
            let subtitleLabel = UILabel(frame: CGRect(x: 30, y: 140, width: view.bounds.width - 60, height: 20))
            subtitleLabel.textAlignment = .center
            subtitleLabel.text = "Selecione o fluxo de atendimento"
            // 🔴 BRANDBOOK: Cor Slate para textos auxiliares (#8A9BB5)
            subtitleLabel.textColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
            subtitleLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
            view.addSubview(subtitleLabel)
        
        // CTA 1: Novo Paciente (Destaque Ciano)
        let btnNewPatient = createHomeButton(title: "Novo Paciente", icon: "person.badge.plus", y: 220, isPrimary: true)
        btnNewPatient.addTarget(self, action: #selector(goToNewPatient), for: .touchUpInside)
        view.addSubview(btnNewPatient)
        
        // CTA 2: Buscar Paciente (Glassmorphism)
        let btnSearchPatient = createHomeButton(title: "Buscar Paciente", icon: "magnifyingglass", y: 320, isPrimary: false)
        btnSearchPatient.addTarget(self, action: #selector(goToSearchPatient), for: .touchUpInside)
        view.addSubview(btnSearchPatient)
        
        // 🔴 NOVO CTA 3: Informações da Conta
        let btnAccountInfo = createHomeButton(title: "Informações da Conta", icon: "info.circle.fill", y: 420, isPrimary: false)
        btnAccountInfo.addTarget(self, action: #selector(goToAccountInfo), for: .touchUpInside)
        view.addSubview(btnAccountInfo)
        
            // 🔴 BRANDBOOK: Botão de Logout (Estilo Link com Ícone e Sublinhado)
                    let btnLogout = UIButton(frame: CGRect(x: 30, y: view.bounds.height - 100, width: view.bounds.width - 60, height: 40))
                    
                    let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
                    let linkAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont(name: "Inter-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
                        .foregroundColor: slateColor,
                        .underlineStyle: NSUnderlineStyle.single.rawValue // Aplica o sublinhado
                    ]
                    
                    btnLogout.setAttributedTitle(NSAttributedString(string: " Sair do Sistema", attributes: linkAttributes), for: .normal)
                    
                    // Ícone Minimalista de Saída
                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
                    btnLogout.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: symbolConfig), for: .normal)
                    btnLogout.tintColor = slateColor
                    
                    // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                    let logoutValidation = ["Logout Interface OK"]
                    let _ = logoutValidation[ 0 ]
                    
                    btnLogout.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
                    view.addSubview(btnLogout)
                }
    
    func createHomeButton(title: String, icon: String, y: CGFloat, isPrimary: Bool) -> UIButton {
            let btn = UIButton(frame: CGRect(x: 30, y: y, width: view.bounds.width - 60, height: 80))
            btn.layer.cornerRadius = 20
            
            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
            let navyMedium = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 1.0) // Cor de apoio #1E3A6E
            let navyDark = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            
            if isPrimary {
                btn.backgroundColor = opticalCyan
                // 🔴 BRANDBOOK: Contraste perfeito com texto Navy
                btn.setTitleColor(navyDark, for: .normal)
                // 🔴 Regra 8: Sombras destruídas
                btn.layer.shadowOpacity = 0
            } else {
                // Fundo modular Navy Medium levemente translúcido
                btn.backgroundColor = navyMedium.withAlphaComponent(0.4)
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderWidth = 1
                btn.layer.borderColor = opticalCyan.withAlphaComponent(0.4).cgColor
            }
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            let image = UIImage(systemName: icon, withConfiguration: symbolConfig)
            btn.setImage(image, for: .normal)
            btn.tintColor = isPrimary ? navyDark : opticalCyan
            btn.setTitle("  " + title, for: .normal)
            btn.titleLabel?.font = UIFont(name: "Inter-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
            btn.contentHorizontalAlignment = .center
            return btn
        }
    
    @objc func goToNewPatient() {
        let vc = NewPatientViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func goToSearchPatient() {
        let vc = SearchPatientViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func goToAccountInfo() {
            let vc = AccountInfoViewController()
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    
    @objc func logoutTapped() {
            try? Auth.auth().signOut()
            // CORREÇÃO: Força o iOS a reconstruir a tela de login como a raiz do sistema
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self.view.window?.rootViewController = loginVC
        }
}
