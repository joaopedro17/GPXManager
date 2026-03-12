import Foundation

enum GPXExportMode {
    case waypoints, route
}

enum GPXGenerator {
    static func generate(from coordinates: [Coordinate], mode: GPXExportMode = .waypoints) -> String {
        let isoDate = ISO8601DateFormatter().string(from: Date())

        let waypointBlock: String
        let trackBlock: String

        switch mode {
        case .waypoints:
            waypointBlock = coordinates.map { coord in
                "    <wpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">\n        <n>\(escapeXML(coord.name))</n>\n    </wpt>"
            }.joined(separator: "\n")
            trackBlock = ""

        case .route:
            waypointBlock = ""
            let trackPoints = coordinates.map { coord in
                "            <trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">\n                <n>\(escapeXML(coord.name))</n>\n            </trkpt>"
            }.joined(separator: "\n")
            trackBlock = "    <trk>\n        <n>Route</n>\n        <trkseg>\n\(trackPoints)\n        </trkseg>\n    </trk>"
        }

        let blocks = [waypointBlock, trackBlock].filter { !$0.isEmpty }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1"
             creator="GPXManager"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
            <metadata>
                <n>GPXManager Export</n>
                <time>\(isoDate)</time>
            </metadata>
        \(blocks)
        </gpx>
        """
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
