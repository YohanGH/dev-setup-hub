#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    setup_obsidian.sh                                   |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/07/22 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Génère le coffre Obsidian entreprise "ANKAMA_OBSIDIAN" :
#   4.1  arborescence de dossiers (méthode GTD)
#   4.2  templates (LINT_CONFIG, TEMP_CONTACT, TEMP_NOTE, TEMP_TICKET)
#   4.3  fichier AI-SECURITY.md (protection des droits d'auteur)
#
# Usage : ./setup_obsidian.sh [chemin_destination]
#         (par défaut : ~/ANKAMA_OBSIDIAN)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OBS_DATA="$REPO_DIR/data_for_obsidian"

DEST="${1:-$HOME/ANKAMA_OBSIDIAN}"
VAULT="ANKAMA_OBSIDIAN"
ROOT="$DEST"

c_reset='\033[0m'; c_ok='\033[0;32m'; c_info='\033[0;34m'; c_warn='\033[0;33m'
log()  { printf "${c_info}[*]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_ok}[OK]${c_reset} %s\n" "$*"; }
warn() { printf "${c_warn}[!]${c_reset} %s\n" "$*"; }

TODAY="$(date +%Y-%m-%d)"

log "Création du coffre : $ROOT"

# -------------------------------------------------------------------------- #
# 4.1  Arborescence                                                          #
# -------------------------------------------------------------------------- #
FOLDERS=(
	"0.Inbox"
	"1.Activable_NON/Incubation"
	"1.Activable_NON/References/Biographie"
	"1.Activable_NON/References/Contact"
	"1.Activable_NON/References/Documents"
	"2.Activable_OUI/2_minutes_NON/EN_Attente"
	"2.Activable_OUI/2_minutes_NON/Tache_A_Faire"
	"2.Activable_OUI/2_minutes_OUI"
	"2.Activable_OUI/Projets"
	"3.Formation_Developpement"
	"4.Idee_&_Refelxions"
	"5.List_Controle"
	"6.Fonctionnement"
	"7.Archive/Calendrier"
	"7.Archive/Canvas"
	"7.Archive/Excalidraw"
	"7.Archive/Images"
	"7.Archive/Template"
	"8.Clippings"
	"9.Excalidraw"
	"10.Figma"
)

for f in "${FOLDERS[@]}"; do
	mkdir -p "$ROOT/$f"
done
# Conserve les dossiers vides dans git
find "$ROOT" -type d -empty -exec touch {}/.gitkeep \;
ok "Arborescence créée (${#FOLDERS[@]} dossiers)."

TPL_DIR="$ROOT/7.Archive/Template"

# -------------------------------------------------------------------------- #
# Fichier GTD : 2_minutes_OUI/FAITES_LA.md                                   #
# -------------------------------------------------------------------------- #
cat > "$ROOT/2.Activable_OUI/2_minutes_OUI/FAITES_LA.md" <<EOF
---
title: FAITES_LA
created: $TODAY
modified: $TODAY
tags:
  - GTD
  - Action
concept: Règle des 2 minutes — si une tâche prend moins de 2 minutes, fais-la maintenant.
---

# FAITES_LA

> [!tip] Règle des 2 minutes
> Toute tâche « activable » qui prend **moins de 2 minutes** doit être
> réalisée **immédiatement** plutôt que planifiée.

## À faire maintenant

- [ ] Exemple : répondre à un message court
- [ ] Exemple : classer un document dans References

## Fait aujourd'hui ($TODAY)

- [x] Coffre ANKAMA_OBSIDIAN initialisé
EOF
ok "FAITES_LA.md créé."

# -------------------------------------------------------------------------- #
# 4.2  Templates                                                             #
# -------------------------------------------------------------------------- #

# --- LINT_CONFIG.md : copié depuis data_for_obsidian si disponible -------- #
if [ -f "$OBS_DATA/LINT_CONFIG.md" ]; then
	cp "$OBS_DATA/LINT_CONFIG.md" "$TPL_DIR/LINT_CONFIG.md"
	ok "LINT_CONFIG.md copié depuis le dépôt."
else
	warn "LINT_CONFIG.md source introuvable — création d'un placeholder."
	printf '# lint-config\n\n> Configuration du plugin Linter Obsidian (à compléter).\n' \
		> "$TPL_DIR/LINT_CONFIG.md"
fi

# --- TEMP_CONTACT.md  (ANNEXE A) ------------------------------------------ #
cat > "$TPL_DIR/TEMP_CONTACT.md" <<'EOF'
---
title: Nom de la personne
created:
  "{ date }":
