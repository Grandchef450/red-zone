# Migration vers Qbox — RedZone Survival

Passage d'ox_core à **Qbox** (`qbx_core` 1.24.0), le fork moderne de
QBCore compatible nativement avec ox_lib, ox_inventory et ox_target.

Serveur vide, donc aucune donnée à migrer.

---

## Pourquoi Qbox et pas QBCore

Ton `ox_inventory` n'a pas de pont QBCore. Ses dossiers framework sont
`esx`, `nd`, `ox`, `qbx`. Depuis la version 2.x, ox_inventory a
abandonné QBCore au profit de Qbox.

Passer à QBCore classique t'aurait obligé à remplacer ox_inventory par
qb-inventory — donc à perdre les 212 items, les conteneurs, les sacs à
dos, et à réécrire une partie de `rz_craft`.

Qbox te donne l'écosystème QB **sans rien perdre** : ses exports sont
publiés sous le nom `qb-core` grâce à un pont intégré. Les scripts
écrits pour QBCore fonctionnent donc sans modification.

---

## 1. Base de données

Deux imports, dans cet ordre.

**a)** `qbx_core/qbx_core.sql` — crée `players`, `bans`, `player_groups`.

**b)** `rz_INSTALL_COMPLET.sql` — nos 12 tables, adaptées à Qbox.

⚠️ Si tu avais déjà importé l'ancienne version, supprime d'abord les
tables `rz_` : leurs colonnes d'identification étaient des entiers
(`charid`), elles sont maintenant des `VARCHAR(50)` contenant le
`citizenid`.

```sql
DROP TABLE IF EXISTS rz_craft_logs, rz_craft_sessions, rz_mailbox,
    rz_player_crafting, rz_trader_offers, rz_traders,
    rz_craft_table_recipes, rz_craft_ingredients, rz_craft_recipes,
    rz_craft_tables, rz_mailbox_points, rz_item_values;
```

Puis réimporte.

---

## 2. Ressources

**Ajouter** `qbx_core` dans `resources/[ox]/`.

**Retirer** `ox_core` — le déplacer hors du dossier `resources`, pas
seulement le commenter dans le cfg. Deux frameworks qui tournent
ensemble se disputent la gestion des personnages.

---

## 3. Configurations à changer à la main

| Fichier | Ligne | Nouvelle valeur |
|---|---|---|
| `val-hud/config.lua` | `Config.FrameWork` | `'qb'` |
| `illenium-appearance/config.lua` | framework | `'qb'` |

Le convar d'ox_inventory est déjà dans le `server.cfg` :

```cfg
setr inventory:framework "qbx"
```

Sans cette ligne, ox_inventory démarre en mode ESX et rien ne
fonctionne. `ox_target`, lui, détecte Qbox tout seul.

---

## 4. OneSync

**Obligatoire.** `qbx_core` le déclare en dépendance dans son
manifeste et refusera de démarrer sans lui.

txAdmin → Settings → FXServer → OneSync : **Infinity** (ou On).

---

## 5. Ce qui a changé dans `rz_craft`

L'identification du joueur passe du `charId` d'ox_core (un entier) au
`citizenid` de Qbox (une chaîne comme `ABC12345`).

```lua
-- avant
local player = Ox.GetPlayer(source)
return player and player.charId

-- après
local player = exports.qbx_core:GetPlayer(source)
return player and player.PlayerData and player.PlayerData.citizenid
```

Toutes les colonnes concernées ont suivi : `rz_player_crafting`,
`rz_craft_sessions`, `rz_mailbox`, `rz_craft_logs`.

---

## 6. `rz_vip` est réactivé

Il appelait `exports['qb-core']:GetCoreObject()`, ce qui plantait sur
ox_core. Le pont de Qbox publie ses exports sous ce nom exact, donc il
fonctionne sans retouche. Sa ligne `ensure` est décommentée dans le
`server.cfg`.

---

## 7. Ordre de démarrage

```
oxmysql → ox_lib → qbx_core → ox_target → ox_inventory
   → illenium-appearance → pma-voice → ox_fuel
   → [MLO] → [Vetements] → véhicules → armes
   → vMenu → [Script] (dont zombies)
   → admin → rz_safezone → rz_craft → outils rz_
   → val-hud
```

Le point à retenir : `rz_safezone` doit démarrer **après** `[Script]`
pour trouver le script de zombies et lui déclarer les zones à vider.

---

## 8. Vérification

Au démarrage, la console doit afficher :

- `qbx_core` chargé sans erreur
- `ox_inventory` avec un nombre d'items supérieur à 400
- aucune ligne `No such export GetCoreObject`

En jeu, teste dans cet ordre :

1. Création de personnage — c'est Qbox qui la gère maintenant
2. `/craftcreator` → le menu s'ouvre
3. `/safezones` → le menu s'ouvre
4. F5 → les sept boutons RedZone sont visibles

---

## Ce qui reste à surveiller

**Les métiers et gangs.** Qbox les définit dans `qbx_core/shared/`.
Pour un serveur post-apo, tu voudras probablement vider la liste par
défaut — police, ambulance, mécano n'ont pas grand sens dans ton
univers.

**Le multicharacter.** Qbox l'intègre. `ZSX_Multicharacter` a été
retiré à l'étape B, il n'y a donc pas de conflit.

**L'argent.** Qbox gère cash, banque et crypto. Ton économie repose sur
les capsules, un item d'inventaire. Les deux coexistent sans se gêner,
mais tu voudras sans doute masquer l'argent classique de l'interface.
