import Foundation

/// Estrutura de dados pura para transitar os valores lidos pela IA na Nuvem
struct ParsedPrescription {
    var esfOD: String = ""
    var cilOD: String = ""
    var eixoOD: String = ""
    var esfOE: String = ""
    var cilOE: String = ""
    var eixoOE: String = ""
    
    /// Validação de segurança: exige pelo menos a leitura de um dos olhos
    var isValid: Bool {
        return !esfOD.isEmpty || !esfOE.isEmpty
    }
}
