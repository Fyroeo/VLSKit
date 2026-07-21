import Foundation
import XCTest
@testable import VLSKit

final class ModelDecodingTests: XCTestCase {

    // MARK: - Date Decoding

    /// Confirms that `JSONDecoder.vls` accepts a timestamp with no time zone
    /// designator and with fractional seconds of different precision.
    ///
    /// The `bikes` endpoint sends timestamps in this format for the `createdAt`,
    /// `updatedAt`, and `lastDataFrameDate` fields.
    func testFlexibleDateAcceptsTimezonelessTimestamps() throws {
        struct Wrapper: Decodable { let date: Date }
        for raw in ["2026-07-10T21:47:28.081586828", "2024-12-26T08:15:38.991457", "2026-07-10T21:40:03"] {
            let json = #"{ "date": "\#(raw)" }"#
            let wrapper = try JSONDecoder.vls.decode(Wrapper.self, from: Data(json.utf8))
            XCTAssertNotNil(wrapper.date, "failed to parse \(raw)")
        }
    }

    /// Confirms that `JSONDecoder.vls` accepts a date-only string with no time
    /// component.
    ///
    /// `Account.birthDate` is a plain calendar date.
    func testFlexibleDateAcceptsDateOnlyStrings() throws {
        struct Wrapper: Decodable { let date: Date }
        let json = #"{ "date": "2003-08-07" }"#
        let wrapper = try JSONDecoder.vls.decode(Wrapper.self, from: Data(json.utf8))
        XCTAssertNotNil(wrapper.date)
    }

    // MARK: - Bike Decoding

    /// Decodes a real response shape from `GET /contracts/lyon/bikes?stationNumber=`,
    /// with the id anonymized.
    ///
    /// This is the electric bike variant. It has a `battery` field and motor and
    /// BMS firmware fields.
    func testElectricBikeDecoding() throws {
        let json = """
        {
          "id": "e5d182ca-4e3f-4d4d-94e3-6c64f24af36e",
          "number": 52009,
          "contractName": "lyon",
          "type": "ELECTRICAL",
          "frameId": "SW2401523",
          "stationNumber": 3058,
          "standNumber": 5,
          "status": "AVAILABLE",
          "statusLabel": "Accroché",
          "hasBattery": true,
          "battery": { "percentage": 83, "type": "INTERNAL", "level": 4 },
          "hasLock": false,
          "rating": { "value": 99.48, "count": 235, "lastRatingDateTime": "2026-07-10T20:56:40.044123" },
          "checked": false,
          "createdAt": "2024-12-26T08:15:38.991457",
          "updatedAt": "2026-07-10T21:47:28.081586828",
          "lastDataFrameDate": "2026-07-10T21:40:03",
          "bikeTopSwVersion": "002.023",
          "bikeTopHwVersion": "E",
          "motorControllerSwVersion": "028.002",
          "motorControllerHwVersion": "M410 2",
          "bmsSwVersion": "000.038",
          "zedSwVersion": "004.004"
        }
        """
        let bike = try JSONDecoder.vls.decode(Bike.self, from: Data(json.utf8))
        XCTAssertEqual(bike.type, .electrical)
        XCTAssertEqual(bike.status, .available)
        XCTAssertEqual(bike.battery?.percentage, 83)
        XCTAssertEqual(bike.rating.value, 99.48)
        XCTAssertEqual(bike.rating.count, 235)
        XCTAssertNil(bike.bikeBatteryMv)
    }

    /// Confirms that `Bike.rating.value` decodes to `nil` when it is missing.
    ///
    /// Production omits `rating.value` on bikes with no ratings yet, even though a
    /// strict model might treat this field as required.
    func testBikeRatingWithoutValueDecodesToNil() throws {
        let json = """
        {
          "id": "e5d182ca-4e3f-4d4d-94e3-6c64f24af36e",
          "number": 52009,
          "contractName": "lyon",
          "type": "ELECTRICAL",
          "frameId": "SW2401523",
          "status": "AVAILABLE",
          "statusLabel": "Accroché",
          "hasBattery": false,
          "hasLock": false,
          "rating": { "count": 0 },
          "checked": false,
          "createdAt": "2024-12-26T08:15:38.991457",
          "updatedAt": "2026-07-10T21:47:28.081586828"
        }
        """
        let bike = try JSONDecoder.vls.decode(Bike.self, from: Data(json.utf8))
        XCTAssertNil(bike.rating.value)
        XCTAssertEqual(bike.rating.count, 0)
    }

