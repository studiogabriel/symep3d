import Foundation

/// Estrutura de dados que armazena a identidade visual, marketing e regras de match de cada armação
struct FrameProfile {
    let id: String
    let name: String
    let shape: String // Geometria da armação (Ex: Redondo, Retangular)
    let bestForFaceShapes: [String] // Matriz de formatos de rosto que combinam com ele
    let storytelling: String // O texto de venda/inspiração que você criou
}

/// Motor de Catálogo Inteligente: Isola as descrições comerciais do motor matemático
enum FrameCatalogEngine {
    
    // 🔴 O SEU BANCO DE DADOS DE STORYTELLING ESCALÁVEL
    static let catalog: [FrameProfile] = [
        FrameProfile(
            id: "luno",
            name: "Luno",
            shape: "Redondo Clássico",
            bestForFaceShapes: ["Longo / Retangular", "Quadrado"],
            storytelling: "O modelo Luno foi inspirado nas lunetas, instrumentos que despertam a curiosidade e ampliam horizontes. Pensado para mentes criativas que vivem perguntando “e se?”, o Luno é um convite para enxergar o mundo com olhos atentos e sempre prontos para uma nova aventura.\n\nCom design leve, encaixe confortável e linhas circulares contínuas, ele une leveza e resistência, acompanhando a imaginação em cada descoberta com uma estética vintage e sofisticada."
        ),
        FrameProfile(
            id: "nunu",
            name: "Nunu",
            shape: "Retangular Wayfarer",
            bestForFaceShapes: ["Redondo / Curto", "Oval"],
            storytelling: "Com linhas sólidas e design essencialmente urbano, o modelo Nunu traz a confiança e a estrutura ideais para quem dita o próprio ritmo. É a peça-chave que transita perfeitamente entre a sala de reunião e o happy hour, entregando uma presença marcante sem esforço.\n\nSua estrutura robusta em acetato garante durabilidade e um encaixe primoroso, afinando a expressão facial com máxima sofisticação e conforto para o uso contínuo."
        ),
        FrameProfile(
            id: "suki",
            name: "Suki",
            shape: "Borboleta Geométrico",
            bestForFaceShapes: ["Coração / Triangular", "Oval"],
            storytelling: "O modelo Suki eleva o olhar com seu design borboleta de recortes hexagonais. Feito para destacar as maçãs do rosto e trazer um ar de elegância atemporal, ele é a escolha definitiva para quem não tem medo de expressar sua personalidade e sofisticação em cada detalhe.\n\nA fusão entre ângulos retos no topo e curvas suaves na base cria uma harmonia perfeita. É o equilíbrio exato entre o clássico e o vanguardista, desenhado para empoderar a sua expressão."
        ),
        FrameProfile(
            id: "timbau",
            name: "Timbau",
            shape: "Retangular Geométrico",
            bestForFaceShapes: ["Redondo / Curto", "Oval"],
            storytelling: "Inspirado na força e na precisão matemática dos instrumentos percussivos, o modelo Timbau oferece uma presença inegavelmente marcante. Suas linhas retas e angulares transmitem autoridade, sendo o acessório perfeito para quem valoriza design industrial e conforto visual absoluto.\n\nEsculpido com precisão geométrica em acetato encorpado, ele garante um repouso perfeito na ponte nasal. Uma verdadeira obra de engenharia óptica feita para acompanhar rotinas intensas com elegância e peso visual."
        )
    ]

    /// Cruza o formato do rosto mapeado com a matriz de formatos ideais de cada armação
    static func recommendFrame(faceShape: String) -> FrameProfile {
        let matches = catalog.filter { $0.bestForFaceShapes.contains(faceShape) }
        
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA: Leitura segura de matrizes
        if !matches.isEmpty {
            return matches[ 0 ]
        }
        
        // Fallback universal caso o formato não encontre um par exato
        let safetyFallback = ["suki"]
        let defaultId = safetyFallback[ 0 ]
        return catalog.first(where: { $0.id == defaultId })!
    }
}
