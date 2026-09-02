import UIKit
import PDFKit

/// PDFLaudoBuilder — geração isolada do laudo PDF.
/// Depende só de UIKit/CoreGraphics — independente da ViewController/tela/ARKit.
struct PDFLaudoBuilder {
    // Medições (Float)
    let dnpDir: Float
    let dnpEsq: Float
    let dnpTotal: Float
    let dnpPertoDir: Float
    let dnpPertoEsq: Float
    let dnpPertoTotal: Float
    let faceWidth: Float
    let faceHeight: Float
    let noseBridgeWidth: Float
    let jawWidth: Float
    let cheekboneWidth: Float
    let pupillaryHeight: Float
    let verticalPupilDiff: Float
    let manualFrameHeight: Float
    let manualFrameWidth: Float
    let manualFrameDiagonal: Float
    let currentGlassesLensWidth: Float
    let currentGlassesBridge: Float
    let currentGlassesHaste: Float
    let headMoveScore: Float
    let eyeMoveScore: Float
 
    // Receita (String)
    let rxEsfOD: String
    let rxCilOD: String
    let rxEixoOD: String
    let rxEsfOE: String
    let rxCilOE: String
    let rxEixoOE: String
    let rxEsfPertoOD: String
    let rxCilPertoOD: String
    let rxEixoPertoOD: String
    let rxEsfPertoOE: String
    let rxCilPertoOE: String
    let rxEixoPertoOE: String

    // Metadados (String)
    let patientName: String
    let patientCPF: String
    let selectedLensType: String
    let faceShape: String
    let frameSuggestion: String
    let visionBehaviorResult: String

    // Flag
    let isFrozen: Bool

    // Imagem (snapshot frontal)
    let image: UIImage

    /// Pontos de referência (bolinhas do gêmeo digital) no espaço de tela do snapshot — nil quando
    /// a captura não gerou nenhum ponto válido (ex.: laudo antigo sem esse dado).
    let referencePoints: MeasurementViewController.ReferencePointsScreen?

    /// Medidas finais do óculos "ideal" recriado pro paciente (ponte/largura/vertical alvo, já
    /// com o ajuste físico aplicado) — mesma fonte usada nas barras de capacidade do Resumo Clínico.
    struct IdealGlasses {
        let modelName: String
        let bridge: Float
        let width: Float
        let vertical: Float
    }
    let idealGlasses: IdealGlasses?

    init(measurement m: Measurement, image: UIImage, referencePoints: MeasurementViewController.ReferencePointsScreen? = nil, idealGlasses: IdealGlasses? = nil) {
        self.referencePoints = referencePoints
        self.idealGlasses = idealGlasses
        self.dnpDir = m.dnpDir;  self.dnpEsq = m.dnpEsq;  self.dnpTotal = m.dnpTotal
        self.dnpPertoDir = m.dnpPertoDir;  self.dnpPertoEsq = m.dnpPertoEsq;  self.dnpPertoTotal = m.dnpPertoTotal
        self.faceWidth = m.faceWidth;  self.faceHeight = m.faceHeight;  self.noseBridgeWidth = m.noseBridgeWidth;  self.jawWidth = m.jawWidth;  self.cheekboneWidth = m.cheekboneWidth;  self.pupillaryHeight = m.pupillaryHeight
        self.verticalPupilDiff = m.verticalPupilDiff;  self.manualFrameHeight = m.manualFrameHeight
        self.manualFrameWidth = m.manualFrameWidth;  self.manualFrameDiagonal = m.manualFrameDiagonal
        self.currentGlassesLensWidth = m.currentGlassesLensWidth;  self.currentGlassesBridge = m.currentGlassesBridge
        self.currentGlassesHaste = m.currentGlassesHaste
        self.headMoveScore = m.headMoveScore;  self.eyeMoveScore = m.eyeMoveScore
        self.rxEsfOD = m.rxEsfOD;  self.rxCilOD = m.rxCilOD;  self.rxEixoOD = m.rxEixoOD
        self.rxEsfOE = m.rxEsfOE;  self.rxCilOE = m.rxCilOE;  self.rxEixoOE = m.rxEixoOE
        self.rxEsfPertoOD = m.rxEsfPertoOD;  self.rxCilPertoOD = m.rxCilPertoOD;  self.rxEixoPertoOD = m.rxEixoPertoOD
        self.rxEsfPertoOE = m.rxEsfPertoOE;  self.rxCilPertoOE = m.rxCilPertoOE;  self.rxEixoPertoOE = m.rxEixoPertoOE
        self.patientName = m.patientName;  self.patientCPF = m.patientCPF;  self.selectedLensType = m.selectedLensType
        self.faceShape = m.faceShape;  self.frameSuggestion = m.frameSuggestion;  self.visionBehaviorResult = m.visionBehaviorResult
        self.isFrozen = m.isFrozen
        self.image = image
    }

    private func f(_ value: Float) -> String { return String(format: "%.1f", value) }

