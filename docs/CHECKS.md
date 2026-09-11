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

Chaque contrôle affiche deux choses :

```
✔  Mises a jour systeme il y a 0 j (seuil 7 j)
   systeme : 56 paquet(s) Homebrew en retard
```

1. **Quand ça a eu lieu** — `✔` à jour, `▲` échéance dépassée, `✖` jamais
   enregistré, avec la commande à lancer si c'est en retard ou jamais fait.
2. **Ce qui cloche maintenant**, sur la ligne du dessous — indépendant de la
   première. Voir plus bas pourquoi les deux comptent.

## Deux sources pour la date, et pourquoi

La première ligne répond à « c'était quand ? ». Deux sources peuvent le dire,
et la plus récente gagne :

- **la date déclarée** — ce que tu as enregistré avec `--done` ;
- **la date relevée** — la trace que l'opération a laissée sur la machine :
  `FETCH_HEAD` d'Homebrew, `/var/log/apt/history.log`, `lynis.log`, le nom du
  dossier rendu par `tmutil latestbackup`.

C'est la seconde qui manquait. Sans elle, un `apt upgrade` lancé cinq minutes
plus tôt s'affichait toujours **« jamais enregistré »** : le fichier d'état ne
connaît que ce qu'on lui a déclaré, et personne ne pense à lancer `--done`
après chaque mise à jour. Quand la date affichée vient de la machine, la ligne
le dit — `(seuil 7 j, releve sur le systeme)`.

L'asymétrie entre les deux justifie que la plus récente l'emporte : une trace
sur le disque ne peut pas inventer un évènement qui n'a pas eu lieu, alors que
le fichier d'état, lui, affirme volontiers une mise à jour qu'on n'a jamais
lancée.

## Pourquoi une preuve en plus de la date

Un fichier d'état a un défaut structurel : il se perd avec `$HOME`, et surtout
**il ment**. Il enregistre que tu *as dit* avoir fait la chose, pas qu'elle a
eu lieu. Rien n'empêche de lancer `./check.sh --done update` sans avoir rien
mis à jour.

D'où la ligne « système » : une commande qui interroge l'état réel de la
machine, indépendamment de toute date. La redondance utile n'est pas deux
copies du même fichier — c'est deux sources qui doivent concorder, et qui
parfois ne concordent pas :

```
✔  Mises a jour systeme il y a 0 j (seuil 7 j)
   systeme : 56 paquet(s) Homebrew en retard
```

Ici, la date déclarée dit « fait aujourd'hui », mais 56 paquets Homebrew sont
réellement en retard. Marquer `update` comme fait n'a pas fait tourner
`brew upgrade` — c'est exactement le genre d'écart que l'outil doit montrer,
pas masquer. Les deux lignes ne se remplacent donc pas : **la date dit quand,
la preuve dit quoi.**

## Les trois contrôles

| Contrôle | Date relevée | Preuve |
|---|---|---|
| `update` | macOS : `FETCH_HEAD` d'Homebrew + dernier dossier du Cellar · Debian : `pkgcache.bin`, `history.log`, `update-success-stamp` | nombre de paquets réellement en retard (`brew outdated`, `apt-get -s upgrade`) |
| `backup` | macOS : la date est dans le nom du dossier rendu par `tmutil latestbackup` · Debian : **aucune** — voir plus bas | `tmutil latestbackup` · Debian : aucune |
| `analyse` | `lynis.log`, dans `/var/log` sous `sudo` et dans `$HOME` sinon | `lynis` est-il seulement installé |

### Trois pièges rencontrés en écrivant ces sondes

- **lynis écrit ailleurs qu'on croit.** Sous `sudo` le journal va dans
  `/var/log/lynis.log`, sans privilèges dans `$HOME/lynis.log`. Ne regarder
  que `/var/log` rendait invisible tout audit lancé sans `sudo`.
- **`lynis show options` réécrit `lynis-report.dat`** sans avoir rien audité,
  alors qu'il laisse `lynis.log` intact. La sonde regarde donc le journal, pas
  le rapport — et ignore un journal vide (`checks_newest_date -s`), parce que
  `lynis show` en crée un quand il n'existe pas.
- **Sonder Homebrew pouvait le mettre à jour.** `brew outdated` déclenche un
  `brew update` en douce selon la configuration du poste. La sonde force
  `HOMEBREW_NO_AUTO_UPDATE=1` : un outil qui promet de ne jamais rien mettre à
  jour n'a pas le droit de le faire par effet de bord.

Seule la `mtime` de ces fichiers est lue, jamais leur contenu — `lynis.log`
appartient à `root` en `0640` et reste illisible depuis ton compte.

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
date_macos = commande shell, imprime une date ISO ou rien
date_debian = idem
preuve_macos = commande shell, silencieuse si tout va bien
preuve_debian = idem, ou laisse vide si aucune verification possible
```

Les quatre clés système sont facultatives : vide, le contrôle retombe sur la
seule date déclarée. Toute sortie de `date_*` qui n'est pas une date ISO est
ignorée — mieux vaut ne rien afficher qu'un « il y a ? j ».

Deux helpers de `lib/checks.sh` sont disponibles dans ces commandes :
`checks_file_date <fichier>` rend la `mtime` d'un fichier au format ISO, et
`checks_newest_date [-s] <fichier>...` la plus récente de plusieurs. Ils
masquent la différence entre le `stat` de BSD (`-f %m`) et celui de GNU
(`-c %Y`) — la même divergence que `checks__epoch` gère déjà pour `date`.

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
