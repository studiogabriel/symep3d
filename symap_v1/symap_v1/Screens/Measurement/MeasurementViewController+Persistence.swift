import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import PDFKit
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import simd
import PencilKit
import FirebaseStorage
import AVFoundation

extension MeasurementViewController {
    
    func saveMeasurementToCloud(storagePath: String?) {
        guard isDataCollectionEnabled else { print("Coleta desativada."); return }
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL:
        // A tela NÃO salva no Firebase diretamente. Ela delega para a camada 'Services'.
        MeasurementRepository().save(currentMeasurement(), storagePath: storagePath,
                                     sessionStartTime: sessionStartTime,
                                     deviceModel: UIDevice.current.model)
    }
    
    /// Monta o modelo `Measurement` a partir do estado atual da tela (lido UMA única vez).
    /// Fonte única consumida pela persistência (`MeasurementRepository`) e pelo laudo (`PDFLaudoBuilder`).
    func currentMeasurement() -> Measurement {
        return Measurement(
            dnpTotal: dnpTotal, dnpEsq: dnpEsq, dnpDir: dnpDir,
            dnpPertoTotal: dnpPertoTotal, dnpPertoEsq: dnpPertoEsq, dnpPertoDir: dnpPertoDir,
            faceWidth: faceWidth, faceWidthLeft: faceWidthLeft, faceWidthRight: faceWidthRight,
            faceHeight: faceHeight,
            noseBridgeWidth: noseBridgeWidth, jawWidth: jawWidth, pupillaryHeight: pupillaryHeight,
            verticalPupilDiff: verticalPupilDiff, nasalProfile: nasalProfile, faceShape: faceShape,
            frameSuggestion: frameSuggestion, manualFrameHeight: manualFrameHeight,
            manualFrameWidth: manualFrameWidth, manualFrameDiagonal: manualFrameDiagonal,
            currentGlassesLensWidth: currentGlassesLensWidth ?? 0, currentGlassesBridge: currentGlassesBridge ?? 0,
            currentGlassesHaste: currentGlassesHaste ?? 0,
            selectedLensType: selectedLensType, patientName: patientName, patientCPF: patientCPF,
            patientGender: patientGender,
            rxEsfOD: rxEsfOD, rxCilOD: rxCilOD, rxEixoOD: rxEixoOD,
            rxEsfOE: rxEsfOE, rxCilOE: rxCilOE, rxEixoOE: rxEixoOE,
            rxEsfPertoOD: rxEsfPertoOD, rxCilPertoOD: rxCilPertoOD, rxEixoPertoOD: rxEixoPertoOD,
            rxEsfPertoOE: rxEsfPertoOE, rxCilPertoOE: rxCilPertoOE, rxEixoPertoOE: rxEixoPertoOE,
            headMoveScore: headMoveScore, eyeMoveScore: eyeMoveScore, visionBehaviorResult: visionBehaviorResult,
            isFrozen: isFrozen
        )
    }
    
    func showLocalShareSheet(pdfData: Data) {
        let vc = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        if let p = vc.popoverPresentationController { p.sourceView = captureButton }
        present(vc, animated: true)
    }
    
    func createPDF(image: UIImage) -> Data {
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL:
        // A tela NÃO desenha o PDF. Ela delega para a camada 'Reports'.
        return PDFLaudoBuilder(measurement: currentMeasurement(), image: image).build()
    }
}
