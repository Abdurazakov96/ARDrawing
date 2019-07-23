import UIKit
import ARKit

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    private let configuration = ARWorldTrackingConfiguration()
    private var selectedNode: SCNNode?
    private var placedNodes = [SCNNode]()
    private var planeNodes = [SCNNode]()

    private var lastObjectPlacedPosition: SCNVector3?
    let distanceThreshold: Float = 0.05

    enum ObjectPlacementMode {
        case freeform, plane, image
    }
    
    var objectMode: ObjectPlacementMode = .freeform {
        didSet {
            reloadConfiguration()
        }
    }

    private var rootNode: SCNNode {
        return sceneView.scene.rootNode
    }

    private var showPlaneOverlay = false {
        didSet {
            planeNodes.forEach { $0.isHidden = !showPlaneOverlay }
        }
    }

    private func reloadConfiguration(removeAnchors: Bool = false) {
        configuration.detectionImages = (objectMode == .image) ?
            ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) : nil

        configuration.planeDetection = [.horizontal]

        let options: ARSession.RunOptions

        if removeAnchors {
            options = [.removeExistingAnchors]
            (placedNodes + planeNodes).forEach { $0.removeFromParentNode() }
            placedNodes.removeAll()
            planeNodes.removeAll()
        } else {
            options = []
        }

        sceneView.session.run(configuration, options: options)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let node = selectedNode else { return }
        guard let touch = touches.first else { return }

        switch objectMode {
        case .freeform:
            addNodeInFront(node)

        case .plane:
            addNode(node, at: touch.location(in: sceneView))
            break

        case .image:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let node = selectedNode else { return }
        guard let touch = touches.first else { return }
        guard objectMode == .plane else { return }

        let newTouchPoint = touch.location(in: sceneView)
        addNode(node, at: newTouchPoint)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        lastObjectPlacedPosition = nil
    }

    private func addNodeInFront(_ node: SCNNode) {
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }

        let transform = currentFrame.camera.transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.2
        node.simdTransform = matrix_multiply(transform, translation)

        addNode(node, to: rootNode)
    }

    private func addNode(_ node: SCNNode, to parentNode: SCNNode) {
        let cloneNode = node.clone()
        parentNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }

    private func addNode(_ node: SCNNode, at point: CGPoint) {
        guard let result = sceneView.hitTest(point, types: [.existingPlaneUsingExtent]).first
            else { return }

        let transform = result.worldTransform
        let position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )

        var distance = Float.greatestFiniteMagnitude

        if let lastPosition = lastObjectPlacedPosition {
            let deltaX = position.x - lastPosition.x
            let deltaY = position.y - lastPosition.y
            let deltaZ = position.z - lastPosition.z

            distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        }

        if distanceThreshold < distance {
            node.position = position
            addNode(node, to: rootNode)
            lastObjectPlacedPosition = node.position
        }
    }

    private func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let floorNode = SCNNode()

        let planeGeometry = SCNPlane(
            width: CGFloat(planeAnchor.extent.x),
            height: CGFloat(planeAnchor.extent.z)
        )

        planeGeometry.firstMaterial?.diffuse.contents = #colorLiteral(red: 1, green: 0.6799775482, blue: 0.1184521644, alpha: 1)

        floorNode.geometry = planeGeometry
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.opacity = 0.25

        return floorNode
    }

    private func nodeAdded(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        let floor = createFloor(planeAnchor: anchor)
        floor.isHidden = !showPlaneOverlay

        node.addChildNode(floor)
        planeNodes.append(floor)
    }

    private func nodeAdded(_ node: SCNNode, for anchor: ARImageAnchor) {
        guard let selectedNode = self.selectedNode else { return }
        addNode(selectedNode, to: node)
    }

    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
            showPlaneOverlay = false
        case 1:
            objectMode = .plane
            showPlaneOverlay = true
        case 2:
            objectMode = .image
            showPlaneOverlay = false
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
}

// MARK: - OptionsViewControllerDelegate

extension ViewController: OptionsViewControllerDelegate {
    func objectSelected(node: SCNNode) {
        dismiss(animated: true, completion: nil)
        selectedNode = node
    }
    
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
        showPlaneOverlay.toggle()
    }
    
    func undoLastObject() {
        guard let lastNode = placedNodes.last else { return }
        lastNode.removeFromParentNode()
        placedNodes.removeLast()
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
        reloadConfiguration(removeAnchors: true)
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            nodeAdded(node, for: imageAnchor)
        } else if let planeAnchor = anchor as? ARPlaneAnchor {
            nodeAdded(node, for: planeAnchor)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard let floor = node.childNodes.first else { return }
        guard let plane = floor.geometry as? SCNPlane else { return }

        floor.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
}
