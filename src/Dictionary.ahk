; Dictionary.ahk — freedictionaryapi.com client (Wiktionary data, no API key) with a
; Datamuse fallback for words the primary's snapshot is missing.
; Wiktionary lists senses in historical order, so the first one is often the least
; useful ("juxtaposition: the nearness of objects with little or no delimiter").
; _Score picks the most everyday sense instead and carries its example sentence.
; Input validation, HTTPS only, session cache. Pronunciation fields ignored by design.
#Requires AutoHotkey v2.0

class Dictionary {
    static _cache := Map()

    ; Returns { ok, word, partOfSpeech, definition, example, error }
    static Lookup(word) {
        word := Trim(word)

        if (StrLen(word) > Config.MaxWordLen || !RegExMatch(word, Config.WordPattern))
            return Dictionary._Fail(word, "not a single word")

        key := StrLower(word)
        if Dictionary._cache.Has(key)
            return Dictionary._cache[key]

        result := Dictionary._Fetch(key)

        if (Dictionary._cache.Count >= Config.CacheMaxEntries)
            Dictionary._cache.Clear()
        Dictionary._cache[key] := result
        return result
    }

    ; Public so callers can build the web-search URL without a second encoder.
    static UrlEncode(s) {
        return Dictionary._UrlEncode(s)
    }

    static _Fetch(word) {
        enc := Dictionary._UrlEncode(word)

        body := Dictionary._Get(Config.ApiBase . enc, &status)
        if (status == 0)
            return Dictionary._Fail(word, "offline / network error")
        if (status == 200) {
            r := Dictionary._Parse(word, body)
            if r.ok
                return r
        }

        body := Dictionary._Get(Config.ApiFallbackBase . enc, &fbStatus)
        if (fbStatus == 200) {
            r := Dictionary._ParseFallback(word, body)
            if r.ok
                return r
        }

        ; A real 404 means the word is unknown; any other status is the service failing.
        if (status != 200 && status != 404)
            return Dictionary._Fail(word, "service error (" . status . ")")
        return Dictionary._Fail(word, "no definition found")
    }

    ; Returns the response body; sets status (0 = host unreachable at all).
    static _Get(url, &status) {
        status := 0
        try {
            req := ComObject("WinHttp.WinHttpRequest.5.1")
            req.SetTimeouts(Config.HttpTimeoutMs, Config.HttpTimeoutMs, Config.HttpTimeoutMs, Config.HttpTimeoutMs)
            req.Open("GET", url, false)
            req.SetRequestHeader("Accept", "application/json")
            req.Send()
            status := req.Status
            return req.ResponseText
        } catch {
            return ""
        }
    }

    ; Walks the response in document order, collecting one candidate per sense.
    ; Targeted scanning beats a full JSON parser here: three fields are needed and the
    ; order already says which example belongs to which sense (a sense's examples always
    ; follow its definition, and subsenses follow their parent).
    ; "quotes" are deliberately not matched — they are long literary citations.
    static _Parse(word, body) {
        static token := '"partOfSpeech"\s*:\s*"([^"]*)"'
                      . '|"definition"\s*:\s*"((?:[^"\\]|\\.)*)"'
                      . '|"examples"\s*:\s*\[\s*"((?:[^"\\]|\\.)*)"'

        cands := [], pos := "", open := false, p := 1
        while RegExMatch(body, token, &m, p) {
            p := m.Pos + m.Len
            if m.Pos[1] {                      ; applies to every sense that follows it
                pos := m[1], open := false
            } else if m.Pos[2] {
                def := Dictionary._Clean(Dictionary._Unescape(m[2]))
                ; A skipped sense also closes the slot, so its examples cannot be
                ; misattached to the previous kept sense.
                if (open := !Dictionary._IsLabel(def))
                    cands.Push({ pos: pos, def: def, example: "" })
            } else if (m.Pos[3] && open)
                cands[cands.Length].example := Dictionary._CleanExample(Dictionary._Unescape(m[3]))
        }
        return Dictionary._Choose(word, cands)
    }

    ; Datamuse: [{"word":"delimiter","defs":["n\tThat which delimits…", …]}]
    ; No examples here, so scoring only weeds out circular and domain-tagged senses.
    static _ParseFallback(word, body) {
        if !RegExMatch(body, '"word"\s*:\s*"((?:[^"\\]|\\.)*)"', &w)
            return Dictionary._Fail(word, "no definition found")
        if (StrLower(Dictionary._Unescape(w[1])) != StrLower(word))
            return Dictionary._Fail(word, "no definition found")
        if !RegExMatch(body, '"defs"\s*:\s*\[(.*?)\]', &d)
            return Dictionary._Fail(word, "no definition found")

        cands := [], p := 1
        while RegExMatch(d[1], '"((?:[^"\\]|\\.)*)"', &m, p) {
            p := m.Pos + m.Len
            ; Split on the raw two-character \t escape — _Unescape would flatten it.
            parts := StrSplit(m[1], "\t")
            def := Dictionary._Clean(Dictionary._Unescape(parts.Length > 1 ? parts[2] : m[1]))
            if (def != "" && !Dictionary._IsLabel(def))
                cands.Push({ pos: parts.Length > 1 ? Dictionary._PosName(parts[1]) : ""
                           , def: def, example: "" })
        }
        return Dictionary._Choose(word, cands)
    }

