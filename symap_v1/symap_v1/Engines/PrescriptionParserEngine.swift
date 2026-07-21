import Foundation

/// Motor Lógico de Inteligência Artificial Local (OCR Parser)
enum PrescriptionParserEngine {
    
    static func parse(rawText: String) -> ParsedPrescription {
        var result = ParsedPrescription()
        
        // =================================================================
        // 1. FILTRO DE RUÍDO CLÍNICO
        // =================================================================
        var cleanText = " " + rawText.uppercased()
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "\n", with: " \n ") + " "
        
        // Padroniza as bizarrices das receitas brasileiras
        cleanText = cleanText
            .replacingOccurrences(of: "O.D.", with: " OD ")
            .replacingOccurrences(of: "O.E.", with: " OE ")
            .replacingOccurrences(of: "O.D", with: " OD ")
            .replacingOccurrences(of: "O.E", with: " OE ")
            .replacingOccurrences(of: "0.D.", with: " OD ")
            .replacingOccurrences(of: "0.E.", with: " OE ")
            .replacingOccurrences(of: " PL ", with: " 0.00 ") // Resolve Imagem 11.45.22
            .replacingOccurrences(of: " PLANO ", with: " 0.00 ")
            .replacingOccurrences(of: " DE ", with: " ") // Resolve Imagem 11.40.24
            .replacingOccurrences(of: " DC ", with: " ")
            .replacingOccurrences(of: "DC", with: " ")
            .replacingOccurrences(of: "ESF", with: " ")
            .replacingOccurrences(of: "CIL", with: " ")
            .replacingOccurrences(of: "º", with: "°")
            .replacingOccurrences(of: "(°)", with: " ") // Impede que o cabeçalho vire '180'
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
            .replacingOccurrences(of: "+ ", with: "+")
            .replacingOccurrences(of: "- ", with: "-")
            .replacingOccurrences(of: " D ", with: " OD ") // Resolve o Diagrama 11.46.13
            .replacingOccurrences(of: " E ", with: " OE ")
        
        // =================================================================
        // 2. DESTRUIDOR DE FALSOS POSITIVOS (CPF, CRM, DATAS)
        // =================================================================
        var validLines: [String] = []
        for line in cleanText.components(separatedBy: .newlines) {
            let l = line.trimmingCharacters(in: .whitespaces)
            // Se a linha tiver dados inúteis, a IA deleta a linha inteira para não ler o CPF como grau
            if l.contains("CPF") || l.contains("CRM") || l.contains("DATA") || l.contains("CEP") || l.contains("NOME") || l.contains("PACIENTE") {
                continue
            }
            validLines.append(l)
        }
        
        // Regex Blindado: Exige dígito obrigatório. Pega sinais, decimais e graus.
        let pattern = "([+-]?\\d+(?:\\.\\d+)?°?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return result }
        
        var foundODLine = false
        var foundOELine = false
        
        // =================================================================
        // ESTRATÉGIA A: Leitura Clássica Linha a Linha
        // =================================================================
        for line in validLines {
            let nsString = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var numbers: [String] = []
            for match in matches {
                let matchRange = match.range(at: 0) // 🔴 DIRETRIZ ARQUITETURAL
                let numStr = nsString.substring(with: matchRange).trimmingCharacters(in: .whitespaces)
                if numStr != "." && numStr != "-" && numStr != "+" && numStr != "/" {
                    numbers.append(numStr)
                }
            }
            
            let hasOD = line.contains("OD") || line.contains("DIR")
            let hasOE = line.contains("OE") || line.contains("ESQ")
            
            if hasOD && !numbers.isEmpty {
                foundODLine = true
                result.esfOD = formatNumber(numbers[ 0 ], isAxis: false)
                if numbers.count >= 2 { result.cilOD = formatNumber(numbers[ 1 ], isAxis: false) }
                if numbers.count >= 3 { result.eixoOD = formatNumber(numbers[ 2 ], isAxis: true) }
            }
            if hasOE && !numbers.isEmpty {
                foundOELine = true
                result.esfOE = formatNumber(numbers[ 0 ], isAxis: false)
                if numbers.count >= 2 { result.cilOE = formatNumber(numbers[ 1 ], isAxis: false) }
                if numbers.count >= 3 { result.eixoOE = formatNumber(numbers[ 2 ], isAxis: true) }
            }
        }
        
