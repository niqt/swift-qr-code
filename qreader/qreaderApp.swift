//
//  qreaderApp.swift
//  qreader
//
//  Created by Nicola De Filippo on 09/03/24.
//

import SwiftUI

@main
struct qreaderApp: App {
    init() {
        // Valore usato finché non se ne salva uno diverso nelle impostazioni
        UserDefaults.standard.register(defaults: [
            "serverIsLocal": true,
            "localHost": "192.168.0.206",
            "localPort": "8080",
            "googleBooksApiKey": Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String ?? ""
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
