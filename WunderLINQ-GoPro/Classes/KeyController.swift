/*
WunderLINQ Client Application
Copyright (C) 2020  Keith Conger, Black Box Embedded, LLC
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation
import SwiftUI

class KeyController<Content>: UIHostingController<Content> where Content: View {

    override func becomeFirstResponder() -> Bool {
        true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: "\u{d}", modifierFlags:[], action: #selector(enter)),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags:[], action: #selector(escape)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags:[], action: #selector(left)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags:[], action: #selector(right)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags:[], action: #selector(up)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags:[], action: #selector(down))
        ]
        if #available(iOS 15, *) {
            commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }
        return commands
    }

    @objc func left(_ sender: UIKeyCommand) {
        print(">>> left was pressed")
    }
    @objc func right(_ sender: UIKeyCommand) {
        print(">>> right was pressed")
    }
    @objc func up(_ sender: UIKeyCommand) {
        print(">>> up was pressed")
    }
    @objc func down(_ sender: UIKeyCommand) {
        print(">>> down was pressed")
    }
    @objc func enter(_ sender: UIKeyCommand) {
        print(">>> enter was pressed")
    }
    @objc func escape(_ sender: UIKeyCommand) {
        print(">>> escape was pressed")
    }

}
