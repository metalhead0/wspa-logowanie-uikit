import FirebaseAuth

class FirebaseAuthManager {
    static let shared = FirebaseAuthManager()
    private init() {}

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }

    func register(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }

    func logout(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            completion(false)
        }
    }

    var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
}
