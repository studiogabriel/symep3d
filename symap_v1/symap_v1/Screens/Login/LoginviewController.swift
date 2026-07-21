import UIKit
import FirebaseAuth
import LocalAuthentication

class LoginViewController: UIViewController {
    // --- ELEMENTOS DE UI ---
    var emailField: UITextField!
    var passwordField: UITextField!
    var loginButton: UIButton!
    var statusLabel: UILabel!
    var titleLabel: UILabel!
    var iconImageView: UIImageView!
    var forgotPasswordButton: UIButton!
    var rememberMeButton: UIButton!
    var isRememberMeChecked: Bool = false
    
    var faceIDButton: UIButton! //BOTAO DE BIOMETRIA
    
    // NOVO: Controle de Fundo Animado 2D
    var animatedGradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        setup2DAnimatedBackground()
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
        
        // 1. Ícone Oficial do App
                let logoSize: CGFloat = 100
                let logoY: CGFloat = 100
                let logoContainer = UIView(frame: CGRect(x: (view.bounds.width - logoSize) / 2, y: logoY, width: logoSize, height: logoSize))
                logoContainer.backgroundColor = .clear // 🔴 Força o fundo a ser invisível
                
                // 🔴 CORREÇÃO: Removemos a imagem "Branco" para que o erro de digitação não gere um quadrado
                iconImageView = UIImageView()
                if let logoImg = UIImage(named: "LogoTransparente")?.withRenderingMode(.alwaysOriginal) {
                    iconImageView.image = logoImg
                } else {
                    print("AVISO: O Xcode não encontrou o nome 'LogoTransparente' no Assets.")
                }
                
                iconImageView.backgroundColor = .clear // 🔴 Força a transparência da imagem
                iconImageView.frame = logoContainer.bounds
                iconImageView.contentMode = .scaleAspectFit
                iconImageView.clipsToBounds = true
                logoContainer.addSubview(iconImageView)
        view.addSubview(logoContainer)
        
