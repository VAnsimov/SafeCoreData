//
//  SafeCoreData+ContextOutputThread.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation

extension SafeCoreData {
    public enum ContextOutputThread {
        case main, global

        func action(actionBlock: @escaping () -> Void) {
            switch self {
            case .main:
                DispatchQueue.main.async {
                    actionBlock()
                }

            case .global:
                DispatchQueue.global().async {
                    actionBlock()
                }
            }
        }
    }
}
