//
//  Floor.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

import ARKit

class Floor: SCNNode {
    init(planeAnchor: ARPlaneAnchor) {
        super.init()
        setup(with: planeAnchor)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(with planeAnchor: ARPlaneAnchor) {
        let planeGeometry = SCNPlane(
            width: CGFloat(planeAnchor.extent.x),
            height: CGFloat(planeAnchor.extent.z)
        )

        planeGeometry.firstMaterial?.diffuse.contents = #colorLiteral(red: 1, green: 0.6799775482, blue: 0.1184521644, alpha: 1)

        self.geometry = planeGeometry
        self.eulerAngles.x = -.pi / 2
        self.opacity = 0.25
    }

    func update(with planeAnchor: ARPlaneAnchor) {
        guard let planeGeometry = self.geometry as? SCNPlane else { return }

        planeGeometry.width = CGFloat(planeAnchor.extent.x)
        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        self.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
}