    ; Shows the source's own first sense AND the highest-scoring one. Neither alone is
    ; safe: the first sense is often archaic ("juxtaposition: the nearness of objects
    ; with little or no delimiter") while the best-scoring one can be a deep subsense
    ; ("run: to fuse, to shape, to mould"). Together the reader always gets a usable
    ; reading. Candidates are limited to the first part of speech so one popup does not
    ; mix a noun and a verb under a single header.
    static _Choose(word, cands) {
        if !cands.Length
            return Dictionary._Fail(word, "no definition found")

        primary := cands[1]
        best := primary
        bestScore := Dictionary._Score(word, primary.def, primary.example)
        for i, c in cands {
            if (i == 1 || c.pos != primary.pos)
                continue
            s := Dictionary._Score(word, c.def, c.example)
            if (s > bestScore)
                bestScore := s, best := c
        }

        alt := (best.def == primary.def) ? "" : best.def
        example := best.example != "" ? best.example : primary.example
        return Dictionary._Result(word, primary.pos, primary.def, alt, example)
    }

    ; Higher is more useful to a human reading a popup:
    ;   +2  has a usable example sentence — the strongest signal of an everyday sense
    ;   -3  circular AND unillustrated ("To place in juxtaposition.") — teaches nothing
    ;   -1  domain-tagged ("(rhetoric) …") — a specialist reading of the word
    ;   -4  a pointer to another entry ("Abbreviation of catapult.") — not a meaning
    static _Score(word, def, example) {
        static pointer := "i)^\s*(\([^)]*\)\s*)?(abbreviation|acronym|initialism|synonym"
                        . "|alternative (form|spelling)|obsolete form|misspelling"
                        . "|plural|singular|past tense|past participle|present participle) of\b"
        s := 0
        if (example != "")
            s += 2
        else if InStr(def, Dictionary._Stem(word))
            s -= 3
        if RegExMatch(def, "^\s*\(")
            s -= 1
        if RegExMatch(def, pointer)
            s -= 4
        return s
    }

    ; Wiktionary files literary citations and bare word-fragments alongside plain usage
    ; sentences. Both are worse than no example at all in a small popup, so they are
    ; dropped rather than truncated — and a sense loses its example bonus with them.
    static _CleanExample(s) {
        s := Trim(RegExReplace(StrReplace(s, "`n", " "), "^\s*Example:\s*"))
        if RegExMatch(s, "^\d{4}")                       ; "1821-1822, Vicesimus Knox, …"
            || InStr(s, "ISBN") || InStr(s, ", page ") || InStr(s, ", editors,")
            || StrLen(s) > Config.MaxExampleLen
            return ""
        if (StrSplit(Trim(RegExReplace(s, "\s+", " ")), " ").Length < 4)   ; "to run bullets"
            return ""
        return s
    }

    ; Strips leading grammatical/register tags — "(countable) A mammal…" reads better as
    ; "A mammal…" and the tag is noise to someone who just wants the meaning. Subject
    ; tags like "(computing)" are kept: they are information, and _Score uses what is
    ; left to spot senses that only apply inside one field.
    static _Clean(def) {
        static grammatical := ",countable,uncountable,transitive,intransitive,ambitransitive"
                            . ",reflexive,figurative,by extension,attributive,plural,singular"
                            . ",idiomatic,informal,colloquial,"
        def := Trim(def)
        loop {
            if !RegExMatch(def, "^\(([^()]*)\)\s*(.+)$", &m)
                return def
            for tag in StrSplit(m[1], ",")
                if !InStr(grammatical, "," . Trim(StrLower(tag)) . ",")
                    return def
            def := Trim(m[2])
        }
    }

    ; Wiktionary groups senses under headings that are not definitions at all
    ; ("cat: Terms relating to animals."); the real meanings sit in their subsenses.
    static _IsLabel(def) {
        return RegExMatch(def, "i)^\s*(\([^)]*\)\s*)?terms relating to\b")
            || RegExMatch(def, ":\s*$")
    }

    ; Crude stem so "delimits"/"juxtapositions" still count as circular.
    static _Stem(word) {
        w := StrLower(word)
        return StrLen(w) > 6 ? SubStr(w, 1, StrLen(w) - 3) : w
    }

    static _PosName(code) {
        switch code {
            case "n": return "noun"
            case "v": return "verb"
            case "adj": return "adjective"
            case "adv": return "adverb"
            case "u": return ""
        }
        return code
    }

    ; MaxDefinitionLen is the budget for the definitions as a whole — the second sense
    ; is dropped rather than shrunk when it does not fit.
    static _Result(word, pos, def, alt, example) {
        if (StrLen(def) > Config.MaxDefinitionLen)
            def := SubStr(def, 1, Config.MaxDefinitionLen) . "…"
        if (StrLen(def) + StrLen(alt) > Config.MaxDefinitionLen)
            alt := ""

        return { ok: true, word: word, partOfSpeech: pos, definition: def
               , altDefinition: alt, example: example, error: "" }
    }

    static _Fail(word, err) {
        return { ok: false, word: word, partOfSpeech: "", definition: ""
               , altDefinition: "", example: "", error: err }
    }

    static _Unescape(s) {
        s := StrReplace(s, '\"', '"')
        s := StrReplace(s, "\/", "/")
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
