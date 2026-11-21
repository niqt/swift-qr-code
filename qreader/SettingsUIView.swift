//
//  SettingsUIView.swift
//  qreader
//
//  Created by Nicola De Filippo on 27/12/25.
//

import SwiftUI
import Security

/// Configurazione del server letta da UserDefaults (e dal Portachiavi per la password).
enum ServerConfig {
    static let apiPath = "/api/v1"

    static var isLocal: Bool {
        UserDefaults.standard.bool(forKey: "serverIsLocal")
    }

    /// URL base delle API, es. "http://192.168.0.206:8080/api/v1"
    static var baseURL: String {
        let defaults = UserDefaults.standard
        if isLocal {
            let host = (defaults.string(forKey: "localHost") ?? "").trimmingCharacters(in: .whitespaces)
            let port = (defaults.string(forKey: "localPort") ?? "").trimmingCharacters(in: .whitespaces)
            let hostPart = host.isEmpty ? "192.168.0.206" : host
            return port.isEmpty ? "http://\(hostPart)\(apiPath)" : "http://\(hostPart):\(port)\(apiPath)"
        }
        var url = (defaults.string(forKey: "serverURL") ?? "").trimmingCharacters(in: .whitespaces)
        while url.hasSuffix("/") { url.removeLast() }
        return url
    }

    /// Crea una richiesta verso il server, con autenticazione Basic se il server è remoto.
    static func request(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if !isLocal {
            let username = UserDefaults.standard.string(forKey: "serverUsername") ?? ""
            let password = Keychain.read(key: "serverPassword") ?? ""
            if !username.isEmpty {
                let token = Data("\(username):\(password)".utf8).base64EncodedString()
                request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        return request
    }
}

/// Salvataggio minimale di stringhe nel Portachiavi.
enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "qreader"

    private static func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    static func read(key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(key: String, value: String) {
        SecItemDelete(query(key) as CFDictionary)
        guard !value.isEmpty else { return }
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(q as CFDictionary, nil)
    }
}

struct SettingsUIView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("googleBooksApiKey") private var googleBooksApiKey = ""
    @AppStorage("serverIsLocal") private var serverIsLocal = true
    @AppStorage("localHost") private var localHost = ""
    @AppStorage("localPort") private var localPort = ""
    @AppStorage("serverURL") private var serverURL = ""
    @AppStorage("serverUsername") private var serverUsername = ""
    @State private var serverPassword = Keychain.read(key: "serverPassword") ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Server locale", isOn: $serverIsLocal)
                    if serverIsLocal {
                        TextField("Nome o IP (es. 192.168.0.206)", text: $localHost)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Porta (es. 8080)", text: $localPort)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("https://esempio.it/api/v1", text: $serverURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Server")
                } footer: {
                    if serverIsLocal {
                        Text("Nessuna autenticazione. Indirizzo usato: \(ServerConfig.baseURL)")
                    } else {
                        Text("Indirizzo del server, incluso /api/v1")
                    }
                }
                if !serverIsLocal {
                    Section {
                        TextField("Utente", text: $serverUsername)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $serverPassword)
                            .textContentType(.password)
                    } header: {
                        Text("Autenticazione")
                    } footer: {
                        Text("Inviate con HTTP Basic. La password è salvata nel Portachiavi.")
                    }
                }
                Section {
                    TextField("API key", text: $googleBooksApiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Google Books")
                } footer: {
                    Text("Senza API key Google limita fortemente le richieste.")
                }
            }
            .navigationTitle("Impostazioni")
            .onChange(of: serverPassword) { _, newValue in
                Keychain.save(key: "serverPassword", value: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsUIView()
}
