//
//  Command.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

protocol Command {
    var isExecuted: Bool { get }

    func execute()
    func undo()
    func redo()
}
