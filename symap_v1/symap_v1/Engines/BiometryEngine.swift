import Foundation
import simd

/// Constantes de calibração clínica e física.
enum CalibrationFactors {
    /// Origem (0.9653): Fator fixo que corrige o ínfimo desvio refracional do polímero da tela sobre a projeção infravermelha do LiDAR (Altura Pupilar).
    static let pupilHeight: Float = 0.9653
    
    /// Origem (0.98): Fator de Conforto (Comfort Factor). Representa a compensação de 2% de compressão biomecânica do material da armação sobre o tecido humano.
    static let faceWidthComfort: Float = 1.00
    
    /// Origem (0.980, 0.969, 0.977): Fatores empíricos de calibração espacial para a desprojeção de linhas 2D nativas sobre a profundidade 3D nas réguas da tela.
    static let manualHeight: Float = 0.980
    static let manualWidth: Float = 0.969
    static let manualDiagonal: Float = 0.977
}

/// BiometryEngine — núcleo de cálculo PURO do Symap Med.
enum BiometryEngine {
    
    // MARK: - Tipos de retorno
    struct DecentrationProfile {
        let deltaX_OD: Float
        let deltaX_OE: Float
        let deltaY: Float
        let decentrationOD: Float
        let decentrationOE: Float
        let maxDecentration: Float
        let effectiveED: Float
    }
    
    struct FaceGeometryResult {
        let minX, maxX, minY, maxY, minNX, maxNX, minJawX, maxJawX, maxNoseZ: Float
        let faceWidthLeft, faceWidthRight, faceWidth: Float
        let noseBridgeWidth: Float
        let bridgeValid: Bool
        let nasalProfile: String
        let nasalProjection: Float
        let jawWidth: Float
        let jawValid: Bool
        let cheekboneWidth: Float
        let cheekboneValid: Bool
        let faceHeight: Float
        /// Distância vertical (mm) entre a linha do olho e a altura onde a bochecha REALMENTE
        /// começa a projetar pra frente — medida dinâmica por pessoa, não um offset fixo chutado.
        /// Ver comentário em faceGeometry para o método (varredura de profundidade por faixa de Y).
        let eyeToCheekClearance: Float
        let eyeToCheekClearanceValid: Bool

        /// Pontos 3D (espaço local do ARFaceAnchor) que geraram cada extremo acima — só pra
        /// desenho de referência visual (laudo PDF), não influenciam nenhum cálculo de encaixe.
        /// nil quando a banda correspondente não teve nenhum vértice válido.
        let widthPointLeft, widthPointRight: simd_float3?
        let bridgePointLeft, bridgePointRight: simd_float3?
        let jawPointLeft, jawPointRight: simd_float3?
        let cheekPointLeft, cheekPointRight: simd_float3?
        let foreheadPoint, chinPoint: simd_float3?
    }
    
    // MARK: - Equivalente esférico (EE)
    static func equivalentSphere(esf: Float, cil: Float) -> Float {
        return esf + (cil / 2.0)
    }
    
    static func maxEquivalentSphere(eeOD: Float, eeOE: Float) -> Float {
        return abs(eeOD) > abs(eeOE) ? eeOD : eeOE
    }
    
    // MARK: - Descentração oblíqua + diâmetro efetivo
    static func decentration(frameWidth: Float, bridge: Float, dnpOD: Float, dnpEsq: Float, pupilHeight: Float, frameHeight: Float, frameDiagonal: Float) -> DecentrationProfile {
        let dcgMetade = (frameWidth + bridge) / 2.0
        let deltaX_OD = dcgMetade - dnpOD
        let deltaX_OE = dcgMetade - dnpEsq
        let deltaY = pupilHeight > 0 ? (pupilHeight - (frameHeight / 2.0)) : 0.0
        
        let decentracaoObliquaOD = sqrt(pow(deltaX_OD, 2) + pow(deltaY, 2))
        let decentracaoObliquaOE = sqrt(pow(deltaX_OE, 2) + pow(deltaY, 2))
        let maxDecentration = max(decentracaoObliquaOD, decentracaoObliquaOE)
        let edEfetivo = frameDiagonal > 0 ? (frameDiagonal + (maxDecentration * 2.0)) : 0.0
        
        return DecentrationProfile(deltaX_OD: deltaX_OD, deltaX_OE: deltaX_OE, deltaY: deltaY, decentrationOD: decentracaoObliquaOD, decentrationOE: decentracaoObliquaOE, maxDecentration: maxDecentration, effectiveED: edEfetivo)
    }
    
