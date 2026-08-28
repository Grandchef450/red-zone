Config = {}

-- Touche d'ouverture du menu
Config.OpenKey = 'F6'  -- F8 est la console FiveM, ne jamais l'utiliser

Config.Debug = true

-- Permissions : false en dev. En prod : true + add_ace group.admin rz.props allow
Config.AdminOnly = false

-- Vitesse de deplacement en mode placement (metres / cran)
Config.MoveStep   = 0.05
Config.MoveStepFast = 0.25   -- avec Shift maintenu
Config.RotateStep = 2.0      -- degres / cran

-- Modeles proposes dans le menu (tu peux taper n'importe quel modele)
Config.PropPresets = {
    { model = 'prop_tool_bench02',     label = 'Etabli (workbench)' },
    { model = 'gr_prop_gr_bench_04b',  label = 'Etabli armes' },
    { model = 'prop_toolchest_05',     label = 'Caisse a outils' },
    { model = 'prop_box_wood02a_pu',   label = 'Caisse en bois' },
    { model = 'prop_cash_crate_01',    label = 'Caisse d\'argent' },
    { model = 'prop_ld_shelf_01',      label = 'Etagere' },
    { model = 'p_cs_locker_01_s',      label = 'Casier (vestiaire)' },
    { model = 'prop_gas_pump_1a',      label = 'Pompe a essence' },
    { model = 'prop_barrier_work05',   label = 'Barriere chantier' },
}
