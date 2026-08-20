import Combine
import Foundation
import UIKit

/// One identified aircraft. Same tail is not counted again for a few hours.
struct SpotEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let icao24: String
    let typeCode: String
    let familyId: String
    let callsign: String
    let airlineKey: String
    let airlineName: String

    init(
        date: Date = Date(),
        icao24: String,
        typeCode: String,
        familyId: String,
        callsign: String,
        airlineKey: String,
        airlineName: String
    ) {
        self.id = UUID()
        self.date = date
        self.icao24 = icao24
        self.typeCode = typeCode
        self.familyId = familyId
        self.callsign = callsign
        self.airlineKey = airlineKey
        self.airlineName = airlineName
    }
}

struct AirlineSpotSummary: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let count: Int
    let sampleCallsign: String
}

struct PlaneCard: Identifiable, Hashable {
    var id: String { familyId }
    let familyId: String
    let number: Int
    let shortTitle: String
    let fullName: String
    let spotCount: Int
    let topAirline: AirlineSpotSummary?
    let airlines: [AirlineSpotSummary]
    let firstSpotted: Date
}

struct UserProfileStore {
    static let shared = UserProfileStore()

    private let debounce: TimeInterval = 2 * 60 * 60
    private let nameKey = "overhead.profile.displayName"

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var spotsURL: URL {
        directory.appendingPathComponent("spots.json")
    }

    private var photoURL: URL {
        directory.appendingPathComponent("avatar.jpg")
    }

    private var directory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Overhead", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func loadName() -> String {
        UserDefaults.standard.string(forKey: nameKey) ?? ""
    }

    func saveName(_ name: String) {
        UserDefaults.standard.set(name, forKey: nameKey)
    }

    func loadPhoto() -> UIImage? {
        guard let data = try? Data(contentsOf: photoURL) else { return nil }
        return UIImage(data: data)
    }

    func savePhoto(_ image: UIImage?) {
        if let image {
            let data = image.jpegData(compressionQuality: 0.86)
            try? data?.write(to: photoURL, options: .atomic)
        } else {
            try? fileManager.removeItem(at: photoURL)
        }
    }

    func loadSpots() -> [SpotEvent] {
        guard let data = try? Data(contentsOf: spotsURL),
              let spots = try? decoder.decode([SpotEvent].self, from: data)
        else { return [] }
        return spots
    }

    func saveSpots(_ spots: [SpotEvent]) {
        guard let data = try? encoder.encode(spots) else { return }
        try? data.write(to: spotsURL, options: .atomic)
    }

    func shouldRecord(flight: Flight, existing: [SpotEvent], now: Date = Date()) -> SpotEvent? {
        let type = flight.type.uppercased().trimmingCharacters(in: .whitespaces)
        guard let family = PlaneCardCatalog.familyId(forType: type) else { return nil }
        let icao = flight.icao24.lowercased()
        if let last = existing.filter({ $0.icao24.lowercased() == icao }).map(\.date).max(),
           now.timeIntervalSince(last) < debounce {
            return nil
        }
        let cs = flight.callsign.trimmingCharacters(in: .whitespacesAndNewlines)
        return SpotEvent(
            date: now,
            icao24: icao,
            typeCode: type,
            familyId: family,
            callsign: cs,
            airlineKey: airlineICAO(cs),
            airlineName: airlineName(cs)
        )
    }

    func cards(from spots: [SpotEvent]) -> [PlaneCard] {
        let grouped = Dictionary(grouping: spots, by: \.familyId)
        let ordered = grouped.keys.sorted { a, b in
            let da = grouped[a]?.map(\.date).min() ?? .distantFuture
            let db = grouped[b]?.map(\.date).min() ?? .distantFuture
            if da != db { return da < db }
            return a < b
        }
        return ordered.enumerated().map { index, family in
            let events = grouped[family] ?? []
            let first = events.map(\.date).min() ?? Date()
            let airlines = airlineSummaries(in: events)
            let sampleType = events.last?.typeCode ?? ""
            return PlaneCard(
                familyId: family,
                number: index + 1,
                shortTitle: PlaneCardCatalog.shortTitle(familyId: family, typeCode: sampleType),
                fullName: PlaneCardCatalog.fullName(familyId: family, typeCode: sampleType),
                spotCount: events.count,
                topAirline: airlines.first,
                airlines: airlines,
                firstSpotted: first
            )
        }
    }

    private func airlineSummaries(in events: [SpotEvent]) -> [AirlineSpotSummary] {
        let grouped = Dictionary(grouping: events, by: \.airlineKey)
        return grouped.map { key, list in
            let latest = list.max(by: { $0.date < $1.date })
            return AirlineSpotSummary(
                key: key,
                name: latest?.airlineName ?? airlineName(key),
                count: list.count,
                sampleCallsign: latest?.callsign ?? key
            )
        }
        .sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.name < $1.name
        }
    }
}

@MainActor
final class UserProfile: ObservableObject {
    @Published var displayName: String {
        didSet { UserProfileStore.shared.saveName(displayName) }
    }
    @Published var photo: UIImage? {
        didSet { UserProfileStore.shared.savePhoto(photo) }
    }
    @Published private(set) var spots: [SpotEvent]

