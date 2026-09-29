import Foundation
import Testing

@testable import CodexClient

struct ResponseDecodingTests {
    @Test func readsAnAccountWithoutAnEmail() throws {
        let json = #"{"account": {"type": "apiKey"}, "requiresOpenaiAuth": true}"#

        let response = try JSONDecoder().decode(AccountResponse.self, from: Data(json.utf8))

        #expect(response.account == Account(type: "apiKey", email: nil))
    }

    @Test func readsNoAccountWhenNobodyIsSignedIn() throws {
        let json = #"{"account": null, "requiresOpenaiAuth": true}"#

        #expect(
            try JSONDecoder().decode(AccountResponse.self, from: Data(json.utf8)).account == nil)
    }

    @Test func readsRateLimitsWithoutTheOptionalParts() throws {
        let json =
            #"{"rateLimits": {"primary": {"usedPercent": 3.5, "windowDurationMins": null, "resetsAt": null}}}"#

        let rateLimits = try JSONDecoder().decode(RateLimits.self, from: Data(json.utf8))

        #expect(rateLimits.accountId == nil)
        #expect(rateLimits.rateLimits?.primary?.usedPercent == 3.5)
        #expect(rateLimits.rateLimitsByLimitId == nil)
    }
}
