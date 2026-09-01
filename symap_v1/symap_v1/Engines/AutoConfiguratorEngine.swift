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
        /// mm de largura que a PONTE move como efeito colateral, por unidade de peso, em
        /// QUALQUER direção (medido direto na planilha — Ponte_a/Ponte_d sempre mudam Largura
        /// em ±4.00mm nos 12 modelos, independente da capacidade própria de Largura_a/Largura_d).
        /// Antes essa acoplagem era aproximada reaproveitando larguraA (weight*larguraA), o que
        /// ficou errado quando larguraA passou a ser maior que a acoplagem real medida.
        let bridgeWidthCoupling: Float
        let larguraA: Float
        let larguraD: Float
        let verticalA: Float
        let verticalD: Float
    }

    struct ModelSpec {
            let baseBridge: Float
            let baseWidth: Float
            let baseHeight: Float
            let limits: ModelLimits
        }

    // BANCO DE DADOS ESCALÁVEL
    // 🔴 REMODELAGEM COMPLETA (2026-09-01): Gabriel regerou os 12 arquivos 3D do zero e
    // levantou uma planilha nova, com metodologia padronizada — medição em repouso (peso 0.0) E
    // com CADA shape key isolada em peso 1.0 (as outras em 0), pra cada um dos 12 modelos.
    // Confirmado por bounding box real extraída de dentro dos .usdc (usdcat) contra a planilha:
    // as 12 larguras batem exatamente. Essa remodelagem também:
    // - Renomeou as shape keys: Ponte→Ponte_a, Ponte_m→Ponte_d, Largura_r→Largura_d,
    //   Vertical_r→Vertical_d, Nasal→Nasal_a (motivo: deixar claro o que aumenta/diminui).
    // - REMOVEU a shape key Ferradura de todos os modelos (não tinha uso real).
    // - Nasal_a não mudou de capacidade (ainda 2.0mm em todos, confirmado pelo Gabriel).
    // - bridgeWidthCoupling agora é medido direto (±4.00mm uniforme nos 12), não mais aproximado
    //   via larguraA — ver comentário em ModelLimits.
    static let specs: [String: ModelSpec] = [
        // --- COLEÇÃO FEMININA ---
        "luno_feminino": ModelSpec(baseBridge: 21.42, baseWidth: 136.26, baseHeight: 51.14, limits: ModelLimits(bridgePlus: 3.95, bridgeMinus: 4.05, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 1.99, verticalD: 3.01)),
        "nunu_feminino": ModelSpec(baseBridge: 23.05, baseWidth: 136.35, baseHeight: 47.09, limits: ModelLimits(bridgePlus: 4.16, bridgeMinus: 3.84, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 1.99, verticalD: 3.01)),
        "suki_feminino": ModelSpec(baseBridge: 22.30, baseWidth: 136.26, baseHeight: 52.34, limits: ModelLimits(bridgePlus: 3.87, bridgeMinus: 4.13, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 2.00)),
        "timbau_feminino": ModelSpec(baseBridge: 20.96, baseWidth: 136.27, baseHeight: 51.85, limits: ModelLimits(bridgePlus: 4.00, bridgeMinus: 4.00, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 2.00)),

        // --- COLEÇÃO MASCULINA ---
        "luno_masculino": ModelSpec(baseBridge: 23.60, baseWidth: 142.00, baseHeight: 53.31, limits: ModelLimits(bridgePlus: 4.20, bridgeMinus: 3.80, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 1.99, verticalD: 3.01)),
        "nunu_masculino": ModelSpec(baseBridge: 21.99, baseWidth: 142.00, baseHeight: 48.94, limits: ModelLimits(bridgePlus: 4.17, bridgeMinus: 3.83, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 1.99, verticalD: 3.01)),
        "suki_masculino": ModelSpec(baseBridge: 22.90, baseWidth: 142.00, baseHeight: 54.73, limits: ModelLimits(bridgePlus: 4.10, bridgeMinus: 3.90, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 2.00)),
        "timbau_masculino": ModelSpec(baseBridge: 21.69, baseWidth: 141.93, baseHeight: 53.99, limits: ModelLimits(bridgePlus: 4.11, bridgeMinus: 3.89, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 2.00)),

        // --- COLEÇÃO INFANTIL ---
        "luno_infantil": ModelSpec(baseBridge: 20.49, baseWidth: 125.22, baseHeight: 44.01, limits: ModelLimits(bridgePlus: 3.61, bridgeMinus: 4.39, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 3.01)),
        "nunu_infantil": ModelSpec(baseBridge: 22.15, baseWidth: 125.22, baseHeight: 39.97, limits: ModelLimits(bridgePlus: 4.05, bridgeMinus: 3.95, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 3.00)),
        "suki_infantil": ModelSpec(baseBridge: 19.87, baseWidth: 125.22, baseHeight: 44.70, limits: ModelLimits(bridgePlus: 3.93, bridgeMinus: 4.07, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 1.99, verticalD: 2.01)),
        "timbau_infantil": ModelSpec(baseBridge: 21.22, baseWidth: 125.22, baseHeight: 43.74, limits: ModelLimits(bridgePlus: 4.18, bridgeMinus: 3.82, nasal: 2.0, bridgeWidthCoupling: 4.0, larguraA: 8.0, larguraD: 4.0, verticalA: 2.00, verticalD: 2.00))
    ]
    
    /// Resultado completo de uma avaliação de encaixe: os pesos das Shape Keys E se algum
    /// eixo bateu no limite físico do molde (saturou) — informação que calculateMorphWeights
    /// sempre descartou, mas que é exatamente o que diz se um modelo "cabe bem" ou não.
    struct FitResult {
        let weights: [String: Float]
        let bridgeSaturated: Bool
        let widthSaturated: Bool
        let verticalSaturated: Bool
        /// Deltas em mm REALMENTE aplicados (já com clipping físico do molde) — fonte única
        /// para qualquer texto de UI que mostre "Ponte Nasal: -2.9mm" etc. Antes as telas de
        /// resumo/try-on reimplementavam essa conta em paralelo (comentário "LÓGICA ESPELHADA
        /// DO MOTOR"), e a cópia ficou desatualizada (regra de ponte antiga, amortecimento
        /// vertical de 0.05 em vez de 0.6) — ver VisagismClinicalRules.verticalDampening.
        let appliedBridgeDiff: Float
        let appliedWidthDiff: Float
        let appliedVerticalDiff: Float
        /// Quanto o rosto PRECISARIA além do que o molde físico permite, em mm — 0 quando o
        /// eixo não saturou. Ex.: precisa de 4.26mm de largura, molde só dá 4.0mm → overage 0.26mm.
        /// Só para diagnóstico interno (dev), não é o valor mostrado como ajuste ao cliente.
        let bridgeOverage: Float
        let widthOverage: Float
        let verticalOverage: Float
        var isGoodFit: Bool { !bridgeSaturated && !widthSaturated && !verticalSaturated }
    }

    /// Folga temporal por linha — feminino usa uma folga maior (ver VisagismClinicalRules).
    private static func widthClearance(forKey key: String) -> Float {
        return key.hasSuffix("_feminino") ? VisagismClinicalRules.temporalClearanceFeminino : VisagismClinicalRules.temporalClearance
    }

    /// Meta de ponte por linha — regra fixa de engenharia (ponte do paciente + folga), com
    /// folga própria por linha. Ver VisagismClinicalRules.bridgeOffsetMasculino/Feminino/Infantil.
    private static func bridgeOffset(forKey key: String) -> Float {
        if key.hasSuffix("_masculino") { return VisagismClinicalRules.bridgeOffsetMasculino }
        if key.hasSuffix("_feminino") { return VisagismClinicalRules.bridgeOffsetFeminino }
        return VisagismClinicalRules.bridgeOffsetInfantil
    }

    /// Núcleo único de cálculo — usado tanto por calculateMorphWeights (um modelo específico,
    /// busca fuzzy por keyword) quanto por bestFittingModels (varre o catálogo inteiro).
    private static func computeFit(key: String, spec: ModelSpec, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> FitResult {
        // 🔴 PISO DE SEGURANÇA (armação atual do paciente): quando o paciente informa aro+ponte
        // da armação que já usa e tolera, nunca miramos abaixo disso — só o cálculo biométrico
        // pode pedir MAIS largura, nunca menos do que o que a pessoa já usa fisicamente. Ver
        // VisagismClinicalRules.currentGlassesRimAllowance.
        var targetWidth = faceWidth + widthClearance(forKey: key)
        if let lensWidth = currentGlassesLensWidth, let currentBridge = currentGlassesBridge {
            let currentGlassesTotalWidth = (2 * lensWidth) + currentBridge + VisagismClinicalRules.currentGlassesRimAllowance
            targetWidth = max(targetWidth, currentGlassesTotalWidth)
        }
        let targetBridge = bridgeWidth + bridgeOffset(forKey: key)

        var weights: [String: Float] = [:]

        // 🔴 1. CÁLCULO DA PONTE (Vem primeiro porque afasta as lentes e expande a armação)
        let rawDiffBridge = targetBridge - spec.baseBridge
        var appliedBridgeDiff: Float = 0.0
        var bridgeWidthCoupling: Float = 0.0
        var bridgeSaturated = false
        var bridgeOverage: Float = 0.0

        if rawDiffBridge > 0 {
            bridgeSaturated = rawDiffBridge > spec.limits.bridgePlus
            bridgeOverage = bridgeSaturated ? rawDiffBridge - spec.limits.bridgePlus : 0
            let weight = min(1.0, rawDiffBridge / spec.limits.bridgePlus)
            weights["Ponte_a"] = weight
            appliedBridgeDiff = weight * spec.limits.bridgePlus
            bridgeWidthCoupling = weight * spec.limits.bridgeWidthCoupling
        } else {
            bridgeSaturated = abs(rawDiffBridge) > spec.limits.bridgeMinus
            bridgeOverage = bridgeSaturated ? abs(rawDiffBridge) - spec.limits.bridgeMinus : 0
            let weight = min(1.0, abs(rawDiffBridge) / spec.limits.bridgeMinus)
            weights["Ponte_d"] = weight
            appliedBridgeDiff = -(weight * spec.limits.bridgeMinus)
            bridgeWidthCoupling = -(weight * spec.limits.bridgeWidthCoupling)
        }

        // 🔴 2. CÁLCULO DE LARGURA COMPENSADA (Mágica Paramétrica)
        // A ponte move a largura como efeito colateral — mas essa acoplagem (bridgeWidthCoupling,
        // medida direto na planilha em ±4.00mm) é um número PRÓPRIO, independente da capacidade
        // de Largura_a/Largura_d (8.0/4.0) — não dá pra aproximar um pelo outro, ficou provado
        // quando a planilha nova trouxe capacidades diferentes pros dois.
        let diffWidth = (targetWidth - spec.baseWidth) - bridgeWidthCoupling
        var widthSaturated = false
        var appliedWidthDiff: Float = 0.0
        var widthOverage: Float = 0.0

        if diffWidth > 0 {
            widthSaturated = diffWidth > spec.limits.larguraA
            widthOverage = widthSaturated ? diffWidth - spec.limits.larguraA : 0
            let weight = min(1.0, diffWidth / spec.limits.larguraA)
            weights["Largura_a"] = weight
            appliedWidthDiff = weight * spec.limits.larguraA
        } else {
            widthSaturated = abs(diffWidth) > spec.limits.larguraD
            widthOverage = widthSaturated ? abs(diffWidth) - spec.limits.larguraD : 0
            let weight = min(1.0, abs(diffWidth) / spec.limits.larguraD)
            weights["Largura_d"] = weight
            appliedWidthDiff = -(weight * spec.limits.larguraD)
        }

        // 3. 🔴 APOIO NASAL PROPORCIONAL: quanto mais achatado o nariz (abaixo do limiar
        // clínico), mais forte o apoio — capado pelo teto nasalSupportWeight e pelo
        // limite físico do próprio modelo (spec.limits.nasal), que antes nunca era usado.
        // 🔴 Reforço por rosto triangular: mandíbula bem mais estreita que o rosto significa
        // menos apoio passivo lateral — a armação fica "pendurada" só pela ponte. jawWidth já
        // era capturado (decide o FORMATO do rosto) mas nunca influenciava uma deformação real.
        // Soma até 15% do limiar clínico como "achatamento extra" — não é achatamento de verdade,
        // é compensação por falta de apoio estrutural lateral. Mesmo limiar (0.85) da classificação.
        let jawSupportBonus: Float = (jawWidth > 0 && jawWidth < faceWidth * 0.85) ? (VisagismClinicalRules.nasalProminenceThreshold * 0.15) : 0

        let flatness = (VisagismClinicalRules.nasalProminenceThreshold - nasalProjection) + jawSupportBonus
        if flatness > 0 && spec.limits.nasal > 0 {
            weights["Nasal_a"] = min(VisagismClinicalRules.nasalSupportWeight, flatness / spec.limits.nasal)
        }

        // 🔴 CÁLCULO VERTICAL ABSOLUTO (Visagismo Suave / Dampening)
        // 1. Proporção Equilibrada (1/4.0 do crânio ARKit)
        let targetHeight = faceHeight / 4.0
        let rawDiffHeight = targetHeight - spec.baseHeight

        // 2. 🔴 PRESSÃO POR FOLGA OLHO→BOCHECHA: quando a bochecha da pessoa começa antes do
        // limiar clínico (cheekClearanceThreshold), a lente corre risco real de encostar nela —
        // isso empurra o ajuste pra encolher MAIS do que a proporção genérica pediria sozinha
        // (nunca pra esticar: falta de folga é sempre motivo de reduzir, não de aumentar).
        // Antes o cálculo vertical não tinha NENHUMA relação com a bochecha, só com a altura
        // total do rosto — ver eyeToCheekClearance em BiometryEngine.faceGeometry.
        let cheekShortfall: Float = (eyeToCheekClearanceValid && eyeToCheekClearance < VisagismClinicalRules.cheekClearanceThreshold)
            ? (VisagismClinicalRules.cheekClearanceThreshold - eyeToCheekClearance)
            : 0

        // 2b. 🔴 BOOST DE VISAGISMO POR FORMATO DO ROSTO: rosto longo/retangular pede lente MAIS
        // alta (quebra a proporção alongada), rosto redondo/curto pede lente mais achatada — regra
        // clássica de visagismo que antes não existia aqui (verticalStretchWeight/verticalSquashWeight
        // ficavam declaradas mas nunca eram usadas). Mesmo limiar de classificação de
        // BiometryEngine.analyzeVisagisme (ver VisagismClinicalRules.longFaceRatioThreshold/
        // shortFaceRatioThreshold), pra não ter 2 leituras divergentes do mesmo rosto.
        let heightWidthRatio: Float = faceWidth > 0 ? faceHeight / faceWidth : 0
        var shapeBoost: Float = 0
        if heightWidthRatio > VisagismClinicalRules.longFaceRatioThreshold {
            shapeBoost = VisagismClinicalRules.verticalShapeBoostMm * VisagismClinicalRules.verticalStretchWeight
        } else if heightWidthRatio > 0 && heightWidthRatio < VisagismClinicalRules.shortFaceRatioThreshold {
            shapeBoost = -(VisagismClinicalRules.verticalShapeBoostMm * VisagismClinicalRules.verticalSquashWeight)
        }

        // 3. 🔴 A MÁGICA DA SUA IDEIA: Fator de Amortecimento Estético (60%)
        // Transforma uma distorção matemática agressiva de 2.0mm em apenas 1.2mm, preservando
        // o design de fábrica da armação! 🔴 CORREÇÃO: antes o amortecimento só entrava na
        // proporção geral (rawDiffHeight) — a pressão da bochecha (cheekShortfall) somava por
        // cima crua, sem freio nenhum. Prova física real (Luno masculino, 2026-08) mostrou
        // encolhimento excessivo (saturava no teto do molde e ainda "faltava" 0.5-0.8mm) — a
        // pressão sem amortecimento provavelmente era a maior responsável. Agora os dois termos
        // são somados ANTES do amortecimento, então a bochecha também é suavizada — o boost de
        // formato entra na mesma soma, pelo mesmo motivo.
        let smoothDiffHeight = (rawDiffHeight + shapeBoost - cheekShortfall) * VisagismClinicalRules.verticalDampening
        var verticalSaturated = false
        var appliedVerticalDiff: Float = 0.0
        var verticalOverage: Float = 0.0

        if smoothDiffHeight > 0 {
            verticalSaturated = smoothDiffHeight > spec.limits.verticalA
            verticalOverage = verticalSaturated ? smoothDiffHeight - spec.limits.verticalA : 0
            let weight = min(1.0, smoothDiffHeight / spec.limits.verticalA)
            weights["Vertical_a"] = weight
            appliedVerticalDiff = weight * spec.limits.verticalA
        } else if smoothDiffHeight < 0 {
            verticalSaturated = abs(smoothDiffHeight) > spec.limits.verticalD
            verticalOverage = verticalSaturated ? abs(smoothDiffHeight) - spec.limits.verticalD : 0
            let weight = min(1.0, abs(smoothDiffHeight) / spec.limits.verticalD)
            weights["Vertical_d"] = weight
            appliedVerticalDiff = -(weight * spec.limits.verticalD)
        }

        return FitResult(weights: weights, bridgeSaturated: bridgeSaturated, widthSaturated: widthSaturated, verticalSaturated: verticalSaturated, appliedBridgeDiff: appliedBridgeDiff, appliedWidthDiff: appliedWidthDiff, appliedVerticalDiff: appliedVerticalDiff, bridgeOverage: bridgeOverage, widthOverage: widthOverage, verticalOverage: verticalOverage)
    }

    /// Calcula os pesos (0.0 a 1.0) para as Shape Keys (Morphers) baseados na biometria do paciente
    static func calculateMorphWeights(keyword: String, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, faceShape: String, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> [String: Float] {
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })

        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return [:] }

        return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge).weights
    }

    /// Mesma busca fuzzy de calculateMorphWeights, mas devolve o FitResult completo (pesos +
    /// deltas em mm já aplicados/clipados) — fonte única para textos de UI como "Ponte Nasal:
    /// -2.9mm", evitando reimplementar a fórmula do motor em cada tela.
    static func fitDetails(forKeyword keyword: String, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> FitResult? {
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })
        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return nil }
        return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge)
    }

    /// Mesma busca fuzzy de calculateMorphWeights, mas devolve só se o modelo cabe sem saturar
    /// nenhum eixo — usado para avisar o cliente ANTES de trocar manualmente de armação no try-on.
    /// nil quando a keyword não bate com nenhum modelo do catálogo.
    static func isGoodFit(forKeyword keyword: String, faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> Bool? {
        let safeKeyword = keyword.lowercased().replacingOccurrences(of: " ", with: "_")
        let sortedKeys = specs.keys.sorted(by: { $0.count > $1.count })
        guard let key = sortedKeys.first(where: { safeKeyword.contains($0) }),
              let spec = specs[key] else { return nil }
        return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge).isGoodFit
    }

    /// Varre TODO o catálogo (todas as linhas) e retorna as chaves dos modelos que encaixam
    /// sem saturar nenhum eixo físico (ponte/largura/vertical) para a biometria informada —
    /// isto é, óculos que realmente cabem, não só o modelo que combina com o formato do rosto.
    static func bestFittingModels(faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> [String] {
        return specs.keys.filter { key in
            guard let spec = specs[key] else { return false }
            return computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge).isGoodFit
        }.sorted()
    }

    /// Resultado de avaliar um modelo específico contra a biometria do paciente, com métricas
    /// pra RANQUEAR (não só filtrar) — usado por bestOptimizedModels pra escolher o modelo que
    /// exige o MENOR esforço de deformação, não só "cabe/não cabe" feito bestFittingModels.
    struct FitScore {
        let key: String
        let fit: FitResult
        /// Soma do quanto cada eixo saturado passou do limite físico, em mm — 0 quando nenhum
        /// eixo saturou (encaixe perfeito dentro da capacidade real do molde).
        let totalOverage: Float
        /// Soma dos pesos (0.0-1.0) realmente usados nos 3 eixos — quanto menor, menos a
        /// armação precisou se afastar do desenho original de fábrica pra caber nesse rosto.
        let totalEffort: Float
    }

    /// Escaneia o catálogo INTEIRO (as 3 linhas — masculino/feminino/infantil — não só a
    /// indicada pela largura do rosto) e ranqueia cada modelo pelo menor esforço de deformação
    /// necessário. Diferente de bestFittingModels (booleano "cabe ou não cabe"), aqui todo
    /// modelo entra na lista, ordenado do encaixe mais preciso pro menos preciso — prioriza
    /// sempre não saturar (totalOverage=0), e entre modelos empatados nisso desempata pelo que
    /// exige menos deformação total (totalEffort), preservando ao máximo o desenho de fábrica.
    /// Pedido explícito do Gabriel: sempre indicar o modelo mais otimizado do catálogo inteiro,
    /// aceitando que às vezes vai estourar um pouco em vez de nunca conseguir recomendar nada.
    static func bestOptimizedModels(faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> [FitScore] {
        return specs.keys.compactMap { key -> FitScore? in
            guard let spec = specs[key] else { return nil }
            let fit = computeFit(key: key, spec: spec, faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge)
            let totalOverage = fit.bridgeOverage + fit.widthOverage + fit.verticalOverage
            let totalEffort = (fit.weights["Ponte_a"] ?? fit.weights["Ponte_d"] ?? 0)
                + (fit.weights["Largura_a"] ?? fit.weights["Largura_d"] ?? 0)
                + (fit.weights["Vertical_a"] ?? fit.weights["Vertical_d"] ?? 0)
            return FitScore(key: key, fit: fit, totalOverage: totalOverage, totalEffort: totalEffort)
        }.sorted { a, b in
            if a.totalOverage != b.totalOverage { return a.totalOverage < b.totalOverage }
            return a.totalEffort < b.totalEffort
        }
    }

    /// Só a chave do modelo mais otimizado do catálogo inteiro (primeiro colocado do ranking
    /// acima) — nil apenas se specs estiver vazio.
    static func mostOptimizedModel(faceWidth: Float, faceHeight: Float, bridgeWidth: Float, nasalProjection: Float, jawWidth: Float, eyeToCheekClearance: Float = 0, eyeToCheekClearanceValid: Bool = false, currentGlassesLensWidth: Float? = nil, currentGlassesBridge: Float? = nil) -> String? {
        return bestOptimizedModels(faceWidth: faceWidth, faceHeight: faceHeight, bridgeWidth: bridgeWidth, nasalProjection: nasalProjection, jawWidth: jawWidth, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, currentGlassesLensWidth: currentGlassesLensWidth, currentGlassesBridge: currentGlassesBridge).first?.key
    }

    /// "luno_infantil" → "Luno (Infantil)" — nome de exibição a partir da chave do banco de specs.
    static func displayName(forKey key: String) -> String {
        let parts = key.split(separator: "_")
        guard let line = parts.last, parts.count >= 2 else { return key.capitalized }
        let model = parts.dropLast().joined(separator: " ").capitalized
        return "\(model) (\(line.capitalized))"
    }
}
