//
//  ContentView.swift
//  qreader
//
//  Created by Nicola De Filippo on 09/03/24.
//

import SwiftUI

struct ContentView: View {
    @State var qr = ""
    @State var scan = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(qr)
            }.sheet(isPresented: $scan) {
                SheetView(qrCode: $qr)
            }
            .padding()
            .toolbar {
                Button(action: {
                    qr = ""
                    scan = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
