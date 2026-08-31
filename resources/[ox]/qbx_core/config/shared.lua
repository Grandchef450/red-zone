return {
    serverName = 'RedZone Survival',

    --[[
        DÉFAUT DE SECOURS

        Cette position ne sert que si rz_spawn ne répond pas. En
        temps normal c'est lui qui place les joueurs, sur le mont
        Chiliad.
    ]]
    defaultSpawn = vec4(-431.4511, 1102.2653, 340.4395, 346.9962),

    -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
    notifyPosition = 'top-right',

    ---@type { name: string, amount: integer, metadata: fun(source: number): table }[]

    --[[
        ═══════════════════════════════════════════════════════════
         OBJETS DE DÉPART — REDZONE
        ═══════════════════════════════════════════════════════════

        ─── CE QUI A ÉTÉ RETIRÉ ───────────────────────────────────

        Les trois objets d'origine étaient : un téléphone, une carte
        d'identité et un permis de conduire.

        Les deux derniers appelaient qbx_idcard, une ressource qui
        n'est pas installée :

          « qbx_idcard resource not found. Required to give an
            id_card as a starting item »

        Et sur le fond, aucun des trois n'a sa place ici. Un permis
        de conduire dans un monde où plus aucune administration
        n'existe, c'est du décor de serveur RP classique.

        ─── CE QUI LES REMPLACE ───────────────────────────────────

        Le strict nécessaire pour ne pas mourir dans l'heure. Rien
        qui dispense de farmer : un joueur doit chercher tout le
        reste.

        Le pager mérite une mention : sans lui, on ne reçoit ni les
        annonces du staff, ni les alertes de zone radioactive, ni
        les largages aériens. C'est le seul objet qui relie un
        nouveau venu au reste du monde.
    ]]
    starterItems = {
        -- Communication : indispensable pour recevoir les alertes
        { name = 'pager', amount = 1 },

        --[[
            MONNAIE DE DÉPART

            500 capsules. De quoi troquer chez un ped marchand ou
            payer un lot de craft supplémentaire sans avoir encore
            rien farmé.
        ]]
        { name = 'capsule', amount = 500 },

        --[[
            EAU ET NOURRITURE

            eau_purifiee et non bouteille_eau_sale : l'eau sale
            existe dans ton tableau comme matière à purifier, pas
            comme boisson. En donner cinq au départ enverrait le
            mauvais signal.

            Les plats viennent de la CUISSON SIMPLE, pas des plats
            avancés. Un civet de cerf ou une papillote de saumon,
            c'est le sommet de ta chaîne de cuisine — l'offrir à
            quelqu'un qui n'a pas encore allumé un feu viderait
            cette progression de son sens.
        ]]
        { name = 'eau_purifiee', amount = 5 },
        { name = 'steak_cerf', amount = 3 },
        { name = 'filet_truite', amount = 2 },

        -- Premiers soins
        { name = 'bandage_survie', amount = 2 },

        --[[
            La première arme.

            ⚠️  C'est « hache_survie » et non « couteau_survie ».

            Le couteau de survie existe bien dans items.lua, mais
            c'est un ITEM INERTE : on peut le porter, pas s'en
            servir pour se battre. Les quatre couteaux craftables
            sont dans le même cas — ils attendent d'être convertis
            en armes, comme l'ont été les haches.

            La hache de survie, elle, est une vraie arme depuis la
            conversion : 30 de dégâts, modèle w_me_hatchette_b.
        ]]
        { name = 'hache_survie', amount = 1 },

        -- Un contenant minimal : 12 slots, ça force à choisir
        { name = 'sac_survie_12', amount = 1 },

        -- Quelques matériaux pour amorcer le premier craft
        { name = 'ferraille', amount = 3 },
        { name = 'morceau_bois', amount = 3 },
    }
}