    var cards: [PlaneCard] {
        UserProfileStore.shared.cards(from: spots)
    }

    init() {
        let store = UserProfileStore.shared
        displayName = store.loadName()
        photo = store.loadPhoto()
        var loaded = store.loadSpots()
        let dummySet = 3
        let dummyKey = "overhead.profile.dummySet"
        if UserDefaults.standard.integer(forKey: dummyKey) < dummySet || loaded.isEmpty {
            loaded = Self.demoSpots
            store.saveSpots(loaded)
            UserDefaults.standard.set(dummySet, forKey: dummyKey)
        }
        spots = loaded
    }

    /// Placeholder collection — the three painted plates only.
    private static let demoSpots: [SpotEvent] = [
        SpotEvent(
            date: Date().addingTimeInterval(-86_400),
            icao24: "demo-b737",
            typeCode: "B737",
            familyId: "ac_b737",
            callsign: "DAL123",
            airlineKey: "DAL",
            airlineName: "DELTA"
        ),
        SpotEvent(
            date: Date().addingTimeInterval(-50_000),
            icao24: "demo-b777",
            typeCode: "B777",
            familyId: "ac_b777",
            callsign: "UAL88",
            airlineKey: "UAL",
            airlineName: "UNITED"
        ),
        SpotEvent(
            date: Date().addingTimeInterval(-4_000),
            icao24: "demo-a380",
            typeCode: "A388",
            familyId: "ac_a380",
            callsign: "UAE203",
            airlineKey: "UAE",
            airlineName: "EMIRATES"
        ),
    ]

    @discardableResult
    func recordSpot(from flight: Flight) -> Bool {
        guard let event = UserProfileStore.shared.shouldRecord(flight: flight, existing: spots)
        else { return false }
        let isNewCard = !spots.contains(where: { $0.familyId == event.familyId })
        spots.append(event)
        UserProfileStore.shared.saveSpots(spots)
        if isNewCard {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        return true
    }

    func card(familyId: String) -> PlaneCard? {
        cards.first { $0.familyId == familyId }
    }
}

enum PlaneCardCatalog {
    static func familyId(forType code: String) -> String? {
        let type = code.uppercased().trimmingCharacters(in: .whitespaces)
        guard !type.isEmpty else { return nil }
        return AircraftIcon.assetName(for: type) ?? type
    }

    static func shortTitle(familyId: String, typeCode: String) -> String {
        if let mapped = titles[familyId]?.short { return mapped }
        let spec = AIRCRAFT_DB[typeCode.uppercased()]?.name ?? typeCode
        return compactNumber(from: spec)
    }

    static func fullName(familyId: String, typeCode: String) -> String {
        if let mapped = titles[familyId]?.full { return mapped }
        if let spec = AIRCRAFT_DB[typeCode.uppercased()] { return spec.name }
        return typeCode.isEmpty ? "Aircraft" : typeCode
    }

    private static func compactNumber(from name: String) -> String {
        let parts = name.split(separator: " ")
        if let last = parts.last, last.contains(where: \.isNumber) {
            return String(last.prefix(6))
        }
        return String(name.suffix(5))
    }

    private static let titles: [String: (short: String, full: String)] = [
        "ac_b737": ("B737", "Boeing 737"),
        "ac_b747": ("B747", "Boeing 747"),
        "ac_b757": ("B757", "Boeing 757"),
        "ac_b767": ("B767", "Boeing 767"),
        "ac_b777": ("B777", "Boeing 777"),
        "ac_b787": ("B787", "Boeing 787"),
        "ac_b707": ("B707", "Boeing 707"),
        "ac_a220": ("A220", "Airbus A220"),
        "ac_a310": ("A310", "Airbus A310"),
        "ac_a320": ("A320", "Airbus A320"),
        "ac_a321": ("A321", "Airbus A321"),
        "ac_a330": ("A330", "Airbus A330"),
        "ac_a340": ("A340", "Airbus A340"),
        "ac_a350": ("A350", "Airbus A350"),
        "ac_a380": ("A380", "Airbus A380"),
        "ac_e170": ("E170", "Embraer E170"),
        "ac_e175": ("E175", "Embraer E175"),
        "ac_e190": ("E190", "Embraer E190"),
        "ac_e195": ("E195", "Embraer E195"),
        "ac_erj135": ("ERJ", "Embraer ERJ"),
        "ac_erj145": ("ERJ", "Embraer ERJ"),
        "ac_atr42": ("ATR 42", "ATR 42"),
        "ac_atr72": ("ATR 72", "ATR 72"),
        "ac_dash8": ("Q400", "Dash 8"),
        "ac_citation": ("CJ", "Citation"),
        "ac_cessna150": ("150", "Cessna 150"),
        "ac_cessna152": ("152", "Cessna 152"),
        "ac_cessna172": ("172", "Cessna 172"),
        "ac_pipercub": ("Cub", "Piper Cub"),
    ]
}
