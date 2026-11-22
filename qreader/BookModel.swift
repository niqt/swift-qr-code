//
//  BookModel.swift
//  qreader
//
//  Created by Nicola De Filippo on 06/12/25.
//

import Foundation

struct GoogleBooks: Codable {
    var kind: String = ""
    var totalItems: Int = 0
    var items: Array<GoogleBook> = []

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? ""
        totalItems = try container.decodeIfPresent(Int.self, forKey: .totalItems) ?? 0
        // Google Books omette "items" quando non trova risultati
        items = try container.decodeIfPresent(Array<GoogleBook>.self, forKey: .items) ?? []
    }
}

struct GoogleBook: Codable {
    var id: String
    var volumeInfo: VolumeInfo?
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        volumeInfo = try container.decodeIfPresent(VolumeInfo.self, forKey: .volumeInfo)
    }
}

struct VolumeInfo: Codable {
    var title: String
    var subtitle: String?
    var authors: Array<String>?
    var imageLinks: ImagesLink?
    var isbn13: String?
    var isbn10: String?
    let publisher: String?
    let publishedDate: String?
    var read: Bool = false
    var position: String?
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        title = try container.decode(String.self, forKey: .title)
        authors = try container.decodeIfPresent(Array<String>.self, forKey: .authors)
        imageLinks = try container.decodeIfPresent(ImagesLink.self, forKey: .imageLinks)
        isbn10 = try container.decodeIfPresent(String.self, forKey: .isbn10)
        isbn13 = try container.decodeIfPresent(String.self, forKey: .isbn13)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        publishedDate = try container.decodeIfPresent(String.self, forKey: .publishedDate)
        // Google Books non ha questo campo: di default il libro non è letto
        read = try container.decodeIfPresent(Bool.self, forKey: .read) ?? false
        position = try container.decodeIfPresent(String.self, forKey: .position)
    }
    init(title: String,
             subtitle: String? = nil,
             authors: [String]? = nil,
             imageLinks: ImagesLink? = nil,
             isbn13: String? = nil,
             isbn10: String? = nil,
             publisher: String? = nil,
             publishedDate: String? = nil,
             read: Bool = false,
             position: String? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.authors = authors
            self.imageLinks = imageLinks
            self.isbn13 = isbn13
            self.isbn10 = isbn10
            self.publisher = publisher
            self.publishedDate = publishedDate
            self.read = read
            self.position = position
        }
}

/// ISBN validato, scritto in qualsiasi formato ammesso:
/// "9788804668237", "978-88-04-66823-7", "88 04 66823 X", "ISBN-13: 978…", "isbn 88…".
struct ISBN {
    let isbn13: String
    /// Esiste solo per i codici con prefisso 978
    let isbn10: String?

    init?(_ text: String) {
        var raw = text.uppercased()
        if let range = raw.range(of: "ISBN") {
            raw.removeSubrange(raw.startIndex..<range.upperBound)
        }
        // Toglie l'eventuale "-13:" / "-10" / " 13 " che segue "ISBN"
        raw = raw.trimmingCharacters(in: .whitespaces)
        if let range = raw.range(of: #"^-?1[03](\s*:|\s+)"#, options: .regularExpression) {
            raw.removeSubrange(range)
        }
        let chars = raw.filter { !" -:.\u{2010}\u{2011}\u{2013}".contains($0) }
        guard chars.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "X") }) else { return nil }

        if chars.count == 13, chars.allSatisfy(\.isNumber), ISBN.isValid13(chars) {
            isbn13 = chars
            isbn10 = chars.hasPrefix("978") ? ISBN.to10(chars) : nil
        } else if chars.count == 10, ISBN.isValid10(chars) {
            isbn10 = chars
            isbn13 = ISBN.to13(chars)
        } else {
            return nil
        }
    }

    private static func digits(_ s: String) -> [Int] {
        s.map { $0 == "X" ? 10 : Int(String($0))! }
    }

    static func isValid13(_ s: String) -> Bool {
        let d = digits(s)
        let sum = d.enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return sum % 10 == 0
    }

    static func isValid10(_ s: String) -> Bool {
        // La X è ammessa solo come cifra di controllo
        guard s.dropLast().allSatisfy(\.isNumber) else { return false }
        let d = digits(s)
        let sum = d.enumerated().reduce(0) { $0 + $1.element * (10 - $1.offset) }
        return sum % 11 == 0
    }

    private static func to13(_ isbn10: String) -> String {
        let body = "978" + isbn10.dropLast()
        let sum = digits(body).enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return body + String((10 - sum % 10) % 10)
    }

    private static func to10(_ isbn13: String) -> String {
        let body = String(isbn13.dropFirst(3).dropLast())
        let sum = digits(body).enumerated().reduce(0) { $0 + $1.element * (10 - $1.offset) }
        let check = (11 - sum % 11) % 11
        return body + (check == 10 ? "X" : String(check))
    }
}