        // =================================================================
        // ESTRATÉGIA B/C: Modo Tabela em Colunas (Mágica Matricial)
        // Se a câmera leu em "Colunas", a Estratégia A falha. Nós acionamos isso:
        // =================================================================
        if (!foundODLine || !foundOELine) && (!result.isValid) {
            let allText = validLines.joined(separator: " ")
            let tokens = allText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            var opticalNumbers: [String] = []
            var odNumbers: [String] = []
            var oeNumbers: [String] = []
            var currentEye = ""
            
            for token in tokens {
                if token == "OD" || token == "DIR" { currentEye = "OD" }
                else if token == "OE" || token == "ESQ" { currentEye = "OE" }
                else {
                    let range = NSRange(location: 0, length: token.utf16.count)
                    if let match = regex.firstMatch(in: token, options: [], range: range) {
                        let numStr = (token as NSString).substring(with: match.range(at: 0))
                        
                        // Trava de segurança: Só aceita se for grau médico real
                        if numStr.contains("+") || numStr.contains("-") || numStr.contains("°") || numStr == "0.00" || (Float(numStr) != nil && Float(numStr)! <= 180) {
                            opticalNumbers.append(numStr)
                            
                            if currentEye == "OD" { odNumbers.append(numStr) }
                            else if currentEye == "OE" { oeNumbers.append(numStr) }
                        }
                    }
                }
            }
            
            // ESTRATÉGIA C: Mágica de Tabela (O OCR juntou OD e OE no topo, e os 6 números embaixo)
            if opticalNumbers.count == 6 && currentEye == "" {
                result.esfOD = formatNumber(opticalNumbers[ 0 ], isAxis: false)
                result.esfOE = formatNumber(opticalNumbers[ 1 ], isAxis: false)
                result.cilOD = formatNumber(opticalNumbers[ 2 ], isAxis: false)
                result.cilOE = formatNumber(opticalNumbers[ 3 ], isAxis: false)
                result.eixoOD = formatNumber(opticalNumbers[ 4 ], isAxis: true)
                result.eixoOE = formatNumber(opticalNumbers[ 5 ], isAxis: true)
            }
            // ESTRATÉGIA B: Mapeamento em Blocos Livres (Para o Diagrama NovOlhar)
            else {
                if result.esfOD.isEmpty && odNumbers.count >= 1 {
                    result.esfOD = formatNumber(odNumbers[ 0 ], isAxis: false)
                    if odNumbers.count >= 2 { result.cilOD = formatNumber(odNumbers[ 1 ], isAxis: false) }
                    if odNumbers.count >= 3 { result.eixoOD = formatNumber(odNumbers[ 2 ], isAxis: true) }
                }
                if result.esfOE.isEmpty && oeNumbers.count >= 1 {
                    result.esfOE = formatNumber(oeNumbers[ 0 ], isAxis: false)
                    if oeNumbers.count >= 2 { result.cilOE = formatNumber(oeNumbers[ 1 ], isAxis: false) }
                    if oeNumbers.count >= 3 { result.eixoOE = formatNumber(oeNumbers[ 2 ], isAxis: true) }
                }
            }
        }
        
        return result
    }
    
    // =================================================================
    // FORMATADOR MATEMÁTICO (Impede +0.00)
    // =================================================================
    private static func formatNumber(_ val: String, isAxis: Bool) -> String {
        let cleanVal = val.replacingOccurrences(of: "°", with: "").replacingOccurrences(of: "O", with: "0")
        guard let floatVal = Float(cleanVal) else { return val }
        
        if floatVal == 0 { return "0.00" } // Transforma plano/pl em 0.00 limpo
        
        if isAxis {
            return String(format: "%.0f°", abs(floatVal))
        } else {
            let sign = floatVal > 0 ? "+" : ""
            return String(format: "%@%.2f", sign, floatVal)
        }
    }
}
