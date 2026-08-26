import Foundation

/// Central de Parâmetros Clínicos de Visagismo e Ergonomia
/// Altere os valores aqui para calibrar as decisões da Inteligência Artificial
struct VisagismClinicalRules {
    
    // =======================================================
    // 🔴 1. FOLGAS ANATÔMICAS GERAIS (em milímetros)
    // =======================================================
    static let temporalClearance: Float = 10 // 5mm de cada lado — usado por infantil e masculino

    /// 🔴 REGRA DE ENGENHARIA (as 3 linhas): desde a remedição via Blender com metodologia
    /// consistente, a meta de ponte deixou de ser calibrada por tentativa/erro (antigo
    /// bridgeClearance -0.40, pensado pra medição manual imprecisa da ponte) e passou a ser uma
    /// regra fixa por linha: ponte alvo = ponte medida do paciente + folga sobre o osso nasal.
    /// Masculino: ajustado de 2mm para 4.5mm após prova física real (2026-08) — 2mm deixou a
    /// ponte curta demais no rosto do próprio Gabriel. Feminino e infantil alinhados na mesma
    /// folga (4.5mm) por decisão do Gabriel — infantil ainda SEM prova física própria pra essa
    /// regra; revalidar assim que houver prova.
    static let bridgeOffsetMasculino: Float = 4.5
    static let bridgeOffsetFeminino: Float = 4.5
    static let bridgeOffsetInfantil: Float = 4.5

    /// Folga temporal específica da linha feminino. Caso real (rosto 120.2mm / ponte 17.8mm):
    /// com a folga padrão de 10mm, o Suki feminino não saturava o limite de encolhimento (usava
    /// 3.35mm de um teto de 4.0mm) mas ainda assim foi sentido como apertado na prova — ou seja,
    /// o teto do molde não era o problema, a meta calculada é que pedia pouco. Com 14mm, o mesmo
    /// caso passa a pedir um leve esticamento (~33% do teto) em vez de quase saturar o encolhimento.
    /// Não aplicado a infantil (já saturado, piorar a meta não ajuda) nem a masculino (sem dado real ainda).
    static let temporalClearanceFeminino: Float = 14
    
    // =======================================================
    // 🔴 2. INTENSIDADE DAS DEFORMAÇÕES (Pesos de 0.0 a 1.0)
    // =======================================================
    /// Teto do apoio nasal: quanto mais achatado o nariz (abaixo de nasalProminenceThreshold),
    /// mais perto desse valor o peso chega — não é mais um liga/desliga fixo, é proporcional.
    static let nasalSupportWeight: Float = 0.7
    static let verticalStretchWeight: Float = 0.8 // Aumento da lente para baixo (Rostos Longos)
    static let verticalSquashWeight: Float = 0.8  // Achatamento da lente (Rostos Redondos)
    static let keyholeBridgeWeight: Float = 0.9   // Engrossamento em ferradura (Nariz Fino)
    
    // =======================================================
    // 🔴 3. LIMITES CLÍNICOS DE GATILHO
    // =======================================================
    static let narrowNoseThreshold: Float = 15.0  // Abaixo dessa medida (mm), a IA ativa a Ferradura

    /// Folga mínima (mm) entre a linha do olho e onde a bochecha começa a projetar pra frente
    /// (ver BiometryEngine.faceGeometry / eyeToCheekClearance). Abaixo disso, a lente corre risco
    /// de encostar na bochecha — comum em rostos com região malar mais projetada (ex.: traço
    /// asiático citado na prova física). 18mm é estimativa inicial de anatomia geral, SEM
    /// validação por prova física ainda — mesmo status que bridgeOffsetMasculino tinha antes da
    /// prova real de 2026-08. Recalibrar assim que houver casos de encaixe com marca na bochecha.
    static let cheekClearanceThreshold: Float = 18.0

    /// Projeção nasal (mm) abaixo da qual o perfil é considerado "Plano" e o apoio nasal entra em ação.
    /// Antes esse número ficava solto dentro do BiometryEngine; agora é calibrável aqui, junto dos outros.
    static let nasalProminenceThreshold: Float = 20.0

    // =======================================================
    // 🔴 4. LINHA DE TAMANHO (Infantil / Feminino / Masculino)
    // =======================================================
    /// Abaixo disso, usa a linha infantil. Baixado de 124.0 para 119.0: caso real de rosto
    /// 120.2mm provou matematicamente que a linha infantil satura o limite de largura (precisava
    /// de 8.65mm, teto físico do molde é 8.0mm) — não tem constante que resolva isso, é limite
    /// do molde 3D. A linha feminino, para o mesmo rosto, não satura em nenhum eixo. Baseado em
    /// n=1 até aqui; revalidar threshold com mais provas antes de considerar definitivo.
    static let kidsFaceWidthThreshold: Float = 119.0
    static let largeFaceWidthThreshold: Float = 130.1  // A partir disso, usa a linha masculina

    // =======================================================
    // 🔴 5. ESTABILIDADE DE CAPTURA (ARKit)
    // =======================================================
    /// Suavização (média móvel exponencial) aplicada a faceWidth/noseBridgeWidth/faceHeight/jawWidth
    /// enquanto a medição ainda não foi congelada — evita que o frame único do "clique" do LiDAR
    /// decida sozinho a linha de tamanho ou os pesos do motor. Mesmo padrão já usado em smoothHeadRoll.
    static let biometrySmoothingAlpha: Float = 0.05

    /// Fator de amortecimento estético do ajuste vertical (rostos longos/curtos).
    /// Origem: pensado para 60% (2.0mm de distorção crua vira 1.2mm suave), mas o código
    /// aplicava 0.05 por engano — quase zerando o ajuste vertical. Corrigido para bater com a intenção.
    static let verticalDampening: Float = 0.6
}
