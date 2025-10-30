import UIKit
import FirebaseAuth

// MARK: - DynamicCell
final class DynamicCell: UITableViewCell {
    private let postImageView = UIImageView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        postImageView.contentMode = .scaleAspectFit
        postImageView.clipsToBounds = true
        postImageView.layer.cornerRadius = 36
        
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        
        
        contentView.addSubview(postImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        

        postImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            postImageView.widthAnchor.constraint(equalToConstant: 72),
            postImageView.heightAnchor.constraint(equalToConstant: 72),
            
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        
        
        contentView.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.setContentHuggingPriority(.required, for: .vertical)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with title: String, description: String, imageName: String?) {
        titleLabel.text = title
        descriptionLabel.text = description
        if let name = imageName, let image = UIImage(named: name) {
            postImageView.image = image
            postImageView.isHidden = false
        } else {
            
            postImageView.image = nil
            postImageView.isHidden = true
        }
    }
}

struct Post {
    let title: String
    let description: String
    let imageName: String
}

class AuthManager {
    static let shared = AuthManager()
    private init() {}
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func register(email: String, password: String, confirmPassword: String, completion: @escaping (Bool, String?) -> Void) {
        guard isValidEmail(email) else {
            completion(false, "Nieprawidłowy format adresu email")
            return
        }
        
        guard !email.isEmpty, password == confirmPassword, password.count >= 6 else {
            completion(false, "Nieprawidłowe dane rejestracji")
            return
        }
        
        print(" Attempting registration: \(email)")
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                print(" Registration Error:")
                print("   Code: \(error.code)")
                print("   Domain: \(error.domain)")
                print("   Description: \(error.localizedDescription)")
                print("   UserInfo: \(error.userInfo)")
                
                let message = self.handleAuthError(error)
                completion(false, message)
            } else {
                print(" Registration Success: \(result?.user.email ?? "")")
                completion(true, nil)
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard isValidEmail(email) else {
            completion(false, "Nieprawidłowy format adresu email")
            return
        }
        
        guard !email.isEmpty, !password.isEmpty else {
            completion(false, "Email i hasło są wymagane")
            return
        }
        
        print(" Attempting login: \(email)")
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                print(" Login Error:")
                print("   Code: \(error.code)")
                print("   Domain: \(error.domain)")
                print("   Description: \(error.localizedDescription)")
                print("   UserInfo: \(error.userInfo)")
                
                let message = self.handleAuthError(error)
                completion(false, message)
            } else {
                print(" Login Success: \(result?.user.email ?? "")")
                completion(true, nil)
            }
        }
    }
    
    func logout(completion: (() -> Void)? = nil) {
        do {
            try Auth.auth().signOut()
            print(" Logout Success")
            completion?()
        } catch let error as NSError {
            print(" Logout Error: \(error.localizedDescription)")
            completion?()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleAuthError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Nieprawidłowy format adresu email"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Ten adres email jest już zarejestrowany"
        case AuthErrorCode.weakPassword.rawValue:
            return "Hasło jest zbyt słabe (minimum 6 znaków)"
        case AuthErrorCode.wrongPassword.rawValue:
            return "Nieprawidłowe hasło"
        case AuthErrorCode.userNotFound.rawValue:
            return "Użytkownik o tym adresie email nie istnieje.\nZarejestruj się najpierw."
        case AuthErrorCode.networkError.rawValue:
            return "Błąd połączenia z internetem.\nSprawdź swoje połączenie."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Zbyt wiele prób logowania.\nSpróbuj ponownie za chwilę."
        case AuthErrorCode.userDisabled.rawValue:
            return "To konto zostało zablokowane"
        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Email/Password authentication nie jest włączone.\nSkontaktuj się z administratorem."
        case AuthErrorCode.invalidCredential.rawValue:
            return "Nieprawidłowe dane logowania"
        default:
            if error.localizedDescription.contains("internal") {
                return "Błąd Firebase.\n\nSprawdź:\n1. Czy Email/Password jest włączone w Firebase Console\n2. Czy GoogleService-Info.plist jest poprawny\n3. Czy masz połączenie z internetem"
            }
            return "Błąd: \(error.localizedDescription)"
        }
    }
}

