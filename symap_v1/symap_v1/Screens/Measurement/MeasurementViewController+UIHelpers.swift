import UIKit

// 🔴 COMPONENTES DE UI REUTILIZÁVEIS (accordion + barra de capacidade) — extraídos de
// showVisagismResults (que tinha essa lógica só como closure local) pra também poder usar na
// tela de Resumo Clínico, sem duplicar ~80 linhas de UIKit.
extension MeasurementViewController {

    /// Card retrátil (accordion): clique no header expande/colapsa o corpo. `stackToRelayout` é
    /// o UIStackView pai — precisa de layoutIfNeeded() na animação, senão a altura não anima
    /// suave dentro de uma stack view.
    @discardableResult
    func makeAccordionCard(title: String, contentView: UIView, startExpanded: Bool, stackToRelayout: UIStackView) -> UIView {
        let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
        let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)

        let cardContainer = UIStackView()
        cardContainer.axis = .vertical
        cardContainer.backgroundColor = UIColor(red: 0.118, green: 0.227, blue: 0.431, alpha: 0.25) // Navy Medium translúcido
        cardContainer.layer.cornerRadius = 12
        cardContainer.layer.borderWidth = 1.0
        cardContainer.layer.borderColor = opticalCyan.withAlphaComponent(0.2).cgColor
        cardContainer.clipsToBounds = true

        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Inter-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = offWhite
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let arrowLabel = UILabel()
        arrowLabel.text = startExpanded ? "▼" : "▶"
        arrowLabel.textColor = opticalCyan
        arrowLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(arrowLabel)

        let invisibleBtn = UIButton(type: .custom)
        invisibleBtn.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(invisibleBtn)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowLabel.leadingAnchor, constant: -8),

            arrowLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            arrowLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            invisibleBtn.topAnchor.constraint(equalTo: headerView.topAnchor),
            invisibleBtn.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            invisibleBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            invisibleBtn.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])

        let bodyWrapper = UIView()
        bodyWrapper.translatesAutoresizingMaskIntoConstraints = false
        bodyWrapper.isHidden = !startExpanded

        contentView.translatesAutoresizingMaskIntoConstraints = false
        bodyWrapper.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: bodyWrapper.topAnchor, constant: 4),
            contentView.leadingAnchor.constraint(equalTo: bodyWrapper.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: bodyWrapper.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: bodyWrapper.bottomAnchor, constant: -12)
        ])

        cardContainer.addArrangedSubview(headerView)
        cardContainer.addArrangedSubview(bodyWrapper)

        invisibleBtn.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.25) {
                bodyWrapper.isHidden.toggle()
                arrowLabel.text = bodyWrapper.isHidden ? "▶" : "▼"
                stackToRelayout.layoutIfNeeded()
            }
        }, for: .touchUpInside)

        return cardContainer
    }

    /// Variante em texto simples (a maioria dos casos) — monta o UILabel por dentro.
    @discardableResult
    func makeAccordionCard(title: String, text: String, startExpanded: Bool, stackToRelayout: UIStackView) -> UIView {
        let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)
        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = slateColor
        bodyLabel.font = UIFont(name: "Inter-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .justified
        bodyLabel.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: paragraphStyle])
        return makeAccordionCard(title: title, contentView: bodyLabel, startExpanded: startExpanded, stackToRelayout: stackToRelayout)
    }

    /// Barra de progresso mostrando quanto % da capacidade física do molde foi usado num eixo
    /// (largura/ponte/vertical) — mais rápido de escanear que só o número em mm, e vira alerta
    /// visual natural quando o eixo está perto do limite (laranja acima de 95%).
    func makeCapacityBar(label: String, percent: Float, valueText: String) -> UIView {
        let opticalCyan = UIColor(red: 0.000, green: 0.765, blue: 0.851, alpha: 1.0)
        let offWhite = UIColor(red: 0.949, green: 0.957, blue: 0.973, alpha: 1.0)
        let slateColor = UIColor(red: 0.541, green: 0.608, blue: 0.710, alpha: 1.0)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let clampedPercent = max(0, min(1, percent))
        let barColor = clampedPercent >= 0.95 ? UIColor.systemOrange : opticalCyan

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = UIFont(name: "Inter-SemiBold", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .semibold)
        nameLabel.textColor = offWhite
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = valueText
        valueLabel.font = UIFont(name: "Inter-SemiBold", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .semibold)
        valueLabel.textColor = slateColor
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let track = UIView()
        track.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        track.layer.cornerRadius = 3
        track.translatesAutoresizingMaskIntoConstraints = false

        let fill = UIView()
        fill.backgroundColor = barColor
        fill.layer.cornerRadius = 3
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)

        container.addSubview(nameLabel)
        container.addSubview(valueLabel)
        container.addSubview(track)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),

            track.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 6),
            track.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: CGFloat(clampedPercent))
        ])

        return container
    }

    /// Empilha N barras de capacidade numa UIStackView vertical — conteúdo pronto pra entrar
    /// direto num makeAccordionCard(contentView:).
    func makeCapacityBarsStack(_ bars: [UIView]) -> UIView {
        let stack = UIStackView(arrangedSubviews: bars)
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }
}
