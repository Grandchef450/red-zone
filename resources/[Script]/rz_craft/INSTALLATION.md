# rz_craft — Installation

Système de craft, progression et boîte aux lettres pour RedZone Survival.

---

## 1. Base de données

Importer dans cet ordre, via phpMyAdmin ou HeidiSQL :

1. `rz_craft_schema.sql` — établis, recettes, ingrédients, peds, progression
2. `rz_craft_capsules.sql` — valeurs en capsules et colonnes de substitution
3. `rz_craft_sessions.sql` — sessions de craft et boîte aux lettres

Vérification :

```sql
SHOW TABLES LIKE 'rz_%';
```

Onze tables doivent apparaître.

---

## 2. ox_inventory

Deux fichiers à remplacer, livrés séparément :

| Fichier | Destination |
|---|---|
| `items.lua` | `ox_inventory/data/items.lua` |
| `containers.snippet.lua` | à coller dans `ox_inventory/modules/items/containers.lua` |

Pour les conteneurs, retirer les exemples `paperbag` et `pizzabox` d'origine.

Redémarrer puis vérifier en console : le nombre d'items chargés doit
passer de 218 à plus de 400.

---

## 3. La ressource

Copier le dossier `rz_craft` dans `resources/[vqc_scripts]/`.

Dans `server.cfg`, **après** le bloc ox :

```cfg
ensure rz_craft
```

L'ordre compte : `rz_craft` dépend d'`ox_lib`, `ox_core`,
`ox_inventory`, `ox_target` et `oxmysql`.

---

## 4. Permissions admin

Toujours dans `server.cfg` :

```cfg
add_ace group.admin rz_craft.admin allow
add_principal identifier.license:TA_LICENCE group.admin
```

Pour trouver ta licence : connecte-toi et tape `status` en console serveur.

---

## 5. Premier établi

Rien n'apparaît en jeu tant qu'aucun établi n'existe en base.
En attendant l'éditeur admin, un insert manuel suffit pour tester :

```sql
-- Un établi de test à Sandy Shores
INSERT INTO rz_craft_tables
    (label, tier, x, y, z, heading, prop_model, blip_sprite, blip_color, in_safezone)
VALUES
    ('Établi de test', 1, 1698.28, 2586.14, 45.56, 180.0,
     'prop_toolchest_01', 566, 5, 1);

-- Une recette simple : 3 ferrailles donnent 1 couteau de survie
INSERT INTO rz_craft_recipes
    (output_item, output_qty, category, required_level, xp_gain)
VALUES
    ('couteau_survie', 1, 'equipement', 0, 25);

SET @recipe = LAST_INSERT_ID();

INSERT INTO rz_craft_ingredients (recipe_id, item, qty) VALUES
    (@recipe, 'ferraille', 3),
    (@recipe, 'morceau_bois', 2);

-- Rendre la recette disponible sur l'établi
INSERT INTO rz_craft_table_recipes (table_id, recipe_id)
VALUES (LAST_INSERT_ID() - 0, @recipe);
```

⚠️ La dernière ligne suppose que l'établi porte l'`id` 1.
Vérifier avec `SELECT id, label FROM rz_craft_tables;` et corriger si besoin.

Puis en console serveur :

```
restart rz_craft
```

---

## 6. Point de retrait des colis

Le point de retrait est un **ped**, pas une boîte : un survivant qui
garde les colis.

```sql
INSERT INTO rz_mailbox_points
    (label, x, y, z, heading, ped_model, scenario, blip_sprite, blip_color, safezone_id)
VALUES
    ('Le Facteur — Sandy', 1701.50, 2590.00, 45.56, 90.0,
     'a_m_m_hillbilly_01', 'WORLD_HUMAN_CLIPBOARD', 480, 5, 'safezone_sandy');
```

Modèles qui collent au thème : `a_m_m_hillbilly_01`, `a_m_m_tramp_01`,
`s_m_m_dockwork_01`, `s_m_y_dealer_01`.

Scénarios utiles : `WORLD_HUMAN_CLIPBOARD` (consulte un registre),
`WORLD_HUMAN_GUARD_STAND`, `WORLD_HUMAN_AA_COFFEE`, `WORLD_HUMAN_SMOKING`.

La colonne `prop_model` reste disponible si tu veux ajouter un décor
à côté du ped — une caisse, un comptoir. Laisse-la à `NULL` pour un
ped seul.

Test du dépôt de colis, en jeu :

```
/colis 1 ferraille 10 Test
```

---

## Réglages

Tout se trouve dans `config.lua`.

**Durée de craft** — `Config.CraftTime.halfway` est le seul curseur à
connaître : c'est le niveau auquel un craft prend 2 min 30. Le monter
étale la progression, le descendre la durcit.

**Capsules** — `Config.Capsules.multiplier` à 2.5. Ne jamais descendre
sous 1.5, sinon payer devient moins cher que farmer et le système
d'économie s'effondre.

**Zone** — `Config.CraftZone.radius` à 2 mètres, avec une tolérance à 3
et 5 secondes de grâce. Ces deux dernières valeurs absorbent les
bousculades et les décalages d'animation. Les mettre à zéro rendrait le
craft long très frustrant.

**Lot** — 5 items gratuits, 20 au maximum. Le plafond n'est pas
cosmétique : sans lui, un joueur riche lance un lot de 500 et bloque une
boucle serveur pendant des heures.

---

## Diagnostic

Passer `Config.Debug = true` pour tracer le chargement et les
réservations en console.

| Symptôme | Cause probable |
|---|---|
| Aucun établi visible | Table `rz_craft_tables` vide, ou `restart rz_craft` oublié |
| « Recette introuvable » | Aucune ligne dans `rz_craft_table_recipes` |
| Item impossible à déplacer | Réservation orpheline — `restart rz_craft` la libère |
| Craft annulé aussitôt | Coordonnées de l'établi fausses : le joueur est hors rayon |
| « Personnage introuvable » | ox_core n'est pas démarré avant `rz_craft` |

---

## 7. Bouton dans le panneau admin (F5)

Ouvre `resources/[Script]/admin/Nui/index.html`, va tout en bas, et
colle le contenu de `INTEGRATION_ADMIN.html` **juste avant** `</body>`.

C'est la seule modification à faire dans le panneau. Aucun de ses
fichiers Lua n'est touché : le bouton appelle directement le callback
de `rz_craft`. Si tu remplaces un jour ce panneau, tu n'auras que ce
bloc à recoller.

Puis `restart admin` et `restart rz_craft`.

Un bouton **Craft Creator** apparaît en bas de la barre latérale du F5.

Si le bouton ne répond pas, la commande `/craftcreator` ouvre le même
menu — utile pour vérifier que le problème vient bien de l'intégration
et non de la ressource.

---

## Le créateur

**Poser un établi / un facteur** — un formulaire, puis un prop
semi-transparent apparaît devant toi.

| Touche | Effet |
|---|---|
| Molette | distance |
| Page haut / bas | hauteur |
| Q / E | rotation |
| Maj + Q/E | rotation rapide |
| Entrée | valider |
| Échap | annuler |

**Créer une recette** — trois étapes : l'item produit et son niveau,
puis les ingrédients ligne par ligne avec un bouton « Ajouter », puis
le choix des établis où la recette sera disponible.

Tout est écrit en base et rechargé immédiatement chez tous les joueurs
connectés. Aucun redémarrage.

---

## Ce qui reste à construire

- Peds troqueurs (schéma prêt, code à écrire)
- Import des 134 recettes depuis le classeur Excel
- Icônes des items dans `ox_inventory/web/images/`
