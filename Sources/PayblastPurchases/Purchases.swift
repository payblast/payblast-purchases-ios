import Foundation
#if os(iOS)
import StoreKit
#endif

public protocol HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public protocol StorePurchasing {
    func purchase(productId: String) async throws -> String
}

public struct Package: Decodable, Sendable {
    public let lookupKey: String
    public let products: [String: String]

    enum CodingKeys: String, CodingKey {
        case lookupKey = "lookup_key"
        case products
    }
}

public struct CustomerInfo: Decodable, Sendable {
    public let appUserId: String
    public let entitlements: [String: Entitlement]

    public struct Entitlement: Decodable, Sendable {
        public let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case isActive = "is_active"
        }
    }

    enum CodingKeys: String, CodingKey {
        case appUserId = "app_user_id"
        case entitlements
    }
}

public enum PurchasesError: Error {
    case productUnavailable
    case unverified
    case cancelled
    case pending
    case requestFailed
}

public final class Purchases: @unchecked Sendable {
    private let baseURL: URL
    private let http: HTTPClient
    private let store: StorePurchasing
    private var apiKey = ""
    private var appUserId = ""

    public init(baseURL: URL, http: HTTPClient, store: StorePurchasing) {
        self.baseURL = baseURL
        self.http = http
        self.store = store
    }

    public func configure(apiKey: String, appUserId: String) {
        self.apiKey = apiKey
        self.appUserId = appUserId
    }

    public func logIn(appUserId: String) async throws -> CustomerInfo {
        let body = try JSONSerialization.data(withJSONObject: ["new_app_user_id": appUserId])
        let info: CustomerInfo = try await send(path: "/v1/customers/\(self.appUserId)/login", method: "POST", body: body)
        self.appUserId = appUserId
        return info
    }

    public func logOut() {
        appUserId = "$payblastAnon\(UUID().uuidString)"
    }

    public func getOfferings() async throws -> Data {
        try await raw(path: "/v1/offerings", method: "GET", body: nil)
    }

    public func purchase(package: Package) async throws -> CustomerInfo {
        let productId = package.products["ios"] ?? ""
        _ = try await store.purchase(productId: productId)
        return try await getCustomerInfo()
    }

    public func restore() async throws -> CustomerInfo {
        try await getCustomerInfo()
    }

    public func getCustomerInfo() async throws -> CustomerInfo {
        try await send(path: "/v1/customers/\(appUserId)", method: "GET", body: nil)
    }

    public func presentPaywall(document: String, packages: [Package]) -> String {
        let keys = packages.map(\.lookupKey).joined(separator: " ")
        return "\(document) \(keys)"
    }

    private func send<T: Decodable>(path: String, method: String, body: Data?) async throws -> T {
        let data = try await raw(path: path, method: method, body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func raw(path: String, method: String, body: Data?) async throws -> Data {
        let root = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: URL(string: root + path)!)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await http.send(request)
        guard (200 ..< 300).contains(response.statusCode) else { throw PurchasesError.requestFailed }
        return data
    }
}

#if os(iOS)
public struct StoreKitPurchaser: StorePurchasing {
    public init() {}

    public func purchase(productId: String) async throws -> String {
        let products = try await Product.products(for: [productId])
        guard let product = products.first else { throw PurchasesError.productUnavailable }
        switch try await product.purchase() {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return String(transaction.id)
            case .unverified:
                throw PurchasesError.unverified
            }
        case .userCancelled:
            throw PurchasesError.cancelled
        case .pending:
            throw PurchasesError.pending
        @unknown default:
            throw PurchasesError.pending
        }
    }
}
#endif