    // MARK: - MBS (Minimum Blank Size) e bloco comercial
    static func minimumBlankSize(frameWidth: Float, bridge: Float, frameDiagonal: Float, frameHeight: Float, dnpOD: Float, dnpEsq: Float) -> (mbs: Float, commercialBlock: Float) {
        let menorDNP = min(dnpEsq, dnpOD)
        let dcg = frameWidth + bridge
        let edMax = max(frameDiagonal, frameWidth, frameHeight)
        let descentracao = abs(dcg - (menorDNP * 2))
        
        let mbs = edMax > 0 ? (edMax + descentracao + 2.0) : 0.0
        var blocoComercial = mbs > 0 ? ceil(mbs / 5.0) * 5.0 : 0.0
        if blocoComercial > 0 && blocoComercial < 65.0 { blocoComercial = 65.0 }
        
        return (mbs, blocoComercial)
    }
    
    // MARK: - Prisma induzido
    static func prismaticDeviation(maxDecentration: Float, maxEE: Float) -> Float {
        return (maxDecentration / 10.0) * abs(maxEE)
    }
    
    // MARK: - Curva base (Sagitta)
    static func baseCurveSagitta(maxEE: Float) -> Float {
        var curvaBaseIdeal: Float = 0.0
        if maxEE > 0 {
            curvaBaseIdeal = maxEE + 6.0
        } else if maxEE < 0 {
            curvaBaseIdeal = (maxEE / 2.0) + 6.0
        }
        return curvaBaseIdeal
    }
    
    // MARK: - Seleção de material / índice de refração
    static func lensMaterial(maxEE: Float) -> (index: Float, name: String) {
        var indiceRefracao: Float = 1.50
        var nomeMaterial = "CR-39 / Resina Comum"
        
        if abs(maxEE) > 6.0 {
            indiceRefracao = 1.74; nomeMaterial = "Alto Índice (1.74)"
        } else if abs(maxEE) > 4.0 {
            indiceRefracao = 1.67; nomeMaterial = "Resina Média (1.67)"
        } else if abs(maxEE) > 2.0 {
            indiceRefracao = 1.59; nomeMaterial = "Policarbonato (1.59)"
        }
        return (indiceRefracao, nomeMaterial)
    }
    
    // MARK: - Espessura de borda
    static func edgeThickness(maxEE: Float, lensRadius: Float, refractiveIndex: Float) -> Float {
        return (abs(maxEE) * pow(lensRadius, 2)) / (2000.0 * (refractiveIndex - 1.0))
    }
    
    // MARK: - DNP (distância pupilar)
    static func pupillaryDistance(leftCenter: simd_float3, rightCenter: simd_float3, leftGaze: simd_float3, rightGaze: simd_float3, gazeRadius: Float = 0.012) -> (dnpEsq: Float, dnpDir: Float, dnpTotal: Float, verticalDiff: Float, dnpPertoEsq: Float, dnpPertoDir: Float, dnpPertoTotal: Float) {
        let dnpEsq = abs(leftCenter.x) * 1000
        let dnpDir = abs(rightCenter.x) * 1000
        let dnpTotal = dnpEsq + dnpDir
        let verticalDiff = (leftCenter.y - rightCenter.y) * 1000
        
        let lPupil = leftCenter + (leftGaze * gazeRadius)
        let rPupil = rightCenter + (rightGaze * gazeRadius)
        
        let dnpPertoEsq = abs(lPupil.x) * 1000
        let dnpPertoDir = abs(rPupil.x) * 1000
        let dnpPertoTotal = dnpPertoEsq + dnpPertoDir
        
        return (dnpEsq, dnpDir, dnpTotal, verticalDiff, dnpPertoEsq, dnpPertoDir, dnpPertoTotal)
    }

