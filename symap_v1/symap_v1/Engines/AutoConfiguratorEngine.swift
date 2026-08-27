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
            // --- COLEÇÃO FEMININA (Base Larga: ~136.3mm) ---
            // 🔴 baseWidth/baseHeight/baseBridge corrigidos com medição direta do molde 3D em
            // repouso (peso 0) via Blender — os 4 modelos convergem pra ~136.3mm de largura
            // (não 128-135mm variados como a estimativa manual anterior) e ~20mm de ponte (não
            // 14.5-16.0mm). limits.bridgePlus/bridgeMinus/larguraA/larguraR/verticalA/verticalR:
            // 1ª medição real de capacidade (peso 1.0 no Blender). larguraA/larguraR convergem
            // pra ~3.84mm nos 4 modelos — coerente com a correção de acoplamento ponte→largura
            // (bridgeWidthCoupling), já que aqui a largura muda a mesma coisa em ambas direções.
            "luno_feminino": ModelSpec(baseBridge: 19.96, baseWidth: 136.26, baseHeight: 51.14, limits: ModelLimits(bridgePlus: 5.11, bridgeMinus: 3.33, nasal: 2.0, ferradura: 2.0, larguraR: 3.84, larguraA: 3.84, verticalR: 1.93, verticalA: 1.91)),
            "nunu_feminino": ModelSpec(baseBridge: 19.79, baseWidth: 136.35, baseHeight: 47.09, limits: ModelLimits(bridgePlus: 3.88, bridgeMinus: 2.77, nasal: 2.0, ferradura: 1.5, larguraR: 3.84, larguraA: 3.84, verticalR: 1.93, verticalA: 1.91)),
            "suki_feminino": ModelSpec(baseBridge: 20.05, baseWidth: 136.27, baseHeight: 52.34, limits: ModelLimits(bridgePlus: 3.16, bridgeMinus: 3.33, nasal: 2.0, ferradura: 1.5, larguraR: 3.85, larguraA: 3.83, verticalR: 1.91, verticalA: 1.91)),
            "timbau_feminino": ModelSpec(baseBridge: 20.22, baseWidth: 136.27, baseHeight: 51.85, limits: ModelLimits(bridgePlus: 3.73, bridgeMinus: 2.83, nasal: 2.0, ferradura: 0.0, larguraR: 3.84, larguraA: 3.84, verticalR: 1.92, verticalA: 1.92)),
            
            // --- COLEÇÃO MASCULINA (Base Larga: ~142mm) ---
            // 🔴 baseWidth/baseHeight corrigidos com medição direta do molde 3D em repouso
            // (peso 0), extraída via Claude dentro do Blender — não é estimativa por
            // impressão/paquímetro como o infantil. baseWidth estava uniformemente 140.0 pros
            // 4 modelos; a medida real é ~142.0 nos 4 (mesmo desvio consistente, não é ruído).
            // 🔴 baseBridge: 2ª remedição via Blender com metodologia consistente de "Ponte"
            // (23.86/23.80/23.81/23.78) substitui a 1ª leitura (14.20/14.20/14.20/14.19) — a
            // 1ª usava uma região diferente da ponte; Altura/Largura bateram igual nas duas
            // medições, então só a leitura da ponte mudou de metodologia. Ver bridgeOffsetMasculino
            // em VisagismClinicalRules: a meta de ponte pra essa linha agora é regra fixa
            // (ponte do paciente + 2mm), não mais bridgeClearance calibrado por tentativa.
            // 🔴 limits.bridgePlus/bridgeMinus: 1ª medição real de capacidade (peso 1.0 no Blender,
            // não mais estimativa de 4.0/4.0 uniforme). larguraA/larguraR/verticalA/verticalR
            // conferidas contra a mesma planilha e já batiam com os valores existentes — não mudaram.
            "luno_masculino": ModelSpec(baseBridge: 23.86, baseWidth: 142.00, baseHeight: 53.31, limits: ModelLimits(bridgePlus: 6.11, bridgeMinus: 3.98, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "nunu_masculino": ModelSpec(baseBridge: 23.80, baseWidth: 142.00, baseHeight: 48.94, limits: ModelLimits(bridgePlus: 4.67, bridgeMinus: 3.33, nasal: 2.0, ferradura: 2.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "suki_masculino": ModelSpec(baseBridge: 23.81, baseWidth: 142.00, baseHeight: 54.73, limits: ModelLimits(bridgePlus: 3.75, bridgeMinus: 3.95, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),
            "timbau_masculino": ModelSpec(baseBridge: 23.78, baseWidth: 141.93, baseHeight: 53.99, limits: ModelLimits(bridgePlus: 4.39, bridgeMinus: 3.33, nasal: 2.0, ferradura: 0.0, larguraR: 4.0, larguraA: 4.0, verticalR: 2.0, verticalA: 2.0)),

            // --- COLEÇÃO INFANTIL (Base M: ~120.2mm) ---
            // 🔴 baseWidth/baseHeight/baseBridge corrigidos com medição direta do molde 3D em
            // repouso (peso 0) via Blender. baseWidth confirmado ~120.21 nos 4 (bate com o valor
            // antigo). baseBridge sai de 17.0 fixo pra 18.70-20.04 (varia por modelo, medição
            // precisa). limits.bridgePlus/bridgeMinus/verticalA/verticalR: 1ª medição real de
            // capacidade (peso 1.0 no Blender). larguraR confirmado em 5.0 nos 4 (bate com o
            // valor existente).
            // 🔴 larguraA: substituído de 10.1/10.1/10.6/10.4 (medição de prova impressa) para
            // 8.00mm nos 4 modelos — dado do Blender (peso 1.0), mais confiável porque reflete
            // exatamente o que a malha digital faz na tela (a impressão física tinha uma variável
            // de material/impressora que inflava a medida além do que a malha realmente permite).
            // Decisão confirmada em 2026-08-26.
            "luno_infantil": ModelSpec(baseBridge: 19.02, baseWidth: 120.21, baseHeight: 42.06, limits: ModelLimits(bridgePlus: 5.58, bridgeMinus: 4.11, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 8.00, verticalR: 2.0, verticalA: 2.0)),
            "nunu_infantil": ModelSpec(baseBridge: 20.02, baseWidth: 120.21, baseHeight: 38.28, limits: ModelLimits(bridgePlus: 4.11, bridgeMinus: 4.00, nasal: 2.0, ferradura: 1.5, larguraR: 5.0, larguraA: 8.00, verticalR: 2.0, verticalA: 2.0)),
            "suki_infantil": ModelSpec(baseBridge: 18.70, baseWidth: 120.21, baseHeight: 42.67, limits: ModelLimits(bridgePlus: 4.07, bridgeMinus: 3.93, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 8.00, verticalR: 2.0, verticalA: 2.0)),
            "timbau_infantil": ModelSpec(baseBridge: 20.04, baseWidth: 120.21, baseHeight: 41.82, limits: ModelLimits(bridgePlus: 3.95, bridgeMinus: 4.05, nasal: 2.0, ferradura: 0.0, larguraR: 5.0, larguraA: 8.00, verticalR: 2.0, verticalA: 2.0))
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
            weights["Ponte"] = weight
            appliedBridgeDiff = weight * spec.limits.bridgePlus
            bridgeWidthCoupling = weight * spec.limits.larguraA
        } else {
            bridgeSaturated = abs(rawDiffBridge) > spec.limits.bridgeMinus
            bridgeOverage = bridgeSaturated ? abs(rawDiffBridge) - spec.limits.bridgeMinus : 0
            let weight = min(1.0, abs(rawDiffBridge) / spec.limits.bridgeMinus)
            weights["Ponte_m"] = weight
            appliedBridgeDiff = -(weight * spec.limits.bridgeMinus)
            bridgeWidthCoupling = -(weight * spec.limits.larguraR)
        }

        // 🔴 2. CÁLCULO DE LARGURA COMPENSADA (Mágica Paramétrica)
        // Antes subtraíamos appliedBridgeDiff (mm de MOVIMENTO da ponte) da meta de largura,
        // assumindo 1mm de ponte = 1mm de largura já ganha. Dado real do Blender (peso 1.0)
        // mostra que isso é falso: no Luno, a ponte abre 6.11mm no total mas a largura só
        // acompanha 4.00mm — não é 1:1. O que acopla largura↔ponte de verdade é o PESO do shape
        // key: nos 4 modelos masculinos, ponte no peso 1.0 (pra qualquer lado) sempre move a
        // largura em exatamente a capacidade de larguraA/larguraR já cadastrada. Por isso usamos
        // bridgeWidthCoupling (peso × largura) em vez de appliedBridgeDiff (mm de ponte).
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
            widthSaturated = abs(diffWidth) > spec.limits.larguraR
            widthOverage = widthSaturated ? abs(diffWidth) - spec.limits.larguraR : 0
            let weight = min(1.0, abs(diffWidth) / spec.limits.larguraR)
            weights["Largura_r"] = weight
            appliedWidthDiff = -(weight * spec.limits.larguraR)
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
            weights["Nasal"] = min(VisagismClinicalRules.nasalSupportWeight, flatness / spec.limits.nasal)
        }

        // 3b. 🔴 FERRADURA PROPORCIONAL: quanto mais fino o nariz (abaixo do limiar clínico),
        // mais reforço na ponte — capado pelo teto keyholeBridgeWeight e pelo limite físico do
        // modelo (spec.limits.ferradura). Antes o popup/laudo PROMETIA esse reforço pro cliente
        // sempre que o nariz era fino, mas o peso nunca era calculado em lugar nenhum — bug.
        let thinness = VisagismClinicalRules.narrowNoseThreshold - bridgeWidth
        if thinness > 0 && spec.limits.ferradura > 0 {
            weights["Ferradura"] = min(VisagismClinicalRules.keyholeBridgeWeight, thinness / spec.limits.ferradura)
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
            verticalSaturated = abs(smoothDiffHeight) > spec.limits.verticalR
            verticalOverage = verticalSaturated ? abs(smoothDiffHeight) - spec.limits.verticalR : 0
            let weight = min(1.0, abs(smoothDiffHeight) / spec.limits.verticalR)
            weights["Vertical_r"] = weight
            appliedVerticalDiff = -(weight * spec.limits.verticalR)
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
            let totalEffort = (fit.weights["Ponte"] ?? fit.weights["Ponte_m"] ?? 0)
                + (fit.weights["Largura_a"] ?? fit.weights["Largura_r"] ?? 0)
                + (fit.weights["Vertical_a"] ?? fit.weights["Vertical_r"] ?? 0)
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
