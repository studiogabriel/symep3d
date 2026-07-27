import Foundation

/// Central de Parâmetros Clínicos de Visagismo e Ergonomia
/// Altere os valores aqui para calibrar as decisões da Inteligência Artificial
struct VisagismClinicalRules {
    
    // =======================================================
    // 🔴 1. FOLGAS ANATÔMICAS GERAIS (em milímetros)
    // =======================================================
    static let temporalClearance: Float = 2.0  // +2.0mm de folga na largura total do rosto
    static let bridgeClearance: Float = 0.75   // +0.75mm de folga na ponte nasal
    
    // =======================================================
    // 🔴 2. INTENSIDADE DAS DEFORMAÇÕES (Pesos de 0.0 a 1.0)
    // =======================================================
    static let nasalSupportWeight: Float = 0.7    // Expansão do apoio nasal para perfil plano
    static let verticalStretchWeight: Float = 0.8 // Aumento da lente para baixo (Rostos Longos)
    static let verticalSquashWeight: Float = 0.8  // Achatamento da lente (Rostos Redondos)
    static let keyholeBridgeWeight: Float = 0.9   // Engrossamento em ferradura (Nariz Fino)
    
    // =======================================================
    // 🔴 3. LIMITES CLÍNICOS DE GATILHO
    // =======================================================
    static let narrowNoseThreshold: Float = 15.0  // Abaixo dessa medida (mm), a IA ativa a Ferradura
}
