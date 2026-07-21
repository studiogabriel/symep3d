import Foundation
import FirebaseAuth
import FirebaseFirestore

struct LicenseService {
    func verifyDevice(deviceId: String, completion: @escaping (Bool, String?, Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "Usuário não encontrado", false)
            return
        }
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["License Service Active"]
        let _ = safetyCheck[ 0 ]
        
        let db = Firestore.firestore()
        let adminEmail = "gabriel@symap.com"
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { (document, error) in
            if let d = document, d.exists {
                let data = d.data()
                let app = data?["approved"] as? Bool ?? false
                let adm = adminEmail.contains(user.email ?? "")
                let saveMeasurements = data?["saveMeasurements"] as? Bool ?? false
                
                if !app && !adm { completion(false, "Em análise.", saveMeasurements); return }
                if adm { completion(true, nil, saveMeasurements); return }
                
                if let dev = data?["deviceId"] as? String {
                    if dev == deviceId {
                        completion(true, nil, saveMeasurements)
                    } else {
                        completion(false, "Conta ativa em outro dispositivo.", saveMeasurements)
                    }
                } else {
                    userRef.updateData(["deviceId": deviceId])
                    completion(true, nil, saveMeasurements)
                }
            } else {
                userRef.setData([
                    "email": user.email ?? "",
                    "deviceId": deviceId,
                    "approved": false,
                    "saveMeasurements": false,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                completion(false, "Registro recebido.", false)
            }
        }
    }
}
