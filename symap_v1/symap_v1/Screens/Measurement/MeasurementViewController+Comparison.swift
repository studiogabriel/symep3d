import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import PDFKit
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import simd
import PencilKit
import FirebaseStorage
import AVFoundation

extension MeasurementViewController {
    
    @objc func addToComparison() {
        // Trava de limite de memória: Máximo de 10 fotos na galeria
        if comparisonImages.count >= 10 {
            let alert = UIAlertController(title: "Limite Atingido", message: "Limite atingido, remova alguma.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        let snap = sceneView.snapshot()
        comparisonImages.append(snap)
        
        let flash = UIView(frame: view.bounds)
        flash.backgroundColor = .white
        flash.alpha = 0.5
        view.addSubview(flash)
        
        UIView.animate(withDuration: 0.2) {
            flash.alpha = 0.0
        } completion: { _ in
            flash.removeFromSuperview()
        }
        
        if comparisonImages.count > 0 {
            btnShowCompare.isHidden = false
            btnShowCompare.setTitle("\(comparisonImages.count)", for: .normal)
        }
    }
    
    @objc func showComparisonUI() {
        guard comparisonImages.count > 0 else { return }
        
        comparisonOverlay = UIView(frame: view.bounds)
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        comparisonOverlay?.addSubview(blurView)
        
        let closeBtn = UIButton(frame: CGRect(x: view.bounds.width - 60, y: 40, width: 40, height: 40))
        closeBtn.setTitle("X", for: .normal)
        closeBtn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeBtn.layer.cornerRadius = 20
        closeBtn.addTarget(self, action: #selector(closeComparison), for: .touchUpInside)
        comparisonOverlay?.addSubview(closeBtn)
        
        let clearBtn = UIButton(frame: CGRect(x: 20, y: 40, width: 120, height: 40))
        clearBtn.setTitle("Limpar Tudo", for: .normal)
        clearBtn.setTitleColor(.systemRed, for: .normal)
        clearBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        clearBtn.addTarget(self, action: #selector(clearComparisons), for: .touchUpInside)
        comparisonOverlay?.addSubview(clearBtn)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 120, width: view.bounds.width, height: view.bounds.height - 180))
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        
        let cardW = view.bounds.width * 0.8
        let cardH = cardW * 1.4
        let spacing = view.bounds.width * 0.1
        var xOffset = spacing
        
        for (i, img) in comparisonImages.enumerated() {
            let cardView = UIView(frame: CGRect(x: xOffset, y: 20, width: cardW, height: cardH))
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.5
            cardView.layer.shadowRadius = 20
            cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
            
            let iv = UIImageView(frame: cardView.bounds)
            iv.image = img
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 24
            iv.clipsToBounds = true
            cardView.addSubview(iv)
            
            let lbl = UILabel(frame: CGRect(x: 0, y: cardH + 20, width: cardW, height: 30))
            lbl.text = "OPÇÃO \(i + 1)"
            lbl.textColor = .white
            lbl.textAlignment = .center
            lbl.font = UIFont.systemFont(ofSize: 16, weight: .black)
            cardView.addSubview(lbl)
            
            // NOVO: Botão de Lixeira Individual
            let deleteBtn = UIButton(frame: CGRect(x: cardW - 55, y: 15, width: 40, height: 40))
            deleteBtn.setTitle("X - Descartar", for: .normal)
            deleteBtn.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            deleteBtn.layer.cornerRadius = 20
            deleteBtn.tag = i // Atrela o índice da imagem ao botão
            deleteBtn.addTarget(self, action: #selector(deleteSingleComparison(_:)), for: .touchUpInside)
            cardView.addSubview(deleteBtn)
            
            scrollView.addSubview(cardView)
            xOffset += view.bounds.width
        }
        
        scrollView.contentSize = CGSize(width: xOffset - spacing, height: cardH + 50)
        comparisonOverlay?.addSubview(scrollView)
        view.addSubview(comparisonOverlay!)
    }
    
    @objc func closeComparison() { comparisonOverlay?.removeFromSuperview(); comparisonOverlay = nil }
    
    @objc func clearComparisons() { comparisonImages.removeAll(); btnShowCompare.isHidden = true; closeComparison() }
    
    // NOVA LÓGICA: Exclusão individual atrelada ao índice da lixeira
    @objc func deleteSingleComparison(_ sender: UIButton) {
        let indexToRemove = sender.tag
        if indexToRemove >= 0 && indexToRemove < comparisonImages.count {
            // Remove cirurgicamente a foto da matriz
            comparisonImages.remove(at: indexToRemove)
            if comparisonImages.isEmpty {
                // Se era a última foto, fecha o espelho e esconde o botão
                btnShowCompare.isHidden = true
                closeComparison()
            } else {
                // Atualiza o contador na tela principal
                btnShowCompare.setTitle("\(comparisonImages.count)", for: .normal)
                // Reconstrói a interface para recalcular os índices e posicionamentos
                closeComparison()
                showComparisonUI()
            }
        }
    }
    
    func createHandle(text: String = "", color: UIColor = .yellow) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleManualPan(_:)))
        v.addGestureRecognizer(pan)
        
        let lbl = UILabel(frame: CGRect(x: 15, y: -5, width: 30, height: 20))
        lbl.text = text
        lbl.textColor = color
        lbl.textAlignment = .center
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.tag = 999
        lbl.isHidden = true
        v.addSubview(lbl)
        
        return v
    }
}
