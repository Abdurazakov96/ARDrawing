//
//  CommandManager.swift
//  ARDrawing
//
//  Created by Nikolay Naumenkov on 24/07/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

class CommandManager {
    private var undoStack = [Command]()
    private var redoStack = [Command]()

    func executeCommand(command: Command) {
        command.execute()

        if command.isExecuted {
            redoStack.removeAll()
            undoStack.append(command)
        }
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        guard let top = undoStack.last else { return }

        top.undo()
        redoStack.append(top)
        undoStack.removeLast()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        guard let top = redoStack.last else { return }

        top.redo()
        undoStack.append(top)
        redoStack.removeLast()
    }

    func reset() {
        guard !undoStack.isEmpty else { return }
        undoStack.forEach { $0.undo() }
        clear()
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
