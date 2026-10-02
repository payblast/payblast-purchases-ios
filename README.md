# payblast-purchases-ios

Payblast iOS SDK (StoreKit 2)

This repository does not vendor RevenueCat source. The public API shape is studied from [https://github.com/RevenueCat/purchases-ios](https://github.com/RevenueCat/purchases-ios) and reimplemented against Payblast.

## Contract

```text
configure(apiKey, appUserId)
logIn(appUserId) / logOut()
getOfferings()
purchase(package)
restore()
getCustomerInfo()
presentPaywall(offering?)
```

```bash
swift test
```

`Samples/FetchOfferings.swift` calls `getOfferings` against `http://127.0.0.1:4000`. StoreKit 2 purchases stay behind `StorePurchasing`; tests use a fake store.

`getCustomerInfo` exposes `entitlements[lookupKey].isActive`. Packages carry the store product identifier for this SDK's platform. Purchases of digital goods inside the native app go through that store. Web purchases use Stripe Checkout on the app maker's connected account.

## Reference

- https://github.com/RevenueCat/purchases-ios
