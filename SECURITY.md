# Security Policy

## Supported Versions

Ce dépôt fournit des scripts de configuration pour un poste Debian/Ubuntu.
Seule la dernière version publiée sur la branche `main` est maintenue et
reçoit des correctifs de sécurité.

| Version        | Supportée          |
| -------------- | ------------------ |
| `main` (HEAD)  | :white_check_mark: |
| Anciens tags   | :x:                |

## Reporting a Vulnerability

Si vous découvrez une vulnérabilité (fuite de secret, commande dangereuse,
injection dans un script d'installation, etc.) :

1. **Ne pas** ouvrir d'issue publique.
2. Envoyer un rapport privé à **YohanGH &lt;YohanGH@proton.me&gt;** avec :
   - une description du problème,
   - les étapes de reproduction,
   - l'impact potentiel,
   - une suggestion de correctif si possible.
3. Vous recevrez un accusé de réception sous **72 heures**.
4. Un correctif ou une réponse détaillée est visé sous **14 jours**.

## Bonnes pratiques appliquées dans ce dépôt

- Aucun secret (clé, token, mot de passe) n'est versionné : voir `.gitignore`.
- Les scripts d'installation ne s'exécutent pas en `root` implicitement et
  demandent `sudo` uniquement lorsque c'est nécessaire.
- Chaque commande installée est vérifiée avant usage (`command -v`).
- Le contenu du coffre `ANKAMA_OBSIDIAN` est protégé par le fichier
  `AI-SECURITY.md` (droits d'auteur, restrictions d'usage IA).

## Scope

Sont concernés : les scripts `scripts/*.sh`, les fichiers de configuration
(`.vimrc`, `zshrc`, `stdheader.vim`) et les templates générés.
Hors périmètre : les outils tiers installés (oh-my-zsh, powerlevel10k,
plugins Vim), gérés par leurs propres mainteneurs.
