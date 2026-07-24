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

---

## Vision du projet

Halo affiche l'état du système (CPU, RAM, réseau, température, GPU…) dans un
overlay discret, toujours visible et click-through, sans jamais gêner l'usage du
bureau.

- **HUD système léger** — objectif < 0,5 % CPU et < 15 Mo de RAM.
- **100 % Rust** — un seul langage, du capteur au rendu.
- **Linux-first**, **Wayland & X11**.
- **Modulaire** — widgets et thèmes indépendants, plugins sans toucher au cœur.
- **Animations GPU** — transitions fluides via `wgpu`.

## Stack

```
Cargo → Tokio (async) → sysinfo (system) → serde (config)
      → egui / Slint → wgpu → overlay transparent
```

> `sysinfo` est utilisé au départ pour aller vite. Il sera remplacé par des
> lectures directes de `/proc` et `/sys` là où cela apporte un vrai gain : moins
> de dépendances et un meilleur contrôle.

## Architecture

Halo est un **workspace Cargo**. Chaque responsabilité vit dans sa propre crate,
ce qui permet de faire évoluer le rendu sans toucher au monitoring.

```
halo/  (workspace)
└── crates/
    ├── halo-core      # monitoring + échantillonnage (scheduler)
    ├── halo-config    # config TOML, profils, thèmes actifs
    ├── halo-themes    # couleurs, typographie, animations
    ├── halo-ui        # overlay transparent, rendu GPU
    ├── halo-daemon    # boucle async : sample → render → arrêt propre
    └── halo-cli       # binaire `halo` : install · run · config
```

Flux des dépendances :

```
halo-core ──► halo-ui ──► halo-daemon ──► halo-cli
halo-config ─┘   ▲            ▲
halo-themes ─────┘            │
config.toml ──────────────────┘
```

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
(la souris passe au travers) ; les jauges CPU/RAM/Swap/Disk s'animent en douceur
vers chaque nouvelle valeur, selon le thème. `Ctrl+Alt+H` affiche/masque le HUD.
Sous Wayland, l'ancrage précis dans un coin passera à terme par `wlr-layer-shell`.

Installer le binaire `halo` sur le système :

```bash
cargo install --path crates/halo-cli
halo            # démarre le HUD depuis n'importe où
```

Un [`justfile`](justfile) regroupe les tâches courantes (`just run`,
`just overlay`, `just install`, `just ci`…) si vous avez
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

> Une fenêtre de réglages graphique (egui) avec aperçu en direct est prévue
> (Phase 12) et s'appuiera sur `Config::save` / `to_toml` ; elle nécessite une
> session graphique et n'est pas encore implémentée.

## Démarrage automatique (systemd)

Sous Linux, la bonne pratique est un service utilisateur `systemd`, plus fiable
qu'un script lancé au hasard dans le gestionnaire de session. Une unité prête à
l'emploi est fournie dans [`dist/systemd/halo.service`](dist/systemd/halo.service) :

```bash
install -Dm644 dist/systemd/halo.service ~/.config/systemd/user/halo.service
systemctl --user daemon-reload
systemctl --user enable --now halo
```

Halo démarre alors automatiquement avec la session graphique.

## Développement

```bash
cargo fmt --all                          # format
cargo clippy --workspace --all-targets   # lint (warnings = erreurs en CI)
cargo test --workspace                   # tests
cargo test -p halo-core                  # tests d'une seule crate
cargo deny check                         # audit dépendances / licences
```

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour le détail du workflow et
[SECURITY.md](SECURITY.md) pour signaler une vulnérabilité.

## Roadmap

La feuille de route va d'un simple affichage texte à un HUD GPU complet, chaque
phase restant utilisable indépendamment. Légende : ✅ implémenté et testé ·
🟢 implémenté et compilé, à vérifier visuellement sur un bureau Linux · ⏳ à faire.

