import Foundation

/// Central de Parâmetros Clínicos de Visagismo e Ergonomia
/// Altere os valores aqui para calibrar as decisões da Inteligência Artificial
struct VisagismClinicalRules {
    
    // =======================================================
    // 🔴 1. FOLGAS ANATÔMICAS GERAIS (em milímetros)
    // =======================================================
    /// Ajustado de 10mm para 15mm por decisão do Gabriel (2026-08) — aceita que isso pode
    /// saturar o limite físico de largura em alguns modelos/rostos (ver widthOverage/[DEV]).
    static let temporalClearance: Float = 15 // 7.5mm de cada lado — usado por infantil e masculino

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
    /// 🔴 Ajustado de 14 para 18mm (2026-08-27) após 2 provas físicas reais: caso do rosto
    /// 124.4mm (Nunu feminino) ainda ficou "no limite, sem folga" com 14mm; segundo caso relatou
    /// a armação "extremamente pequena" horizontalmente, com pedido explícito de ajuste "grande e
    /// perceptível" — não incremental. Ainda sem dado que feche o número exato, revisar com mais provas.
    static let temporalClearanceFeminino: Float = 18

    /// Piso mínimo de largura frontal derivado da armação atual do paciente (quando informada):
    /// nunca recomendamos algo menor do que o que a pessoa já usa e tolera fisicamente, mesmo que
    /// o cálculo biométrico sozinho pedisse menos. Ver AutoConfiguratorEngine.computeFit
    /// (currentGlassesLensWidth/currentGlassesBridge). Cobre a borda de material entre a lente e
    /// a dobradiça, que não aparece nos 2 números gravados na armação (aro + ponte). Estimativa
    /// inicial SEM validação por prova física — mesmo status que cheekClearanceThreshold tinha
    /// antes da prova real; recalibrar assim que tivermos casos comparando armação atual x conforto.
    static let currentGlassesRimAllowance: Float = 4.0
    
    // =======================================================
    // 🔴 2. INTENSIDADE DAS DEFORMAÇÕES (Pesos de 0.0 a 1.0)
    // =======================================================
    /// Teto do apoio nasal: quanto mais achatado o nariz (abaixo de nasalProminenceThreshold),
    /// mais perto desse valor o peso chega — não é mais um liga/desliga fixo, é proporcional.
    static let nasalSupportWeight: Float = 0.7
    static let verticalStretchWeight: Float = 0.8 // Aumento da lente para baixo (Rostos Longos)
    static let verticalSquashWeight: Float = 0.8  // Achatamento da lente (Rostos Redondos)
    static let keyholeBridgeWeight: Float = 0.9   // Engrossamento em ferradura (Nariz Fino)

    /// Limiares de proporção altura/largura que classificam o formato do rosto — mesmos números
    /// usados em BiometryEngine.analyzeVisagisme (ratio > 1.35 = Longo/Retangular, ratio < 1.15 =
    /// Redondo/Curto). Centralizados aqui pra AutoConfiguratorEngine.computeFit usar exatamente o
    /// mesmo corte na hora de aplicar o boost vertical por formato — evita 2 classificações
    /// divergentes do mesmo rosto em lugares diferentes do código (like já aconteceu antes com
    /// recommendedAutoModel vs visagismStyleModel).
    static let longFaceRatioThreshold: Float = 1.35
    static let shortFaceRatioThreshold: Float = 1.15

    /// Magnitude (mm) do empurrão vertical extra por formato de rosto — rostos longos/retangulares
    /// puxam a lente mais pra baixo (verticalStretchWeight), rostos redondos/curtos achatam mais
    /// (verticalSquashWeight). Antes essas 2 constantes existiam mas nunca eram usadas no cálculo
    /// real — o ajuste vertical era cego ao formato do rosto, só via proporção genérica
    /// (faceHeight/4.0).
    /// 🔴 Ajustado de 2.0 para 4.0 (2026-08-27) após 3 provas físicas reais seguidas pedindo mais
    /// vertical: (1) rosto longo 186.3mm, cálculo dava só -0.3mm de encolhimento (quase neutro)
    /// e mesmo assim sentido como pequeno; (2) segundo caso relatou "extremamente pequeno" nos
    /// dois eixos; (3) rosto 170.9mm/124.6mm (razão 1.37, Nunu feminino) — com o boost de 2.0 já
    /// ativo o encolhimento caiu de -2.6mm (que saturaria o molde) pra -1.7mm, mas ainda foi
    /// sentido como pequeno. 3 casos consistentes no mesmo sentido: não é mais só "borda de rosto
    /// longo", é sinal forte o suficiente pra dobrar a força agora. Ainda sem validação que feche
    /// o número exato — pode passar do necessário pra algum caso; recalibrar com mais provas.
    static let verticalShapeBoostMm: Float = 4.0
    
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

    /// Excedente total aceitável (soma dos 3 eixos, mm) ao ranquear o modelo mais otimizado do
    /// catálogo inteiro (AutoConfiguratorEngine.bestOptimizedModels). Pedido explícito do
    /// Gabriel: sempre indicar o melhor encaixe possível entre TODAS as linhas, aceitando que
    /// às vezes vai estourar "uma pequena quantidade" em vez de nunca recomendar nada. Sem
    /// validação por prova física ainda.
    static let acceptableOverageTolerance: Float = 2.0

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
