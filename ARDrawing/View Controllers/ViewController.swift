import UIKit
import ARKit

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    private let commandManager = CommandManager()
    private let configuration = ARWorldTrackingConfiguration()
    private var selectedNode: SCNNode?
    private var planeNodes = [SCNNode]()

    private var lastObjectPlacedPosition: SCNVector3?
    private let distanceThreshold: Float = 0.05

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
            resetPlaneNodes()
            commandManager.reset()
        } else {
            options = []
        }

        sceneView.session.run(configuration, options: options)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
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

    private func resetPlaneNodes() {
        planeNodes.forEach { $0.removeFromParentNode() }
        planeNodes.removeAll()
    }

    private func addNodeInFront(_ node: SCNNode) {
        guard let currentFrame = sceneView.session.currentFrame else { return }

        commandManager.executeCommand(command: PlaceNodeInFrontCommand(
            sourceNode: node,
            parentNode: rootNode,
            cameraTransform: currentFrame.camera.transform,
            distance: 0.2
        ))
    }

    private func addNode(_ node: SCNNode, at point: CGPoint) {
        guard let result = sceneView.hitTest(point, types: [.existingPlaneUsingExtent]).first
            else { return }

        let command = PlaceNodeInPlaneCommand(
            sourceNode: node,
            parentNode: rootNode,
            transform: result.worldTransform,
            distanceThreshold: distanceThreshold,
            lastPlacedPosition: lastObjectPlacedPosition
        )

        commandManager.executeCommand(command: command)

        if command.isExecuted {
            lastObjectPlacedPosition = command.targetNodePosition
        }
    }

    private func nodeAdded(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        let floor = Floor(planeAnchor: anchor)
        floor.isHidden = !showPlaneOverlay

        node.addChildNode(floor)
        planeNodes.append(floor)
    }

    private func nodeAdded(_ node: SCNNode, for anchor: ARImageAnchor) {
        guard let selectedNode = self.selectedNode else { return }

        commandManager.executeCommand(command: PlaceNodeCommand(
            sourceNode: selectedNode,
            parentNode: node
        ))
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

    @IBAction func undoPressed(_ sender: UIButton) {
        commandManager.undo()
    }

    @IBAction func redoPressed(_ sender: UIButton) {
        commandManager.redo()
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
        commandManager.undo()
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
        guard let floor = node.childNodes.first as? Floor else { return }

        floor.update(with: planeAnchor)
    }
}