        // Efeito de "Respiração" (Flutuação contínua e suave) na Logo
        UIView.animate(withDuration: 2.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            logoContainer.transform = CGAffineTransform(translationX: 0, y: -8)
        }, completion: nil)
        
        // 2. Título Elegante Ancorado Bem Abaixo da Logo
        // A matemática (logoY + logoSize + 15) garante espaçamento perfeito independentemente da tela!
        titleLabel = UILabel(frame: CGRect(x: 30, y: logoY + logoSize + 15, width: width, height: 40))
        titleLabel.textAlignment = .center
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .black),
            .foregroundColor: UIColor.white,
            .kern: 3.0 // Espaçamento entre as letras
        ]
        titleLabel.attributedText = NSAttributedString(string: "SYMAP 3D", attributes: textAttributes)
        view.addSubview(titleLabel)
        
        // 3. Campos de Texto
        emailField = createTextField(y: 280, placeholder: "E-mail Corporativo", icon: "envelope.fill")
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        view.addSubview(emailField)
        
        passwordField = createTextField(y: 350, placeholder: "Senha de Acesso", icon: "lock.fill")
        passwordField.isSecureTextEntry = true
        view.addSubview(passwordField)
        
        // --- 3.5 OPÇÕES DE ACESSO (LEMBRAR E RECUPERAR) ---
        // Botão Checkbox: Lembrar E-mail
        rememberMeButton = UIButton(frame: CGRect(x: 30, y: 420, width: 160, height: 20))
        rememberMeButton.setTitle(" Lembrar meu E-mail", for: .normal)
        rememberMeButton.setTitleColor(.lightGray, for: .normal)
        rememberMeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        rememberMeButton.contentHorizontalAlignment = .left
        rememberMeButton.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Ciano
        rememberMeButton.setImage(UIImage(systemName: "square"), for: .normal)
        rememberMeButton.addTarget(self, action: #selector(toggleRememberMe), for: .touchUpInside)
        view.addSubview(rememberMeButton)
        
        // Botão: Esqueci minha senha (Agora sublinhado e elegante)
                forgotPasswordButton = UIButton(frame: CGRect(x: view.bounds.width - 180, y: 420, width: 150, height: 20))
                
                let linkAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0),
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
                let attributedTitle = NSAttributedString(string: "Esqueci a Senha", attributes: linkAttributes)
                
                forgotPasswordButton.setAttributedTitle(attributedTitle, for: .normal)
                forgotPasswordButton.contentHorizontalAlignment = .right
                forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
                view.addSubview(forgotPasswordButton)
        
        // Verifica se já existe um e-mail salvo para preencher automaticamente
        if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
            emailField.text = savedEmail
            isRememberMeChecked = true
            rememberMeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        }
        
        // 4. Botão de Login Estilo iOS 15+
                loginButton = UIButton(frame: CGRect(x: 30, y: 460, width: width, height: 55))
                loginButton.backgroundColor = UIColor(red: 0.0, green: 0.45, blue: 1.0, alpha: 1.0) // Azul Apple
                loginButton.setTitle("Acessar Plataforma", for: .normal)
                loginButton.setTitleColor(.white, for: .normal)
                loginButton.layer.cornerRadius = 16
                loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
                loginButton.layer.shadowColor = UIColor(red: 0.0, green: 0.45, blue: 1.0, alpha: 1.0).cgColor
                loginButton.layer.shadowOpacity = 0.4
                loginButton.layer.shadowOffset = CGSize(width: 0, height: 6)
                loginButton.layer.shadowRadius = 10
                loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
                view.addSubview(loginButton)
                
                // 🔴 4.5 NOVO: Botão de Face ID Sob Demanda (Estilo Glassmorphism)
                faceIDButton = UIButton(frame: CGRect(x: 30, y: 530, width: width, height: 50))
                faceIDButton.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                faceIDButton.setTitle(" Entrar com Face ID", for: .normal)
                faceIDButton.setTitleColor(.white, for: .normal)
                faceIDButton.layer.cornerRadius = 16
                faceIDButton.layer.borderWidth = 1
                faceIDButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                faceIDButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                
                let faceIdConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
                faceIDButton.setImage(UIImage(systemName: "faceid", withConfiguration: faceIdConfig), for: .normal)
                faceIDButton.tintColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                faceIDButton.addTarget(self, action: #selector(authenticateWithBiometrics), for: .touchUpInside)
                faceIDButton.isHidden = true // Nasce oculto. Só aparece se houver sessão validada!
                view.addSubview(faceIDButton)

                // 5. Label de Status (🔴 Empurrado de y:540 para y:590)
                statusLabel = UILabel(frame: CGRect(x: 30, y: 590, width: width, height: 40))
                statusLabel.textColor = .lightGray
                statusLabel.textAlignment = .center
                statusLabel.numberOfLines = 0
                statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                statusLabel.text = ""
                view.addSubview(statusLabel)
    }
    
    // Função auxiliar para criar caixas de texto com ícones (Glassmorphism)
    func createTextField(y: CGFloat, placeholder: String, icon: String) -> UITextField {
        let width = view.bounds.width - 60
        let tf = UITextField(frame: CGRect(x: 30, y: y, width: width, height: 55))
        
        // Efeito "Glassmorphism"
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        tf.layer.cornerRadius = 14
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        tf.textColor = .white
        tf.font = UIFont.systemFont(ofSize: 16)
        
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray.withAlphaComponent(0.7)]
        )
        
        // Ícone lateral dentro do campo
        let iconView = UIImageView(frame: CGRect(x: 15, y: 17, width: 22, height: 20))
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = UIColor.lightGray
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
            self.titleLabel.alpha = 0
            self.iconImageView.alpha = 0
        }
        
        // 2. Cria a View da Splash Screen
        let splashView = UIView(frame: self.view.bounds)
        splashView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0) // Void Black
        splashView.alpha = 0
        self.view.addSubview(splashView)
        
        // 3. Adiciona a Logo Centralizada (Splash Screen)
                let splashLogo = UIImageView()
                if let logoImg = UIImage(named: "LogoTransparente")?.withRenderingMode(.alwaysOriginal) {
                    splashLogo.image = logoImg
                }
                
                splashLogo.backgroundColor = .clear // 🔴 Força a transparência
                splashLogo.frame = CGRect(x: (self.view.bounds.width - 120) / 2, y: (self.view.bounds.height - 120) / 2, width: 120, height: 120)
                splashLogo.contentMode = .scaleAspectFit
                splashLogo.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) // Começa pequena
                splashView.addSubview(splashLogo)
        
        // 4. Adiciona o texto de status
        let loadingLabel = UILabel(frame: CGRect(x: 30, y: splashLogo.frame.maxY + 30, width: self.view.bounds.width - 60, height: 30))
        loadingLabel.text = "PREPARANDO AMBIENTE CLÍNICO..."
        loadingLabel.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
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
        // --- MÁGICA VISUAL: FUNDO 2D ANIMADO (SUBSTITUTO DO ARKIT) ---
        func setup2DAnimatedBackground() {
            animatedGradientLayer = CAGradientLayer()
            animatedGradientLayer.frame = view.bounds
            animatedGradientLayer.colors = [
                UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.0, green: 0.2, blue: 0.3, alpha: 1.0).cgColor,
                UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0).cgColor
            ]
            animatedGradientLayer.startPoint = CGPoint(x: 0, y: 0)
            animatedGradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            view.layer.insertSublayer(animatedGradientLayer, at: 0)
            
            // Animação suave e cíclica do gradiente (Loop infinito)
            let animation = CABasicAnimation(keyPath: "colors")
            animation.toValue = [
                UIColor(red: 0.0, green: 0.2, blue: 0.3, alpha: 1.0).cgColor,
                UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.0, green: 0.1, blue: 0.2, alpha: 1.0).cgColor
            ]
            animation.duration = 8.0
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animatedGradientLayer.add(animation, forKey: "gradientAnimation")
            
            // Efeito Glassmorphism base
            let blurEffect = UIBlurEffect(style: .dark)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.bounds
            blurView.alpha = 0.6
            view.insertSubview(blurView, aboveSubview: UIView())
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

