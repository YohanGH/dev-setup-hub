# Plugins Obsidian

Inventaire des **14 plugins communautaires** qui étaient installés dans
ce dépôt, relevé depuis leur `manifest.json` avant retrait des binaires.

## Pourquoi ils ne sont plus versionnés

`obsidian/plugins/*/main.js` pesait **22 Mo** — du JavaScript compilé
appartenant à d'autres projets, sous d'autres licences, et représentant à lui
seul 95 % du poids du dépôt. Ce n'est pas de la configuration : c'est le build
de quelqu'un d'autre.

## Ce qu'il faut savoir avant de réinstaller

> **Obsidian ne réinstalle pas ces plugins tout seul.**

`community-plugins.json` n'est **pas** une liste d'installation : c'est la liste
des plugins **activés**. Obsidian n'y va jamais chercher quoi que ce soit à
télécharger. Dans ce dépôt elle est d'ailleurs vide (`[]`), donc les quatorze
plugins ci-dessous étaient installés mais tous désactivés.

La réinstallation passe donc par l'interface :
**Réglages → Modules complémentaires → Parcourir**, puis rechercher chaque nom.

## Inventaire

| Identifiant | Nom affiché | Version relevée |
|---|---|---|
| `avatar` | Avatar | 1.0.5 |
| `file-tree-alternative` | File Tree Alternative Plugin | 2.4.2 |
| `flashcards-obsidian` | Flashcards | 1.6.5 |
| `graph-analysis` | Graph Analysis | 0.15.4 |
| `meld-encrypt` | Meld Encrypt | 2.3.5 |
| `mermaid-tools` | Mermaid Tools | 1.1.1 |
| `note-refactor-obsidian` | Note Refactor | 1.8.2 |
| `obsidian-excalidraw-plugin` | Excalidraw | 2.0.7 |
| `obsidian-full-calendar` | Full Calendar | 0.10.7 |
| `obsidian-kanban` | Kanban | 1.5.3 |
| `obsidian-mind-map` | Mind Map | 1.1.0 |
| `obsidian-outliner` | Outliner | 4.8.0 |
| `obsidian-tasks-plugin` | Tasks | 5.2.0 |
| `table-editor-obsidian` | Advanced Tables | 0.19.1 |

Les versions sont celles présentes au moment du retrait — les plugins ont
évolué depuis, prends les versions courantes.

## Thèmes

Les thèmes restent versionnés, eux : `Cyber Glow`, `Cybertron`, `Elegance` et
`MagicUser`. Ce sont des feuilles de style, quelques centaines de kilo-octets,
et Obsidian ne sait pas les retrouver à partir d'un identifiant comme il le
fait pour les plugins du catalogue.