    // MARK: - Assimetria facial
    /// A armação hoje só tem ajuste de largura simétrico (Largura_a/Largura_r) — não existe shape
    /// key esquerda/direita separada. Isso não corrige o encaixe, só avisa quando a diferença lateral
    /// é grande o bastante pra a armação tender a ficar mais apertada de um lado e girar/escorregar
    /// pro lado mais largo. Mesmo limiar (1.5mm) já usado em MeasurementRepository.
    static func facialAsymmetryWarning(faceWidthLeft: Float, faceWidthRight: Float, threshold: Float = 1.5) -> String? {
        let diff = abs(faceWidthLeft - faceWidthRight)
        guard diff > threshold else { return nil }
        let biggerSide = faceWidthLeft > faceWidthRight ? "esquerdo" : "direito"
        return "Seu rosto tem uma leve assimetria (lado \(biggerSide) \(fmt(diff))mm mais largo) — o ajuste automático é simétrico, pode precisar de um acerto manual fino."
    }

    //  MARK: - Visagismo
        private static func fmt(_ value: Float) -> String { return String(format: "%.1f", value) }
        
    static func analyzeVisagisme(width: Float, height: Float, bridge: Float, jaw: Float, dnpTotal: Float, cheekbone: Float = 0, cheekboneValid: Bool = false, nasalProjection: Float = 0) -> (faceShape: String, frameSuggestion: String, recommendedModel: String) {
            let ratio = height / width
            let dnpRatio = dnpTotal / width
            var shape = ""
            var recommendedModel = ""

            // 🔴 Tríade clássica de visagismo (testa/têmpora × maçã do rosto × mandíbula) em vez
            // de só 2 medidas. `width` já funciona como proxy de testa/têmpora (é amostrado logo
            // acima da linha dos olhos). O que faltava era a maçã do rosto — sem ela, a checagem
            // de "queixo estreito" comparava a mandíbula com a testa, que é o ponto anatômico
            // errado; o correto é comparar com o ponto mais largo real do rosto (a maçã).
            let widestPoint = (cheekboneValid && cheekbone > jaw) ? cheekbone : width
            let jawRatio = jaw / widestPoint

            // 1. CÁLCULO MATEMÁTICO DO FORMATO DO ROSTO
            if ratio > 1.35 {
                shape = "Longo / Retangular"
            } else if ratio < 1.15 {
                shape = "Redondo / Curto"
            } else if jawRatio < 0.85 {
                shape = "Coração / Triangular"
            } else {
                shape = "Oval"
            }

            // 🔴 2. A MÁGICA: A IA agora consulta o seu novo Catálogo de História e Marketing!
            let recommendedProfile = FrameCatalogEngine.recommendFrame(faceShape: shape)
            recommendedModel = recommendedProfile.id

            // 3. PROPORÇÃO E DETALHES FACIAIS
            var eyesAdvice = ""
            if dnpRatio < 0.43 {
                eyesAdvice = "Olhos Próximos: Evite sobrecarregar o centro do rosto. A IA priorizou pontes confortáveis e detalhes nas extremidades da armação."
            } else {
                eyesAdvice = "Proporção Ocular: O distanciamento dos seus olhos está em perfeita harmonia anatômica."
            }

            var noseAdvice = ""
            if bridge < 15.0 {
                noseAdvice = "Tamanho do Nariz: Pontes altas ajudam a não destacar tanto o osso nasal."
            } else {
                noseAdvice = "Sobrancelhas: A parte superior da armação (\(recommendedProfile.shape)) foi selecionada para acompanhar o desenho natural do seu supercílio."
            }

            // 🔴 Nota de meio-rosto: quando a maçã do rosto é claramente mais larga que testa e
            // mandíbula juntas, é um traço que muda o ponto de equilíbrio visual da armação —
            // vale reportar mesmo sem mudar o balde de formato (só 4 estilos no catálogo hoje).
            var midfaceAdvice: String? = nil
            if cheekboneValid && cheekbone > width * 1.05 && cheekbone > jaw * 1.05 {
                midfaceAdvice = "Meio-Rosto: A maçã do rosto é o ponto mais largo — armações com destaque na parte superior equilibram melhor as proporções."
            }

            let colorsAdvice = "CORES E TOM DE PELE\n• Pele Quente (fundos amarelados): Harmoniza com tons terrosos, dourado e tartaruga.\n• Pele Fria (fundos rosados): Rosa-antigo, azul, cinza e tons pastéis combinam muito bem."

            // 🔴 4. MONTAGEM FINAL DO LAUDO (Juntando a Matemática com a sua Poesia)
            let finalSuggestion = """
            1. RESULTADO DO VISAGISMO 3D
            Seu rosto possui o formato predominantemente \(shape.uppercased()).

            📖 CONCEITO DO MODELO INDICADO (\(recommendedProfile.name.uppercased())):
            \(recommendedProfile.storytelling)

            2. ANÁLISE DE PROPORÇÕES (IA)
            • \(eyesAdvice)
            • \(noseAdvice)\(midfaceAdvice != nil ? "\n• \(midfaceAdvice!)" : "")

            3. \(colorsAdvice)
            """

            return (shape, finalSuggestion, recommendedModel)
        }
    
