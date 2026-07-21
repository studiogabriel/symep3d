import Foundation
import FirebaseFirestore
import FirebaseAuth
import SceneKit

struct CloudGlassModel {
    let id: String
    let name: String
    let fileUrl: String
    let scale: Float
    let position: SCNVector3
    let rotation: SCNVector3
}

class CloudManager {
    static let shared = CloudManager()
    private let db = Firestore.firestore()
    var availableModels: [CloudGlassModel] = []
    
    func fetchMyModels(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else { completion(false); return }
        
        db.collection("models").whereField("ownerId", isEqualTo: user.uid).getDocuments { (snap, err) in
            guard let docs = snap?.documents, err == nil else { completion(false); return }
            
            self.availableModels = docs.map { doc in
                let d = doc.data()
                return CloudGlassModel(
                    id: doc.documentID,
                    name: d["name"] as? String ?? "Sem Nome",
                    fileUrl: d["fileUrl"] as? String ?? "",
                    scale: (d["scale"] as? NSNumber)?.floatValue ?? 0.001,
                    position: SCNVector3(
                        (d["posX"] as? NSNumber)?.floatValue ?? 0,
                        (d["posY"] as? NSNumber)?.floatValue ?? 0.02,
                        (d["posZ"] as? NSNumber)?.floatValue ?? 0.06
                    ),
                    rotation: SCNVector3(
                        (d["rotX"] as? NSNumber)?.floatValue ?? 0,
                        (d["rotY"] as? NSNumber)?.floatValue ?? 0,
                        (d["rotZ"] as? NSNumber)?.floatValue ?? 0
                    )
                )
            }
            completion(true)
        }
    }
    
    func downloadModelFile(url: String, completion: @escaping (URL?) -> Void) {
        guard let u = URL(string: url) else { completion(nil); return }
        let safeName = u.lastPathComponent.replacingOccurrences(of: "/", with: "_")
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
        
        if FileManager.default.fileExists(atPath: dest.path) {
            completion(dest)
            return
        }
        
        URLSession.shared.downloadTask(with: u) { loc, _, _ in
            guard let loc = loc else { completion(nil); return }
            try? FileManager.default.moveItem(at: loc, to: dest)
            completion(dest)
        }.resume()
    }
}

