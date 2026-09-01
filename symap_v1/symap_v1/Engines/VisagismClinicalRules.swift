import Foundation

/// Central de Parâmetros Clínicos de Visagismo e Ergonomia
/// Altere os valores aqui para calibrar as decisões da Inteligência Artificial
struct VisagismClinicalRules {
    
    // =======================================================
    // 🔴 1. FOLGAS ANATÔMICAS GERAIS (em milímetros)
    // =======================================================
    /// 🔴 Foi 10 → 15mm (2026-08) tentando compensar rostos "pequenos demais" — mas depois
    /// descobrimos que os arquivos 3D estavam com problema de tamanho/capacidade na época
    /// (larguraA tinha metade do curso da malha nova, e 3 dos 4 femininos vieram com a malha
    /// desatualizada). Com o catálogo remodelado (2026-09-01, larguraA dobrou pra 8.0mm em
    /// todos os 12 modelos) o mesmo 15mm passou a ficar grande demais. Volta pro valor
    /// original (10mm) como ponto de partida pra recalibrar do zero com a base agora correta.
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

    /// 🔴 Foi 10 → 14 → 18mm ao longo de 2026-08, subindo a cada prova física que sentia a
    /// armação pequena. Só depois descobrimos a causa raiz real: 3 dos 4 arquivos 3D femininos
    /// (Luno/Suki/Nunu) estavam com a malha desatualizada, 6-8mm mais estreita do que a tabela
    /// de calibração assumia — e a linha feminino, mesmo com o arquivo certo, tinha só metade
    /// do curso de largura da malha nova. Ou seja: boa parte do que essa folga "compensava" era
    /// o bug de asset, não falta de folga de verdade. Com o catálogo remodelado (2026-09-01,
    /// malhas corrigidas + larguraA dobrado pra 8.0mm) volta pro valor original (10mm) como
    /// ponto de partida pra recalibrar do zero.
    static let temporalClearanceFeminino: Float = 10

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
    /// (verticalSquashWeight). Mecanismo continua ligado no código (computeFit), só a força foi
    /// zerada — fica fácil reativar depois que tivermos mais provas com a base 3D corrigida.
    /// 🔴 Foi 0 (recém-criado) → 2.0 → 4.0mm ao longo de 2026-08, subindo a cada prova física
    /// que sentia a vertical pequena. Mesma ressalva do temporalClearanceFeminino: parte desse
    /// "precisa de mais vertical" provavelmente vinha do bug de malha 3D (3 dos 4 femininos
    /// desatualizados), não de uma falta real de empurrão por formato. Desligado (0.0) com o
    /// catálogo remodelado (2026-09-01) — recalibrar do zero com dado real da base corrigida
    /// antes de religar.
    static let verticalShapeBoostMm: Float = 0.0
    
    // =======================================================
    // 🔴 3. LIMITES CLÍNICOS DE GATILHO
    // =======================================================
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
