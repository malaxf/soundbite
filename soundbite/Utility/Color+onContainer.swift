//
//  Color+onContainer.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/14/25.
//

import SwiftUI

extension Color {
    static var onContainer: Color {
        Color.container.mix(with: Color.white, by: 0.2)
    }
}
