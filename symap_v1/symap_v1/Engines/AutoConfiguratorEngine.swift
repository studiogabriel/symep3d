import Foundation

/// Motor Puro de Parametrização Automática Baseado no Visagismo 3D
enum AutoConfiguratorEngine {

    /// Fonte única da linha de tamanho (infantil/feminino/masculino) a partir da largura do rosto.
    /// Antes essa decisão estava duplicada com números soltos em 4 lugares diferentes das telas de Measurement.
    static func sizeLineSuffix(forFaceWidth faceWidth: Float) -> String {
        if faceWidth < VisagismClinicalRules.kidsFaceWidthThreshold { return "infantil" }
        if faceWidth >= VisagismClinicalRules.largeFaceWidthThreshold { return "masculino" }
        return "feminino"
    }

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
            let baseHeight: Float
            let limits: ModelLimits
        }
    
    // BANCO DE DADOS ESCALÁVEL
        static let specs: [String: ModelSpec] = [
            // --- COLEÇÃO FEMININA (Base Média: 130mm) ---
            "luno_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, baseHeight: 51.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 2.0, larguraA: 2.5, verticalR: 1.0, verticalA: 2.0)),
            "nunu_feminino": ModelSpec(baseBridge: 16.0, baseWidth: 128.0, baseHeight: 47.0, limits: ModelLimits(bridgePlus: 5.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_feminino": ModelSpec(baseBridge: 15.0, baseWidth: 130.0, baseHeight: 52.2, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 4.0, larguraA: 2.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_feminino": ModelSpec(baseBridge: 14.5, baseWidth: 135.0, baseHeight: 51.5, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            
            // --- COLEÇÃO MASCULINA (Base Larga: 140mm) ---
            "luno_masculino": ModelSpec(baseBridge: 18.0, baseWidth: 140.0, baseHeight: 53.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "nunu_masculino": ModelSpec(baseBridge: 17.0, baseWidth: 140.0, baseHeight: 48.5, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_masculino": ModelSpec(baseBridge: 16.0, baseWidth: 140.0, baseHeight: 54.5, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_masculino": ModelSpec(baseBridge: 16.2, baseWidth: 140.0, baseHeight: 54.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            
            // --- COLEÇÃO INFANTIL (Base M: 120mm) ---
            // 🔴 larguraA corrigido por medição real de prova impressa (peso 1.0/saturado):
            // baseWidth=120.0 confirmado correto no Blender (peso 0) — o shape key Largura_a
            // é que entregava mais do que os 8.0mm creditados. Medido: Luno 130.1mm, Nunu 130.1mm,
            // Suki 130.6mm, Timbau 130.4mm → larguraA real = medido - 120.0, por modelo.
            "luno_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, baseHeight: 42.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 10.1, verticalR: 2.0, verticalA: 2.0)),
            "nunu_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, baseHeight: 38.0, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 10.1, verticalR: 2.0, verticalA: 2.0)),
            "suki_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, baseHeight: 42.5, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 10.6, verticalR: 2.0, verticalA: 2.0)),
            "timbau_infantil": ModelSpec(baseBridge: 17.0, baseWidth: 120.0, baseHeight: 41.5, limits: ModelLimits(bridgePlus: 4.0, bridgeMinus: 4.0, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 10.4, verticalR: 2.0, verticalA: 2.0))
        ]
    
    /// Resultado completo de uma avaliação de encaixe: os pesos das Shape Keys E se algum
    /// eixo bateu no limite físico do molde (saturou) — informação que calculateMorphWeights
    /// sempre descartou, mas que é exatamente o que diz se um modelo "cabe bem" ou não.
    struct FitResult {
        let weights: [String: Float]
        let bridgeSaturated: Bool
        let widthSaturated: Bool
        let verticalSaturated: Bool
        var isGoodFit: Bool { !bridgeSaturated && !widthSaturated && !verticalSaturated }
    }

    /// Folga temporal por linha — feminino usa uma folga maior (ver VisagismClinicalRules).
    private static func widthClearance(forKey key: String) -> Float {
        return key.hasSuffix("_feminino") ? VisagismClinicalRules.temporalClearanceFeminino : VisagismClinicalRules.temporalClearance
    }

    /// Núcleo único de cálculo — usado tanto por calculateMorphWeights (um modelo específico,
    /// busca fuzzy por keyword) quanto por bestFittingModels (varre o catálogo inteiro).
    private static func computeFit(key: String, spec: ModelSpec, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float) -> FitResult {
        let targetWidth = faceWidth + widthClearance(forKey: key)
        let targetBridge = bridgeWidth + VisagismClinicalRules.bridgeClearance

        var weights: [String: Float] = [:]

        // 🔴 1. CÁLCULO DA PONTE (Vem primeiro porque afasta as lentes e expande a armação)
        let rawDiffBridge = targetBridge - spec.baseBridge
        var appliedBridgeDiff: Float = 0.0
        var bridgeSaturated = false

        if rawDiffBridge > 0 {
            bridgeSaturated = rawDiffBridge > spec.limits.bridgePlus
            let weight = min(1.0, rawDiffBridge / spec.limits.bridgePlus)
            weights["Ponte"] = weight
            appliedBridgeDiff = weight * spec.limits.bridgePlus
        } else {
            bridgeSaturated = abs(rawDiffBridge) > spec.limits.bridgeMinus
            let weight = min(1.0, abs(rawDiffBridge) / spec.limits.bridgeMinus)
            weights["Ponte_m"] = weight
            appliedBridgeDiff = -(weight * spec.limits.bridgeMinus)
        }

        // 🔴 2. CÁLCULO DE LARGURA COMPENSADA (Mágica Paramétrica)
        // Se a ponte expandiu 4.7mm, o óculos já cresceu 4.7mm. Subtraímos isso da meta temporal!
        let diffWidth = (targetWidth - spec.baseWidth) - appliedBridgeDiff
        var widthSaturated = false

        if diffWidth > 0 {
            widthSaturated = diffWidth > spec.limits.larguraA
            weights["Largura_a"] = min(1.0, diffWidth / spec.limits.larguraA)
        } else {
            widthSaturated = abs(diffWidth) > spec.limits.larguraR
            weights["Largura_r"] = min(1.0, abs(diffWidth) / spec.limits.larguraR)
        }

        // 3. 🔴 APOIO NASAL PROPORCIONAL: quanto mais achatado o nariz (abaixo do limiar
        // clínico), mais forte o apoio — capado pelo teto nasalSupportWeight e pelo
        // limite físico do próprio modelo (spec.limits.nasal), que antes nunca era usado.
        let flatness = VisagismClinicalRules.nasalProminenceThreshold - nasalProjection
        if flatness > 0 && spec.limits.nasal > 0 {
            weights["Nasal"] = min(VisagismClinicalRules.nasalSupportWeight, flatness / spec.limits.nasal)
        }

        // 🔴 CÁLCULO VERTICAL ABSOLUTO (Visagismo Suave / Dampening)
        // 1. Proporção Equilibrada (1/4.0 do crânio ARKit)
        let targetHeight = faceHeight / 4.0
        let rawDiffHeight = targetHeight - spec.baseHeight

        // 2. 🔴 A MÁGICA DA SUA IDEIA: Fator de Amortecimento Estético (60%)
        // Transforma uma distorção matemática agressiva de 2.0mm em apenas 1.2mm,
        // preservando o design de fábrica da armação!
        let smoothDiffHeight = rawDiffHeight * VisagismClinicalRules.verticalDampening
        var verticalSaturated = false

        if smoothDiffHeight > 0 {
            verticalSaturated = smoothDiffHeight > spec.limits.verticalA
            weights["Vertical_a"] = min(1.0, smoothDiffHeight / spec.limits.verticalA)
        } else if smoothDiffHeight < 0 {
            verticalSaturated = abs(smoothDiffHeight) > spec.limits.verticalR
            weights["Vertical_r"] = min(1.0, abs(smoothDiffHeight) / spec.limits.verticalR)
        }

        return FitResult(weights: weights, bridgeSaturated: bridgeSaturated, widthSaturated: widthSaturated, verticalSaturated: verticalSaturated)
    }

    /// Calcula os pesos (0.0 a 1.0) para as Shape Keys (Morphers) baseados na biometria do paciente
    static func calculateMorphWeights(keyword: String, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, faceShape: String) -> [String: Float] {
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })

        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return [:] }

        return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection).weights
    }

    /// Mesma busca fuzzy de calculateMorphWeights, mas devolve só se o modelo cabe sem saturar
    /// nenhum eixo — usado para avisar o cliente ANTES de trocar manualmente de armação no try-on.
    /// nil quando a keyword não bate com nenhum modelo do catálogo.
    static func isGoodFit(forKeyword keyword: String, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float) -> Bool? {
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })
        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return nil }
        return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection).isGoodFit
    }

    /// Varre TODO o catálogo (todas as linhas) e retorna as chaves dos modelos que encaixam
    /// sem saturar nenhum eixo físico (ponte/largura/vertical) para a biometria informada —
    /// isto é, óculos que realmente cabem, não só o modelo que combina com o formato do rosto.
    static func bestFittingModels(faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float) -> [String] {
        return specs.keys.filter { key in
            guard let spec = specs[key] else { return false }
            return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection).isGoodFit
        }.sorted()
    }

    /// "luno_infantil" → "Luno (Infantil)" — nome de exibição a partir da chave do banco de specs.
    static func displayName(forKey key: String) -> String {
        let parts = key.split(separator: "_")
        guard let line = parts.last, parts.count >= 2 else { return key.capitalized }
        let model = parts.dropLast().joined(separator: " ").capitalized
        return "\(model) (\(line.capitalized))"
    }
}
