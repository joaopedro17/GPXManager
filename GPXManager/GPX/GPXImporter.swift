import Foundation

enum GPXImporter {
    struct ImportResult {
        let coordinates: [Coordinate]
        let skipped: Int
    }

    static func parse(url: URL, defaultGroup: String = "Imported") -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            return ImportResult(coordinates: [], skipped: 0)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            return ImportResult(coordinates: [], skipped: 0)
        }

        let parser = GPXParser(data: data, defaultGroup: defaultGroup)
        return parser.parse()
    }
}

// MARK: - GPXParser

private class GPXParser: NSObject, XMLParserDelegate {
    private let data: Data
    private let defaultGroup: String

    private var coordinates: [Coordinate] = []
    private var skipped = 0

    private var currentLat: Double?
    private var currentLon: Double?
    private var currentName: String?
    private var insideNameTag = false
    private var currentElement = ""

    init(data: Data, defaultGroup: String) {
        self.data = data
        self.defaultGroup = defaultGroup
    }

    func parse() -> GPXImporter.ImportResult {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return GPXImporter.ImportResult(coordinates: coordinates, skipped: skipped)
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes: [String: String]) {
        currentElement = elementName

        if elementName == "wpt" || elementName == "trkpt" || elementName == "rtept" {
            if let latStr = attributes["lat"], let lonStr = attributes["lon"],
               let lat = Double(latStr), let lon = Double(lonStr) {
                currentLat = lat
                currentLon = lon
                currentName = nil
            }
        }

        if elementName == "n" || elementName == "name" {
            insideNameTag = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if insideNameTag {
            currentName = (currentName ?? "") + trimmed
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "n" || elementName == "name" {
            insideNameTag = false
        }

        if elementName == "wpt" || elementName == "trkpt" || elementName == "rtept" {
            guard let lat = currentLat, let lon = currentLon else {
                skipped += 1
                return
            }

            guard (-90...90).contains(lat), (-180...180).contains(lon) else {
                skipped += 1
                return
            }

            let name = currentName?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "Waypoint \(coordinates.count + 1)"

            coordinates.append(Coordinate(
                name: name,
                latitude: lat,
                longitude: lon,
                group: defaultGroup
            ))

            currentLat = nil
            currentLon = nil
            currentName = nil
        }
    }
}
