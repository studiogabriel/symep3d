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
    
    func setupScene() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor is ARFaceAnchor else { return nil }
            faceNode = SCNNode()
            
            let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)
            let maskNode = SCNNode(geometry: faceGeometry)
            maskNode.geometry?.firstMaterial?.colorBufferWriteMask = []
            faceNode?.addChildNode(maskNode)
            
            if let fn = faceNode {
                setupTechMask(on: fn)
                
                // 🔴 A MÁGICA: Se a IA (Visagismo) já baixou um óculos, mas a âncora do rosto tinha se perdido, ela cola o óculos instantaneamente agora!
                if let gn = self.glassesNode, gn.parent == nil {
                    fn.addChildNode(gn)
                }
            }
            return faceNode
        }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if renderer === self.visionMappingView {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
            self.lastFaceDetectionTime = Date().timeIntervalSince1970
            guard let camTransform = renderer.pointOfView?.simdTransform else { return }
            
            // 🔴 COMPENSAÇÃO ANATÔMICA DA CABEÇA (-0.065 rad)
            let relativeFaceTransform = simd_mul(simd_inverse(camTransform), faceAnchor.transform)
            let rawHeadPitch = relativeFaceTransform.columns.2.y
            let headPitch = rawHeadPitch - 0.065
            let headYaw = relativeFaceTransform.columns.2.x
            
            let leftEye = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform).columns.3
            let rightEye = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform).columns.3
            
            let lEyeScreen = renderer.projectPoint(SCNVector3(leftEye.x, leftEye.y, leftEye.z))
            let rEyeScreen = renderer.projectPoint(SCNVector3(rightEye.x, rightEye.y, rightEye.z))
            
            let rawHeadRoll = atan2(Float(lEyeScreen.y - rEyeScreen.y), Float(lEyeScreen.x - rEyeScreen.x))
            self.smoothHeadRoll = (self.smoothHeadRoll * 0.95) + (rawHeadRoll * 0.05)
            self.updateHeadHorizonUI(roll: self.smoothHeadRoll, pitch: headPitch, yaw: headYaw)
            
            if self.isMappingVision {
                let headYawAbs = abs(headYaw)
                let headPitchAbs = abs(headPitch)
                let relLeftEyeTransform = simd_mul(relativeFaceTransform, faceAnchor.leftEyeTransform)
                let eyeYaw = abs(relLeftEyeTransform.columns.2.x)
                let eyePitch = abs(relLeftEyeTransform.columns.2.y)
                
                let tremorLimit: Float = 0.035
                let cleanHeadYaw = headYawAbs > tremorLimit ? headYawAbs : 0
                let cleanHeadPitch = headPitchAbs > tremorLimit ? headPitchAbs : 0
                let cleanEyeYaw = eyeYaw > tremorLimit ? eyeYaw : 0
                let cleanEyePitch = eyePitch > tremorLimit ? eyePitch : 0
                
                self.headMoveScore += (cleanHeadYaw + cleanHeadPitch)
                self.eyeMoveScore += (cleanEyeYaw + cleanEyePitch)
            }
            return
        }
        
        // --- MODO: CAPTURA PRINCIPAL (TELA DA MÁSCARA 3D) ---
        self.lastFaceDetectionTime = Date().timeIntervalSince1970
        if isFrozen { return }
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        if node.childNodes.count > 0 {
            // 🔴 DIRETRIZ ARQUITETURAL INEGOCIÁVEL: Índice zero blindado
            let safetyNodes = node.childNodes
            if let faceGeometry = safetyNodes[ 0 ].geometry as? ARSCNFaceGeometry {
                faceGeometry.update(from: faceAnchor.geometry)
            }
        }
        
        let leftM = faceAnchor.leftEyeTransform
        let rightM = faceAnchor.rightEyeTransform
        let lCenter = simd_make_float3(leftM.columns.3)
        let rCenter = simd_make_float3(rightM.columns.3)
        let dnp = BiometryEngine.pupillaryDistance(
            leftCenter: lCenter, rightCenter: rCenter,
            leftGaze: simd_make_float3(leftM.columns.2),
            rightGaze: simd_make_float3(rightM.columns.2))
        
        // 🔴 COFRE BIOMÉTRICO (Parte 1): Blindagem Matemática da DNP
                let safetyCheck = ["Vault Locked"]
                let _ = safetyCheck[ 0 ]

                // Se a captura já foi feita (Visagismo OK), não deixamos as pupilas oscilarem!
                if !self.isVisagismCompleted {
                    self.dnpEsq = dnp.dnpEsq
                    self.dnpDir = dnp.dnpDir
                    self.dnpTotal = dnp.dnpTotal
                    self.verticalPupilDiff = dnp.verticalDiff
                    self.dnpPertoEsq = dnp.dnpPertoEsq
                    self.dnpPertoDir = dnp.dnpPertoDir
                    self.dnpPertoTotal = dnp.dnpPertoTotal
                }
        
        let lPos = lCenter
        let rPos = rCenter
        
        let leftEyeWorldTransform = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)
        let rightEyeWorldTransform = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
        self.lastLeftEyeWorldPos = SCNVector3(leftEyeWorldTransform.columns.3.x, leftEyeWorldTransform.columns.3.y, leftEyeWorldTransform.columns.3.z)
        self.lastRightEyeWorldPos = SCNVector3(rightEyeWorldTransform.columns.3.x, rightEyeWorldTransform.columns.3.y, rightEyeWorldTransform.columns.3.z)
        
        if isGuidesActive, let line = pupilLineNode {
            let dy = lPos.y - rPos.y
            let dx = lPos.x - rPos.x
            let angle = atan2(dy, abs(dx))
            line.eulerAngles.z = Float.pi / 2 + angle
        }
        
        // Atualização contínua do HUD Aeronáutico
        if let lEyePos = self.lastLeftEyeWorldPos, let rEyePos = self.lastRightEyeWorldPos,
           let camTransform = sceneView.pointOfView?.simdTransform {
            let lEyeScreen = sceneView.projectPoint(lEyePos)
            let rEyeScreen = sceneView.projectPoint(rEyePos)
            let deltaY = Float(lEyeScreen.y - rEyeScreen.y)
            let deltaX = Float(lEyeScreen.x - rEyeScreen.x)
            let rawHeadRoll = atan2(deltaY, deltaX)
            let alpha: Float = 0.05
            self.smoothHeadRoll = (self.smoothHeadRoll * (1.0 - alpha)) + (rawHeadRoll * alpha)
            
            // 🔴 APLICANDO A CURA ERGONÔMICA NA CÂMERA PRINCIPAL TBM!
            let relativeFaceTransform = simd_mul(simd_inverse(camTransform), faceAnchor.transform)
            let rawHeadPitch = relativeFaceTransform.columns.2.y
            let headPitch = rawHeadPitch - 0.065
            let headYaw = relativeFaceTransform.columns.2.x
            self.updateHeadHorizonUI(roll: self.smoothHeadRoll, pitch: headPitch, yaw: headYaw)
        }
        
        let verts = faceAnchor.geometry.vertices
        let eyeLevelY = (lPos.y + rPos.y) / 2.0
        let eyeDepthZ = (lPos.z + rPos.z) / 2.0
        let bridgeHeightY = eyeLevelY + 0.000
        
        let fg = BiometryEngine.faceGeometry(vertices: verts, eyeLevelY: eyeLevelY, eyeDepthZ: eyeDepthZ)

                let minX = fg.minX
                let maxX = fg.maxX
                let minNX = fg.minNX
                let maxNX = fg.maxNX
                
                // 🔴 COFRE BIOMÉTRICO (Parte 2): Congela o Visagismo e a Malha
                // A tela continua viva acompanhando o rosto com o ARKit, mas os números do Laudo ficam blindados.
                // Assim, o Provador Virtual nunca mais oscilará as medidas no PopUp!
                    if !self.isVisagismCompleted {
                    // 🔴 Suavização por média móvel exponencial: evita que a medida de um
                    // único frame (ruído do LiDAR/leve movimento) decida sozinha a linha de
                    // tamanho (infantil/feminino/masculino) ou os pesos do motor automático.
                    let alpha = VisagismClinicalRules.biometrySmoothingAlpha
                    self.faceWidthRight = (self.faceWidthRight * (1 - alpha)) + (fg.faceWidthRight * alpha)
                    self.faceWidthLeft = (self.faceWidthLeft * (1 - alpha)) + (fg.faceWidthLeft * alpha)
                    self.faceHeight = (self.faceHeight * (1 - alpha)) + (fg.faceHeight * alpha)
                    self.faceWidth = (self.faceWidth * (1 - alpha)) + (fg.faceWidth * alpha)
                    if fg.bridgeValid { self.noseBridgeWidth = (self.noseBridgeWidth * (1 - alpha)) + (fg.noseBridgeWidth * alpha) }
                    self.nasalProfile = fg.nasalProfile
                    self.nasalProjection = (self.nasalProjection * (1 - alpha)) + (fg.nasalProjection * alpha)
                    if fg.jawValid { self.jawWidth = (self.jawWidth * (1 - alpha)) + (fg.jawWidth * alpha) }

                    let visagisme = BiometryEngine.analyzeVisagisme(width: self.faceWidth, height: self.faceHeight, bridge: self.noseBridgeWidth, jaw: self.jawWidth, dnpTotal: self.dnpTotal)
                    self.faceShape = visagisme.faceShape
                    self.frameSuggestion = visagisme.frameSuggestion
                    self.recommendedAutoModel = visagisme.recommendedModel
                }
        
        let currentBridgeY = bridgeHeightY
        let currentTempleY = eyeLevelY + 0.025
        let finalMinX = minX
        let finalMaxX = maxX
        let finalMinNX = minNX
        let finalMaxNX = maxNX
        
        DispatchQueue.main.async {
            self.updateLabels()
            self.templeLineNode?.position.y = currentTempleY
            self.templeLeftArrow?.position.y = currentTempleY
            self.templeRightArrow?.position.y = currentTempleY
            if finalMinX < finalMaxX {
                self.templeLeftArrow?.position.x = finalMinX
                self.templeRightArrow?.position.x = finalMaxX
            }
            let widthMeters = finalMaxX - finalMinX
            self.templeLineNode?.position.x = (finalMinX + finalMaxX) / 2
            self.templeLineNode?.scale.y = widthMeters
            
            self.bridgeLineNode?.position.y = currentBridgeY
            self.bridgeLeftArrow?.position.y = currentBridgeY
            self.bridgeRightArrow?.position.y = currentBridgeY
            if finalMinNX < finalMaxNX {
                self.bridgeLeftArrow?.position.x = finalMinNX
                self.bridgeRightArrow?.position.x = finalMaxNX
                let bridgeWidthMeters = finalMaxNX - finalMinNX
                self.bridgeLineNode?.position.x = (finalMinNX + finalMaxNX) / 2
                self.bridgeLineNode?.scale.y = bridgeWidthMeters
            }
        }
    }
}
