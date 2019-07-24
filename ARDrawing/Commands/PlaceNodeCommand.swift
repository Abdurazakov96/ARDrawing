//
//  PlaceNodeCommand.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

import SceneKit

class PlaceNodeCommand: Command {
    private(set) var isExecuted: Bool = false

    private let targetNode: SCNNode
    private let parentNode: SCNNode

    init(targetNode: SCNNode, parentNode: SCNNode) {
        self.targetNode = targetNode
        self.parentNode = parentNode
    }

    convenience init(sourceNode: SCNNode, parentNode: SCNNode) {
        self.init(targetNode: sourceNode.clone(), parentNode: parentNode)
    }

    func execute() {
        parentNode.addChildNode(targetNode)
        isExecuted = true
    }

    func undo() {
        guard isExecuted else { return }
        targetNode.removeFromParentNode()
    }

    func redo() {
        guard isExecuted else { return }
        parentNode.addChildNode(targetNode)
    }
}
