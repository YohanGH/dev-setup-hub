<h1 align="center">Halo</h1>

<p align="center">
  <strong>HUD système léger, 100 % Rust, Linux-first.</strong><br>
  Un overlay transparent, modulaire et très faible consommation pour Wayland &amp; X11.
</p>

<p align="center">
  <a href="#licence"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="Rust" src="https://img.shields.io/badge/rust-2021%20edition-orange.svg">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux-informational.svg">
  <img alt="Status" src="https://img.shields.io/badge/status-pré--alpha-red.svg">
</p>

<p align="center">
  <a href="docs/OVERVIEW.md">Vision, architecture &amp; roadmap →</a>
</p>

---

## Démarrage rapide

Prérequis : un toolchain Rust stable via [rustup](https://rustup.rs). Le canal et
les composants sont épinglés dans [`rust-toolchain.toml`](rust-toolchain.toml).

```bash
# Compiler et lancer le HUD (valeurs par défaut)
cargo run -p halo-cli

# Lancer avec une configuration
cargo run -p halo-cli -- --config examples/config.toml

# Afficher la configuration effective sans démarrer l'overlay
cargo run -p halo-cli -- config
```

### Overlay graphique & réglages (features optionnelles)

L'overlay GPU et la fenêtre de réglages sont derrière des features (`eframe`/
`egui`) pour garder le build par défaut léger. Ils nécessitent une session
graphique :

```bash
cargo run -p halo-cli --features overlay -- overlay    # HUD transparent (jauges animées)
cargo run -p halo-cli --features gui -- settings        # fenêtre de réglages avec aperçu
```

L'overlay est transparent, sans bordure, toujours au-dessus et **click-through**
(la souris passe au travers) ; `Ctrl+Alt+H` affiche/masque le HUD.

> **Wayland.** Un client Wayland ne peut pas positionner sa propre fenêtre : le
> réglage `position` est ignoré et le compositeur centre l'overlay. Halo bascule
> donc automatiquement sur le backend **X11 (XWayland)**, où l'ancrage dans un
> coin fonctionne. Pour forcer le Wayland natif (position gérée par le
> compositeur), lancez Halo sans `DISPLAY` : `env -u DISPLAY halo`.
> Ce backend X11/XWayland nécessite `libxkbcommon-x11.so.0` sur le système. Sur
> Debian/Ubuntu : `sudo apt install libxkbcommon-x11-0`. Sans cette lib,
> `halo overlay`/`halo settings` paniquent au démarrage (`Library
> libxkbcommon-x11.so could not be loaded`).

### Installation

```bash
cargo install --path crates/halo-cli
halo            # démarre le HUD depuis n'importe où
```

Un [`justfile`](justfile) regroupe les tâches courantes (`just run`,
`just overlay`, `just install`…) si vous avez
[`just`](https://github.com/casey/just) ; sinon, chaque tâche reste une simple
commande `cargo`.

## Configuration

Halo est piloté par un unique `config.toml` (voir
[`examples/config.toml`](examples/config.toml)). Tous les champs sont optionnels
et retombent sur des valeurs par défaut.

```toml
position   = "top-right"   # top-left | top-right | bottom-left | bottom-right
opacity    = 0.55          # 0.0 .. 1.0
refresh_ms = 500           # intervalle de rafraîchissement (ms)
theme      = "minimal"
font_size  = 18
```

Emplacement recommandé : `~/.config/halo/config.toml`. Générez un fichier de
départ sans l'écrire à la main :

```bash
cargo run -p halo-cli -- init   # écrit la config par défaut dans le chemin standard
```

La fenêtre de réglages graphique (`halo settings`, feature `gui`) permet de
modifier thème, position et widgets avec un aperçu, puis réécrit ce fichier.

### Démarrage automatique (systemd)

Une unité utilisateur prête à l'emploi est fournie dans
[`dist/systemd/halo.service`](dist/systemd/halo.service) :

```bash
install -Dm644 dist/systemd/halo.service ~/.config/systemd/user/halo.service
systemctl --user daemon-reload
systemctl --user enable --now halo
```

Halo démarre alors automatiquement avec la session graphique.

## Documentation

Vision, pile technique, architecture, feuille de route et guide de
développement : **[docs/OVERVIEW.md](docs/OVERVIEW.md)**.
Contribution : [CONTRIBUTING.md](CONTRIBUTING.md) ·
[Code de conduite](CODE_OF_CONDUCT.md) · [SECURITY.md](SECURITY.md).

## Licence

Distribué sous licence [MIT](LICENSE).
