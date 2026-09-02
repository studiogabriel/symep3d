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
            noseBridgeWidth: noseBridgeWidth, jawWidth: jawWidth, cheekboneWidth: cheekboneWidth, pupillaryHeight: pupillaryHeight,
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
        let (ideal, mods) = idealGlassesAndModifications()
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL:
        // A tela NÃO desenha o PDF. Ela delega para a camada 'Reports'.
        return PDFLaudoBuilder(measurement: currentMeasurement(), image: image,
                                referencePoints: savedReferencePointsScreen,
                                idealGlasses: ideal, appliedModifications: mods).build()
    }

    /// Medidas finais do óculos "ideal" recriado pro paciente + a lista de modificações aplicadas
    /// na armação (largura/ponte/vertical/apoio nasal) — mesma fonte de verdade já usada nas
    /// barras de capacidade do Resumo Clínico e no popup de diagnóstico (showModificationsPopup em
    /// +Visagism.swift), pra não reimplementar a fórmula em paralelo (já causou divergência de
    /// números nesta sessão antes). Hoje essa lista só aparecia no popup e sumia depois — o
    /// paciente não tinha como conferir de novo, daí entrar no laudo também.
    private func idealGlassesAndModifications() -> (PDFLaudoBuilder.IdealGlasses?, [String]) {
        let key = recommendedAutoModelKey.isEmpty ? recommendedAutoModel : recommendedAutoModelKey
        guard !key.isEmpty, let spec = AutoConfiguratorEngine.specs[key.lowercased()],
              let fit = AutoConfiguratorEngine.fitDetails(
                forKeyword: key, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: noseBridgeWidth,
                nasalProjection: nasalProjection, jawWidth: jawWidth,
                eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid,
                currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge)
        else { return (nil, []) }

        let ideal = PDFLaudoBuilder.IdealGlasses(
            modelName: key.capitalized,
            bridge: spec.baseBridge + fit.appliedBridgeDiff,
            width: spec.baseWidth + fit.appliedWidthDiff,
            vertical: spec.baseHeight + fit.appliedVerticalDiff)

        var mods: [String] = []
        if abs(fit.appliedWidthDiff) > 0.1 {
            let sign = fit.appliedWidthDiff > 0 ? "+" : ""
            mods.append("Largura Temporal: \(sign)\(String(format: "%.1f", fit.appliedWidthDiff)) mm")
        }
        if abs(fit.appliedBridgeDiff) > 0.1 {
            let sign = fit.appliedBridgeDiff > 0 ? "+" : ""
            mods.append("Ponte Nasal: \(sign)\(String(format: "%.1f", fit.appliedBridgeDiff)) mm")
        }
        if nasalProfile == "Plano" {
            mods.append("Apoio Nasal: Expandido (Perfil Plano)")
        }
        if abs(fit.appliedVerticalDiff) > 0.1 {
            let sign = fit.appliedVerticalDiff > 0 ? "+" : ""
            let explanation = fit.appliedVerticalDiff > 0 ? "Alongamento visual" : "Estética compacta"
            mods.append("Design Vertical: \(sign)\(String(format: "%.1f", fit.appliedVerticalDiff)) mm (\(explanation))")
        }
        if mods.isEmpty { mods.append("Proporções originais perfeitas para sua face.") }

        return (ideal, mods)
    }
}
