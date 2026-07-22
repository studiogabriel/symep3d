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
    
    // BANCO DE DADOS ESCALÁVEL (Basta adicionar novos modelos aqui no futuro)
    static let specs: [String: ModelSpec] = [
        "luno": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 2.0, larguraA: 2.5, verticalR: 1.0, verticalA: 2.0)),
        "nunu": ModelSpec(baseBridge: 16.0, baseWidth: 128.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
        "suki": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0))
    ]
    
    /// Calcula os pesos (0.0 a 1.0) para as Shape Keys (Morphers) baseados na biometria do paciente
    static func calculateMorphWeights(keyword: String, faceWidth: Float, bridgeWidth: Float, nasalProfile: String) -> [String: Float] {
        
        // Busca o modelo que contém a palavra-chave
        guard let key = specs.keys.first(where: { keyword.lowercased().contains($0) }),
              let spec = specs[key] else { return [:] }
        
        // 🔴 REGRAS DO VISAGISMO E ERGONOMIA APLICADAS:
        // Margem de Conforto Largura: Rosto + 2.0mm (média ideal entre 0 e 4mm)
        let targetWidth = faceWidth + 2.0
        // Margem de Conforto Ponte Nasal: Nariz + 0.75mm (média ideal entre 0.5 e 1.0mm)
        let targetBridge = bridgeWidth + 0.75
        
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
        
        // 3. Cálculo de Nasal (Se perfil for plano, aumenta o apoio para a lente não encostar no olho)
        if nasalProfile == "Plano" {
            weights["Nasal"] = 0.7
        }
        
        return weights
    }
}
