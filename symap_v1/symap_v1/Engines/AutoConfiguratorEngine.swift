import Foundation

/// Motor Puro de Parametrização Automática Baseado no Visagismo 3D
enum AutoConfiguratorEngine {
    
    // 🔴 ENCAPSULAMENTO DE NAMESPACE:
    // Colocamos os structs DENTRO do enum para não conflitar com o Configurator antigo!
    struct ModelLimits {
        let bridgePlus: Float
        let bridgeMinus: Float
        let nasal: Float
        let ferradura: Float
        let larguraR: Float
        let larguraA: Float
        let verticalR: Float
        let verticalA: Float
    }

    struct ModelSpec {
        let baseBridge: Float
        let baseWidth: Float
        let limits: ModelLimits
    }
    
    // BANCO DE DADOS ESCALÁVEL
        static let specs: [String: ModelSpec] = [
            // --- COLEÇÃO FEMININA (Base Média: 130mm) ---
            "luno_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 2.0, larguraA: 2.5, verticalR: 1.0, verticalA: 2.0)),
            "nunu_feminino": ModelSpec(baseBridge: 16.0, baseWidth: 128.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_feminino": ModelSpec(baseBridge: 14.5, baseWidth: 135.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            
            // --- COLEÇÃO MASCULINA (Base Larga: 140mm) ---
            "luno_masculino": ModelSpec(baseBridge: 18.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "nunu_masculino": ModelSpec(baseBridge: 17.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_masculino": ModelSpec(baseBridge: 16.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_masculino": ModelSpec(baseBridge: 16.2, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            
            // --- COLEÇÃO INFANTIL (Base M: 120mm) ---
            // Tolerâncias elásticas altas (Largura_r = 5.0 | Largura_a = 8.0) para abraçar desde o rostinho P (115mm) até o G (128mm)
            "luno_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 8.0, verticalR: 2.0, verticalA: 2.0)),
            "nunu_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 8.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 8.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 8.0, verticalR: 2.0, verticalA: 2.0))
        ]
    
    /// Calcula os pesos (0.0 a 1.0) para as Shape Keys (Morphers) baseados na biometria do paciente
    static func calculateMorphWeights(keyword: String, faceWidth: Float, bridgeWidth: Float, nasalProfile: String, faceShape: String) -> [String: Float] {
            
            let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
            let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })
            
            guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
                  let spec = specs[key] else { return [:] }
            
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
            let safetyCheck = ["Physical Compensation System"]
            let _ = safetyCheck[ 0 ]
            
            let targetWidth = faceWidth + VisagismClinicalRules.temporalClearance
            let targetBridge = bridgeWidth + VisagismClinicalRules.bridgeClearance
            
            var weights: [String: Float] = [:]
            
            // 🔴 1. CÁLCULO DA PONTE (Vem primeiro porque afasta as lentes e expande a armação)
            let rawDiffBridge = targetBridge - spec.baseBridge
            var appliedBridgeDiff: Float = 0.0
            
            if rawDiffBridge > 0 {
                let weight = min(1.0, rawDiffBridge / spec.limits.bridgePlus)
                weights["Ponte"] = weight
                appliedBridgeDiff = weight * spec.limits.bridgePlus
            } else {
                let weight = min(1.0, abs(rawDiffBridge) / spec.limits.bridgeMinus)
                weights["Ponte_m"] = weight
                appliedBridgeDiff = -(weight * spec.limits.bridgeMinus)
            }
            
            // 🔴 2. CÁLCULO DE LARGURA COMPENSADA (Mágica Paramétrica)
            // Se a ponte expandiu 4.7mm, o óculos já cresceu 4.7mm. Subtraímos isso da meta temporal!
            let diffWidth = (targetWidth - spec.baseWidth) - appliedBridgeDiff
            
            if diffWidth > 0 {
                weights["Largura_a"] = min(1.0, diffWidth / spec.limits.larguraA)
            } else {
                weights["Largura_r"] = min(1.0, abs(diffWidth) / spec.limits.larguraR)
            }
            
            // 3. Nasal e Vertical (Estes não afetam a largura total)
            if nasalProfile == "Plano" {
                weights["Nasal"] = VisagismClinicalRules.nasalSupportWeight
            }
            
            if faceShape.contains("Longo") {
                weights["Vertical_a"] = VisagismClinicalRules.verticalStretchWeight
            } else if faceShape.contains("Redondo") {
                weights["Vertical_r"] = VisagismClinicalRules.verticalSquashWeight
            }
            
            if bridgeWidth < VisagismClinicalRules.narrowNoseThreshold {
                weights["Ferradura"] = VisagismClinicalRules.keyholeBridgeWeight
            }
            
            return weights
        }
}
