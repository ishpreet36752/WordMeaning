; Dictionary.ahk — dictionaryapi.dev client. Validates input, HTTPS only,
; extracts part-of-speech + first definition. Pronunciation fields ignored by design.
#Requires AutoHotkey v2.0

class Dictionary {
    static _cache := Map()

    ; Returns { ok, word, partOfSpeech, definition, error }
    static Lookup(word) {
        word := Trim(word)

        if (StrLen(word) > Config.MaxWordLen || !RegExMatch(word, Config.WordPattern))
            return { ok: false, word: word, error: "not a single word" }

        key := StrLower(word)
        if Dictionary._cache.Has(key)
            return Dictionary._cache[key]

        result := Dictionary._Fetch(key)

        if (Dictionary._cache.Count >= Config.CacheMaxEntries)
            Dictionary._cache.Clear()
        Dictionary._cache[key] := result
        return result
    }

    static _Fetch(word) {
        url := Config.ApiBase . Dictionary._UrlEncode(word)
        try {
            req := ComObject("WinHttp.WinHttpRequest.5.1")
            req.SetTimeouts(Config.HttpTimeoutMs, Config.HttpTimeoutMs, Config.HttpTimeoutMs, Config.HttpTimeoutMs)
            req.Open("GET", url, false)
            req.SetRequestHeader("Accept", "application/json")
            req.Send()
        } catch {
            return { ok: false, word: word, error: "offline / network error" }
        }

        if (req.Status == 404)
            return { ok: false, word: word, error: "no definition found" }
        if (req.Status != 200)
            return { ok: false, word: word, error: "service error (" . req.Status . ")" }

        return Dictionary._Parse(word, req.ResponseText)
    }

    ; Minimal targeted extraction — full JSON parsing is unnecessary for two fields.
    static _Parse(word, body) {
        pos := ""
        def := ""
        if RegExMatch(body, '"partOfSpeech"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
            pos := m[1]
        if RegExMatch(body, '"definition"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
            def := Dictionary._Unescape(m[1])

        if (def == "")
            return { ok: false, word: word, error: "no definition found" }

        if (StrLen(def) > Config.MaxDefinitionLen)
            def := SubStr(def, 1, Config.MaxDefinitionLen) . "…"

        return { ok: true, word: word, partOfSpeech: pos, definition: def, error: "" }
    }

    static _Unescape(s) {
        s := StrReplace(s, '\"', '"')
        s := StrReplace(s, "\n", " ")
        s := StrReplace(s, "\t", " ")
        s := StrReplace(s, "\\", "\")
        return s
    }

    static _UrlEncode(s) {
        out := ""
        loop parse s {
            c := A_LoopField
            if RegExMatch(c, "[A-Za-z0-9\-_.~]")
                out .= c
            else
                out .= Format("%{:02X}", Ord(c))
        }
        return out
    }
}
