//
//  PlaceNodeInFrontCommand.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

import SceneKit

class PlaceNodeInFrontCommand: Command {
    private(set) var isExecuted: Bool = false

    private let targetNode: SCNNode
    private let parentNode: SCNNode
    private let cameraTransform: simd_float4x4
    private let distance: Float

    init(targetNode: SCNNode,
         parentNode: SCNNode,
         cameraTransform: simd_float4x4,
         distance: Float) {

        self.targetNode = targetNode
        self.parentNode = parentNode
        self.cameraTransform = cameraTransform
        self.distance = distance
    }

    convenience init(sourceNode: SCNNode,
                     parentNode: SCNNode,
                     cameraTransform: simd_float4x4,
                     distance: Float) {

        self.init(targetNode: sourceNode.clone(),
                  parentNode: parentNode,
                  cameraTransform: cameraTransform,
                  distance: distance)
    }

    func execute() {
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -distance
        targetNode.simdTransform = matrix_multiply(cameraTransform, translation)
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
