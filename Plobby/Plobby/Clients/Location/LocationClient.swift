//
//  LocationClient.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import CoreLocation

import Dependencies

struct LocationClient {

    var currentLocation: @Sendable () async throws -> Coordinate
}

extension LocationClient: DependencyKey {

    static let liveValue: LocationClient = {
        .init(
            currentLocation: {
                let session = CLServiceSession(authorization: .whenInUse)
                defer { session.invalidate() }

                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location {
                        return Coordinate(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                    }

                    if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                        throw LocationClientError.denied
                    }
                }

                throw LocationClientError.unavailable
            }
        )
    }()
}

// MARK: - LocationAuthorizationRequest

/// CLLocationManager의 권한 변경 콜백을 async로 바꿔요. 요청이 끝날 때까지 호출한 쪽이 붙잡고 있어요.
@MainActor
private final class LocationAuthorizationRequest: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<LocationAuthorization, Never>?

    func request() async -> LocationAuthorization {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return LocationAuthorization(status) }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            // 델리게이트를 붙이자마자 현재 상태(.notDetermined)로 한 번 호출되므로, 결정된 뒤에만 돌려줘요.
            let status = self.manager.authorizationStatus
            guard status != .notDetermined else { return }

            continuation?.resume(returning: LocationAuthorization(status))
            continuation = nil
        }
    }
}

private extension LocationAuthorization {

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        default:
            self = .denied
        }
    }
}
