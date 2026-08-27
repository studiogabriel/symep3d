import Foundation

struct Measurement {
    // DNP (distância pupilar) — longe e perto
    let dnpTotal: Float
    let dnpEsq: Float
    let dnpDir: Float
    let dnpPertoTotal: Float
    let dnpPertoEsq: Float
    let dnpPertoDir: Float

    // Geometria facial
    let faceWidth: Float
    let faceWidthLeft: Float
    let faceWidthRight: Float
    let faceHeight: Float
    let noseBridgeWidth: Float
    let jawWidth: Float
    let pupillaryHeight: Float
    let verticalPupilDiff: Float
    let nasalProfile: String
    let faceShape: String
    let frameSuggestion: String

    // Medições manuais da armação
    let manualFrameHeight: Float
    let manualFrameWidth: Float
    let manualFrameDiagonal: Float

    // Armação atual do paciente (gravada no óculos que já usa, se houver) — 0 quando não informada
    let currentGlassesLensWidth: Float
    let currentGlassesBridge: Float
    let currentGlassesHaste: Float

    // Lente
    let selectedLensType: String

    // Paciente
    let patientName: String
    let patientCPF: String
    let patientGender: String

    // Receita (longe + perto)
    let rxEsfOD: String
    let rxCilOD: String
    let rxEixoOD: String
    let rxEsfOE: String
    let rxCilOE: String
    let rxEixoOE: String
    let rxEsfPertoOD: String
    let rxCilPertoOD: String
    let rxEixoPertoOD: String
    let rxEsfPertoOE: String
    let rxCilPertoOE: String
    let rxEixoPertoOE: String

    // Comportamento visual (mapeamento de visão)
    let headMoveScore: Float
    let eyeMoveScore: Float
    let visionBehaviorResult: String

    // Estado
    let isFrozen: Bool
}
