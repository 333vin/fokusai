//
//  AnalyticsService.swift
//  fokusai
//
//  Anonymous install-level analytics. Identifies a device install (UUID in
//  UserDefaults), never a person. Posts event rows to Supabase REST. Failures
//  are swallowed — analytics must never crash or stall the UI.
//

import Foundation

enum AnalyticsService {

    private static let installIDKey = "fokusai.installID"

    /// Stable per-install identifier. Created once, reused forever.
    static var installID: UUID {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: installIDKey),
           let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        defaults.set(id.uuidString, forKey: installIDKey)
        return id
    }

    /// Fire-and-forget event. Never logs task text or personal content.
    static func log(_ eventName: String, metadata: [String: String]? = nil) {
        let installID = self.installID
        Task.detached {
            do {
                let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/events")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                request.timeoutInterval = 15

                let body = EventBody(
                    install_id: installID.uuidString,
                    event_name: eventName,
                    metadata: metadata
                )
                request.httpBody = try JSONEncoder().encode(body)

                let (_, response) = try await URLSession.shared.data(for: request)
                _ = response
            } catch {
                // Silent by design — analytics must never affect the app.
            }
        }
    }

    private struct EventBody: Encodable {
        let install_id: String
        let event_name: String
        let metadata: [String: String]?
    }
}
