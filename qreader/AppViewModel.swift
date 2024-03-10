//
//  AppViewModel.swift
//  qreader
//
//  Created by Nicola De Filippo on 09/03/24.
//

import Foundation

class AppViewModel: ObservableObject {
    @Published var run: Bool = false
    @Published var qr: String = ""
    @Published var s: () -> () = {}
}
