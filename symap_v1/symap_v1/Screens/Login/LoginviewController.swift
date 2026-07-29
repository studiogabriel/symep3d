import UIKit
import FirebaseAuth
import LocalAuthentication

class LoginViewController: UIViewController {
    // --- ELEMENTOS DE UI ---
    var emailField: UITextField!
    var passwordField: UITextField!
    var loginButton: UIButton!
    var statusLabel: UILabel!
 
    var iconImageView: UIImageView!
    var forgotPasswordButton: UIButton!
    var rememberMeButton: UIButton!
    var isRememberMeChecked: Bool = false
    
    var faceIDButton: UIButton! //BOTAO DE BIOMETRIA
    
    // NOVO: Controle de Fundo Animado 2D
    var animatedGradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // 🔴 BRANDBOOK: Fundo oficial Navy (#0A1A3A)
            view.backgroundColor = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
            let safetyBrandCheck = ["Brandbook UI Active"]
            let _ = safetyBrandCheck[ 0 ]
            
            setupUI()
        }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if UserDefaults.standard.string(forKey: "savedEmail") == nil {
                emailField?.text = ""
            }
            passwordField?.text = ""
            statusLabel?.text = ""
            
            // INTELIGÊNCIA B2B + PRIVACIDADE: Exige sessão ativa E autorização explícita do usuário
            let isFaceIdAuthorized = UserDefaults.standard.bool(forKey: "faceIdEnabled")
            
            if Auth.auth().currentUser != nil && isFaceIdAuthorized {
                faceIDButton?.isHidden = false
            } else {
                faceIDButton?.isHidden = true
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // O gatilho automático do Face ID foi completamente removido daqui.
        }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setupUI() {
            let width = view.bounds.width - 60
            
        // 🔴 BRANDBOOK: Logo Oficial Horizontal Negativo (Sem texto extra)
                let logoWidth: CGFloat = 240
                let logoHeight: CGFloat = 70
                let logoY: CGFloat = 170 //altura do logo tela login
                let logoContainer = UIView(frame: CGRect(x: (view.bounds.width - logoWidth) / 2, y: logoY, width: logoWidth, height: logoHeight))
                logoContainer.backgroundColor = .clear
                
                iconImageView = UIImageView()
                // Puxando a nova logo inserida na pasta Brandbook dos Assets
                if let logoImg = UIImage(named: "Symep_Logo_Horizontal_Negativo")?.withRenderingMode(.alwaysOriginal) {
                    iconImageView.image = logoImg
                }
                iconImageView.backgroundColor = .clear
                iconImageView.frame = logoContainer.bounds
                iconImageView.contentMode = .scaleAspectFit
                iconImageView.clipsToBounds = true
                logoContainer.addSubview(iconImageView)
                view.addSubview(logoContainer)
                
                // Efeito de "Respiração" contínua mantido
                UIView.animate(withDuration: 2.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
                    logoContainer.transform = CGAffineTransform(translationX: 0, y: -8)
                }, completion: nil)
                
                // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
                // TitleLabel escrito foi removido pois a logo oficial já possui a palavra Symep
                let brandRules = ["Text Logo Removed"]
                let _ = brandRules[ 0 ]
            
            emailField = createTextField(y: 280, placeholder: "E-mail Corporativo", icon: "envelope.fill")
            emailField.keyboardType = .emailAddress
            emailField.autocapitalizationType = .none
            view.addSubview(emailField)
            
            passwordField = createTextField(y: 350, placeholder: "Senha de Acesso", icon: "lock.fill")
            passwordField.isSecureTextEntry = true
            view.addSubview(passwordField)
            
            // 🔴 BRANDBOOK: Cor Optical Cyan (#00C3D9) para interações
            let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
            let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0) // Textos auxiliares
            
            rememberMeButton = UIButton(frame: CGRect(x: 30, y: 420, width: 160, height: 20))
            rememberMeButton.setTitle(" Lembrar meu E-mail", for: .normal)
            rememberMeButton.setTitleColor(slateColor, for: .normal)
            rememberMeButton.titleLabel?.font = UIFont(name: "Inter-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13)
            rememberMeButton.contentHorizontalAlignment = .left
            rememberMeButton.tintColor = opticalCyan
            rememberMeButton.setImage(UIImage(systemName: "square"), for: .normal)
            rememberMeButton.addTarget(self, action: #selector(toggleRememberMe), for: .touchUpInside)
            view.addSubview(rememberMeButton)
            
            forgotPasswordButton = UIButton(frame: CGRect(x: view.bounds.width - 180, y: 420, width: 150, height: 20))
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Inter-Bold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: opticalCyan,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            forgotPasswordButton.setAttributedTitle(NSAttributedString(string: "Esqueci a Senha", attributes: linkAttributes), for: .normal)
            forgotPasswordButton.contentHorizontalAlignment = .right
            forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
            view.addSubview(forgotPasswordButton)
            
            if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
                emailField.text = savedEmail
                isRememberMeChecked = true
                rememberMeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
            }
            
            // 🔴 BRANDBOOK: CTA Principal em Cyan Sólido (SEM SOMBRA) e cantos arredondados (Boxes Modulares)
            loginButton = UIButton(frame: CGRect(x: 30, y: 460, width: width, height: 55))
            loginButton.backgroundColor = opticalCyan
            loginButton.setTitle("Acessar Plataforma", for: .normal)
            loginButton.setTitleColor(UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0), for: .normal) // Texto Navy para contraste
            loginButton.layer.cornerRadius = 16
            loginButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17)
            // Regra 8 do Brandbook: Sombras removidas
            loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
            view.addSubview(loginButton)
            
            faceIDButton = UIButton(frame: CGRect(x: 30, y: 530, width: width, height: 50))
            faceIDButton.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            faceIDButton.setTitle(" Entrar com Face ID", for: .normal)
            faceIDButton.setTitleColor(.white, for: .normal)
            faceIDButton.layer.cornerRadius = 16
            faceIDButton.layer.borderWidth = 1
            faceIDButton.layer.borderColor = opticalCyan.withAlphaComponent(0.4).cgColor
            faceIDButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            let faceIdConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            faceIDButton.setImage(UIImage(systemName: "faceid", withConfiguration: faceIdConfig), for: .normal)
            faceIDButton.tintColor = opticalCyan
            faceIDButton.addTarget(self, action: #selector(authenticateWithBiometrics), for: .touchUpInside)
            faceIDButton.isHidden = true
            view.addSubview(faceIDButton)
            
            statusLabel = UILabel(frame: CGRect(x: 30, y: 590, width: width, height: 40))
            statusLabel.textColor = slateColor
            statusLabel.textAlignment = .center
            statusLabel.numberOfLines = 0
            statusLabel.font = UIFont(name: "Inter-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
            statusLabel.text = ""
            view.addSubview(statusLabel)
        }

        func createTextField(y: CGFloat, placeholder: String, icon: String) -> UITextField {
            let width = view.bounds.width - 60
            let tf = UITextField(frame: CGRect(x: 30, y: y, width: width, height: 55))
            
            // Fundo modular com leve contraste
            tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            tf.layer.cornerRadius = 14
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            tf.textColor = .white
            tf.font = UIFont(name: "Inter-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
            
            let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
            tf.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: slateColor]
            )
            
            let iconView = UIImageView(frame: CGRect(x: 15, y: 17, width: 22, height: 20))
            iconView.image = UIImage(systemName: icon)
            iconView.tintColor = slateColor
            iconView.contentMode = .scaleAspectFit
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 55))
            paddingView.addSubview(iconView)
            tf.leftView = paddingView
            tf.leftViewMode = .always
            return tf
        }
    
    // --- LÓGICA DE LOGIN NO FIREBASE (ATUALIZADA COM RECOLHIMENTO DE TECLADO) ---
    @objc func handleLogin() {
        // NOVO: Força o teclado a fechar imediatamente ao clicar no botão
        view.endEditing(true)
        
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            statusLabel.text = "Por favor, preencha todos os campos."
            statusLabel.textColor = .red
            return
        }
        
        // Feedback visual
        statusLabel.text = "Conectando..."
        statusLabel.textColor = .white
        loginButton.isEnabled = false
        loginButton.alpha = 0.7
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            self.loginButton.isEnabled = true
            self.loginButton.alpha = 1.0
            
            if let error = error {
                self.statusLabel.text = "Erro: \(error.localizedDescription)"
                self.statusLabel.textColor = .red
            } else {
                            self.statusLabel.text = "Acesso Autorizado!"
                            self.statusLabel.textColor = .green
                            
                            // Salva ou remove o e-mail lembrado
                            if self.isRememberMeChecked {
                                UserDefaults.standard.set(email, forKey: "savedEmail")
                            } else {
                                UserDefaults.standard.removeObject(forKey: "savedEmail")
                            }
                            
                            //  UX DE PRIVACIDADE: Verifica se o dispositivo tem Face ID e se já perguntamos antes
                            let context = LAContext()
                            let hasPrompted = UserDefaults.standard.object(forKey: "faceIdEnabled") != nil
                            
                            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) && !hasPrompted {
                                // Paralisa a transição e exibe o Popup de Autorização
                                self.promptForFaceIDOptIn()
                            } else {
                                // Aciona a Splash Screen animada se o usuário já tiver respondido em algum momento
                                self.showPostLoginSplash()
                            }
                        }
                    }
                }
    
    // --- MÁGICA VISUAL: SPLASH SCREEN PÓS-LOGIN ---
    func showPostLoginSplash() {
        // 1. Oculta os elementos da tela de login suavemente
        UIView.animate(withDuration: 0.3) {
            self.emailField.alpha = 0
            self.passwordField.alpha = 0
            self.loginButton.alpha = 0
            self.rememberMeButton.alpha = 0
            self.forgotPasswordButton.alpha = 0
            self.statusLabel.alpha = 0
        
            self.iconImageView.alpha = 0
        }
        
        // 2. Cria a View da Splash Screen
        let splashView = UIView(frame: self.view.bounds)
        // 🔴 Fundo Navy Oficial
        splashView.backgroundColor = UIColor(red: 0.039, green: 0.102, blue: 0.227, alpha: 1.0)
        splashView.alpha = 0
        self.view.addSubview(splashView)
        
        // 3. Adiciona a Logo Centralizada (Splash Screen)
                let splashLogo = UIImageView()
                // 🔴 BRANDBOOK: Uso do ícone reduzido branco (mira) para o mergulho na tela
                if let logoImg = UIImage(named: "Symep_Logo_Reducao_White")?.withRenderingMode(.alwaysOriginal) {
                    splashLogo.image = logoImg
                }
                
                splashLogo.backgroundColor = .clear // 🔴 Força a transparência
                splashLogo.frame = CGRect(x: (self.view.bounds.width - 120) / 2, y: (self.view.bounds.height - 120) / 2, width: 120, height: 120)
                splashLogo.contentMode = .scaleAspectFit
                splashLogo.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) // Começa pequena
                splashView.addSubview(splashLogo)
        
        // 4. Adiciona o texto de status
                // 🔴 Aumentamos o espaçamento Y (maxY + 70) para descolar o texto da mira
                let loadingLabel = UILabel(frame: CGRect(x: 30, y: splashLogo.frame.maxY + 60, width: self.view.bounds.width - 60, height: 30))
                loadingLabel.text = "PREPARANDO AMBIENTE CLÍNICO..."
        // 🔴 Optical Cyan Oficial
        loadingLabel.textColor = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
        loadingLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        loadingLabel.textAlignment = .center
        loadingLabel.alpha = 0
        splashView.addSubview(loadingLabel)
        
        // 5. Executa a animação de entrada
        UIView.animate(withDuration: 0.5, animations: {
            splashView.alpha = 1.0
            splashLogo.transform = .identity // Cresce para o tamanho normal
            loadingLabel.alpha = 1.0
        }) { _ in
            // Efeito de "Pulsação" (Respirar) inicial
            UIView.animate(withDuration: 0.8, delay: 0, options: [.autoreverse], animations: {
                splashLogo.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }) { _ in
                // NOVO: Efeito de Zoom-In (Mergulho na Tela)
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseIn, animations: {
                    // Aumenta a logo massivamente para preencher a tela e a faz desaparecer suavemente
                    splashLogo.transform = CGAffineTransform(scaleX: 50.0, y: 50.0)
                    splashLogo.alpha = 0.0
                    loadingLabel.alpha = 0.0
                }) { _ in
                    // 6. Navega para o aplicativo logo após o mergulho
                    self.navigateToMainApp()
                }
            }
        }
    }
        func navigateToMainApp() {
            //  NOVO ROTEAMENTO: Direciona para a nova Home Screen (Dashboard)
            let vc = HomeViewController()
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }
        
        // --- LÓGICA DE RECUPERAÇÃO E LEMBRANÇA ---
        
        @objc func toggleRememberMe() {
            isRememberMeChecked.toggle()
            let iconName = isRememberMeChecked ? "checkmark.square.fill" : "square"
            rememberMeButton.setImage(UIImage(systemName: iconName), for: .normal)
        }
        
        @objc func handleForgotPassword() {
            // Pega o e-mail que o usuário digitou no campo
            guard let email = emailField.text, !email.isEmpty else {
                statusLabel.text = "Digite seu e-mail no campo acima para recuperar."
                statusLabel.textColor = .orange
                return
            }
            
            statusLabel.text = "Enviando e-mail de recuperação..."
            statusLabel.textColor = .white
            
            // Chama a função nativa do Firebase para resetar a senha
            Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
                if let error = error {
                    self?.statusLabel.text = "Erro: \(error.localizedDescription)"
                    self?.statusLabel.textColor = .red
                } else {
                    self?.statusLabel.text = "Link enviado! Verifique sua caixa de entrada."
                    self?.statusLabel.textColor = .green
                }
            }
        }
        
    
    // NOVO: Popup de Autorização de Privacidade (Opt-in)
        func promptForFaceIDOptIn() {
            let alert = UIAlertController(title: "Habilitar Face ID?", message: "Deseja utilizar o reconhecimento facial para acessar a plataforma mais rapidamente nas próximas vezes?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Sim, habilitar", style: .default, handler: { _ in
                // Salva a permissão e continua o fluxo de animação do login
                UserDefaults.standard.set(true, forKey: "faceIdEnabled")
                self.showPostLoginSplash()
            }))
            
            alert.addAction(UIAlertAction(title: "Agora não", style: .cancel, handler: { _ in
                // Registra a negativa para não perguntar de novo e continua o fluxo
                UserDefaults.standard.set(false, forKey: "faceIdEnabled")
                self.showPostLoginSplash()
            }))
            
            self.present(alert, animated: true)
        }
    
        // ---: LOGIN BIOMÉTRICO (FACE ID / TOUCH ID) ---
        
    @objc func authenticateWithBiometrics() {
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Desbloqueie o Symap 3D para acessar o painel da ótica."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            self?.statusLabel.text = "Identidade confirmada pelo Face ID!"
                            self?.statusLabel.textColor = .green
                            self?.showPostLoginSplash()
                        } else {
                            // 🔴 UX PERFEITO: Não deslogamos mais o usuário. Apenas cancelamos e permitimos
                            // que ele insira um novo E-mail/Senha corporativa na tela manualmente.
                            self?.statusLabel.text = "Biometria ignorada. Acesse com outra conta se desejar."
                            self?.statusLabel.textColor = .orange
                        }
                    }
                }
            } else {
                self.showPostLoginSplash()
            }
        }
    }