    func build() -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let meta = [kCGPDFContextCreator: "Symep Pro", kCGPDFContextAuthor: "System"]
        format.documentInfo = meta as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8), format: format)

        return renderer.pdfData { (context) in

            func desenharCabecalhoWhiteLabel(titulo: String) {
                let techBlack = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
                let techCyan = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
                techBlack.setFill(); context.cgContext.fill(CGRect(x: 0, y: 0, width: 595.2, height: 90))

                if let logoImg = UIImage(named: "Branco") {
                    logoImg.draw(in: CGRect(x: 30, y: 20, width: 50, height: 50))
                    "ÓTICA PARCEIRA".draw(at: CGPoint(x: 90, y: 35), withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .heavy), .foregroundColor: UIColor.white, .kern: 1.5])
                } else {
                    "SYMEP".draw(at: CGPoint(x: 30, y: 25), withAttributes: [.font: UIFont.systemFont(ofSize: 26, weight: .heavy), .foregroundColor: UIColor.white, .kern: 2.0])
                }

                titulo.draw(at: CGPoint(x: 30, y: 70), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 12) ?? UIFont.systemFont(ofSize: 12), .foregroundColor: techCyan])
            }

            let cgContext = context.cgContext
            let techBlack = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            let techCyan = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
            let techTextMain = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            let techLine = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)

            let esfOD = Float(rxEsfOD.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let cilOD = Float(rxCilOD.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let esfOE = Float(rxEsfOE.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let cilOE = Float(rxCilOE.replacingOccurrences(of: ",", with: ".")) ?? 0.0

            let eeOD = esfOD + (cilOD / 2.0)
            let eeOE = esfOE + (cilOE / 2.0)
            let maiorEE = abs(eeOD) > abs(eeOE) ? eeOD : eeOE

            // =========================================================================
            // 📄 PÁGINA 1: ANÁLISE BIOMÉTRICA E VISAGISMO
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()

            desenharCabecalhoWhiteLabel(titulo: "RELATÓRIO DE ANÁLISE BIOMÉTRICA")

            DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short).draw(at: CGPoint(x: 400, y: 35), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray])

            let colX: CGFloat = 30.0
            var cy: CGFloat = 120.0
            let boxW: CGFloat = 535.0

            func drawTechBox(title: String, height: CGFloat, content: () -> Void) {
                let rect = CGRect(x: colX, y: cy, width: boxW, height: height)
                UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: colX, y: cy+5, width: 4, height: height-10), cornerRadius: 2).fill()
                title.uppercased().draw(at: CGPoint(x: colX + 12, y: cy + 8), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor.gray])
                content()
                cy += height + 12
            }

            drawTechBox(title: "Distância Pupilar (DNP)", height: 85) {
                let valFont = UIFont(name: "Courier-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
                let labelFont = UIFont.systemFont(ofSize: 10)
                let totalFont = UIFont.boldSystemFont(ofSize: 16)
                let nearFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
                let cxOE = colX + 80.0;    let cxOD = colX + boxW - 80.0;    let cxTotal = colX + boxW / 2.0;    let startY = cy + 18.0

                func drawCentered(_ text: String, font: UIFont, color: UIColor, cx: CGFloat, y: CGFloat) {   let size = text.size(withAttributes: [.font: font]); text.draw(at: CGPoint(x: cx - size.width/2, y: y), withAttributes: [.font: font, .foregroundColor: color]) }

                drawCentered("OE", font: labelFont, color: .gray, cx: cxOE, y: startY)
                drawCentered("TOTAL (LONGE)", font: labelFont, color: .gray, cx: cxTotal, y: startY)
                drawCentered("OD", font: labelFont, color: .gray, cx: cxOD, y: startY)

                let valY = startY + 14.0
                drawCentered("\(self.f(self.dnpEsq))", font: valFont, color: techBlack, cx: cxOE, y: valY)
                drawCentered("\(self.f(self.dnpTotal)) mm", font: totalFont, color: techCyan, cx: cxTotal, y: valY + 2)
                drawCentered("\(self.f(self.dnpDir))", font: valFont, color: techBlack, cx: cxOD, y: valY)

                let nearY = valY + 30.0
                drawCentered("LEITURA (PERTO): \(self.f(self.dnpPertoTotal)) mm  (OE: \(self.f(self.dnpPertoEsq)) | OD: \(self.f(self.dnpPertoDir)))", font: nearFont, color: .darkGray, cx: cxTotal, y: nearY)
            }

            drawTechBox(title: "Análise Biométrica Avançada", height: 115) {
                let col1X = colX + 30;    let col2X = colX + 280;    var localY = cy + 22;    let rowH: CGFloat = 26
                func drawMetric(label: String, value: String, x: CGFloat, y: CGFloat, highlight: Bool = false) {
                    label.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
                    let fontSize: CGFloat = value.count > 18 ? 10 : 14
                    value.draw(at: CGPoint(x: x, y: y+12), withAttributes: [.font: UIFont(name: "Courier", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize), .foregroundColor: highlight ? techCyan : techTextMain])
                }

                drawMetric(label: "LARGURA FACE", value: "\(self.f(self.faceWidth)) mm", x: col1X, y: localY)
                drawMetric(label: "LARGURA PONTE", value: "\(self.f(self.noseBridgeWidth)) mm", x: col2X, y: localY)
                localY += rowH
                let alt = self.isFrozen ? "\(self.f(self.pupillaryHeight)) mm" : "N/A"
                drawMetric(label: "ALTURA PUPILAR (H)", value: alt, x: col1X, y: localY)
                let diffVal = abs(self.verticalPupilDiff) < 0.5 ? "SIMÉTRICO (\(self.f(abs(self.verticalPupilDiff)))mm)" : (self.verticalPupilDiff > 0 ? "OE MAIS ALTO" : "OD MAIS ALTO")
                drawMetric(label: "DISPARIDADE VERTICAL", value: diffVal, x: col2X, y: localY)
                localY += rowH
                drawMetric(label: "FORMATO DETECTADO", value: self.faceShape, x: col1X, y: localY)
                drawMetric(label: "ALTURA ROSTO", value: "\(self.f(self.faceHeight)) mm", x: col2X, y: localY)
            }

            if self.manualFrameHeight > 0 || self.manualFrameWidth > 0 || self.manualFrameDiagonal > 0 {
                drawTechBox(title: "Medidas da Armação (Manual)", height: 75) {
                    var manualY = cy + 22
                    let attrFont = UIFont(name: "Courier", size: 11) ?? UIFont.boldSystemFont(ofSize: 14)
                    if self.manualFrameHeight > 0 { "ALT. LENTE (H): \(self.f(self.manualFrameHeight))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                    if self.manualFrameWidth > 0 { "LARG. LENTE (W): \(self.f(self.manualFrameWidth))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                    if self.manualFrameDiagonal > 0 { "DIAGONAL (Ø): \(self.f(self.manualFrameDiagonal))mm".draw(at: CGPoint(x: colX + 15, y: manualY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); manualY += 15 }
                }
            }

            if self.currentGlassesLensWidth > 0 || self.currentGlassesBridge > 0 || self.currentGlassesHaste > 0 {
                drawTechBox(title: "Armação Atual do Paciente (Gravada)", height: 75) {
                    var glassesY = cy + 22
                    let attrFont = UIFont(name: "Courier", size: 11) ?? UIFont.boldSystemFont(ofSize: 14)
                    if self.currentGlassesLensWidth > 0 { "ARO: \(self.f(self.currentGlassesLensWidth))mm".draw(at: CGPoint(x: colX + 15, y: glassesY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); glassesY += 15 }
                    if self.currentGlassesBridge > 0 { "PONTE: \(self.f(self.currentGlassesBridge))mm".draw(at: CGPoint(x: colX + 15, y: glassesY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); glassesY += 15 }
                    if self.currentGlassesHaste > 0 { "HASTE: \(self.f(self.currentGlassesHaste))mm".draw(at: CGPoint(x: colX + 15, y: glassesY), withAttributes: [.font: attrFont, .foregroundColor: techTextMain]); glassesY += 15 }
                }
            }

            let visY = cy
            let orderY: CGFloat = 690.0
            let visH: CGFloat = orderY - visY - 15.0
            let visRect = CGRect(x: 30, y: visY, width: 535, height: visH)
            UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: visRect, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: visY, width: 6, height: visH), cornerRadius: 6).fill()

            "CONSULTORIA DE ESTILO E VISAGISMO (IA)".draw(at: CGPoint(x: 50, y: visY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])
            "TAMANHO RECOMENDADO:".draw(at: CGPoint(x: 50, y: visY + 35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.gray])

            let sizeRec = self.faceWidth < 128 ? "PEQUENO (S)" : (self.faceWidth < 140 ? "MÉDIO (M)" : "GRANDE (L)")
            let hasteRec = self.faceWidth < 128 ? "Haste 130-135mm" : (self.faceWidth < 140 ? "Haste 140mm" : "Haste 145mm+")
            "\(sizeRec) - \(hasteRec)".draw(at: CGPoint(x: 50, y: visY + 50), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techCyan])

            var extraTips = ""
            if self.faceShape.contains("Longo") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Para rostos alongados, hastes com detalhes contrastantes ou armações mais grossas ajudam a 'cortar' o rosto horizontalmente, adicionando uma agradável largura visual. Cores degradê (escuras na parte superior e translúcidas na inferior) também encurtam perfeitamente a extensão do rosto. Aposte em pontes mais baixas no nariz."
            } else if self.faceShape.contains("Oval") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Com proporções já geometricamente ideais, você tem total liberdade na escolha! Brinque com texturas ousadas, peças em acetato translúcido e designs hiper-geométricos. Apenas certifique-se de que a largura total da armação empate de forma exata com a parte mais larga do seu rosto para manter a simetria orgânica."
            } else if self.faceShape.contains("Redondo") {
                extraTips = "\n\n✨ DICAS AVANÇADAS: O segredo clínico aqui é criar linhas de expressão estruturadas artificiais. Armações retangulares e poligonais farão seu rosto parecer imediatamente mais afinado e comprido. Hastes presas na parte superior da armação elevam o centro de gravidade e destacam com força o seu olhar."
            } else {
                extraTips = "\n\n✨ DICAS AVANÇADAS: Para maxilares afinados, chame atenção para o topo. Cores fortes na barra superior (como o estilo Clubmaster/Browline) elevam a expressão. Recomendamos manter a metade inferior da lente limpa, utilizando preferencialmente o estilo Nylor (fio de nylon) para não sobrecarregar as maçãs do rosto com acetato."
            }

            let fullVisagismText = self.frameSuggestion + extraTips
            let textRect = CGRect(x: 50, y: visY + 75, width: 495, height: visH - 90)
            let style = NSMutableParagraphStyle(); style.alignment = .justified; style.lineSpacing = 5
            let attrStr = NSAttributedString(string: fullVisagismText, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: techTextMain, .paragraphStyle: style])
            attrStr.draw(in: textRect)

            let orderRect = CGRect(x: 30, y: orderY, width: 535, height: 90)
            UIColor(white: 0.95, alpha: 1.0).setFill(); UIBezierPath(roundedRect: orderRect, cornerRadius: 6).fill()
            "ESPECIFICAÇÕES DO PEDIDO".draw(at: CGPoint(x: 45, y: orderY+12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])

            "TIPO DE LENTE:".draw(at: CGPoint(x: 45, y: orderY+35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            self.selectedLensType.uppercased().draw(at: CGPoint(x: 45, y: orderY+48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techCyan])

            "NOME DO PACIENTE / CPF:".draw(at: CGPoint(x: 240, y: orderY+35), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            let notes = "\(self.patientName) (\(self.patientCPF))"
            notes.draw(at: CGPoint(x: 240, y: orderY+48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techTextMain])

            let footerY = orderRect.maxY + 15
            let line = UIBezierPath(); line.move(to: CGPoint(x: 30, y: footerY)); line.addLine(to: CGPoint(x: 565, y: footerY)); UIColor.lightGray.setStroke(); line.lineWidth = 0.5; line.stroke()

            "RELATÓRIO GERADO PELO SISTEMA | SYMEP v2.2 | BIOMETRIA SEGURA".draw(at: CGPoint(x: 30, y: footerY + 10), withAttributes: [.font: UIFont(name: "Courier", size: 9) ?? UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])

            // =========================================================================
            // 📄 PÁGINA 2: GABARITO DE BLOQUEIO E MONTAGEM
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()

            desenharCabecalhoWhiteLabel(titulo: "GABARITO DE BLOQUEIO E DESCENTRAÇÃO (1:1)")

            let h = self.pupillaryHeight
            var seloCor: UIColor = .clear;   var seloTitulo = "";   var seloDesc = ""

            if h >= 21.0 { seloCor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0); seloTitulo = "✅ APROVADO: CORREDOR MULTIFOCAL LONGO (14mm+)"; seloDesc = "Excelente espaço vertical. Proporciona amplo campo de visão para leitura e transição suave." }
            else if h >= 16.0 { seloCor = UIColor.systemOrange; seloTitulo = "⚠️ ATENÇÃO: CORREDOR MULTIFOCAL CURTO (11 a 13mm)"; seloDesc = "Montagem requer precisão milimétrica. O campo de visão de perto (leitura) será mais estreito." }
            else if h > 0.0 { seloCor = UIColor.red; seloTitulo = "❌ ALERTA CRÍTICO: INCOMPATÍVEL COM LENTES MULTIFOCAIS"; seloDesc = "Altura pupilar muito baixa (\(self.f(h))mm). A área de leitura será cortada fisicamente pela máquina facetadora." }
            else { seloCor = UIColor.gray; seloTitulo = "ℹ️ LAUDO DE MULTIFOCAL: AGUARDANDO MEDIÇÃO"; seloDesc = "Utilize a ferramenta de Altura (H) na tela principal para gerar a recomendação do corredor." }

            let seloRect = CGRect(x: 30, y: 110, width: 535, height: 45)
            seloCor.withAlphaComponent(0.08).setFill(); UIBezierPath(roundedRect: seloRect, cornerRadius: 8).fill()
            seloCor.setStroke();   let seloBorder = UIBezierPath(roundedRect: seloRect, cornerRadius: 8); seloBorder.lineWidth = 1.5; seloBorder.stroke()

            seloTitulo.draw(at: CGPoint(x: 45, y: 118), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: seloCor])
            seloDesc.draw(at: CGPoint(x: 45, y: 135), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: techBlack])

            let dcgMetade = (self.manualFrameWidth + self.noseBridgeWidth) / 2.0
            let mm: CGFloat = 2.83465
            let yCentroBlocos: CGFloat = 330.0;   let xDereito: CGFloat = 160.0;   let xEsquerdo: CGFloat = 595.2 - 160.0

            func desenharBlocoMateriaPrima(cx: CGFloat, cy: CGFloat, dnpOlho: Float, titulo: String) {
                cgContext.saveGState()
                let textY = cy - ((75.0 / 2.0) * mm) - 50.0
                titulo.draw(at: CGPoint(x: cx - 75, y: textY), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .heavy), .foregroundColor: techBlack])
                "GABARITO TÉCNICO VIRTUAL".draw(at: CGPoint(x: cx - 65, y: textY + 22), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: techCyan])

                let raioBlocoBase = (75.0 / 2.0) * mm
                UIColor.lightGray.withAlphaComponent(0.8).setStroke(); cgContext.setLineWidth(0.5); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])

                cgContext.move(to: CGPoint(x: cx, y: cy - raioBlocoBase - 35)); cgContext.addLine(to: CGPoint(x: cx, y: cy + raioBlocoBase + 35))
                cgContext.move(to: CGPoint(x: cx - raioBlocoBase - 35, y: cy)); cgContext.addLine(to: CGPoint(x: cx + raioBlocoBase + 35, y: cy)); cgContext.strokePath()

                let axisFont = UIFont.systemFont(ofSize: 9, weight: .bold)
                "90°".draw(at: CGPoint(x: cx - 8, y: cy - raioBlocoBase + 15), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])
                "0°".draw(at: CGPoint(x: cx + raioBlocoBase + 10, y: cy + 4), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])
                "180°".draw(at: CGPoint(x: cx - raioBlocoBase - 30, y: cy + 4), withAttributes: [.font: axisFont, .foregroundColor: UIColor.gray])

                cgContext.setLineDash(phase: 0, lengths: [])
                let rectBloco = CGRect(x: cx - raioBlocoBase, y: cy - raioBlocoBase, width: raioBlocoBase * 2, height: raioBlocoBase * 2)
                UIColor.white.withAlphaComponent(0.9).setFill(); cgContext.fillEllipse(in: rectBloco)
                techCyan.setStroke(); cgContext.setLineWidth(2.0); cgContext.strokeEllipse(in: rectBloco)

                let raioUtil = raioBlocoBase - (5.0 * mm)
                if raioUtil > 0 {  let rectUtil = CGRect(x: cx - raioUtil, y: cy - raioUtil, width: raioUtil * 2, height: raioUtil * 2); techCyan.withAlphaComponent(0.3).setStroke(); cgContext.setLineWidth(1.0); cgContext.setLineDash(phase: 0, lengths: [2.0, 4.0]); cgContext.strokeEllipse(in: rectUtil) }

                cgContext.setLineDash(phase: 0, lengths: [])
                UIColor.lightGray.setStroke(); cgContext.setLineWidth(0.5)
                cgContext.move(to: CGPoint(x: cx - 15, y: cy)); cgContext.addLine(to: CGPoint(x: cx + 15, y: cy))
                cgContext.move(to: CGPoint(x: cx, y: cy - 15)); cgContext.addLine(to: CGPoint(x: cx, y: cy + 15)); cgContext.strokePath()

                let shiftDNP = (dcgMetade - dnpOlho) * Float(mm)
                let alturaValida = self.pupillaryHeight >= 10.0 && self.pupillaryHeight <= 40.0
                let shiftAltura = alturaValida ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) * Float(mm) : 0.0

                let direcaoInvertida: CGFloat = titulo.contains("OD") ? 1.0 : -1.0
                let cxOtico = cx + (CGFloat(shiftDNP) * direcaoInvertida)
                let cyOtico = cy - CGFloat(shiftAltura)

                // Cruz de Montagem
                UIColor.red.setStroke(); cgContext.setLineWidth(1.5); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
                cgContext.move(to: CGPoint(x: cxOtico, y: cyOtico - 25)); cgContext.addLine(to: CGPoint(x: cxOtico, y: cyOtico + 25))
                cgContext.move(to: CGPoint(x: cxOtico - 25, y: cyOtico)); cgContext.addLine(to: CGPoint(x: cxOtico + 25, y: cyOtico)); cgContext.strokePath()

                cgContext.setLineDash(phase: 0, lengths: []); UIColor.red.setFill(); cgContext.fillEllipse(in: CGRect(x: cxOtico - 3.5, y: cyOtico - 3.5, width: 7, height: 7))

                let textoMira = alturaValida ? "CENTRO" : "ALTURA (H) NÃO MEDIDA"
                textoMira.draw(at: CGPoint(x: cxOtico + 8, y: cyOtico + 5), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.red])

                // =======================================================
                // 🔴 NOVO: GABARITO DE MARCAÇÕES A LASER DA LENTE MULTIFOCAL
                // =======================================================
                let laserDist = 17.0 * CGFloat(mm) // Distância padrão internacional de 17mm a partir do centro
                let laserLeftX = cxOtico - laserDist
                let laserRightX = cxOtico + laserDist

                UIColor.gray.withAlphaComponent(0.8).setStroke()
                cgContext.setLineWidth(0.8)
                let radiusLaser: CGFloat = 2.0

                // Círculos invisíveis (Laser)
                cgContext.strokeEllipse(in: CGRect(x: laserLeftX - radiusLaser, y: cyOtico - radiusLaser, width: radiusLaser * 2, height: radiusLaser * 2))
                cgContext.strokeEllipse(in: CGRect(x: laserRightX - radiusLaser, y: cyOtico - radiusLaser, width: radiusLaser * 2, height: radiusLaser * 2))

                // Legenda Nasal (N) e Temporal (T) inteligente por olho
                let txtNasal = titulo.contains("OD") ? "N" : "T"
                let txtTemp = titulo.contains("OD") ? "T" : "N"
                txtNasal.draw(at: CGPoint(x: laserLeftX - 8, y: cyOtico - 3), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 5), .foregroundColor: UIColor.gray])
                txtTemp.draw(at: CGPoint(x: laserRightX + 4, y: cyOtico - 3), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 5), .foregroundColor: UIColor.gray])

                cgContext.restoreGState()
            }

            desenharBlocoMateriaPrima(cx: xDereito, cy: yCentroBlocos, dnpOlho: self.dnpDir, titulo: "LENTE DIREITA (OD)")
            desenharBlocoMateriaPrima(cx: xEsquerdo, cy: yCentroBlocos, dnpOlho: self.dnpEsq, titulo: "LENTE ESQUERDA (OE)")

            let labY: CGFloat = 530
            let rectLab = CGRect(x: 30, y: labY, width: 535, height: 160)
            UIColor.white.setFill(); UIBezierPath(roundedRect: rectLab, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: labY, width: 4, height: 160), cornerRadius: 6).fill()

            "INSTRUÇÕES DE BLOQUEIO E LEITURA".draw(at: CGPoint(x: 45, y: labY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])

            let deltaX_OD = dcgMetade - self.dnpDir
            let deltaX_OE = dcgMetade - self.dnpEsq
            let deltaY = self.pupillaryHeight > 0 ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) : 0.0

            let decentracaoObliquaOD = sqrt(pow(deltaX_OD, 2) + pow(deltaY, 2))
            let decentracaoObliquaOE = sqrt(pow(deltaX_OE, 2) + pow(deltaY, 2))
            let maxDecentration = max(decentracaoObliquaOD, decentracaoObliquaOE)
            let edEfetivo = self.manualFrameDiagonal > 0 ? (self.manualFrameDiagonal + (maxDecentration * 2.0)) : 0.0

            let labFont = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
            let lblFont = UIFont.systemFont(ofSize: 10)

            var lh = labY + 45
            let col1X: CGFloat = 45;   let val1X: CGFloat = 175
            "DNP LONGE (OD / OE):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.dnpDir)) / \(self.f(self.dnpEsq))".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); lh += 22
            "DNP PERTO (OD / OE):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.dnpPertoDir)) / \(self.f(self.dnpPertoEsq))".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techCyan]); lh += 22
            "ALTURA PUPILAR (H):".draw(at: CGPoint(x: col1X, y: lh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "\(self.f(self.pupillaryHeight)) mm".draw(at: CGPoint(x: val1X, y: lh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); lh += 22

            UIColor.lightGray.withAlphaComponent(0.3).setStroke()
            cgContext.setLineWidth(1.0); cgContext.move(to: CGPoint(x: 290, y: labY + 45)); cgContext.addLine(to: CGPoint(x: 290, y: labY + 105)); cgContext.strokePath()

            var rh = labY + 45
            let col2X: CGFloat = 310;   let val2X: CGFloat = 430
            "COORDENADA EIXO X:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ΔX: \(self.f(deltaX_OD)) / \(self.f(deltaX_OE))".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); rh += 22
            "COORDENADA EIXO Y:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ΔY: \(self.f(deltaY)) mm".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack]); rh += 22
            "DIÂMETRO EFETIVO:".draw(at: CGPoint(x: col2X, y: rh), withAttributes: [.font: lblFont, .foregroundColor: UIColor.gray])
            "ED MÁX: \(self.f(edEfetivo)) mm".draw(at: CGPoint(x: val2X, y: rh - 2), withAttributes: [.font: labFont, .foregroundColor: techBlack])

            if self.manualFrameWidth > 0 && self.manualFrameDiagonal > 0 {
                let boxMontY = labY + 160 + 15
                let boxMontH: CGFloat = 80
                let rectMont = CGRect(x: 30, y: boxMontY, width: 535, height: boxMontH)
                UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: rectMont, cornerRadius: 6).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: boxMontY, width: 4, height: boxMontH), cornerRadius: 6).fill()

                "DADOS DE MONTAGEM E LABORATÓRIO".draw(at: CGPoint(x: 45, y: boxMontY + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])

                let menorDNP = min(dnpEsq, dnpDir)
                let dcg = manualFrameWidth + noseBridgeWidth
                let edMax = max(manualFrameDiagonal, manualFrameWidth, manualFrameHeight)
                let descentracao = abs(dcg - (menorDNP * 2))
                let mbs = edMax > 0 ? (edMax + descentracao + 2.0) : 0.0

                var blocoComercial = mbs > 0 ? ceil(mbs / 5.0) * 5.0 : 0.0
                if blocoComercial > 0 && blocoComercial < 65.0 { blocoComercial = 65.0 }

                let attrFontMont = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
                "DCG TOTAL DA ARMAÇÃO: \(self.f(dcg)) mm".draw(at: CGPoint(x: 45, y: boxMontY + 35), withAttributes: [.font: attrFontMont, .foregroundColor: techTextMain])
                "DNP MÉDIA DA ARMAÇÃO: \(self.f(dcg / 2.0)) mm".draw(at: CGPoint(x: 45, y: boxMontY + 55), withAttributes: [.font: attrFontMont, .foregroundColor: techCyan])
                "DIÂMETRO EXATO (MBS): \(self.f(mbs)) mm".draw(at: CGPoint(x: 310, y: boxMontY + 35), withAttributes: [.font: attrFontMont, .foregroundColor: techTextMain])
                "TAMANHO BLOCO IDEAL:  \(Int(blocoComercial)) mm".draw(at: CGPoint(x: 310, y: boxMontY + 55), withAttributes: [.font: attrFontMont, .foregroundColor: techCyan])
            }

            UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
            cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
            "IMPRIMIR SEMPRE EM ESCALA 100% (SEM AJUSTAR À PÁGINA) MANTENDO PROPORÇÃO 1:1 A4".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.red])

            // =========================================================================
            // 📄 PÁGINA 3: MAPEAMENTO DE COMPORTAMENTO VISUAL (IA)
            // =========================================================================
            if self.selectedLensType != "Visão Simples" {
                context.beginPage()
                cgContext.saveGState()
                cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
                for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
                for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
                cgContext.strokePath()
                cgContext.restoreGState()

                desenharCabecalhoWhiteLabel(titulo: "LAUDO DE COMPORTAMENTO VISUAL (IA)")

                let p3BoxY: CGFloat = 120.0
                let p3BoxH: CGFloat = 190.0
                let rectP3 = CGRect(x: 30, y: p3BoxY, width: 535, height: p3BoxH)

                UIColor.white.setFill(); UIBezierPath(roundedRect: rectP3, cornerRadius: 8).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: p3BoxY, width: 6, height: p3BoxH), cornerRadius: 8).fill()

                "DIAGNÓSTICO COMPORTAMENTAL DE RASTREAMENTO OCULAR:".draw(at: CGPoint(x: 50, y: p3BoxY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.gray])

                let diagColor = self.visionBehaviorResult.contains("Cabeça") ? UIColor.systemOrange : UIColor.systemBlue
                self.visionBehaviorResult.uppercased().draw(at: CGPoint(x: 50, y: p3BoxY + 35), withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .heavy), .foregroundColor: diagColor])

                var recText = ""
                if self.visionBehaviorResult.contains("Cabeça") { recText = "O paciente utiliza predominantemente a rotação do pescoço (cervical) para focar em objetos nas áreas periféricas e na transição para a zona de leitura.\n\n✔️ RECOMENDAÇÃO TÉCNICA:\nLentes multifocais com corredor progressivo Suave (Soft Design). Campos visuais periféricos moderados são bem tolerados, uma vez que o paciente naturalmente centraliza a cabeça em direção ao alvo." }
                else if self.visionBehaviorResult.contains("Olhos") { recText = "O paciente utiliza predominantemente a rotação do globo ocular para focar em objetos periféricos e buscar a zona de leitura, mantendo a cabeça estática.\n\n✔️ RECOMENDAÇÃO TÉCNICA:\nLentes multifocais de Altíssima Performance (Hard Design / Freeform Avançado). É estritamente necessário fornecer zonas periféricas extremamente largas e livre de aberrações, pois o paciente varre as bordas da lente." }
                else { recText = "Mapeamento interativo não realizado nesta sessão.\n\nRecomendamos a execução do teste na tela principal para gerar precisão clínica no desenho da lente multifocal." }

                let pStyle = NSMutableParagraphStyle(); pStyle.alignment = .justified; pStyle.lineSpacing = 5
                let attrRec = NSAttributedString(string: recText, attributes: [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: techTextMain, .paragraphStyle: pStyle])
                attrRec.draw(in: CGRect(x: 50, y: p3BoxY + 75, width: 490, height: 100))

                let chartY = p3BoxY + p3BoxH + 20
                let chartH: CGFloat = 300
                let chartW: CGFloat = 535
                let chartRect = CGRect(x: 30, y: chartY, width: chartW, height: chartH)

                UIColor.white.setFill(); UIBezierPath(roundedRect: chartRect, cornerRadius: 8).fill()
                techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: chartY, width: 6, height: chartH), cornerRadius: 8).fill()

                "MAPA TOPOGRÁFICO DE COMPORTAMENTO VISUAL".draw(at: CGPoint(x: 50, y: chartY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])

                let p3PlotCX = chartRect.midX
                let p3PlotCY = chartY + 160
                let topoRadius: CGFloat = 95.0

                cgContext.saveGState()
                cgContext.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: UIColor.black.withAlphaComponent(0.2).cgColor)
                let bgCircle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: topoRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                UIColor.white.setFill()
                bgCircle.fill()
                cgContext.setShadow(offset: .zero, blur: 0, color: nil)
                bgCircle.addClip()

                let colors = [
                    UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0).cgColor
                ] as CFArray

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.25, 0.5, 0.75, 1.0])!
                cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), startRadius: 0, endCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), endRadius: topoRadius, options: [])
                cgContext.restoreGState()

                cgContext.saveGState()
                UIColor.white.withAlphaComponent(0.6).setStroke()
                cgContext.setLineWidth(0.5)

                for i in 1...4 {
                    let r = (topoRadius / 4.0) * CGFloat(i)
                    let circle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    circle.stroke()
                }

                for angle in stride(from: 0, to: 360, by: 30) {
                    let rad = CGFloat(angle) * .pi / 180.0
                    cgContext.move(to: CGPoint(x: p3PlotCX, y: p3PlotCY))
                    cgContext.addLine(to: CGPoint(x: p3PlotCX + topoRadius * cos(rad), y: p3PlotCY + topoRadius * sin(rad)))
                }
                cgContext.strokePath()

                UIColor.white.setStroke()
                cgContext.setLineWidth(1.0)
                cgContext.move(to: CGPoint(x: p3PlotCX - topoRadius, y: p3PlotCY))
                cgContext.addLine(to: CGPoint(x: p3PlotCX + topoRadius, y: p3PlotCY))
                cgContext.move(to: CGPoint(x: p3PlotCX, y: p3PlotCY - topoRadius))
                cgContext.addLine(to: CGPoint(x: p3PlotCX, y: p3PlotCY + topoRadius))
                cgContext.strokePath()
                cgContext.restoreGState()

                techBlack.setStroke()
                let borderCircle = UIBezierPath(arcCenter: CGPoint(x: p3PlotCX, y: p3PlotCY), radius: topoRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                borderCircle.lineWidth = 2.0
                borderCircle.stroke()

                let fontAxis = UIFont.systemFont(ofSize: 9, weight: .bold)
                "Rotação Cervical (Head) ➔".draw(at: CGPoint(x: p3PlotCX + topoRadius + 15, y: p3PlotCY - 5), withAttributes: [.font: fontAxis, .foregroundColor: UIColor.systemOrange])
                "Rotação Ocular (Eye) ➔".draw(at: CGPoint(x: p3PlotCX - 50, y: p3PlotCY - topoRadius - 20), withAttributes: [.font: fontAxis, .foregroundColor: techCyan])

                let totalScore = max(self.headMoveScore + self.eyeMoveScore, 0.001)
                let pctEye = CGFloat(self.eyeMoveScore / totalScore)
                let pctHead = CGFloat(self.headMoveScore / totalScore)
                let offsetX = (pctHead - 0.5) * 2.0 * topoRadius * 0.8
                let offsetY = (pctEye - 0.5) * 2.0 * topoRadius * 0.8
                let pointX = p3PlotCX + offsetX
                let pointY = p3PlotCY - offsetY

                cgContext.saveGState()
                UIColor.black.setStroke()
                cgContext.setLineWidth(2.0)
                cgContext.move(to: CGPoint(x: pointX - 10, y: pointY))
                cgContext.addLine(to: CGPoint(x: pointX + 10, y: pointY))
                cgContext.move(to: CGPoint(x: pointX, y: pointY - 10))
                cgContext.addLine(to: CGPoint(x: pointX, y: pointY + 10))
                cgContext.strokePath()

                UIColor.white.setFill()
                cgContext.fillEllipse(in: CGRect(x: pointX - 4, y: pointY - 4, width: 8, height: 8))
                UIColor.black.setFill()
                cgContext.fillEllipse(in: CGRect(x: pointX - 2, y: pointY - 2, width: 4, height: 4))

                let lblBox = CGRect(x: pointX + 12, y: pointY - 20, width: 95, height: 18)
                techBlack.setFill(); UIBezierPath(roundedRect: lblBox, cornerRadius: 4).fill()
                "FOCO DO PACIENTE".draw(at: CGPoint(x: pointX + 15, y: pointY - 17), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.white])
                cgContext.restoreGState()

                let scaleX = p3PlotCX - topoRadius - 65
                let scaleY = p3PlotCY - 50
                let scaleW: CGFloat = 10
                let scaleH: CGFloat = 100

                cgContext.saveGState()
                let scalePath = UIBezierPath(roundedRect: CGRect(x: scaleX, y: scaleY, width: scaleW, height: scaleH), cornerRadius: 4)
                scalePath.addClip()
                cgContext.drawLinearGradient(gradient, start: CGPoint(x: scaleX, y: scaleY), end: CGPoint(x: scaleX, y: scaleY + scaleH), options: [])
                cgContext.restoreGState()

                techBlack.setStroke()
                let scaleBorder = UIBezierPath(roundedRect: CGRect(x: scaleX, y: scaleY, width: scaleW, height: scaleH), cornerRadius: 4)
                scaleBorder.lineWidth = 1.0
                scaleBorder.stroke()

                "Alta Intens.".draw(at: CGPoint(x: scaleX - 15, y: scaleY - 15), withAttributes: [.font: UIFont.systemFont(ofSize: 7, weight: .bold), .foregroundColor: UIColor.red])
                "Baixa Intens.".draw(at: CGPoint(x: scaleX - 15, y: scaleY + scaleH + 5), withAttributes: [.font: UIFont.systemFont(ofSize: 7, weight: .bold), .foregroundColor: UIColor.blue])

                let explY = chartY + chartH + 15
                let explRect = CGRect(x: 30, y: explY, width: 535, height: 135)
                UIColor(white: 0.97, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: explRect, cornerRadius: 8).fill()
                techCyan.setFill()
                UIBezierPath(roundedRect: CGRect(x: 30, y: explY, width: 4, height: 135), cornerRadius: 8).fill()

                "💡 ENTENDENDO O SEU MAPA TOPOGRÁFICO:".draw(at: CGPoint(x: 45, y: explY + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: techCyan])

                var mapExplanation = ""
                if self.visionBehaviorResult.contains("Cabeça") {
                    mapExplanation = "A mira no gráfico acima revela a sua assinatura visual. O seu ponto de foco cruzou o eixo horizontal, confirmando que você é um 'Movimentador de Cabeça'. Isso significa que, para olhar para as laterais, você instintivamente vira o pescoço em vez de usar a visão periférica dos olhos. Lentes multifocais padrão costumam proporcionar uma adaptação incrivelmente fácil e natural para a sua fisiologia."
                } else if self.visionBehaviorResult.contains("Olhos") {
                    mapExplanation = "A mira no gráfico acima revela a sua assinatura visual. O seu ponto de foco cruzou o eixo vertical, confirmando que você é um 'Movimentador de Olhos'. Você possui o hábito de mover os olhos para explorar os cantos da armação enquanto mantém a cabeça estática. O seu perfil visual exige a confecção de lentes com tecnologia Freeform Avançada, garantindo bordas panorâmicas perfeitamente limpas."
                } else {
                    mapExplanation = "Mapeamento topográfico pendente. O paciente ainda não realizou o rastreamento interativo com o sensor infravermelho TrueDepth para gerar a mira de foco visual."
                }

                let styleMap = NSMutableParagraphStyle()
                styleMap.alignment = .justified
                styleMap.lineSpacing = 4
                let attrExpl = NSAttributedString(string: mapExplanation, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: techTextMain, .paragraphStyle: styleMap])
                attrExpl.draw(in: CGRect(x: 45, y: explY + 32, width: 505, height: 100))

                UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
                cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
                "ANEXO EXCLUSIVO PARA O CONSULTOR ÓPTICO - SYMEP v2.2".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
            }

            // =========================================================================
            // 📄 PÁGINA 4: PRESCRIÇÃO CLÍNICA E ENGENHARIA ÓPTICA
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()

            desenharCabecalhoWhiteLabel(titulo: "PRESCRIÇÃO CLÍNICA E ENGENHARIA ÓPTICA")

            let p4BoxY: CGFloat = 120.0
            let isMultiLocal_P4 = self.selectedLensType == "Multifocal"
            let recRect_P4 = CGRect(x: 30, y: p4BoxY, width: 535, height: isMultiLocal_P4 ? 190 : 120)

            UIColor.white.setFill(); UIBezierPath(roundedRect: recRect_P4, cornerRadius: 8).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: p4BoxY, width: 6, height: recRect_P4.height), cornerRadius: 8).fill()

            "DADOS DA PRESCRIÇÃO OFTALMOLÓGICA".draw(at: CGPoint(x: 50, y: p4BoxY + 15), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])

            var rxY_P4 = p4BoxY + 45
            "VISÃO DE LONGE:".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
            rxY_P4 += 20
            "OD ➔ ESF: \(self.rxEsfOD)  |  CIL: \(self.rxCilOD)  |  EIXO: \(self.rxEixoOD)".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])
            rxY_P4 += 25
            "OE ➔ ESF: \(self.rxEsfOE)  |  CIL: \(self.rxCilOE)  |  EIXO: \(self.rxEixoOE)".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techBlack])

            let insetOD_P4 = self.dnpDir - self.dnpPertoDir
            let insetOE_P4 = self.dnpEsq - self.dnpPertoEsq

            if isMultiLocal_P4 {
                rxY_P4 += 35
                "VISÃO DE PERTO (ADIÇÃO) E INSET:".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.gray])
                rxY_P4 += 20
                "OD ➔ ESF: \(self.rxEsfPertoOD)  |  CIL: \(self.rxCilPertoOD)  |  EIXO: \(self.rxEixoPertoOD)  |  INSET: \(self.f(insetOD_P4))mm".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), .foregroundColor: techCyan])
                rxY_P4 += 25
                "OE ➔ ESF: \(self.rxEsfPertoOE)  |  CIL: \(self.rxCilPertoOE)  |  EIXO: \(self.rxEixoPertoOE)  |  INSET: \(self.f(insetOE_P4))mm".draw(at: CGPoint(x: 50, y: rxY_P4), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13), .foregroundColor: techCyan])
            }

            let dcgMetade_P4 = (self.manualFrameWidth + self.noseBridgeWidth) / 2.0
            let deltaX_OD_P4 = dcgMetade_P4 - self.dnpDir
            let deltaX_OE_P4 = dcgMetade_P4 - self.dnpEsq
            let deltaY_P4 = self.pupillaryHeight > 0 ? (self.pupillaryHeight - (self.manualFrameHeight / 2.0)) : 0.0

            let decentracaoObliquaOD_P4 = sqrt(pow(deltaX_OD_P4, 2) + pow(deltaY_P4, 2))
            let decentracaoObliquaOE_P4 = sqrt(pow(deltaX_OE_P4, 2) + pow(deltaY_P4, 2))
            let maxDecentration_P4 = max(decentracaoObliquaOD_P4, decentracaoObliquaOE_P4)
            let edEfetivo_P4 = self.manualFrameDiagonal > 0 ? (self.manualFrameDiagonal + (maxDecentration_P4 * 2.0)) : 0.0

            let alertY_P4 = p4BoxY + recRect_P4.height + 20
            let prismaCalculado_P4 = (maxDecentration_P4 / 10.0) * abs(maiorEE)
            let alertRect_P4 = CGRect(x: 30, y: alertY_P4, width: 535, height: 40)

            if prismaCalculado_P4 > 0.5 && maiorEE != 0.0 {
                UIColor.red.withAlphaComponent(0.1).setFill(); UIBezierPath(roundedRect: alertRect_P4, cornerRadius: 4).fill()
                "⚠️ ALERTA PRISMÁTICO CRÍTICO:".draw(at: CGPoint(x: 45, y: alertY_P4 + 8), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.red])
                "O paciente sofrerá um desvio de \(self.f(prismaCalculado_P4)) Δ (Prismas) devido à descentração de \(self.f(maxDecentration_P4))mm.".draw(at: CGPoint(x: 45, y: alertY_P4 + 22), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.red])
            } else {
                UIColor.green.withAlphaComponent(0.1).setFill(); UIBezierPath(roundedRect: alertRect_P4, cornerRadius: 4).fill()
                "✅ MONTAGEM SEGURA: Efeito prismático induzido está sob controle (\(self.f(prismaCalculado_P4)) Δ).".draw(at: CGPoint(x: 45, y: alertY_P4 + 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor(red: 0, green: 0.6, blue: 0, alpha: 1.0)])
            }

            let graphY_P4 = alertY_P4 + 60
            let graphH_P4: CGFloat = 340
            let rectGraph_P4 = CGRect(x: 30, y: graphY_P4, width: 535, height: graphH_P4)
            UIColor.white.setFill(); UIBezierPath(roundedRect: rectGraph_P4, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: graphY_P4, width: 6, height: graphH_P4), cornerRadius: 6).fill()

            "TOPOGRAFIA ÓPTICA E COMPORTAMENTO FÍSICO".draw(at: CGPoint(x: 45, y: graphY_P4 + 10), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: techBlack])

            let plotX_P4: CGFloat = 45
            let plotY_P4: CGFloat = graphY_P4 + 35
            let plotW_P4: CGFloat = 490
            let plotH_P4: CGFloat = 170

            cgContext.saveGState()
            cgContext.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
            cgContext.setLineWidth(0.5)

            for i in 0...4 {
                let yPos_P4 = plotY_P4 + (plotH_P4 / 4) * CGFloat(i)
                cgContext.move(to: CGPoint(x: plotX_P4, y: yPos_P4)); cgContext.addLine(to: CGPoint(x: plotX_P4 + plotW_P4, y: yPos_P4))
            }
            for i in 0...4 {
                let xPos_P4 = plotX_P4 + (plotW_P4 / 4) * CGFloat(i)
                cgContext.move(to: CGPoint(x: xPos_P4, y: plotY_P4)); cgContext.addLine(to: CGPoint(x: xPos_P4, y: plotY_P4 + plotH_P4))
            }
            cgContext.strokePath()

            let graphCX_P4 = plotX_P4 + plotW_P4 / 2
            let graphCY_P4 = plotY_P4 + plotH_P4 / 2

            let pathCorredor_P4 = UIBezierPath()
            pathCorredor_P4.move(to: CGPoint(x: graphCX_P4, y: plotY_P4))
            pathCorredor_P4.addCurve(to: CGPoint(x: graphCX_P4 - 25, y: plotY_P4 + plotH_P4), controlPoint1: CGPoint(x: graphCX_P4, y: plotY_P4 + plotH_P4 * 0.4), controlPoint2: CGPoint(x: graphCX_P4 - 25, y: plotY_P4 + plotH_P4 * 0.6))
            UIColor.systemBlue.setStroke(); pathCorredor_P4.lineWidth = 2.0; pathCorredor_P4.stroke()

            let pathPrisma_P4 = UIBezierPath()
            pathPrisma_P4.move(to: CGPoint(x: plotX_P4, y: plotY_P4 + 10))
            pathPrisma_P4.addQuadCurve(to: CGPoint(x: plotX_P4 + plotW_P4, y: plotY_P4 + 10), controlPoint: CGPoint(x: graphCX_P4, y: plotY_P4 + plotH_P4 + 50))
            UIColor.red.setStroke(); pathPrisma_P4.lineWidth = 1.5; cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0]); pathPrisma_P4.stroke()

            let pathCurva_P4 = UIBezierPath()
            pathCurva_P4.move(to: CGPoint(x: plotX_P4 + 15, y: graphCY_P4 + 10))
            pathCurva_P4.addQuadCurve(to: CGPoint(x: plotX_P4 + plotW_P4 - 15, y: graphCY_P4 + 10), controlPoint: CGPoint(x: graphCX_P4, y: plotY_P4 - 15))
            UIColor(red: 0, green: 0.7, blue: 0, alpha: 1.0).setStroke(); pathCurva_P4.lineWidth = 1.5; cgContext.setLineDash(phase: 0, lengths: [2.0, 2.0]); pathCurva_P4.stroke()

            cgContext.setLineDash(phase: 0, lengths: [])
            cgContext.restoreGState()

            let legY_P4: CGFloat = plotY_P4 + plotH_P4 + 25
            let legTitleFont_P4 = UIFont.systemFont(ofSize: 9, weight: .bold)
            let legDescFont_P4 = UIFont.systemFont(ofSize: 8)

            func desenharLegendaLocal(titulo: String, desc: String, cor: UIColor, dash: [CGFloat], x: CGFloat, y: CGFloat) {
                cgContext.saveGState()
                cor.setStroke(); cgContext.setLineWidth(2.0); cgContext.setLineDash(phase: 0, lengths: dash)
                cgContext.move(to: CGPoint(x: x, y: y + 4)); cgContext.addLine(to: CGPoint(x: x + 18, y: y + 4))
                cgContext.strokePath()
                cgContext.restoreGState()
                titulo.draw(at: CGPoint(x: x + 25, y: y), withAttributes: [.font: legTitleFont_P4, .foregroundColor: techBlack])
                desc.draw(at: CGPoint(x: x + 25, y: y + 12), withAttributes: [.font: legDescFont_P4, .foregroundColor: UIColor.gray])
            }

            desenharLegendaLocal(titulo: "Corredor Progressivo", desc: "Senoide de Convergência", cor: .systemBlue, dash: [], x: 45, y: legY_P4)
            desenharLegendaLocal(titulo: "Estresse Prismático", desc: "Distorção de borda", cor: .red, dash: [4.0, 4.0], x: 220, y: legY_P4)
            desenharLegendaLocal(titulo: "Curvatura Base", desc: "Arco do Menisco", cor: UIColor(red: 0, green: 0.7, blue: 0, alpha: 1.0), dash: [2.0, 2.0], x: 380, y: legY_P4)

            var curvaBaseIdeal_P4: Float = 0.0
            if maiorEE > 0 { curvaBaseIdeal_P4 = maiorEE + 6.0 } else if maiorEE < 0 { curvaBaseIdeal_P4 = (maiorEE / 2.0) + 6.0 }

            let raioLente_P4 = edEfetivo_P4 / 2.0
            var indiceRefracao_P4: Float = 1.50
            var nomeMaterial_P4 = "CR-39 / Resina Comum"

            if abs(maiorEE) > 6.0 {
                indiceRefracao_P4 = 1.74; nomeMaterial_P4 = "Alto Índice (1.74)"
            } else if abs(maiorEE) > 4.0 {
                indiceRefracao_P4 = 1.67; nomeMaterial_P4 = "Resina Média (1.67)"
            } else if abs(maiorEE) > 2.0 {
                indiceRefracao_P4 = 1.59; nomeMaterial_P4 = "Policarbonato (1.59)"
            }

            let espessuraBorda_P4 = (abs(maiorEE) * pow(raioLente_P4, 2)) / (2000.0 * (indiceRefracao_P4 - 1.0))

            var engY_P4 = legY_P4 + 45
            "-> ENGENHARIA ÓPTICA APLICADA:".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .black), .foregroundColor: techCyan])
            engY_P4 += 18

            if maiorEE != 0.0 {
                "Curva Base Recomendada (Sagitta): \(self.f(curvaBaseIdeal_P4))".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
                engY_P4 += 16
                "Espessura Máxima Estimada (\(nomeMaterial_P4)): \(self.f(espessuraBorda_P4)) mm".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
            } else {
                "Aguardando preenchimento da receita para calcular Sagitta e Curva Base.".draw(at: CGPoint(x: 45, y: engY_P4), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray])
            }

            UIColor.lightGray.setStroke(); cgContext.setLineDash(phase: 0, lengths: [4.0, 4.0])
            cgContext.move(to: CGPoint(x: 0, y: 810)); cgContext.addLine(to: CGPoint(x: 595.2, y: 810)); cgContext.strokePath()
            "IMPRIMIR SEMPRE EM ESCALA 100% (SEM AJUSTAR À PÁGINA) MANTENDO PROPORÇÃO 1:1 A4".draw(at: CGPoint(x: 45, y: 815), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.red])

            // =========================================================================
            // 📄 PÁGINA 5: GÊMEO DIGITAL — REFERÊNCIAS DE MEDIÇÃO
            // =========================================================================
            context.beginPage()
            cgContext.saveGState()
            cgContext.setStrokeColor(techLine.cgColor); cgContext.setLineWidth(0.5)
            for x in stride(from: 0.0, through: 595.2, by: 30.0) { cgContext.move(to: CGPoint(x: x, y: 0)); cgContext.addLine(to: CGPoint(x: x, y: 841.8)) }
            for y in stride(from: 0.0, through: 841.8, by: 30.0) { cgContext.move(to: CGPoint(x: 0, y: y)); cgContext.addLine(to: CGPoint(x: 595.2, y: y)) }
            cgContext.strokePath()
            cgContext.restoreGState()

            desenharCabecalhoWhiteLabel(titulo: "GÊMEO DIGITAL — REFERÊNCIAS DE MEDIÇÃO")

            // --- Caixa da imagem (aspect-fit, sem distorcer) ---
            let twinBoxRect = CGRect(x: 30, y: 105, width: 535, height: 480)
            UIColor(white: 0.94, alpha: 1.0).setFill(); UIBezierPath(roundedRect: twinBoxRect, cornerRadius: 8).fill()

            let originalSize = self.referencePoints?.imageSize ?? self.image.size
            let fitScale = originalSize.width > 0 && originalSize.height > 0
                ? min(twinBoxRect.width / originalSize.width, twinBoxRect.height / originalSize.height)
                : 1.0
            let drawnW = originalSize.width * fitScale
            let drawnH = originalSize.height * fitScale
            let imgOriginX = twinBoxRect.minX + (twinBoxRect.width - drawnW) / 2.0
            let imgOriginY = twinBoxRect.minY + (twinBoxRect.height - drawnH) / 2.0
            let imageDrawnRect = CGRect(x: imgOriginX, y: imgOriginY, width: drawnW, height: drawnH)
            self.image.draw(in: imageDrawnRect)
            UIColor.lightGray.withAlphaComponent(0.6).setStroke(); cgContext.setLineWidth(1.0)
            UIBezierPath(roundedRect: twinBoxRect, cornerRadius: 8).stroke()

            // Ponto salvo (espaço do sceneView no instante do snapshot) -> ponto no PDF, aplicando
            // o mesmo fator de escala + centralização usado pra encaixar a imagem na caixa.
            func mapToTwin(_ p: CGPoint) -> CGPoint {
                return CGPoint(x: imgOriginX + p.x * fitScale, y: imgOriginY + p.y * fitScale)
            }

            struct RefMetric { let label: String; let desc: String; let value: Float; let color: UIColor; let a: CGPoint?; let b: CGPoint? }
            let rp = self.referencePoints
            let metrics: [RefMetric] = [
                RefMetric(label: "DNP", desc: "Centro das duas pupilas", value: self.dnpTotal, color: UIColor(red: 0.86, green: 0.0, blue: 0.55, alpha: 1.0), a: rp?.pupilLeft, b: rp?.pupilRight),
                RefMetric(label: "Largura do Rosto", desc: "Têmpora a têmpora, altura dos olhos", value: self.faceWidth, color: techCyan, a: rp?.widthLeft, b: rp?.widthRight),
                RefMetric(label: "Ponte Nasal", desc: "Largura do apoio nasal", value: self.noseBridgeWidth, color: UIColor.systemOrange, a: rp?.bridgeLeft, b: rp?.bridgeRight),
                RefMetric(label: "Mandíbula", desc: "Largura da linha do maxilar", value: self.jawWidth, color: UIColor(red: 0.80, green: 0.62, blue: 0.0, alpha: 1.0), a: rp?.jawLeft, b: rp?.jawRight),
                RefMetric(label: "Maçã do Rosto", desc: "Ponto mais largo da região malar", value: self.cheekboneWidth, color: UIColor.systemPurple, a: rp?.cheekLeft, b: rp?.cheekRight),
                RefMetric(label: "Altura do Rosto", desc: "Da testa à base do queixo", value: self.faceHeight, color: UIColor.systemBlue, a: rp?.foreheadTop, b: rp?.chinBottom)
            ]

            for (index, m) in metrics.enumerated() {
                guard let a = m.a, let b = m.b else { continue }
                let pa = mapToTwin(a); let pb = mapToTwin(b)
                cgContext.saveGState()
                m.color.setStroke(); cgContext.setLineWidth(1.2); cgContext.setLineDash(phase: 0, lengths: [3.0, 2.0])
                cgContext.move(to: pa); cgContext.addLine(to: pb); cgContext.strokePath()
                cgContext.setLineDash(phase: 0, lengths: [])
                m.color.setFill()
                let dotR: CGFloat = 3.5
                cgContext.fillEllipse(in: CGRect(x: pa.x - dotR, y: pa.y - dotR, width: dotR*2, height: dotR*2))
                cgContext.fillEllipse(in: CGRect(x: pb.x - dotR, y: pb.y - dotR, width: dotR*2, height: dotR*2))
                UIColor.white.setStroke(); cgContext.setLineWidth(1.0)
                cgContext.strokeEllipse(in: CGRect(x: pa.x - dotR, y: pa.y - dotR, width: dotR*2, height: dotR*2))
                cgContext.strokeEllipse(in: CGRect(x: pb.x - dotR, y: pb.y - dotR, width: dotR*2, height: dotR*2))
                cgContext.restoreGState()
                let badgeFont = UIFont.boldSystemFont(ofSize: 8)
                "\(index + 1)".draw(at: CGPoint(x: pa.x + 6, y: pa.y - 10), withAttributes: [.font: badgeFont, .foregroundColor: m.color])
            }

            // --- Legenda (grid 2 colunas x 3 linhas) ---
            let legendY: CGFloat = twinBoxRect.maxY + 15
            let legendColW: CGFloat = 267.5
            let legendRowH: CGFloat = 40
            for (index, m) in metrics.enumerated() {
                let col = index % 2
                let row = index / 2
                let lx = 30.0 + CGFloat(col) * legendColW
                let ly = legendY + CGFloat(row) * legendRowH
                m.color.setFill(); cgContext.fillEllipse(in: CGRect(x: lx, y: ly + 2, width: 9, height: 9))
                "\(index + 1). \(m.label): \(self.f(m.value)) mm".draw(at: CGPoint(x: lx + 15, y: ly), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: techBlack])
                m.desc.draw(at: CGPoint(x: lx + 15, y: ly + 14), withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray])
            }

            // --- Óculos ideal recriado ---
            let idealY = legendY + (legendRowH * 3) + 10
            let idealRect = CGRect(x: 30, y: idealY, width: 535, height: 60)
            UIColor(white: 0.97, alpha: 0.95).setFill(); UIBezierPath(roundedRect: idealRect, cornerRadius: 6).fill()
            techCyan.setFill(); UIBezierPath(roundedRect: CGRect(x: 30, y: idealY + 5, width: 4, height: 50), cornerRadius: 2).fill()
            "ÓCULOS IDEAL RECRIADO".draw(at: CGPoint(x: 42, y: idealY + 8), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor.gray])

            if let ideal = self.idealGlasses {
                ideal.modelName.draw(at: CGPoint(x: 42, y: idealY + 22), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: techCyan])
                let idealText = "Ponte: \(self.f(ideal.bridge))mm   |   Largura: \(self.f(ideal.width))mm   |   Altura: \(self.f(ideal.vertical))mm"
                idealText.draw(at: CGPoint(x: 42, y: idealY + 40), withAttributes: [.font: UIFont(name: "Courier-Bold", size: 11) ?? UIFont.boldSystemFont(ofSize: 11), .foregroundColor: techBlack])
            } else {
                "Aguardando seleção do modelo recomendado.".draw(at: CGPoint(x: 42, y: idealY + 25), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray])
            }
        }
    }
}
