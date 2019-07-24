//
//  PlaceNodeInPlaneCommand.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

import SceneKit

class PlaceNodeInPlaneCommand: Command {
    private(set) var isExecuted: Bool = false

    private let targetNode: SCNNode
    private let parentNode: SCNNode
    private let transform: simd_float4x4
    private let distanceThreshold: Float
    private let lastPlacedPosition: SCNVector3?

    var targetNodePosition: SCNVector3 {
        return targetNode.position
    }

    init(targetNode: SCNNode,
         parentNode: SCNNode,
         transform: simd_float4x4,
         distanceThreshold: Float,
         lastPlacedPosition: SCNVector3?) {

        self.targetNode = targetNode
        self.parentNode = parentNode
        self.transform = transform
        self.distanceThreshold = distanceThreshold
        self.lastPlacedPosition = lastPlacedPosition
    }

    convenience init(sourceNode: SCNNode,
                     parentNode: SCNNode,
                     transform: simd_float4x4,
                     distanceThreshold: Float,
                     lastPlacedPosition: SCNVector3?) {

        self.init(targetNode: sourceNode.clone(),
                  parentNode: parentNode,
                  transform: transform,
                  distanceThreshold: distanceThreshold,
                  lastPlacedPosition: lastPlacedPosition)
    }

    func execute() {
        let position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )

        var distance = Float.greatestFiniteMagnitude

        if let lastPosition = lastPlacedPosition {
            let deltaX = position.x - lastPosition.x
            let deltaY = position.y - lastPosition.y
            let deltaZ = position.z - lastPosition.z

            distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        }

        if distanceThreshold < distance {
            targetNode.position = position
            parentNode.addChildNode(targetNode)
            isExecuted = true
        } else {
            isExecuted = false
        }
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
