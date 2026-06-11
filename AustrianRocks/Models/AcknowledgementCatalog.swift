import Foundation

/// Decodes the bundled `Acknowledgements.json` legal-notice catalog.
///
/// Schema v1:
/// - `schemaVersion`: integer schema marker.
/// - `audit`: dependency-audit metadata with `packageResolvedOriginHash`,
///   `auditedPackagePins`, `sourceFiles`, and `omissions`.
/// - `sections`: localized UI groupings. Each section has `id`, `titleKey`, and `entries`.
/// - `entries`: legal notices with `id`, `name`, `version`, `licenseName`,
///   `copyright`, `url`, and verbatim `notice` text.
///
/// When `Package.resolved` changes, re-audit the source files listed in the JSON:
/// the app `LICENSE.md`, `Package.resolved`, and each resolved non-Apple Swift Package
/// license file under Xcode's `SourcePackages/checkouts`. Keep the audited pins, source
/// files, omissions, and notice entries in sync with the current MapLibre and SQLite
/// dependencies while leaving this loader unchanged.
struct AcknowledgementCatalog: Decodable {
    let schemaVersion: Int
    let audit: AcknowledgementAudit
    let sections: [AcknowledgementSection]

    static func load(
        from bundle: Bundle = .main,
        resourceName: String = "Acknowledgements"
    ) throws -> AcknowledgementCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadError.missingResource(resourceName: resourceName)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoadError.unreadableResource(resourceName: resourceName, underlying: error)
        }

        do {
            return try JSONDecoder().decode(AcknowledgementCatalog.self, from: data)
        } catch {
            throw LoadError.malformedResource(resourceName: resourceName, underlying: error)
        }
    }

    enum LoadError: LocalizedError {
        case missingResource(resourceName: String)
        case unreadableResource(resourceName: String, underlying: Error)
        case malformedResource(resourceName: String, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .missingResource(let resourceName):
                return "Missing bundled acknowledgement resource: \(resourceName).json"
            case .unreadableResource(let resourceName, let underlying):
                return "Could not read acknowledgement resource \(resourceName).json: \(underlying.localizedDescription)"
            case .malformedResource(let resourceName, let underlying):
                return "Could not decode acknowledgement resource \(resourceName).json: \(underlying.localizedDescription)"
            }
        }
    }
}

struct AcknowledgementAudit: Decodable {
    let packageResolvedOriginHash: String
    let auditedPackagePins: [AuditedPackagePin]
    let sourceFiles: [String]
    let omissions: [AcknowledgementOmission]
}

struct AuditedPackagePin: Decodable {
    let identity: String
    let version: String
    let revision: String
    let licenseFile: String
}

struct AcknowledgementSection: Decodable, Identifiable {
    let id: String
    let titleKey: String
    let entries: [AcknowledgementEntry]
}

struct AcknowledgementEntry: Decodable, Identifiable {
    let id: String
    let name: String
    let version: String
    let licenseName: String
    let copyright: String
    let url: URL
    let notice: String
}

struct AcknowledgementOmission: Decodable, Identifiable {
    let dependencyName: String
    let reason: String

    var id: String { dependencyName }
}
