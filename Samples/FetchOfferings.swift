import Foundation
import PayblastPurchases

struct URLSessionHTTP: HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response as! HTTPURLResponse)
    }
}

struct PreviewStore: StorePurchasing {
    func purchase(productId: String) async throws -> String { productId }
}

@main
struct FetchOfferings {
    static func main() async throws {
        let purchases = Purchases(
            baseURL: URL(string: "http://127.0.0.1:4000")!,
            http: URLSessionHTTP(),
            store: PreviewStore()
        )
        purchases.configure(apiKey: "pk_replace_me", appUserId: "sample-user")
        let data = try await purchases.getOfferings()
        print(String(decoding: data, as: UTF8.self))
    }
}
