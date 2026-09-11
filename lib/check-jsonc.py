#!/usr/bin/env python3
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    check-jsonc.py                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Valide un ou plusieurs fichiers JSONC (JSON + commentaires // et /*, plus
# les virgules trainantes, exactement ce que VSCode accepte dans settings.json
# et keybindings.json).
#
# Ce parseur a ete ecrit a la main trois fois de suite pendant la
# refactorisation de config/editor/ ; il vit ici pour n'exister qu'une fois,
# utilise en CI comme en verification locale :
#
#   python3 lib/check-jsonc.py config/editor/settings.json config/editor/keybindings.json
#
# '//' est teste AVANT '/*' a chaque position, comme le fait VSCode : une
# ligne commencant par '//*' est un commentaire de ligne, pas un bloc ouvert.
# C'est cette regle precise qui avait fait echouer un parseur plus naif sur
# settings.json (une ligne '//* --- *' y ressemblait a un bloc jamais ferme).
#
import json
import sys


def strip_jsonc(text: str) -> str:
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            out.append(c)
            i += 1
            while i < n:
                if text[i] == "\\":
                    out.append(text[i : i + 2])
                    i += 2
                    continue
                out.append(text[i])
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if text.startswith("//", i):
            while i < n and text[i] != "\n":
                i += 1
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        out.append(c)
        i += 1
    import re

    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def main(paths: list[str]) -> int:
    if not paths:
        print("usage: check-jsonc.py <fichier.json> [...]", file=sys.stderr)
        return 2

    echecs = 0
    for path in paths:
        try:
            with open(path, encoding="utf-8") as f:
                raw = f.read()
            json.loads(strip_jsonc(raw))
        except Exception as exc:
            print(f"INVALIDE  {path}: {exc}", file=sys.stderr)
            echecs += 1
        else:
            print(f"valide    {path}")

    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