struct ImagesLink: Codable {
    var smallThumbnail: String?
}

struct Book: Codable, Identifiable {
    var id: String
    var authors: Array<String>?
    var title: String
    var subtitle: String?
    var position: String?
    var publisher: String?
    var categories: String?
    var imageLinks: ImagesLink?
    var isbn13: String?
    var isbn10: String?
    var user: String?
    var note: String?
    var publishedDate: String?
    var read: Bool?
    
    var type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case authors
        case title
        case subtitle
        case position
        case publisher
        case categories
        case imageLinks
        case isbn13
        case isbn10
        case user
        case note
        case publishedDate
        case read
        case type
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Il server restituisce "id"; "_id" resta come fallback
        if let id = try c.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try c.decode(String.self, forKey: .mongoId)
        }
        authors = try c.decodeIfPresent([String].self, forKey: .authors)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        position = try c.decodeIfPresent(String.self, forKey: .position)
        publisher = try c.decodeIfPresent(String.self, forKey: .publisher)
        categories = try c.decodeIfPresent(String.self, forKey: .categories)
        imageLinks = try c.decodeIfPresent(ImagesLink.self, forKey: .imageLinks)
        isbn13 = try c.decodeIfPresent(String.self, forKey: .isbn13)
        isbn10 = try c.decodeIfPresent(String.self, forKey: .isbn10)
        user = try c.decodeIfPresent(String.self, forKey: .user)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        publishedDate = try c.decodeIfPresent(String.self, forKey: .publishedDate)
        read = try c.decodeIfPresent(Bool.self, forKey: .read)
        type = try c.decodeIfPresent(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(authors, forKey: .authors)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(subtitle, forKey: .subtitle)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(publisher, forKey: .publisher)
        try c.encodeIfPresent(categories, forKey: .categories)
        try c.encodeIfPresent(imageLinks, forKey: .imageLinks)
        try c.encodeIfPresent(isbn13, forKey: .isbn13)
        try c.encodeIfPresent(isbn10, forKey: .isbn10)
        try c.encodeIfPresent(user, forKey: .user)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(publishedDate, forKey: .publishedDate)
        try c.encodeIfPresent(read, forKey: .read)
        try c.encodeIfPresent(type, forKey: .type)
    }
}

struct GoogleAPIError: Codable {
    struct Detail: Codable {
        let code: Int
        let message: String
    }
    let error: Detail
}

struct BooksResponse: Codable {
    let books: [Book]
    let error: String?
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case books
        case error
        case total
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza risultati il server restituisce "books": null
        books = try c.decodeIfPresent([Book].self, forKey: .books) ?? []
        error = try c.decodeIfPresent(String.self, forKey: .error)
        total = try c.decodeIfPresent(Int.self, forKey: .total) ?? books.count
    }
}

@Observable
class BookViewModel {
    var books: [GoogleBook] = []
    var state: State = .Loaded
    var errorMessage: String = ""
    private var baseURL: String { ServerConfig.baseURL }
    enum State {
        case Loading, Loaded, Error
    }
    
