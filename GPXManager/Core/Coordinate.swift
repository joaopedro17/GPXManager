import Foundation

struct Coordinate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var group: String = "Ungrouped"

    var latitudeString: String { String(format: "%.6f", latitude) }
    var longitudeString: String { String(format: "%.6f", longitude) }
}
