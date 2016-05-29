
import CryptoEssentials

extension String {
    var sha256String: String {
        return Base64.urlSafeEncode((self).sha256())
    }
}

