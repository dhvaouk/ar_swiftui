import SwiftUI
import RealityKit
import ARKit

enum ARModel: String, CaseIterable {
 case bodyMesh = "BodyMesh.obj" // Replace with your first model filename
 case benz = "gf.obj" // Replace with your second model filename
}

struct ContentView: View {
 @State private var isModelVisible = false
 @State private var selectedModel: ARModel = .bodyMesh

 var body: some View {
 VStack {
  Text("Hello, AR!")
  .font(.largeTitle)
  .padding()

  Picker("Select Model", selection: $selectedModel) {
  Text(ARModel.bodyMesh.rawValue).tag(ARModel.bodyMesh)
  Text(ARModel.benz.rawValue).tag(ARModel.benz)
  }
  .pickerStyle(.menu)

  ARViewContainer(isModelVisible: $isModelVisible, selectedModel: $selectedModel)
  .edgesIgnoringSafeArea(.all)

  Button("Toggle Model") {
  isModelVisible.toggle() // Toggle model visibility
  }
  .padding()
 }
 }
}

struct ARViewContainer: UIViewRepresentable {
 @Binding var isModelVisible: Bool
 @Binding var selectedModel: ARModel

 func makeUIView(context: Context) -> ARView {
 let arView = ARView(frame: .zero)
 return arView
 }

 func updateUIView(_ uiView: ARView, context: Context) {
 if isModelVisible {
  // Load model based on selection
  let modelName = selectedModel.rawValue
  let model = try! Entity.loadModel(named: modelName)

  // Initial configuration
  model.setScale(SIMD3<Float>(0.1, 0.1, 0.1), relativeTo: nil)
  model.isEnabled = true // Ensure model is enabled

  // Find existing anchor (if any)
  var existingAnchor: AnchorEntity?
  for anchor in uiView.scene.anchors {
  if let anchorEntity = anchor as? AnchorEntity,
   let child = anchorEntity.children.first,
   child.name == modelName {
   existingAnchor = anchorEntity
   break
  }
  }

  // Add new anchor if not found
  if existingAnchor == nil {
  let anchorEntity = AnchorEntity(plane: .horizontal)
  anchorEntity.addChild(model)
  uiView.scene.addAnchor(anchorEntity)
  } else {
  // Update existing anchor with new model
  existingAnchor!.children.removeAll()
  existingAnchor!.addChild(model)
  }

  handleModelPlacement(uiView, model: model)
 } else {
  // Remove model-specific anchor if present
  for anchor in uiView.scene.anchors {
  if let anchorEntity = anchor as? AnchorEntity,
   let child = anchorEntity.children.first,
   child.name == "BodyMesh.obj" || child.name == "benz.obj" { // Update with your model names
   uiView.scene.removeAnchor(anchor)
   break
  }
  }
 }
 }

 func handleModelPlacement(_ uiView: ARView, model: ModelEntity) {
 // Use ARRaycast to find the position on the floor
 if let raycastResult = uiView.raycast(from: uiView.center, allowing: .estimatedPlane, alignment: .horizontal).first {
  let worldTransform = raycastResult.worldTransform
  let modelPosition = SIMD3<Float>(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
  model.setPosition(modelPosition, relativeTo: nil)
 }
 }
}