    /// Decodes the mechanical bike variant.
    ///
    /// This variant has no `battery` field. It has `bikeBatteryMv` instead, the lock
    /// and tracker battery voltage. It also has no motor or BMS firmware fields.
    func testMechanicalBikeDecoding() throws {
        let json = """
        {
          "id": "adb03696-60e5-49de-86b7-068306085bee",
          "number": 20463,
          "contractName": "lyon",
          "type": "MECHANICAL",
          "frameId": "LP18130581",
          "stationNumber": 1031,
          "standNumber": 20,
          "status": "AVAILABLE",
          "statusLabel": "Accroché",
          "hasBattery": false,
          "hasLock": false,
          "rating": { "value": 80.0, "count": 2, "lastRatingDateTime": "2026-07-10T19:59:22.831615" },
          "checked": false,
          "createdAt": "2018-12-10T22:09:17.651776",
          "updatedAt": "2026-07-10T21:47:49.112261468",
          "lastDataFrameDate": "2026-07-10T19:22:50",
          "bikeBatteryMv": 1530,
          "bikeTopSwVersion": "002.017",
          "bikeTopHwVersion": "C",
          "zedSwVersion": "004.003"
        }
        """
        let bike = try JSONDecoder.vls.decode(Bike.self, from: Data(json.utf8))
        XCTAssertEqual(bike.type, .mechanical)
        XCTAssertNil(bike.battery)
        XCTAssertEqual(bike.bikeBatteryMv, 1530)
        XCTAssertNil(bike.motorControllerSwVersion)
    }

    // MARK: - Station Decoding

    func testStationDecoding() throws {
        let json = """
        {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "contractName": "lyon",
          "number": 1001,
          "open": true,
          "connected": true,
          "name": "Bellecour",
          "capacity": { "main": 20, "overflow": 0 },
          "bonus": false,
          "hasShape": false,
          "overflow": false,
          "location": { "latitude": 45.757, "longitude": 4.832 },
          "availabilities": {
            "main": { "stands": 5, "bikes": { "mechanical": 10, "electrical": 5, "electricalInternalBattery": 0, "electricalRemovableBattery": 0 } },
            "overflow": { "stands": 0, "bikes": { "mechanical": 0, "electrical": 0, "electricalInternalBattery": 0, "electricalRemovableBattery": 0 } }
          },
          "createdAt": "2020-01-01T00:00:00.000Z",
          "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """
        let station = try JSONDecoder.vls.decode(Station.self, from: Data(json.utf8))
        XCTAssertEqual(station.name, "Bellecour")
        XCTAssertTrue(station.isOpen)
        XCTAssertFalse(station.hasBonus)
        XCTAssertEqual(station.availabilities?.main.bikes.mechanical, 10)
    }

    // MARK: - GBFS Decoding

    /// Confirms that `GBFSStationInformation` accepts `station_id` as a string.
    ///
    /// Production returns `station_id` as a string, per the GBFS v2.3+ and v3 spec,
    /// even though a strict model might expect a number instead. `JSONDecoder` does
    /// not convert a string to a number automatically, so this field needs its own
    /// lenient decoding.
    func testGBFSStationInformationAcceptsStringStationID() throws {
        let json = """
        {
          "station_id": "10001",
          "name": [{ "text": "Bellecour", "language": "fr" }],
          "lat": 45.757,
          "lon": 4.832,
          "is_bonus": false
        }
        """
        let info = try JSONDecoder.vls.decode(GBFSStationInformation.self, from: Data(json.utf8))
        XCTAssertEqual(info.id, "10001")
    }

    /// Confirms that `GBFSStationInformation.isBonus` defaults to `false` when
    /// `is_bonus` is missing.
    ///
    /// Production omits `is_bonus` on at least some stations, even though a strict
    /// model might treat this field as required.
    func testGBFSStationInformationDefaultsMissingIsBonusToFalse() throws {
        let json = """
        {
          "station_id": "10001",
          "name": [{ "text": "Bellecour", "language": "fr" }],
          "lat": 45.757,
          "lon": 4.832
        }
        """
        let info = try JSONDecoder.vls.decode(GBFSStationInformation.self, from: Data(json.utf8))
        XCTAssertFalse(info.isBonus)
    }

    func testGBFSStationStatusEpochDecoding() throws {
        let json = """
        {
          "station_id": 42,
          "num_vehicles_available": 3,
          "vehicle_types_available": [{ "vehicle_type_id": "mechanical", "count": 3 }],
          "num_docks_available": 7,
          "is_installed": true,
          "is_renting": true,
          "is_returning": true,
          "last_reported": 1700000000
        }
        """
        let status = try JSONDecoder.vls.decode(GBFSStationStatus.self, from: Data(json.utf8))
        XCTAssertEqual(status.id, "42")
        XCTAssertEqual(status.lastReported.timeIntervalSince1970, 1700000000)
        XCTAssertEqual(status.vehicleTypesAvailable.first?.vehicleTypeID, .mechanical)
    }

