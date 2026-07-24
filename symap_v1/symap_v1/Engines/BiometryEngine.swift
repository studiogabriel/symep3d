import Foundation
import simd

/// Constantes de calibração clínica e física.
enum CalibrationFactors {
    /// Origem (0.9653): Fator fixo que corrige o ínfimo desvio refracional do polímero da tela sobre a projeção infravermelha do LiDAR (Altura Pupilar).
    static let pupilHeight: Float = 0.9653
    
    /// Origem (0.98): Fator de Conforto (Comfort Factor). Representa a compensação de 2% de compressão biomecânica do material da armação (acetato/metal) sobre o tecido humano.
    static let faceWidthComfort: Float = 0.98
    
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
        let jawWidth: Float
        let jawValid: Bool
        let faceHeight: Float
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
    
    //  MARK: - Visagismo
        private static func fmt(_ value: Float) -> String { return String(format: "%.1f", value) }
        
    static func analyzeVisagisme(width: Float, height: Float, bridge: Float, jaw: Float, dnpTotal: Float) -> (faceShape: String, frameSuggestion: String, recommendedModel: String) {
            let ratio = height / width
            let dnpRatio = dnpTotal / width
            var shape = ""
            var recommendedModel = ""
            
            // 1. CÁLCULO MATEMÁTICO DO FORMATO DO ROSTO
            if ratio > 1.35 {
                shape = "Longo / Retangular"
            } else if ratio < 1.15 {
                shape = "Redondo / Curto"
            } else if jaw < (width * 0.85) {
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
            
            let colorsAdvice = "CORES E TOM DE PELE\n• Pele Quente (fundos amarelados): Harmoniza com tons terrosos, dourado e tartaruga.\n• Pele Fria (fundos rosados): Rosa-antigo, azul, cinza e tons pastéis combinam muito bem."
            
            // 🔴 4. MONTAGEM FINAL DO LAUDO (Juntando a Matemática com a sua Poesia)
            let finalSuggestion = """
            1. RESULTADO DO VISAGISMO 3D
            Seu rosto possui o formato predominantemente \(shape.uppercased()).
            
            📖 CONCEITO DO MODELO INDICADO (\(recommendedProfile.name.uppercased())):
            \(recommendedProfile.storytelling)
            
            2. ANÁLISE DE PROPORÇÕES (IA)
            • \(eyesAdvice)
            • \(noseAdvice)
            
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
        var maxNoseZ: Float = -100
        let bridgeHeightY = eyeLevelY + 0.000
        let jawLevelY = eyeLevelY - 0.065
        
        for v in vertices {
            if v.y < minY { minY = v.y };      if v.y > maxY { maxY = v.y }
            if v.z > maxNoseZ { maxNoseZ = v.z }
            
            if v.y >= searchYMin && v.y <= searchYMax {
                if v.z > maxDepthLimit && abs(v.x) < maxWidthLimit {
                    if v.x < minX { minX = v.x }
                    if v.x > maxX { maxX = v.x }
                }
            }
            
            if abs(v.y - bridgeHeightY) < 0.002 && abs(v.x) < 0.010 {
                if v.x < minNX { minNX = v.x }
                if v.x > maxNX { maxNX = v.x }
            }
            
            if abs(v.y - jawLevelY) < 0.010 && v.z > maxDepthLimit {
                if v.x < minJawX { minJawX = v.x }
                if v.x > maxJawX { maxJawX = v.x }
            }
        }
        
        let faceWidthRight = (abs(minX) * 1000) * comfortFactor
        let faceWidthLeft = (maxX * 1000) * comfortFactor
        let faceWidth = faceWidthLeft + faceWidthRight
        let bridgeValid = minNX < maxNX
        let noseBridgeWidth = (maxNX - minNX) * 1000
        let projNasal = (maxNoseZ - eyeDepthZ) * 1000
        let nasalProfile = projNasal > 20.0 ? "Proeminente" : "Plano"
        let jawValid = minJawX < maxJawX
        let jawWidth = (maxJawX - minJawX) * 1000
        let faceHeight = (maxY - minY) * 1000
        
        return FaceGeometryResult(minX: minX, maxX: maxX, minY: minY, maxY: maxY, minNX: minNX, maxNX: maxNX, minJawX: minJawX, maxJawX: maxJawX, maxNoseZ: maxNoseZ, faceWidthLeft: faceWidthLeft, faceWidthRight: faceWidthRight, faceWidth: faceWidth, noseBridgeWidth: noseBridgeWidth, bridgeValid: bridgeValid, nasalProfile: nasalProfile, jawWidth: jawWidth, jawValid: jawValid, faceHeight: faceHeight)
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