| Phase | Objectif | État | Livrable |
| :---: | -------- | :--: | -------- |
| **0** | Préparation | ✅ | Workspace qui compile, Git, CI — affiche `Hello Halo`. |
| **1** | Premier daemon | ✅ | Boucle + timer + arrêt propre + logs ; CPU/RAM/Disk/Temp dans le terminal. |
| **2** | Premier overlay | 🟢 | Fenêtre transparente, sans bordure, toujours devant, click-through + hotkey global, **jauges rendues** (`eframe`/`egui`) — `halo overlay`. |
| **3** | Monitoring | ✅ | Lecture CPU, RAM, Swap, disques, réseau. |
| **4** | Configuration | ✅ | `config.toml` découvert et lu au démarrage (XDG), valeurs bornées. |
| **5** | Lancement | ✅ | `cargo install --path crates/halo-cli` puis `halo` ; `justfile`. |
| **6** | Démarrage auto | ✅ | Service utilisateur `systemd` (`dist/systemd/halo.service`). |
| **7** | Widgets | ✅ | Trait `Widget` + registre : CPU, RAM, Swap, Disk, Net, Temp, GPU, Horloge. |
| **8** | Thèmes | ✅ | Minimal, Cyberpunk, Terminal, Glass, Nord, OLED, Monochrome. |
| **9** | Animations | 🟢 | Easing + lissage exponentiel (`anim`, testés) **appliqués aux jauges** de l'overlay. |
| **10** | Personnalisation | ✅ | Widgets activables/désactivables et ordonnés via `config.toml` ; position. |
| **11** | Plugins | ✅ | Système de plugins in-process (`Plugin` + registre) + plugin `git` réel. Chargement de `.so` : à venir. |
| **12** | Interface graphique | 🟢 | Fenêtre de réglages `egui` avec aperçu + écriture `config.toml` (`halo settings`, `halo init`). |
| **13** | Optimisation | ✅ | Scheduler par capteur (CPU 250 ms, RAM 2 s, disques 5 s, réseau 1 s). |
| **14** | **Version 1.0** | 🟢 | Overlay rendu, config, widgets, CPU/RAM/réseau/température/**GPU**, thèmes, auto-start, animations, plugins. Reste : **vérification visuelle** sur bureau Linux (GPU NVIDIA via NVML à venir). |

> **État actuel (v0.1).** Toute la logique — monitoring, scheduler (dont
> l'échantillonnage **GPU** sur Linux AMD/Intel via sysfs), config, widgets,
> thèmes, animations, plugins — est implémentée et testée, le HUD **terminal**
> est pleinement fonctionnel, et l'**overlay graphique** ainsi que la **fenêtre
> de réglages** sont implémentés (`eframe`/`egui`) et compilent. N'ayant pas de
> session graphique dans l'environnement de développement, le rendu visuel de
> l'overlay/GUI reste **à vérifier sur un bureau Linux**. GPU NVIDIA (NVML) et
> l'ancrage Wayland `wlr-layer-shell` sont les évolutions restantes.

### Au-delà de la 1.0 (v2)

- **Disposition libre** — déplacer les widgets à la souris, grille d'alignement.
- **Profils** — « Développement », « Gaming », « Portable », activés selon le contexte.
- **Règles intelligentes** — n'afficher que le pertinent (le GPU quand un jeu tourne,
  le réseau lors d'un gros téléchargement).
- **Historique** — conserver 30–60 s de données pour visualiser les tendances.
- **API & plugins** — permettre à d'autres d'ajouter leurs widgets sans modifier le cœur.

Cette séparation en crates permet de commencer par un simple affichage de texte,
puis de remplacer uniquement le moteur de rendu pour obtenir un HUD moderne sans
toucher à la logique de monitoring — une architecture qui reste saine même à
plusieurs dizaines de milliers de lignes.

## Contribuer

Les contributions sont les bienvenues : lisez
[CONTRIBUTING.md](CONTRIBUTING.md) et le
[Code de conduite](CODE_OF_CONDUCT.md).

## Licence

Distribué sous licence [MIT](LICENSE).