    /// Confirms that an unknown GBFS vehicle type value falls back to `.other`.
    ///
    /// Production sends lowercase values such as `mechanical`, `electrical`, and
    /// `creditcard`, even though a strict model might expect uppercase values
    /// instead. An unrecognized value falls back to `.other` and does not fail to
    /// decode.
    func testGBFSVehicleTypeFallsBackForUnknownValue() throws {
        let json = #"{ "vehicle_type_id": "cargo", "count": 1 }"#
        let availability = try JSONDecoder.vls.decode(GBFSStationStatus.VehicleAvailability.self, from: Data(json.utf8))
        XCTAssertEqual(availability.vehicleTypeID, .other("cargo"))
    }

    /// Confirms that `GBFSStationStatus.lastReported` accepts an ISO-8601 string.
    ///
    /// Production sends `last_reported` as an ISO-8601 string, even though the GBFS
    /// spec implies a Unix epoch-seconds number instead.
    func testGBFSLastReportedAcceptsISOString() throws {
        let json = """
        {
          "station_id": "42",
          "num_vehicles_available": 3,
          "vehicle_types_available": [],
          "num_docks_available": 7,
          "is_installed": true,
          "is_renting": true,
          "is_returning": true,
          "last_reported": "2026-07-10T23:28:00.000Z"
        }
        """
        let status = try JSONDecoder.vls.decode(GBFSStationStatus.self, from: Data(json.utf8))
        XCTAssertNotNil(status.lastReported)
    }

    // MARK: - Release and Trip Decoding

    func testReleaseBikeResponseDecodesTypoedEnum() throws {
        let json = #"{ "transactionState": "UNKNOW" }"#
        let response = try JSONDecoder.vls.decode(ReleaseBikeResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.transactionState, .unknown)
    }

    func testTripAllFieldsOptional() throws {
        let response = try JSONDecoder.vls.decode(Trip.self, from: Data("{}".utf8))
        XCTAssertNil(response.id)
        XCTAssertNil(response.status)
    }

    /// Confirms that `Trip.bikeType` decodes leniently when the value is a number.
    ///
    /// A `GET .../trips` response can carry `bikeType` as a bare number. `Bike.type`
    /// normally uses a string value such as `"MECHANICAL"` or `"ELECTRICAL"`. The old
    /// strict decoding threw an error on the number and silently dropped the entire
    /// trip list. This was the real cause of the app bug "unlock succeeds but no trip
    /// data shows". The number `0` means `MECHANICAL` and `1` means `ELECTRICAL`,
    /// matching `/bikes?number=`'s `type` field for the same bike.
    func testTripDecodesLeniantlyWhenBikeTypeIsANumber() throws {
        let mechanical = #"{ "bikeNumber": 12345, "bikeType": 0 }"#
        let mechanicalTrip = try JSONDecoder.vls.decode(Trip.self, from: Data(mechanical.utf8))
        XCTAssertEqual(mechanicalTrip.bikeNumber, 12345)
        XCTAssertEqual(mechanicalTrip.bikeType, .mechanical)

        let electrical = #"{ "bikeNumber": 12346, "bikeType": 1 }"#
        let electricalTrip = try JSONDecoder.vls.decode(Trip.self, from: Data(electrical.utf8))
        XCTAssertEqual(electricalTrip.bikeType, .electrical)
    }

    // MARK: - Subscription Decoding

    func testRenewalDetailsDefaultsToFalse() throws {
        let details = try JSONDecoder.vls.decode(RenewalDetails.self, from: Data("{}".utf8))
        XCTAssertFalse(details.isAutoRenewal)
        XCTAssertFalse(details.canManualRenewal)
    }
}

final class PKCETests: XCTestCase {
    func testCodeChallengeIsDeterministicForAGivenVerifier() {
        // RFC 7636 Appendix B test vector.
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = PKCE.codeChallenge(for: verifier)
        XCTAssertEqual(challenge, "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    func testGeneratedVerifierIsURLSafe() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertFalse(verifier.contains("+"))
        XCTAssertFalse(verifier.contains("/"))
        XCTAssertFalse(verifier.contains("="))
    }
}

final class AuthorizationRequestTests: XCTestCase {
    func testExtractCodeFromMatchingRedirect() {
        let redirectURI = URL(string: "https://velov.grandlyon.com/")!
        let callback = URL(string: "https://velov.grandlyon.com/?code=abc123&state=xyz")!
        let result = AuthorizationRequestBuilder.extractCode(from: callback, redirectURI: redirectURI)
        XCTAssertEqual(result?.code, "abc123")
        XCTAssertEqual(result?.state, "xyz")
    }

    func testExtractCodeReturnsNilForUnrelatedURL() {
        let redirectURI = URL(string: "https://velov.grandlyon.com/")!
        let other = URL(string: "https://iam.cyclocity.fr/realms/vls-default/protocol/openid-connect/auth")!
        XCTAssertNil(AuthorizationRequestBuilder.extractCode(from: other, redirectURI: redirectURI))
    }
}