    /// Errore della ricerca su Google Books, già con il messaggio da mostrare.
    struct LookupError: Error {
        let message: String
    }

    /// Chiede a Google Books i volumi con questo ISBN.
    private func fetchGoogleBooks(isbn: String) async throws -> [GoogleBook] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [URLQueryItem(name: "q", value: "isbn:\(isbn)")]
        let apiKey = UserDefaults.standard.string(forKey: "googleBooksApiKey") ?? ""
        if !apiKey.isEmpty {
            components?.queryItems?.append(URLQueryItem(name: "key", value: apiKey))
        }
        guard let url = components?.url else {
            throw LookupError(message: "Codice non valido: \(isbn)")
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print("error: ", error)
            throw LookupError(message: "Errore nella richiesta: \(error.localizedDescription)")
        }
        let decoder = JSONDecoder()
        // Google risponde con un oggetto "error" (es. 429 quota esaurita):
        // non va confuso con "nessun libro trovato"
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let apiError = try? decoder.decode(GoogleAPIError.self, from: data)
            print("Google Books error \(http.statusCode):", apiError?.error.message ?? "")
            if http.statusCode == 429 {
                throw LookupError(message: "Quota di Google Books esaurita. Imposta una API key nelle impostazioni.")
            }
            throw LookupError(message: "Errore Google Books (\(http.statusCode)): \(apiError?.error.message ?? "")")
        }
        do {
            let items = try decoder.decode(GoogleBooks.self, from: data).items
            if items.isEmpty {
                throw LookupError(message: "Nessun libro trovato per \(isbn)")
            }
            return items
        } catch let error as LookupError {
            throw error
        } catch {
            print("decoding error: ", error)
            throw LookupError(message: "Errore nella lettura dei dati del libro")
        }
    }

    func loadBooks(isbn: String) async {
        state = .Loading
        errorMessage = ""
        do {
            books = try await fetchGoogleBooks(isbn: isbn)
            books[0].volumeInfo?.isbn13 = isbn
            books[0].volumeInfo?.isbn10 = isbn
            state = .Loaded
        } catch {
            errorMessage = (error as? LookupError)?.message ?? error.localizedDescription
            state = .Error
        }
    }

    /// Cerca i dati di un libro senza toccare `books` né `state` (usato dall'inserimento manuale).
    func lookup(isbn: ISBN) async -> Result<VolumeInfo, LookupError> {
        do {
            let items = try await fetchGoogleBooks(isbn: isbn.isbn13)
            guard var info = items.first(where: { $0.volumeInfo != nil })?.volumeInfo else {
                return .failure(LookupError(message: "Nessun libro trovato per \(isbn.isbn13)"))
            }
            info.isbn13 = isbn.isbn13
            info.isbn10 = isbn.isbn10
            return .success(info)
        } catch {
            return .failure((error as? LookupError) ?? LookupError(message: error.localizedDescription))
        }
    }

    func reset() {
        books = []
        errorMessage = ""
        state = .Loaded
    }
    // Libri già salvati sul server
    var serverBooks: [Book] = []

    /// Carica i libri dal server; con `search` la ricerca la fa il backend (ignora maiuscole, accenti e caratteri speciali).
    /// `descending` chiede al server l'ordine alfabetico Z→A (default A→Z).
    func loadServerBooks(search: String = "", descending: Bool = false) async {
        state = .Loading
        errorMessage = ""
        var components = URLComponents(string: "\(baseURL)/books")
        let query = search.trimmingCharacters(in: .whitespaces)
        var items: [URLQueryItem] = []
        if !query.isEmpty {
            items.append(URLQueryItem(name: "search", value: query))
        }
        if descending {
            items.append(URLQueryItem(name: "order", value: "desc"))
        }
        if !items.isEmpty {
            components?.queryItems = items
        }
        guard let url = components?.url else {
            errorMessage = "URL non valido"
            state = .Error
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: ServerConfig.request(url: url))
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorMessage = http.statusCode == 401 ? "Autenticazione fallita: controlla utente e password" : "Errore server: \(http.statusCode)"
                state = .Error
                return
            }
            let result = try JSONDecoder().decode(BooksResponse.self, from: data)
            if let serverError = result.error, !serverError.isEmpty {
                errorMessage = "Errore server: \(serverError)"
                state = .Error
                return
            }
            serverBooks = result.books
            state = .Loaded
        } catch {
            // Una ricerca sostituita da una più recente non è un errore
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                return
            }
            print("loadServerBooks error: ", error)
            errorMessage = "Impossibile caricare i libri: \(error.localizedDescription)"
            state = .Error
        }
    }

    /// Aggiorna un libro esistente: il server, ricevendo un "id", sostituisce il documento.
    /// Non tocca `state`, così un errore non sostituisce l'elenco con la schermata d'errore.
    /// Restituisce nil se va tutto bene, altrimenti il messaggio d'errore.
    func update(book: Book) async -> String? {
        guard let url = URL(string: "\(baseURL)/books") else {
            return "URL non valido"
        }
        do {
            var request = ServerConfig.request(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(book)

            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return "Errore server: \(http.statusCode)"
            }
            let result = try JSONDecoder().decode(BooksResponse.self, from: data)
            if let serverError = result.error, !serverError.isEmpty {
                return "Errore server: \(serverError)"
            }
            if let index = serverBooks.firstIndex(where: { $0.id == book.id }) {
                serverBooks[index] = result.books.first ?? book
            }
            return nil
        } catch {
            print("update error: ", error)
            return "Errore nella richiesta: \(error.localizedDescription)"
        }
    }

    /// Cancella un libro dal server (DELETE /books/{id}) e lo toglie dall'elenco locale.
    /// Non tocca `state`; restituisce nil se va tutto bene, altrimenti il messaggio d'errore.
    func delete(book: Book) async -> String? {
        guard let id = book.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              !id.isEmpty,
              let url = URL(string: "\(baseURL)/books/\(id)") else {
            return "URL non valido"
        }
        do {
            var request = ServerConfig.request(url: url)
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return http.statusCode == 401 ? "Autenticazione fallita: controlla utente e password" : "Errore server: \(http.statusCode)"
            }
            serverBooks.removeAll { $0.id == book.id }
            return nil
        } catch {
            print("delete error: ", error)
            return "Errore nella richiesta: \(error.localizedDescription)"
        }
    }

    func send(book: VolumeInfo) async -> Bool {
        state = .Loading
        guard let url = URL(string: "\(baseURL)/books") else {
            print("Invalid URL")
            state = .Error
            errorMessage = "URL non valido"
            return false
        }
        
        do {
            var request = ServerConfig.request(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            let encoder = JSONEncoder()
            print("authors", book.authors ?? [])
            let data = try encoder.encode(book)
            request.httpBody = data
            
            let (dataResponse, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                state = .Error
                errorMessage = "Risposta non valida"
                return false
            }
            
            print("Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                do {
                    // Il server risponde con {"books": [...], "error": "", "total": n}
                    let result = try decoder.decode(BooksResponse.self, from: dataResponse)
                    if let serverError = result.error, !serverError.isEmpty {
                        print("Server error: \(serverError)")
                        state = .Error
                        errorMessage = "Errore server: \(serverError)"
                        return false
                    }
                    print("Libro salvato:", result.books.first?.id ?? "-")
                    state = .Loaded
                    return true
                } catch {
                    print("Decoding error: ", error)
                    let resultString = String(data: dataResponse, encoding: .utf8)
                    print("Response data: \(String(describing: resultString))")
                    state = .Error
                    errorMessage = "Errore nella decodifica della risposta"
                    return false
                }
            } else {
                let resultString = String(data: dataResponse, encoding: .utf8)
                print("Error response: \(String(describing: resultString))")
                state = .Error
                errorMessage = "Errore server: \(httpResponse.statusCode)"
                return false
            }
        } catch {
            print("Request error: ", error)
            state = .Error
            errorMessage = "Errore nella richiesta: \(error.localizedDescription)"
            return false
        }
    }
}
