# Rappels de maintenance — `check.sh`

Un rappel, pas un exécuteur. `check.sh` ne lance jamais lui-même une mise à
jour, une sauvegarde ou un audit — il répond à une seule question : *quand
ai-je fait ça pour la dernière fois, et est-ce trop vieux ?*

C'est ce périmètre étroit qui rend l'outil simple. Un outil qui exécuterait
réellement les mises à jour ou les sauvegardes devrait gérer les droits, les
échecs partiels, les reprises — un outil qui compare des dates tient dans un
seul fichier.

## Usage

```bash
./check.sh              # etat de tous les controles
./check.sh --done update   # enregistre "fait aujourd'hui"
./check.sh --list           # liste les controles declares
```

Chaque contrôle affiche trois choses :

```
✔  Mises a jour systeme il y a 0 j (seuil 7 j)
   systeme : 56 paquet(s) Homebrew en retard
```

1. **L'état déclaré** — depuis quand tu as dit avoir fait ça (`✔` à jour,
   `▲` échéance dépassée, `✖` jamais enregistré), avec la commande à lancer
   si c'est en retard ou jamais fait.
2. **La preuve système**, sur la ligne du dessous — indépendante de la date
   déclarée. Voir plus bas pourquoi les deux comptent.

## Pourquoi une deuxième source

Un fichier d'état a un défaut structurel : il se perd avec `$HOME`, et surtout
**il ment**. Il enregistre que tu *as dit* avoir fait la chose, pas qu'elle a
eu lieu. Rien n'empêche de lancer `./check.sh --done update` sans avoir rien
mis à jour.

D'où la ligne « système » : une commande qui interroge l'état réel de la
machine, indépendamment de ce que le fichier d'état raconte. La redondance
utile n'est pas deux copies du même fichier — c'est deux sources qui doivent
concorder, et qui parfois ne concordent pas :

```
✔  Mises a jour systeme il y a 0 j (seuil 7 j)
   systeme : 56 paquet(s) Homebrew en retard
```

Ici, la date déclarée dit « fait aujourd'hui », mais 56 paquets Homebrew sont
réellement en retard. Marquer `update` comme fait n'a pas fait tourner
`brew upgrade` — c'est exactement le genre d'écart que l'outil doit montrer,
pas masquer.

## Les trois contrôles

| Contrôle | Preuve macOS | Preuve Debian |
|---|---|---|
| `update` | nombre de paquets Homebrew en retard (`brew outdated`) | fraîcheur de `/var/log/apt/history.log` |
| `backup` | `tmutil latestbackup` | **aucune pour l'instant** — voir plus bas |
| `analyse` | fraîcheur de `/var/log/lynis.log` | fraîcheur de `/var/log/lynis.log` |

### Le cas `backup` sous Debian

Aucun outil de sauvegarde n'est encore choisi côté Debian — Time Machine n'a
pas d'équivalent direct sur Linux. En attendant, le contrôle `backup` sous
Debian fonctionne **sur la seule date déclarée**, sans preuve système : c'est
une limite connue, pas un oubli.

Une fois l'outil choisi (restic, BorgBackup, ou autre), ajouter la preuve
revient à remplir un seul champ dans `checks.conf` — voir plus bas.

### Une subtilité découverte en écrivant ce contrôle

`tmutil latestbackup` retourne un code de sortie **0 même quand la sauvegarde
a échoué** — vérifié : sur ce poste, il affiche
`Failed to mount backup destination…` tout en sortant proprement. Le contrat
de preuve dans `checks.conf` ignore donc systématiquement le code de sortie et
ne se fie qu'au **texte produit** : silence = rien à signaler, une ligne de
texte = le problème à afficher. Un outil sondé qui échoue "proprement" comme
celui-ci ne serait pas détecté autrement.

## Ajouter un contrôle

Un bloc dans `checks.conf` :

```
[nom]
libelle = Texte affiche
seuil = 30
commande = commande a lancer si en retard ou jamais fait
preuve_macos = commande shell, silencieuse si tout va bien
preuve_debian = idem, ou laisse vide si aucune verification possible
```

Le format est par blocs, pas par ligne à séparateur `|` comme `external.conf` :
les commandes de preuve contiennent elles-mêmes des pipes (`brew outdated |
wc -l`), qui casseraient un séparateur `|`.

La commande de preuve est évaluée par `eval` dans l'environnement de
`check.sh` — même précaution qu'ailleurs dans ce dépôt : ne mets rien là que
tu ne lancerais pas toi-même.

## Ce qui n'existe pas (par choix)

- **Aucun planificateur.** Pas de cron, pas de timer systemd, pas de plist
  launchd. `check.sh` se lance à la main, ou depuis `./install/99-summary.sh`
  qui y renvoie en fin d'installation. `systemd` n'aurait de toute façon pas
  mutualisé macOS et Debian — macOS utilise `launchd`, un mécanisme distinct.
- **Aucune exécution automatique.** L'outil ne mettra jamais à jour, ne
  sauvegardera jamais, ne lancera jamais un audit à ta place.

Si un planificateur devient utile plus tard, il n'a besoin de rien de plus que
lancer `check.sh` périodiquement — aucune de ces deux absences ne bloque quoi
que ce soit d'autre dans ce dépôt.
