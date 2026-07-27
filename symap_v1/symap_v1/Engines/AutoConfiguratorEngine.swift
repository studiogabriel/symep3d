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
    
    /// BANCO DE DADOS ESCALÁVEL
    static let specs: [String: ModelSpec] = [
        // --- COLEÇÃO FEMININA (Tamanhos Base Originais) ---
        "luno_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 2.0, larguraA: 2.5, verticalR: 1.0, verticalA: 2.0)),
        "nunu_feminino": ModelSpec(baseBridge: 16.0, baseWidth: 128.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
        "suki_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
        "timbau_feminino": ModelSpec(baseBridge: 14.5, baseWidth: 135.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
        
        // --- COLEÇÃO MASCULINA (Tamanhos Base Novos do Blender) ---
        "luno_masculino": ModelSpec(baseBridge: 18.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
        "nunu_masculino": ModelSpec(baseBridge: 17.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
        "suki_masculino": ModelSpec(baseBridge: 16.0, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
        "timbau_masculino": ModelSpec(baseBridge: 16.2, baseWidth: 140.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0))
    ]

    /// Calcula os pesos (0.0 a 1.0) para as Shape Keys (Morphers) baseados na biometria do paciente
    static func calculateMorphWeights(keyword: String, faceWidth: Float, bridgeWidth: Float, nasalProfile: String, faceShape: String) -> [String: Float] {
        
        // 🔴 MÁGICA ARQUITETURAL: Normaliza a palavra-chave (ex: "SL Luno Masculino" vira "sl_luno_masculino")
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })
        
        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return [:] }
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL
        let safetyCheck = ["Visagism Clinical Rules"]
        let _ = safetyCheck[ 0 ]
        
        let targetWidth = faceWidth + VisagismClinicalRules.temporalClearance
        let targetBridge = bridgeWidth + VisagismClinicalRules.bridgeClearance
        
        var weights: [String: Float] = [:]
        
        // 1. Cálculo de Largura
        let diffWidth = targetWidth - spec.baseWidth
        if diffWidth > 0 {
            weights["Largura_a"] = min(1.0, diffWidth / spec.limits.larguraA)
        } else {
            weights["Largura_r"] = min(1.0, abs(diffWidth) / spec.limits.larguraR)
        }
        
        // 2. Cálculo de Ponte
        let diffBridge = targetBridge - spec.baseBridge
        if diffBridge > 0 {
            weights["Ponte"] = min(1.0, diffBridge / spec.limits.bridgePlus)
        } else {
            weights["Ponte_m"] = min(1.0, abs(diffBridge) / spec.limits.bridgeMinus)
        }
        
        // 3. Cálculo de Nasal
        if nasalProfile == "Plano" {
            weights["Nasal"] = VisagismClinicalRules.nasalSupportWeight
        }
        
        // 4. Estética Vertical baseada no Formato do Rosto
        if faceShape.contains("Longo") {
            weights["Vertical_a"] = VisagismClinicalRules.verticalStretchWeight
        } else if faceShape.contains("Redondo") {
            weights["Vertical_r"] = VisagismClinicalRules.verticalSquashWeight
        }
        
        // 5. Ergonomia de Ferradura para narizes estreitos
        if bridgeWidth < VisagismClinicalRules.narrowNoseThreshold {
            weights["Ferradura"] = VisagismClinicalRules.keyholeBridgeWeight
        }
        
        return weights
    }
}