// MARK: - BaseViewController
class BaseViewController: UIViewController {
    private var gradientLayer: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        
      
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(white: 0.97, alpha: 1.0).cgColor,
            UIColor(white: 0.85, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
        self.gradientLayer = gradient
    }
}

// MARK: - LoginViewController
class LoginViewController: BaseViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Witaj ponownie!"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Hasło"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Zaloguj się", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Nie masz konta? Зarejestruj się", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    }
    
    @objc private func loginTapped() {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespaces),
              let password = passwordTextField.text else { return }
        
        setLoading(true)
        
        AuthManager.shared.login(email: email, password: password) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                if success {
                    self?.navigateToHome()
                } else {
                    self?.showError(message: error ?? "Nieprawidłowy email lub hasło")
                }
            }
        }
    }
    
    @objc private func registerTapped() {
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    private func setLoading(_ loading: Bool) {
        loginButton.isEnabled = !loading
        registerButton.isEnabled = !loading
        emailTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading
        
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func navigateToHome() {
        let homeVC = HomeViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navController
            }, completion: nil)
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Błąd", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginTapped()
        }
        return true
    }
}

// MARK: - RegisterViewController
class RegisterViewController: BaseViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Utwórz konto"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Hasło (min. 6 znaków)"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.returnKeyType = .next
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Potwierdź hasło"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Zarejestruj się", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rejestracja"
        setupUI()
        setupActions()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(registerButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            registerButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 30),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    }
    
    @objc private func registerTapped() {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespaces),
              let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text else { return }
        
        if password != confirmPassword {
            showError(message: "Hasła nie są identyczne")
            return
        }
        
        if password.count < 6 {
            showError(message: "Hasło musi mieć minimum 6 znaków")
            return
        }
        
        setLoading(true)
        
        AuthManager.shared.register(email: email, password: password, confirmPassword: confirmPassword) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                if success {
                    self?.navigateToHome()
                } else {
                    self?.showError(message: error ?? "Błąd rejestracji")
                }
            }
        }
    }
    
    private func setLoading(_ loading: Bool) {
        registerButton.isEnabled = !loading
        emailTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading
        confirmPasswordTextField.isEnabled = !loading
        
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func navigateToHome() {
        let homeVC = HomeViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navController
            }, completion: nil)
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Błąd", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            textField.resignFirstResponder()
            registerTapped()
        }
        return true
    }
}

// MARK: - HomeViewController
class HomeViewController: BaseViewController {
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Witaj!"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Wyloguj się", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var posts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Strona główna"
        setupUI()
        setupTable()
        setupActions()
        updateUserInfo()
        loadSamplePosts()
    }
    
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .singleLine
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DynamicCell.self, forCellReuseIdentifier: "DynamicCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: logoutButton.topAnchor, constant: -16)
        ])
    }
    
    private func loadSamplePosts() {
        
        posts = [
            Post(title: "test", description: "test.", imageName: "Image 2"),
            Post(title: "Poranek", description: "test", imageName: "Image 1"),
            Post(title: "test", description: "test", imageName: "Image")
        ]
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.addSubview(welcomeLabel)
        view.addSubview(userLabel)
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            userLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor),
            userLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            userLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }
    
    private func updateUserInfo() {
        if let user = AuthManager.shared.currentUser {
            userLabel.text = "Zalogowany jako:\n\(user.email ?? "Nieznany")"
            print("✅ Current user: \(user.email ?? "No email")")
        }
    }
    
    @objc private func logoutTapped() {
        AuthManager.shared.logout {
            DispatchQueue.main.async {
                let loginVC = LoginViewController()
                let navController = UINavigationController(rootViewController: loginVC)
                if let window = self.view.window {
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = navController
                    }, completion: nil)
                }
            }
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicCell", for: indexPath) as? DynamicCell else {
            return UITableViewCell()
        }
        let post = posts[indexPath.row]
        cell.configure(with: post.title, description: post.description, imageName: post.imageName)
        cell.selectionStyle = .none
        return cell
    }
}