modified:
  "{ date }":
tags:
  - Domaine1
  - Domaine2
  - Personne
  - SmockingArt
aliases:
  - Surnom
  - Titre
related:
  - "[[Project1]]"
  - "[[Project1]]"
  - "[[Project1]]"
  - "[[Project1]]"
concept: La contribution unique ou l'innovation distinctive associée à cette personne
---

# Nom de la personne

> [!info] Résumé
> Brève description de la personne, de son importance historique, de sa contribution principale et de l'impact de son travail. Cette description doit se concentrer sur le concept unique associé à cette personne.

## Contributions principales

> [!note] Réalisations clés
> Description des innovations ou contributions fondamentales qui définissent l'importance de cette personne.

### Domaine principal

- Réalisation ou innovation 1
- Réalisation ou innovation 2
- Réalisation ou innovation 3
- Impact de ces réalisations
- Chronologie des développements importants

### Domaine secondaire

- Contribution annexe 1
- Contribution annexe 2
- Relation avec d'autres travaux ou personnes
- Évolution de sa pensée ou de ses méthodes
- Reconnaissance reçue pour ces contributions

## Parcours et développement

> [!quote] Citation notable
> "Citation emblématique de la personne qui illustre sa vision ou sa philosophie."

### Formation et influences

- Parcours académique ou autodidacte
- Mentors et influences intellectuelles
- Événements déterminants dans son développement
- Collaborations formatives
- Évolution de sa pensée

### Projets actuels ou héritage

- Activités récentes ou en cours
- Impact durable de son travail
- Organisations ou projets fondés
- Influence sur la génération suivante
- Perception contemporaine de ses contributions

## Connexions notables

> [!tip] Relations clés
> Cartographie du réseau professionnel et des influences mutuelles avec d'autres figures importantes.

### Collaborateurs et contemporains

- Relations professionnelles significatives
- Collaborations majeures
- Rivalités ou désaccords notables
- Positionnement dans l'écosystème de son domaine
- Influence exercée sur d'autres personnes ou domaines

## Développement atomique

- Idées connexes qui mériteraient des notes séparées:
  - [[Concept spécifique développé par la personne]] - Brève explication
  - [[Méthodologie ou framework créé]] - Brève explication
  - [[Controverse ou débat associé]] - Brève explication

## Liens connexes

- [[Domaine principal]]
- [[Organisation ou projet fondé]]
- [[Technologie ou concept développé]]
- [[Collaborateur principal]]
- [[Mouvement ou école de pensée]]

## Ressources et références

- Livres ou publications principales
- Site personnel ou professionnel
- Profils sur les réseaux sociaux
- Interviews ou conférences notables
- Documentaires ou articles de référence
EOF
ok "TEMP_CONTACT.md créé (ANNEXE A)."

# --- TEMP_NOTE.md  (ANNEXE B) --------------------------------------------- #
cat > "$TPL_DIR/TEMP_NOTE.md" <<'EOF'
---
title: {{title}}
created:
modified:
tags:
  - tag1
  - tag2
aliases:
  - alias1
  - alias2
related:
  - "[[note1]]"
  - "[[note2]]"
concept: Concept unique de cette note
---

# {{title}}

> [!info] Résumé
> Un bref résumé de la note qui se concentre sur UN SEUL concept principal (méthode Zettelkasten)

## Contenu principal

### Section 1

> [!note] Point clé
> Information importante à retenir concernant ce concept unique

### Section 2

> [!tip] Astuce
> Conseil ou astuce utile pour mieux comprendre ou appliquer ce concept

### Section 3

> [!warning] Attention
> Point de vigilance concernant ce concept

## Images et ressources

