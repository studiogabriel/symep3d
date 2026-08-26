import Foundation
import FirebaseAuth
import FirebaseFirestore

/// MeasurementRepository — persistência da medição no Firestore (Fase 1 da modularização).
struct MeasurementRepository {
    
    func save(_ m: Measurement, storagePath: String?, sessionStartTime: Date?, deviceModel: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        let blank = BiometryEngine.minimumBlankSize(frameWidth: m.manualFrameWidth, bridge: m.noseBridgeWidth,
                                                    frameDiagonal: m.manualFrameDiagonal, frameHeight: m.manualFrameHeight,
                                                    dnpOD: m.dnpDir, dnpEsq: m.dnpEsq)
        let mbs = blank.mbs
        let blocoComercial = blank.commercialBlock
        let tempoAtendimento = sessionStartTime != nil ? Int(Date().timeIntervalSince(sessionStartTime!)) : 0
        let tempoStr = "\(tempoAtendimento / 60)m \(tempoAtendimento % 60)s"
        
        let diffLateral = abs(m.faceWidthLeft - m.faceWidthRight)
        let ladoMaior = m.faceWidthLeft > m.faceWidthRight ? "Esq" : "Dir"
        let assimetriaStr = diffLateral > 1.5 ? "\(ladoMaior) +\(Self.f(diffLateral))mm" : "Simétrico"
        
        let corEscolhida = UserDefaults.standard.string(forKey: "lastColor") ?? "Fábrica"
        let horaAtendimento = Calendar.current.component(.hour, from: Date())
        
        let measurementData: [String: Any] = [
            "userId": user.uid,
            "userEmail": user.email ?? "unknown",
            "timestamp": FieldValue.serverTimestamp(),
            "deviceModel": deviceModel,
            "dnpTotal": m.dnpTotal,
            "dnpLeft": m.dnpEsq,
            "dnpRight": m.dnpDir,
            "dnpPertoTotal": m.dnpPertoTotal,
            "dnpPertoLeft": m.dnpPertoEsq,
            "dnpPertoRight": m.dnpPertoDir,
            "faceWidth": m.faceWidth,
            "faceHeight": m.faceHeight,
            "bridgeWidth": m.noseBridgeWidth,
            "pupilHeight": m.pupillaryHeight,
            "verticalDiff": m.verticalPupilDiff,
            "faceShape": m.faceShape,
            "lensType": m.selectedLensType,
            "observations": m.patientName,
            "patientCPF": m.patientCPF,
            "genderPrediction": m.patientGender,
            "manualHeight": m.manualFrameHeight,
            "manualWidth": m.manualFrameWidth,
            "manualDiagonal": m.manualFrameDiagonal,
            "jawWidth": m.jawWidth,
            "mbs": mbs,
            "blocoIdeal": blocoComercial,
            "tempoAtendimento": tempoStr,
            "corEscolhida": corEscolhida,
            "perfilNasal": m.nasalProfile,
            "assimetriaLateral": assimetriaStr,
            "horaAtendimento": horaAtendimento
        ]
        
        var finalData = measurementData
        if let pathFinal = storagePath {
            finalData["storagePath"] = pathFinal
        }
        finalData["status"] = "active"
        
        let logRef = db.collection("measurements_log")
        logRef.whereField("userId", isEqualTo: user.uid)
            .whereField("patientCPF", isEqualTo: m.patientCPF)
            .whereField("status", in: ["active", ""])
            .getDocuments { (snapshot, error) in
                let batch = db.batch()
                if let docs = snapshot?.documents, !docs.isEmpty {
                    // Preservando a diretriz inegociável de leitura de matrizes
                    let laudoAntigoBase = docs[ 0 ]
                    print("Arquivando versão anterior. ID Base: \(laudoAntigoBase.documentID)")
                    for doc in docs {
                        batch.updateData(["status": "superseded"], forDocument: doc.reference)
                    }
                }
                
                let newDocRef = logRef.document()
                batch.setData(finalData, forDocument: newDocRef)
                
                batch.commit { err in
                    if let err = err {
                        print("Erro crítico no versionamento: \(err.localizedDescription)")
                    } else {
                        print("Nova versão do laudo gravada e ativada com sucesso!")
                    }
                }
            }
        
        let auditData: [String: Any] = [
            "actor": user.uid,
            "action": "GENERATE_REPORT",
            "target": user.uid,
            "payload": ["patientCpf": m.patientCPF, "lensType": m.selectedLensType],
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("audit_log").addDocument(data: auditData) { err in
            if let err = err { print("Falha ao registrar Audit Log: \(err)") }
        }
    }
    
    private static func f(_ value: Float) -> String { return String(format: "%.1f", value) }
}
