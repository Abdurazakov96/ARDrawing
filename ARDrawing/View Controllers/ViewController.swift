import UIKit
import ARKit

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    private let configuration = ARWorldTrackingConfiguration()
    private var selectedNode: SCNNode?
    private var placedNodes = [SCNNode]()
    private var planeNodes = [SCNNode]()
    
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

    private func reloadConfiguration() {
        configuration.detectionImages = (objectMode == .image) ?
            ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) : nil

        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration)
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
            break

        case .image:
            break
        }
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

    private func nodeAdded(_ node: SCNNode, for anchor: ARPlaneAnchor) {

    }

    private func nodeAdded(_ node: SCNNode, for anchor: ARImageAnchor) {
        guard let selectedNode = self.selectedNode else { return }
        addNode(selectedNode, to: node)
    }

    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
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
    }
    
    func undoLastObject() {
        
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
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
}
