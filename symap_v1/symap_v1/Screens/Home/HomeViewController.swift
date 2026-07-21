
import UIKit
import FirebaseAuth
import FirebaseFunctions

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        setupUI()
    }
    
    func setupUI() {
        // Título Principal
        let titleLabel = UILabel(frame: CGRect(x: 30, y: 100, width: view.bounds.width - 60, height: 40))
        titleLabel.textAlignment = .center
        titleLabel.attributedText = NSAttributedString(string: "PAINEL DE TRIAGEM", attributes: [
            .font: UIFont.systemFont(ofSize: 24, weight: .black),
            .foregroundColor: UIColor.white,
            .kern: 2.0
        ])
        view.addSubview(titleLabel)
        
        let subtitleLabel = UILabel(frame: CGRect(x: 30, y: 140, width: view.bounds.width - 60, height: 20))
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "Selecione o fluxo de atendimento"
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
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
        
        // Botão de Logout
        let btnLogout = UIButton(frame: CGRect(x: (view.bounds.width - 140) / 2, y: view.bounds.height - 100, width: 140, height: 40))
        btnLogout.setTitle("Sair do Sistema", for: .normal)
        btnLogout.setTitleColor(.lightGray, for: .normal)
        btnLogout.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnLogout.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(btnLogout)
    }
    
    func createHomeButton(title: String, icon: String, y: CGFloat, isPrimary: Bool) -> UIButton {
        let btn = UIButton(frame: CGRect(x: 30, y: y, width: view.bounds.width - 60, height: 80))
        btn.layer.cornerRadius = 20
        
        if isPrimary {
            btn.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            btn.setTitleColor(.black, for: .normal)
            btn.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
            btn.layer.shadowOpacity = 0.4
            btn.layer.shadowOffset = CGSize(width: 0, height: 6)
            btn.layer.shadowRadius = 12
        } else {
            btn.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: icon, withConfiguration: symbolConfig)
        btn.setImage(image, for: .normal)
        btn.tintColor = isPrimary ? .black : .white
        btn.setTitle("  " + title, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
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
