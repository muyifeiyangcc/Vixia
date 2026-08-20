//
//  CASkyBudgetBudgetRY.swift
//

import Foundation


// MARK: - String obfuscation marker

public func MARKER(_ str: String) -> String {
    return str
}



// MARK: - String AES Decrypt

public extension String {


    func desvixae() -> String {


        let key = "vixiavixiavixiax"
        let iv = ""



        guard let result =
                CAEarthClientFunRY.CADateOurSlimeRY(
                    text: self,
                    key: key,
                    iv: iv
                )
        else {
            return self
        }



        return result.CAEnoughSiteCollectRY(
            isForward: false
        )
    }



    // MARK: Escape sequence handling


    func CAEnoughSiteCollectRY(
        isForward: Bool
    ) -> String {

        let map : KeyValuePairs<String, String> = [
            "\\" : "\\\\",
            "\"" : "\\\"",
            "\'" : "\\\'",
            "\n" : "\\n",
            "\r" : "\\r",
            "\u{000C}" : "\\f",
            "\u{2028}" : "\\u2028",
            "\u{2029}" : "\\u2029"
        ]
        var sendJson = self
        for (k, v) in map {
            let originalStr = isForward ? k : v
            let replacingStr = isForward ? v : k
            sendJson = sendJson.replacingOccurrences(of: originalStr , with: replacingStr)
        }
        return sendJson
    }

}