![Description de l'image](chemin/vers/image.jpg)

## Développement atomique

- Idées connexes mais qui mériteraient des notes séparées:
  - [[Concept lié 1]] - Brève description
  - [[Concept lié 2]] - Brève description

## Actions et suivi

- [ ] Tâche 1 liée à l'application ou l'amélioration de ce concept
- [ ] Tâche 2 liée à ce concept

---
EOF
ok "TEMP_NOTE.md créé (ANNEXE B)."

# --- TEMP_TICKET.md  (template de suivi de ticket) ------------------------ #
cat > "$TPL_DIR/TEMP_TICKET.md" <<'EOF'
---
title: {{title}}
created:
modified:
tags:
  - Ticket
  - ANKAMA
aliases:
  - "TICKET-000"
related:
  - "[[Projet lié]]"
status: A_faire      # A_faire | En_cours | Bloqué | En_revue | Terminé
priority: Moyenne    # Basse | Moyenne | Haute | Critique
assignee: YohanGH
concept: Suivi d'un ticket / d'une tâche opérationnelle
---

# {{title}}

> [!info] Contexte
> Description synthétique du besoin ou du problème à traiter.

## Objectif

- Résultat attendu :
- Critère de « Terminé » (Definition of Done) :

## Détails

> [!note] Spécifications
> Détails techniques, contraintes, dépendances.

- Composant concerné :
- Environnement :
- Reproduction / étapes :

## Checklist

- [ ] Analyse
- [ ] Implémentation
- [ ] Tests
- [ ] Revue
- [ ] Déploiement

## Journal

| Date | Auteur | Action |
| ---- | ------ | ------ |
|      | YohanGH |        |

## Liens

- [[Projet lié]]
- [[Documentation]]

---
EOF
ok "TEMP_TICKET.md créé."

# -------------------------------------------------------------------------- #
# 4.3  AI-SECURITY.md : protection des droits d'auteur du coffre             #
# -------------------------------------------------------------------------- #
cat > "$ROOT/AI-SECURITY.md" <<EOF
---
title: AI-SECURITY
created: $TODAY
modified: $TODAY
tags:
  - Sécurité
  - Droits_Auteur
  - IA
  - Confidentiel
concept: Protection des droits d'auteur et restrictions d'usage IA du coffre ANKAMA_OBSIDIAN
---

# AI-SECURITY — $VAULT

> [!danger] Contenu propriétaire et confidentiel
> L'intégralité du contenu du coffre **$VAULT** est la **propriété exclusive**
> de son auteur (YohanGH) et/ou de l'entreprise ANKAMA. Tous droits réservés.

## 1. Droits d'auteur

- © $(date +%Y) YohanGH / ANKAMA. **Tous droits réservés.**
- Le contenu de ce coffre (notes, templates, documents, images, schémas)
  est protégé par le droit d'auteur. Toute reproduction, distribution ou
  communication au public, totale ou partielle, sans autorisation écrite
  préalable est **interdite**.

## 2. Restrictions d'usage par les IA

> [!warning] Interdiction d'entraînement et d'ingestion
> Ce contenu **ne doit pas** être :
> - utilisé pour l'entraînement, le fine-tuning ou l'évaluation de modèles d'IA ;
> - ingéré dans une base vectorielle / RAG hors du périmètre autorisé ;
> - copié, résumé ou reformulé par un agent automatisé à des fins de
>   redistribution.

- \`noai\`, \`noimageai\` : opt-out explicite pour les robots d'IA.
- \`X-Robots-Tag: noai, noindex\` recommandé en cas de synchronisation web.

## 3. Confidentialité

- Ne pas exporter ce coffre vers un service tiers non validé.
- Ne pas partager de lien public sans anonymisation préalable.
- Les fichiers sensibles (identifiants, clés) sont **interdits** dans le coffre
  (voir \`.gitignore\` du dépôt de configuration).

## 4. Contact

Pour toute demande d'autorisation : **YohanGH &lt;YohanGH@proton.me&gt;**

---

*Ce fichier doit rester à la racine du coffre $VAULT.*
EOF
ok "AI-SECURITY.md créé à la racine du coffre."

# --- Fichier README du coffre --------------------------------------------- #
cat > "$ROOT/README.md" <<EOF
# $VAULT

Coffre Obsidian entreprise — organisation **GTD** (Getting Things Done).

- \`0.Inbox\` — capture rapide, non trié.
- \`1.Activable_NON\` — références, incubation, non actionnable.
- \`2.Activable_OUI\` — actions (règle des 2 minutes), projets.
- \`3.Formation_Developpement\` — apprentissage.
- \`4.Idee_&_Refelxions\` — idées & réflexions.
- \`5.List_Controle\` — checklists.
- \`6.Fonctionnement\` — procédures.
- \`7.Archive\` — archives + \`Template/\`.
- \`8.Clippings\`, \`9.Excalidraw\`, \`10.Figma\` — ressources.

> Voir [\`AI-SECURITY.md\`](AI-SECURITY.md) : contenu propriétaire, restrictions IA.

Généré le $TODAY.
EOF
ok "README.md du coffre créé."

echo ''
ok "Coffre $VAULT prêt : $ROOT"
log "Ouvre ce dossier comme coffre dans Obsidian, puis pointe le Linter vers 7.Archive/Template/LINT_CONFIG.md."