    // MARK: - Geometria facial
    static func faceGeometry(vertices: [simd_float3], eyeLevelY: Float, eyeDepthZ: Float, comfortFactor: Float = CalibrationFactors.faceWidthComfort) -> FaceGeometryResult {
        let maxDepthLimit = eyeDepthZ - 0.010
        let searchYMin = eyeLevelY
        let searchYMax = eyeLevelY + 0.030
        let maxWidthLimit: Float = 0.085
        var minX: Float = 100;     var maxX: Float = -100
        var minY: Float = 100;     var maxY: Float = -100
        var minNX: Float = 100;    var maxNX: Float = -100
        var minJawX: Float = 100;  var maxJawX: Float = -100
        var minCheekX: Float = 100; var maxCheekX: Float = -100
        var maxNoseZ: Float = -100
        var widthPointLeft: simd_float3? = nil;  var widthPointRight: simd_float3? = nil
        var bridgePointLeft: simd_float3? = nil; var bridgePointRight: simd_float3? = nil
        var jawPointLeft: simd_float3? = nil;    var jawPointRight: simd_float3? = nil
        var cheekPointLeft: simd_float3? = nil;  var cheekPointRight: simd_float3? = nil
        var foreheadPoint: simd_float3? = nil;   var chinPoint: simd_float3? = nil
        let midlineX: Float = 0.015
        let bridgeHeightY = eyeLevelY + 0.000
        let jawLevelY = eyeLevelY - 0.065
        // 🔴 Terceiro ponto da tríade clássica de visagismo (testa/maçã do rosto/mandíbula).
        // faceWidth (banda searchYMin..searchYMax, logo acima dos olhos) já funciona como proxy
        // de testa/têmpora — o que faltava era a maçã do rosto, que fica entre os olhos e a
        // mandíbula. Offset -0.030 é estimativa inicial (meio caminho até jawLevelY em -0.065);
        // precisa validar visualmente em captura real antes de confiar 100%.
        let cheekboneLevelY = eyeLevelY - 0.030

        // 🔴 CLEARANCE OLHO→BOCHECHA (dinâmico): antes a única referência vertical pro ajuste
        // da lente era faceHeight/4 (proporção do rosto inteiro, sem relação com a bochecha) e
        // cheekboneLevelY (offset fixo de 30mm, chutado igual pra todo mundo). Aqui varremos em
        // faixas de 2mm da altura do olho até a mandíbula e achamos a primeira altura onde a
        // malha projeta pra frente o bastante (>6mm à frente da profundidade do olho) pra ser
        // considerada bochecha, não mais órbita/face plana. Isso dá a folga real de cada pessoa —
        // é justamente essa distância curta que faz a lente encostar na bochecha (comum em rostos
        // com região malar mais projetada). O limiar de detecção (6mm) e o de segurança clínico
        // (VisagismClinicalRules.cheekClearanceThreshold) ainda não têm validação com prova física
        // real — mesmo status inicial que bridgeClearance tinha antes dos dados do Luno/Suki.
        let clearanceStepY: Float = 0.002
        let clearanceScanBottom = jawLevelY
        let cheekDetectDepthDelta: Float = 0.006
        // 🔴 Janela de X sob o olho, excluindo o nariz (que projeta mais que a bochecha e ia
        // disparar a detecção na primeira faixa, zerando a folga de qualquer rosto) e a região
        // bem na têmpora (que já não é mais bochecha). Faixa lateral bilateral: ~15mm a ~50mm
        // do centro do rosto.
        let clearanceXInner: Float = 0.015
        let clearanceXOuter: Float = 0.050
        let clearanceBandCount = max(1, Int(((eyeLevelY - clearanceScanBottom) / clearanceStepY).rounded(.up)) + 1)
        var clearanceBandMaxZ = [Float](repeating: -100, count: clearanceBandCount)

        for v in vertices {
            if v.y < minY { minY = v.y };      if v.y > maxY { maxY = v.y }
            if v.z > maxNoseZ { maxNoseZ = v.z }

            if v.y >= searchYMin && v.y <= searchYMax {
                if v.z > maxDepthLimit && abs(v.x) < maxWidthLimit {
                    if v.x < minX { minX = v.x; widthPointRight = v }
                    if v.x > maxX { maxX = v.x; widthPointLeft = v }
                }
            }

            if abs(v.y - bridgeHeightY) < 0.002 && abs(v.x) < 0.010 {
                if v.x < minNX { minNX = v.x; bridgePointRight = v }
                if v.x > maxNX { maxNX = v.x; bridgePointLeft = v }
            }

            if abs(v.y - jawLevelY) < 0.010 && v.z > maxDepthLimit {
                if v.x < minJawX { minJawX = v.x; jawPointRight = v }
                if v.x > maxJawX { maxJawX = v.x; jawPointLeft = v }
            }

            if abs(v.y - cheekboneLevelY) < 0.010 && v.z > maxDepthLimit {
                if v.x < minCheekX { minCheekX = v.x; cheekPointRight = v }
                if v.x > maxCheekX { maxCheekX = v.x; cheekPointLeft = v }
            }

            // 🔴 Ponto de referência visual (laudo PDF) pra altura do rosto: testa/queixo na
            // linha média (abs(x) pequeno), não os extremos brutos de minY/maxY (que podem cair
            // em qualquer lugar da malha, ex. orelha) — mesmo padrão de faixa central já usado
            // na ponte nasal (abs(x) < 0.010) só que numa janela um pouco mais larga.
            if abs(v.x) < midlineX {
                if foreheadPoint == nil || v.y > foreheadPoint!.y { foreheadPoint = v }
                if chinPoint == nil || v.y < chinPoint!.y { chinPoint = v }
            }

            if v.y <= eyeLevelY && v.y >= clearanceScanBottom && abs(v.x) > clearanceXInner && abs(v.x) < clearanceXOuter {
                let bandIndex = Int((eyeLevelY - v.y) / clearanceStepY)
                if bandIndex >= 0 && bandIndex < clearanceBandCount && v.z > clearanceBandMaxZ[bandIndex] {
                    clearanceBandMaxZ[bandIndex] = v.z
                }
            }
        }
        
        let faceWidthRight = (abs(minX) * 1000) * comfortFactor
        let faceWidthLeft = (maxX * 1000) * comfortFactor
        let faceWidth = faceWidthLeft + faceWidthRight
        let bridgeValid = minNX < maxNX
        let noseBridgeWidth = (maxNX - minNX) * 1000
        let projNasal = (maxNoseZ - eyeDepthZ) * 1000
        let nasalProfile = projNasal > VisagismClinicalRules.nasalProminenceThreshold ? "Proeminente" : "Plano"
        let jawValid = minJawX < maxJawX
        let jawWidth = (maxJawX - minJawX) * 1000
        let cheekboneValid = minCheekX < maxCheekX
        let cheekboneWidth = (maxCheekX - minCheekX) * 1000
        let faceHeight = (maxY - minY) * 1000

        // 🔴 CORREÇÃO: comparar com eyeDepthZ (profundidade da PUPILA) fazia a bochecha "disparar"
        // já na primeira faixa pra quase todo mundo — o globo ocular fica naturalmente recuado
        // dentro da órbita, então a pálpebra inferior/canto do olho ao lado já parece "mais pra
        // frente" que a pupila, sem ter nada a ver com bochecha de verdade. A referência certa é
        // uma linha de base local, tirada das primeiras faixas do próprio scan (logo abaixo do
        // olho, ainda órbita/rosto plano) — e só então procurar onde a malha sobe em relação a
        // ELA, não em relação à pupila.
        var baselineZ: Float = -100
        for i in 0..<min(2, clearanceBandCount) {
            if clearanceBandMaxZ[i] > baselineZ { baselineZ = clearanceBandMaxZ[i] }
        }

        var cheekStartBandIndex: Int? = nil
        if baselineZ > -100 && clearanceBandCount > 2 {
            for i in 2..<clearanceBandCount {
                if clearanceBandMaxZ[i] > -100 && (clearanceBandMaxZ[i] - baselineZ) > cheekDetectDepthDelta {
                    cheekStartBandIndex = i
                    break
                }
            }
        }
        let eyeToCheekClearanceValid = cheekStartBandIndex != nil
        let eyeToCheekClearance = eyeToCheekClearanceValid ? (Float(cheekStartBandIndex!) * clearanceStepY) * 1000 : 0.0

        return FaceGeometryResult(minX: minX, maxX: maxX, minY: minY, maxY: maxY, minNX: minNX, maxNX: maxNX, minJawX: minJawX, maxJawX: maxJawX, maxNoseZ: maxNoseZ, faceWidthLeft: faceWidthLeft, faceWidthRight: faceWidthRight, faceWidth: faceWidth, noseBridgeWidth: noseBridgeWidth, bridgeValid: bridgeValid, nasalProfile: nasalProfile, nasalProjection: projNasal, jawWidth: jawWidth, jawValid: jawValid, cheekboneWidth: cheekboneWidth, cheekboneValid: cheekboneValid, faceHeight: faceHeight, eyeToCheekClearance: eyeToCheekClearance, eyeToCheekClearanceValid: eyeToCheekClearanceValid, widthPointLeft: widthPointLeft, widthPointRight: widthPointRight, bridgePointLeft: bridgePointLeft, bridgePointRight: bridgePointRight, jawPointLeft: jawPointLeft, jawPointRight: jawPointRight, cheekPointLeft: cheekPointLeft, cheekPointRight: cheekPointRight, foreheadPoint: foreheadPoint, chinPoint: chinPoint)
    }
    
    // MARK: - Seam de projeção AR
    static func frameReferencePoint(leftEye: simd_float3, rightEye: simd_float3, cameraPos: simd_float3, offset: Float = 0.015) -> simd_float3 {
        let cx = (leftEye.x + rightEye.x) / 2.0
        let cy = (leftEye.y + rightEye.y) / 2.0
        let cz = (leftEye.z + rightEye.z) / 2.0
        
        let dirX = cameraPos.x - cx
        let dirY = cameraPos.y - cy
        let dirZ = cameraPos.z - cz
        let distance = sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
        
        return simd_float3(cx + (dirX / distance) * offset, cy + (dirY / distance) * offset, cz + (dirZ / distance) * offset)
    }
    
    static func distanceMm(_ a: simd_float3, _ b: simd_float3) -> Float {
        return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2) + pow(b.z - a.z, 2)) * 1000.0
    }
}
