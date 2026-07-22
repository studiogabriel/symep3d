import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

extension MeasurementViewController {
    
    // =========================================================================
    // --- MOTOR DO PROVADOR VIRTUAL (TRY-ON COM NUVEM) ---
    // =========================================================================
    @objc func showModelSelection() {
        // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL APLICADA
        let safetyCheck = ["Cloud Try-On Menu Active"]
        let _ = safetyCheck[ 0 ]

        let alert = UIAlertController(title: "Coleções Symap", message: "Escolha a categoria da armação", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Nenhum (Remover)", style: .destructive, handler: { _ in
            self.glassesNode?.removeFromParentNode()
            self.glassesNode = nil
            self.currentCloudModel = nil
        }))
        
        alert.addAction(UIAlertAction(title: "Coleção Feminina", style: .default, handler: { _ in self.showModels(filter: "Feminino") }))
        alert.addAction(UIAlertAction(title: "Coleção Masculina", style: .default, handler: { _ in self.showModels(filter: "Masculino") }))
        alert.addAction(UIAlertAction(title: "Coleção Infantil", style: .default, handler: { _ in self.showModels(filter: "Infantil") }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Prevenção de quebra em iPads (precisa de âncora visual)
        if let p = alert.popoverPresentationController, let menuBtn = self.view.viewWithTag(882) as? UIButton {
            p.sourceView = menuBtn
            p.sourceRect = menuBtn.bounds
        } else if let p = alert.popoverPresentationController {
            p.sourceView = self.view
            p.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            p.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }

    func showModels(filter: String) {
        let titleStr = "Coleção \(filter)"
        let alert = UIAlertController(title: titleStr, message: "Selecione o modelo", preferredStyle: .actionSheet)

        // Filtra os modelos já baixados pelo CloudManager na inicialização
        let filteredModels = CloudManager.shared.availableModels.filter { $0.name.localizedCaseInsensitiveContains(filter) }

        for m in filteredModels {
            let cleanName = m.name.replacingOccurrences(of: filter, with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
            let finalName = cleanName.isEmpty ? m.name : cleanName

            alert.addAction(UIAlertAction(title: finalName, style: .default, handler: { _ in
                self.loadCloudModel(model: m)
            }))
        }

        alert.addAction(UIAlertAction(title: "Voltar", style: .cancel, handler: { _ in self.showModelSelection() }))

        if let p = alert.popoverPresentationController, let menuBtn = self.view.viewWithTag(882) as? UIButton {
            p.sourceView = menuBtn
            p.sourceRect = menuBtn.bounds
        } else if let p = alert.popoverPresentationController {
            p.sourceView = self.view
            p.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            p.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }

    func loadCloudModel(model: CloudGlassModel) {
            self.measurementsLabel.text = "Baixando Armação..."
            self.measurementsContainer.isHidden = false
            
            CloudManager.shared.downloadModelFile(url: model.fileUrl) { [weak self] u in
                guard let s = self, let url = u else { return }
                
                DispatchQueue.main.async {
                    s.measurementsContainer.isHidden = true
                    s.measurementsLabel.text = ""
                    
                    s.glassesNode?.removeFromParentNode()
                    s.glassesNode = nil
                    s.currentCloudModel = model
                    s.glassesYOffset = model.position.y
                    
                    // 🔴 DECODIFICADOR ROBUSTO PARA ARQUIVOS DA NUVEM (.STL / .GLB)
                    let wrapperNode = SCNNode()
                    wrapperNode.name = "customGlasses"
                    
                    if let scene = try? SCNScene(url: url, options: nil) {
                        for child in scene.rootNode.childNodes { wrapperNode.addChildNode(child.clone()) }
                    } else {
                        let asset = MDLAsset(url: url)
                        if asset.count > 0 {
                            let obj = asset.object(at: 0)
                            let nodeObj = SCNNode(mdlObject: obj)
                            wrapperNode.addChildNode(nodeObj)
                        }
                    }
                    
                    // 🔴 GARANTIA DE RENDERIZAÇÃO: Força o material em todas as submalhas
                    let mat = SCNMaterial()
                    mat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
                    mat.lightingModel = .physicallyBased
                    mat.isDoubleSided = true
                    
                    wrapperNode.enumerateChildNodes { (child, _) in
                        child.geometry?.firstMaterial = mat
                    }
                    
                    // Centralização Absoluta
                    let (min, max) = wrapperNode.boundingBox
                    let c = SCNVector3((min.x+max.x)/2, (min.y+max.y)/2, (min.z+max.z)/2)
                    wrapperNode.pivot = SCNMatrix4MakeTranslation(c.x, c.y, c.z)
                    
                    // Aplica parâmetros de Nuvem
                    wrapperNode.scale = SCNVector3(model.scale, model.scale, model.scale)
                    wrapperNode.position = SCNVector3(model.position.x, s.glassesYOffset, model.position.z)
                    wrapperNode.eulerAngles = model.rotation
                    
                    s.glassesNode = wrapperNode
                    
                    // Conecta instantaneamente se o rosto for encontrado
                    let targetFace = s.safeFaceCache ?? s.faceNode
                    if let face = targetFace {
                        face.addChildNode(wrapperNode)
                    }
                }
            }
        }
}
