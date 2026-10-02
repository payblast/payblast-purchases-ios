import XCTest
@testable import PayblastPurchases

final class PurchasesTests: XCTestCase {
    func testContractReadsOfferingsPurchasesAndRendersPackageKeys() async throws {
        let http = FakeHTTP()
        let store = FakeStore()
        let purchases = Purchases(baseURL: URL(string: "http://127.0.0.1:4000")!, http: http, store: store)
        purchases.configure(apiKey: "pk_test", appUserId: "user-1")

        let offerings = try await purchases.getOfferings()
        XCTAssertTrue(String(decoding: offerings, as: UTF8.self).contains("monthly"))

        let package = Package(lookupKey: "monthly", products: ["ios": "pro_monthly"])
        let info = try await purchases.purchase(package: package)
        XCTAssertEqual(info.entitlements["pro"]?.isActive, true)
        XCTAssertEqual(store.purchased, "pro_monthly")
        XCTAssertEqual(http.authorization, "Bearer pk_test")

        let rendered = purchases.presentPaywall(document: fixture, packages: [
            Package(lookupKey: "monthly", products: ["ios": "pro_monthly"]),
            Package(lookupKey: "annual", products: ["ios": "pro_annual"]),
        ])
        XCTAssertTrue(rendered.contains("monthly"))
        XCTAssertTrue(rendered.contains("annual"))
    }
}

private let fixture = """
{"blocks":[{"type":"text","text":"Go Pro"},{"type":"package_picker"}]}
"""

private final class FakeHTTP: HTTPClient, @unchecked Sendable {
    var authorization = ""

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        authorization = request.value(forHTTPHeaderField: "Authorization") ?? ""
        let path = request.url?.path ?? ""
        let body: String
        if path == "/v1/offerings" {
            body = #"{"offerings":[{"packages":[{"lookup_key":"monthly"}]}]}"#
        } else {
            body = #"{"app_user_id":"user-1","entitlements":{"pro":{"is_active":true}}}"#
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

private final class FakeStore: StorePurchasing, @unchecked Sendable {
    var purchased = ""

    func purchase(productId: String) async throws -> String {
        purchased = productId
        return "txn-1"
    }
}
