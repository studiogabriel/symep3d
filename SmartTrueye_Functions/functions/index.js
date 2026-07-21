const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const os = require("os"); // NOVO: Para gerenciar a memória /tmp do servidor
const THREE = require("three");

// ============================================================================
// 🔴 POLYFILLS SEGUROS (Corrige o erro de EventTarget do Node.js 20)
// ============================================================================
const mockWindow = {
    document: {
        createElement: () => ({ style: {} }),
        createElementNS: () => ({})
    }
};
global.window = mockWindow;
global.self = mockWindow;
global.document = mockWindow.document;

admin.initializeApp();

exports.processarPedido3D = functions
    .runWith({
        memory: "2GB", // Mantemos a memória alta para suportar as malhas
        timeoutSeconds: 120
    })
    .firestore
    .document("orders_stl/{pedidoId}")
    .onCreate(async (snap, context) => {
        const dados = snap.data();
        const pedidoId = context.params.pedidoId;
        const fileName = dados.stlFileName || `pedido_${pedidoId}.stl`;
        const modeloBase = dados.modeloBase || "rayban_f";
        const edicoes = dados.edicoesLaboratorio || {};

        console.log(`🚀 Iniciando Motor 3D para o pedido: ${pedidoId} (Modelo: ${modeloBase})`);

        try {
            const bucket = admin.storage().bucket();
            
            // 🔴 NOVA ARQUITETURA: Baixando o modelo pesado dinamicamente para o /tmp
            const tempFilePath = path.join(os.tmpdir(), `${modeloBase}.glb`);
            const remoteFile = bucket.file(`modelos_base/${modeloBase}.glb`);

            console.log(`📥 Baixando ${modeloBase}.glb do Firebase Storage...`);
            await remoteFile.download({ destination: tempFilePath });

            const { GLTFLoader } = await import("three/examples/jsm/loaders/GLTFLoader.js");
            const { STLExporter } = await import("three/examples/jsm/exporters/STLExporter.js");

            // Lê o arquivo baixado na RAM
            const nodeBuffer = fs.readFileSync(tempFilePath);
            const arrayBuffer = nodeBuffer.buffer.slice(nodeBuffer.byteOffset, nodeBuffer.byteOffset + nodeBuffer.byteLength);

            const loader = new GLTFLoader();
            const gltf = await new Promise((resolve, reject) => {
                loader.parse(arrayBuffer, '', resolve, reject);
            });

            // APLICA A MATEMÁTICA (As "Edições" do iPhone)
            gltf.scene.traverse((child) => {
                if (child.isMesh && child.morphTargetDictionary && child.morphTargetInfluences) {
                    for (const [key, index] of Object.entries(child.morphTargetDictionary)) {
                        if (edicoes[key] !== undefined) {
                            child.morphTargetInfluences[index] = edicoes[key];
                        }
                    }

                    // O CONGELAMENTO (BAKING) DOS VÉRTICES
                    const posAttribute = child.geometry.attributes.position;
                    const vA = new THREE.Vector3();
                    const vB = new THREE.Vector3();

                    for (let i = 0; i < posAttribute.count; i++) {
                        vA.fromBufferAttribute(posAttribute, i);

                        for (const [key, index] of Object.entries(child.morphTargetDictionary)) {
                            const weight = child.morphTargetInfluences[index];
                            if (weight === 0) continue;

                            const morphAttribute = child.geometry.morphAttributes.position[index];
                            if (morphAttribute) {
                                vB.fromBufferAttribute(morphAttribute, i);
                                vA.addScaledVector(vB, weight);
                            }
                        }
                        posAttribute.setXYZ(i, vA.x, vA.y, vA.z);
                    }
                    child.morphTargetInfluences.fill(0);
                    child.geometry.attributes.position.needsUpdate = true;
                }
            });

            // Converte para STL
            const exporter = new STLExporter();
            const stlString = exporter.parse(gltf.scene);

            // Faz o upload de volta pro Storage
            const dateStr = new Date().toLocaleDateString('pt-BR', {timeZone: 'UTC'}).replace(/\//g, '-');
            const filePath = `pedidos_stl/${dateStr}/${fileName}`;
            const file = bucket.file(filePath);

            await file.save(stlString, {
                metadata: {
                    contentType: "application/vnd.ms-pki.stl",
                    metadata: { userId: dados.userId || "anon", modeloBase: modeloBase }
                }
            });

            // 🔴 SEGURANÇA ESTRUTURAL: Lendo a array da URL com índice cirúrgico
            const signedUrls = await file.getSignedUrl({ action: 'read', expires: '01-01-2100' });
            const downloadUrl = signedUrls[ 0 ];

            await snap.ref.update({ status: "Concluído", stlUrl: downloadUrl });

            // Descarte de lixo: apaga o arquivo temporário para não vazar memória no servidor
            fs.unlinkSync(tempFilePath);

            console.log(`✅ Sucesso Absoluto! STL salvo em: ${filePath}`);
            return true;

        } catch (error) {
            console.error("❌ Ocorreu um erro interno:", error.message);
            await snap.ref.update({ status: "Erro ao Gerar 3D" });
            return false;
        }
    });