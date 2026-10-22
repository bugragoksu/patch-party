"""Reference implementation used to generate the shared test vectors.

The Dart client and the TypeScript functions implement the same algorithms
independently; both test suites run against the JSON files produced here.
Run: python3 -I shared/test-vectors/generate.py
"""

import base64
import hashlib
import hmac
import json
import pathlib
import unicodedata

OUT = pathlib.Path(__file__).resolve().parent
CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


def totp(seed_b64: str, event_id: str, window: int) -> dict:
    key = base64.urlsafe_b64decode(seed_b64 + "=" * (-len(seed_b64) % 4))
    digest = hmac.new(key, f"{event_id}|{window}".encode(), hashlib.sha256).digest()
    bits = "".join(f"{b:08b}" for b in digest[:7])
    qr = "".join(CROCKFORD[int(bits[i * 5:i * 5 + 5], 2)] for i in range(10))
    digits = f"{int.from_bytes(digest[28:32], 'big') % 10000:04d}"
    return {"qr": qr, "digits": digits}


def window_of(unix_ms: int, window_sec: int) -> int:
    return unix_ms // (window_sec * 1000)


TR_FOLD = str.maketrans({"ı": "i", "ş": "s", "ğ": "g", "ü": "u", "ö": "o", "ç": "c"})


def normalize_name(raw: str) -> str:
    s = unicodedata.normalize("NFC", raw)
    s = " ".join(s.split())
    s = s.replace("I", "ı").replace("İ", "i").lower()
    s = s.translate(TR_FOLD)
    s = "".join(c for c in unicodedata.normalize("NFD", s) if not unicodedata.combining(c))
    s = "".join(c if ("a" <= c <= "z" or "0" <= c <= "9" or c == " ") else " " for c in s)
    return "-".join(s.split())


def clean_display_name(raw: str) -> str:
    return " ".join(unicodedata.normalize("NFC", raw).split())


def is_valid_display_name(raw: str) -> bool:
    s = clean_display_name(raw)
    if not 2 <= len(s) <= 24:
        return False
    allowed = all(c.isalpha() or c.isdigit() or c in " .'-" for c in s)
    return allowed and normalize_name(s) != ""


def points(a: list, b: list) -> dict:
    bonus = 0 if set(a) & set(b) else 5
    return {"base": 10, "bonus": bonus, "total": 10 + bonus}


def main() -> None:
    seeds = [
        "q8Jz0wq3m1sV0b4w6m3n2r8yZt5uQe1fWv9kLp0xYcA",
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-8",
    ]
    totp_cases = []
    for seed in seeds:
        for event_id, ms in [("gdg-adana-2026-10", 1792900800000), ("gdg-adana-2026-10", 1792900829999),
                             ("gdg-adana-2026-10", 1792900830000), ("rehearsal", 1792900815500)]:
            w = window_of(ms, 30)
            totp_cases.append({"seed": seed, "eventId": event_id, "unixMs": ms, "windowSec": 30,
                               "window": w, **totp(seed, event_id, w)})
    (OUT / "totp.json").write_text(json.dumps({"version": 1, "alphabet": CROCKFORD, "cases": totp_cases},
                                              ensure_ascii=False, indent=2) + "\n")

    names = ["Deniz", "  deniz  ", "DENİZ", "Işıl", "ISIL", "ışıl", "Çağrı Öz", "çağrı   öz", "Şule-Gül",
             "José", "Ümit 2", "Ahmet.K", "A", "Bu isim kesinlikle çok uzun bir isim", "😀😀", "Ali'", "  ",
             "İlknur", "ilknur", "Deniz K."]
    name_cases = [{"input": n, "clean": clean_display_name(n), "key": normalize_name(n),
                   "valid": is_valid_display_name(n)} for n in names]
    (OUT / "names.json").write_text(json.dumps({"version": 1, "cases": name_cases},
                                               ensure_ascii=False, indent=2) + "\n")

    score_cases = [
        {"a": ["flutter", "ai"], "b": ["flutter", "design"]},
        {"a": ["flutter", "ai"], "b": ["design", "security"]},
        {"a": ["web", "data", "devops"], "b": ["devops"]},
        {"a": ["product", "community"], "b": ["backend", "gamedev", "opensource"]},
    ]
    for c in score_cases:
        c.update(points(c["a"], c["b"]))
    (OUT / "scoring.json").write_text(json.dumps({"version": 1, "cases": score_cases},
                                                 ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
