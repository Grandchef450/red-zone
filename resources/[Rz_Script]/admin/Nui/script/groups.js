(function () {
    var sectionKeys = [
        { key: "dashboard", label: "Dashboard", icon: "fa-house", descKey: "groups_perm_desc_dashboard", desc: "Vista general" },
        { key: "players", label: "Players", icon: "fa-user", descKey: "groups_perm_desc_players", desc: "Listado de jugadores" },
        { key: "map", label: "Map", icon: "fa-map-location-dot", descKey: "groups_perm_desc_map", desc: "Mapa del servidor" },
        { key: "logs", label: "Logs", icon: "fa-list", descKey: "groups_perm_desc_logs", desc: "Registro de acciones" },
        { key: "groups", label: "Groups", icon: "fa-users", descKey: "groups_perm_desc_groups", desc: "Gestion de grupos" },
        { key: "bans", label: "Bans", icon: "fa-ban", descKey: "groups_perm_desc_bans", desc: "Seccion de baneos" },
        { key: "terminal", label: "Terminal", icon: "fa-terminal", descKey: "groups_perm_desc_terminal", desc: "Consola y gestion" },
        { key: "comandos", labelKey: "groups_perm_label_comandos", label: "Comandos", icon: "fa-keyboard", descKey: "groups_perm_desc_comandos", desc: "Comandos de staff" },
        { key: "kick_action_menu", label: "Kick Action Menu", icon: "fa-bolt", descKey: "groups_perm_desc_kick_action_menu", desc: "Menu de acciones" }
    ];
    var reportesSection = { key: "reportes", labelKey: "groups_perm_label_reportes", label: "Reportes", icon: "fa-flag", descKey: "groups_perm_desc_reportes", desc: "Reportes de jugadores" };
    var estadisticasSection = { key: "estadisticas", labelKey: "groups_perm_label_estadisticas", label: "Estadísticas", icon: "fa-chart-line", descKey: "groups_perm_desc_estadisticas", desc: "Estadísticas del servidor" };
    function getSectionKeys() {
        var keys = sectionKeys.slice();
        if (typeof window !== "undefined" && window.optionalSections && window.optionalSections.reportes) keys.push(reportesSection);
        keys.push(estadisticasSection);
        return keys;
    }
    var dashboardActionKeys = [
        { key: "info_admin", label: "Info admin", descKey: "groups_perm_desc_info_admin", desc: "Ver info de admins", icon: "fa-circle-info" },
        { key: "announcements", label: "Announcements", descKey: "groups_perm_desc_announcements", desc: "Anuncios globales", icon: "fa-bullhorn" },
        { key: "noclip", label: "Noclip", descKey: "groups_perm_desc_noclip", desc: "Atravesar superficies", icon: "fa-shoe-prints" },
        { key: "server_time", label: "Server time", descKey: "groups_perm_desc_server_time", desc: "Cambiar hora", icon: "fa-clock" },
        { key: "godmode", label: "God mode", descKey: "groups_perm_desc_godmode", desc: "Inmunidad al daño", icon: "fa-user-shield" },
        { key: "invisibility", label: "Invisibility", descKey: "groups_perm_desc_invisibility", desc: "Modo invisible", icon: "fa-eye-slash" },
        { key: "staff_clothing", label: "Staff clothing", descKey: "groups_perm_desc_staff_clothing", desc: "Ropa de staff", icon: "fa-shirt" },
        { key: "tag_player", label: "Tag", descKey: "groups_perm_desc_tag_player", desc: "Tags sobre jugadores", icon: "fa-tag" },
        { key: "admin_tag", label: "Admin Tag", descKey: "groups_perm_desc_admin_tag", desc: "Etiqueta de staff sobre la cabeza", icon: "fa-id-badge" },
        { key: "delete_vehicle", label: "Delete vehicle", descKey: "groups_perm_desc_delete_vehicle", desc: "Eliminar vehiculo", icon: "fa-trash" },
        { key: "fix_vehicle", label: "Fix vehicle", descKey: "groups_perm_desc_fix_vehicle", desc: "Reparar vehiculo", icon: "fa-wrench" },
        { key: "infiniteammo", label: "Infinite Ammo", descKey: "groups_perm_desc_infiniteammo", desc: "Munición infinita", icon: "fa-gun" }
    ];
    var mapActionKeys = [
        { key: "bring", label: "Bring", descKey: "groups_perm_desc_bring", desc: "Traer jugador", icon: "fa-hand-holding" },
        { key: "goto", label: "Goto", descKey: "groups_perm_desc_goto", desc: "Ir al jugador", icon: "fa-location-crosshairs" },
        { key: "freeze", label: "Freeze", descKey: "groups_perm_desc_freeze", desc: "Congelar jugador", icon: "fa-snowflake" },
        { key: "viewScreen", label: "View screen", descKey: "groups_perm_desc_viewScreen", desc: "Ver pantalla", icon: "fa-display" }
    ];
    var playersActionKeys = [
        { key: "bring", label: "Bring", descKey: "groups_perm_desc_bring", desc: "Traer jugador", icon: "fa-hand-holding" },
        { key: "goto", label: "Teleport to player", descKey: "groups_perm_desc_goto", desc: "Ir al jugador", icon: "fa-location-crosshairs" },
        { key: "spectate", label: "Spectate player", descKey: "groups_perm_desc_spectate", desc: "Espectear", icon: "fa-eye" },
        { key: "capture", label: "Take capture", descKey: "groups_perm_desc_capture", desc: "Capturar pantalla", icon: "fa-camera" },
        { key: "skin", label: "Change skin", descKey: "groups_perm_desc_skin", desc: "Cambiar apariencia", icon: "fa-shirt" },
        { key: "job", label: "Assign job", descKey: "groups_perm_desc_job", desc: "Asignar trabajo", icon: "fa-briefcase" },
        { key: "return", label: "Return player", descKey: "groups_perm_desc_return", desc: "Devolver a posicion", icon: "fa-arrow-rotate-left" },
        { key: "items", labelKey: "groups_perm_label_items", label: "Inventario", descKey: "groups_perm_desc_items", desc: "Inventario", icon: "fa-box" },
        { key: "notes", labelKey: "groups_perm_label_notes", label: "Notas", descKey: "groups_perm_desc_notes", desc: "Notas administrativas", icon: "fa-note-sticky" },
        { key: "gang", label: "Assign gang", descKey: "groups_perm_desc_gang", desc: "Asignar banda", icon: "fa-people-group" },
        { key: "revive", label: "Revive", descKey: "groups_perm_desc_revive", desc: "Revivir", icon: "fa-heart-pulse" },
        { key: "rz_effects", labelKey: "player_rz_effects", label: "Annuler les effets", descKey: "groups_perm_desc_rz_effects", desc: "Annuler virus, bonus et gueule de bois (rz_soins)", icon: "fa-broom" },
        { key: "rz_heal", labelKey: "player_rz_heal", label: "Soigner", descKey: "groups_perm_desc_rz_heal", desc: "Remettre un joueur en pleine santé (rz_soins)", icon: "fa-kit-medical" },
        { key: "money", label: "Manage money", descKey: "groups_perm_desc_money", desc: "Gestionar dinero", icon: "fa-wallet" },
        { key: "admin", label: "Assign admin", descKey: "groups_perm_desc_admin", desc: "Dar rango admin", icon: "fa-crown" },
        { key: "kill", label: "Kill", descKey: "groups_perm_desc_kill", desc: "Matar", icon: "fa-skull" },
        { key: "clearinv", label: "Clear inventory", descKey: "groups_perm_desc_clearinv", desc: "Limpiar inventario", icon: "fa-trash" },
        { key: "ck", label: "CK Player", descKey: "groups_perm_desc_ck", desc: "Character kill", icon: "fa-user-xmark" },
        { key: "instancia", labelKey: "groups_perm_label_instancia", label: "Instancia", descKey: "groups_perm_desc_instancia", desc: "Mover a instancia (bucket)", icon: "fa-cube" },
        { key: "spawnvehicle", label: "Spawn vehicle", descKey: "groups_perm_desc_spawnvehicle", desc: "Spamear vehiculo", icon: "fa-car-side" },
        { key: "add_player_vehicle", label: "Add vehicle", descKey: "groups_perm_desc_add_player_vehicle", desc: "Añadir coche al garaje del jugador", icon: "fa-plus" },
        { key: "delete_player_vehicle", labelKey: "groups_perm_label_delete_player_vehicle", label: "Eliminar Vehiculo", descKey: "groups_perm_desc_delete_player_vehicle", desc: "Eliminar coche a miembro", icon: "fa-trash" },
        { key: "ban", label: "Ban from server", descKey: "groups_perm_desc_ban", desc: "Banear", icon: "fa-ban" },
        { key: "kick", label: "Kick from server", descKey: "groups_perm_desc_kick", desc: "Expulsar", icon: "fa-right-from-bracket" }
    ];
    var bansActionKeys = [
        { key: "ban", label: "Ban from server", descKey: "groups_perm_desc_ban", desc: "Banear", icon: "fa-ban" },
        { key: "bans_unban", labelKey: "groups_perm_label_bans_unban", label: "Desbanear", descKey: "groups_perm_desc_bans_unban", desc: "Quitar baneo a un jugador", icon: "fa-unlock" },
        { key: "bans_modify", labelKey: "groups_perm_label_bans_modify", label: "Modificar baneos", descKey: "groups_perm_desc_bans_modify", desc: "Editar razon o fecha", icon: "fa-pen-to-square" }
    ];
    var terminalActionKeys = [
        { key: "terminal_restart", labelKey: "groups_perm_label_terminal_restart", label: "Reiniciar recursos", descKey: "groups_perm_desc_terminal_restart", desc: "Restart de recursos", icon: "fa-rotate-right" },
        { key: "terminal_stop", labelKey: "groups_perm_label_terminal_stop", label: "Parar/iniciar recursos", descKey: "groups_perm_desc_terminal_stop", desc: "Stop y start de recursos", icon: "fa-stop" },
        { key: "terminal_console", labelKey: "groups_perm_label_terminal_console", label: "Escribir en consola", descKey: "groups_perm_desc_terminal_console", desc: "Ejecutar comandos", icon: "fa-terminal" }
    ];
    var logTypes = [
        { key: "log_server_join", labelKey: "groups_perm_label_log_server_join", label: "Entradas", descKey: "groups_perm_desc_log_server_join", desc: "Entradas al servidor", icon: "fa-door-open" },
        { key: "log_server_leave", labelKey: "groups_perm_label_log_server_leave", label: "Salidas", descKey: "groups_perm_desc_log_server_leave", desc: "Salidas del servidor", icon: "fa-door-closed" },
        { key: "log_chat", label: "Chat", descKey: "groups_perm_desc_log_chat", desc: "Chat del servidor", icon: "fa-comments" },
        { key: "log_deaths", labelKey: "groups_perm_label_log_deaths", label: "Muertes", descKey: "groups_perm_desc_log_deaths", desc: "Muertes de jugadores", icon: "fa-skull" },
        { key: "log_kills", label: "Kills", descKey: "groups_perm_desc_log_kills", desc: "Kills de jugadores", icon: "fa-crosshairs" },
        { key: "log_explosions", labelKey: "groups_perm_label_log_explosions", label: "Explosiones", descKey: "groups_perm_desc_log_explosions", desc: "Log de explosiones", icon: "fa-bomb" },
        { key: "log_permissions", labelKey: "groups_perm_label_log_permissions", label: "Permisos", descKey: "groups_perm_desc_log_permissions", desc: "Cambios de permisos", icon: "fa-key" },
        { key: "log_admin_actions", labelKey: "groups_perm_label_log_admin_actions", label: "Admin actions", descKey: "groups_perm_desc_log_admin_actions", desc: "Admin panel action log", icon: "fa-user-shield" },
        { key: "log_bans", labelKey: "groups_perm_label_log_bans", label: "Baneos", descKey: "groups_perm_desc_log_bans", desc: "Baneos del servidor", icon: "fa-ban" },
        { key: "log_unbans", labelKey: "groups_perm_label_log_unbans", label: "Desbaneos", descKey: "groups_perm_desc_log_unbans", desc: "Desbaneos", icon: "fa-circle-check" },
        { key: "log_tx_admin", label: "TX Admin", descKey: "groups_perm_desc_log_tx_admin", desc: "Logs de TX Admin", icon: "fa-terminal" }
    ];
    var reportesActionKeys = [
        { key: "reportes_control_panel", label: "Report Control Panel", descKey: "groups_perm_desc_reportes_control_panel", desc: "Panel de control", icon: "fa-sliders" },
        { key: "reportes_all_reports", label: "All reports", descKey: "groups_perm_desc_reportes_all_reports", desc: "Ver todos los reportes", icon: "fa-flag" },
        { key: "reportes_staff_chat", label: "Staff chat", descKey: "groups_perm_desc_reportes_staff_chat", desc: "Chat de staff", icon: "fa-comments" }
    ];
    var estadisticasActionKeys = [
        { key: "estadisticas", labelKey: "groups_perm_label_estadisticas", label: "Estadísticas", descKey: "groups_perm_desc_estadisticas_view", desc: "Estadísticas del servidor", icon: "fa-chart-line" }
    ];
    function getComandosActionKeys() {
        var list = (typeof window !== "undefined" && window.commandStaffPerms) ? window.commandStaffPerms : [];
        return list.map(function (p) {
            var o = { key: p.key, label: p.label || p.key, desc: p.desc || "", icon: p.icon || "fa-terminal" };
            if (p.descKey) o.descKey = p.descKey;
            return o;
        });
    }
    var kickActionMenuActionKeys = [
        { key: "revive", label: "Revive", descKey: "groups_perm_desc_revive", desc: "Revivir", icon: "fa-heart-pulse" },
        { key: "tpm", label: "Teleport me", descKey: "groups_perm_desc_tpm", desc: "Teletransporte al marcador", icon: "fa-person-arrow-up-from-line" },
        { key: "copy_coords", label: "Copy coords", descKey: "groups_perm_desc_copy_coords", desc: "Copiar coordenadas", icon: "fa-copy" },
        { key: "tune_vehicle", label: "Tune vehicle", descKey: "groups_perm_desc_tune_vehicle", desc: "Tunar vehiculo", icon: "fa-sliders" }
    ];

    function resName() {
        return typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin";
    }

    function getTotalPermsCount() {
        var comandosKeys = getComandosActionKeys();
        var allKeyArrays = [getSectionKeys(), dashboardActionKeys, mapActionKeys, playersActionKeys, logTypes, bansActionKeys, terminalActionKeys, comandosKeys, kickActionMenuActionKeys, reportesActionKeys, estadisticasActionKeys];
        var unique = {};
        allKeyArrays.forEach(function (arr) {
            arr.forEach(function (p) { if (p && p.key) unique[p.key] = true; });
        });
        return Object.keys(unique).length;
    }

    function getGroupPermCounts(perms) {
        perms = perms || {};
        var total = getTotalPermsCount();
        var comandosKeys = getComandosActionKeys();
        var allKeyArrays = [getSectionKeys(), dashboardActionKeys, mapActionKeys, playersActionKeys, logTypes, bansActionKeys, terminalActionKeys, comandosKeys, kickActionMenuActionKeys, reportesActionKeys, estadisticasActionKeys];
        var selectedSet = {};
        allKeyArrays.forEach(function (arr) {
            arr.forEach(function (p) {
                if (p && p.key && (perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1)) selectedSet[p.key] = true;
            });
        });
        return { selected: Object.keys(selectedSet).length, total: total };
    }

    function fetchGroups() {
        return fetch("https://" + resName() + "/groupsGetList", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).then(function (r) { return r.json(); }).then(function (data) {
            return Array.isArray(data) ? data : [];
        }).catch(function () { return []; });
    }

    function renderPermsBlock(containerEl, perms) {
        if (!containerEl) return;
        perms = perms || {};
        containerEl.innerHTML = "";
        var sectionTitle = document.createElement("h4");
        sectionTitle.className = "groups-perms-subtitle";
        sectionTitle.textContent = (typeof window !== "undefined" && window.t && window.t("groups_perms_sections")) || "Section permissions";
        containerEl.appendChild(sectionTitle);
        var sectionGrid = document.createElement("div");
        sectionGrid.className = "groups-perms-grid";
        getSectionKeys().forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var iconClass = p.icon ? "fa-solid " + p.icon : "fa-solid fa-circle";
            var descText = (typeof window !== "undefined" && window.t && p.descKey && window.t(p.descKey)) || (p.desc || "");
            var desc = descText.replace(/</g, "&lt;").replace(/"/g, "&quot;");
            var label = document.createElement("label");
            label.className = "groups-section-perm-item";
            var labelText = (typeof window !== "undefined" && window.t && p.labelKey && window.t(p.labelKey)) || (p.label || "");
            label.innerHTML = "<span class=\"groups-section-perm-icon\"><i class=\"" + iconClass + "\"></i></span><div class=\"groups-section-perm-text\"><span class=\"groups-section-perm-label\">" + labelText.replace(/</g, "&lt;") + "</span><span class=\"groups-section-perm-desc\">" + desc + "</span></div><span class=\"groups-toggle-wrap\"><input type=\"checkbox\" data-perm=\"" + (p.key || "").replace(/"/g, "&quot;") + "\"" + (checked ? " checked" : "") + "><span class=\"groups-toggle-slider\"></span></span>";
            sectionGrid.appendChild(label);
        });
        containerEl.appendChild(sectionGrid);
        var actionWrap = document.createElement("div");
        actionWrap.className = "groups-action-perms-wrap";
        var dashboardChecked = perms.dashboard === true || perms.dashboard === "1" || perms.dashboard === 1;
        var mapChecked = perms.map === true || perms.map === "1" || perms.map === 1;
        var playersChecked = perms.players === true || perms.players === "1" || perms.players === 1;
        var logsChecked = perms.logs === true || perms.logs === "1" || perms.logs === 1;
        var bansChecked = perms.bans === true || perms.bans === "1" || perms.bans === 1;
        var terminalChecked = perms.terminal === true || perms.terminal === "1" || perms.terminal === 1;
        var comandosChecked = perms.comandos === true || perms.comandos === "1" || perms.comandos === 1;
        var kickActionMenuChecked = perms.kick_action_menu === true || perms.kick_action_menu === "1" || perms.kick_action_menu === 1;
        var reportesChecked = perms.reportes === true || perms.reportes === "1" || perms.reportes === 1;
        var estadisticasChecked = perms.estadisticas === true || perms.estadisticas === "1" || perms.estadisticas === 1;
        var anySectionChecked = dashboardChecked || mapChecked || playersChecked || logsChecked || bansChecked || terminalChecked || comandosChecked || kickActionMenuChecked || reportesChecked || estadisticasChecked;
        var actionTitleRow = document.createElement("div");
        actionTitleRow.className = "groups-action-perms-title-row";
        var actionTitle = document.createElement("h4");
        actionTitle.className = "groups-perms-subtitle";
        actionTitle.textContent = (typeof window !== "undefined" && window.t && window.t("groups_perms_actions")) || "Action permissions";
        actionTitleRow.appendChild(actionTitle);
        var actionLoadingSpan = document.createElement("span");
        actionLoadingSpan.className = "groups-action-perms-loading";
        var loadingText = (typeof window !== "undefined" && window.t && window.t("groups_loading")) || "Loading";
        actionLoadingSpan.innerHTML = "<i class=\"fa-solid fa-spinner fa-spin\"></i><span>" + loadingText.replace(/</g, "&lt;") + "</span>";
        actionTitleRow.appendChild(actionLoadingSpan);
        var actionCountSpan = document.createElement("span");
        actionCountSpan.className = "groups-action-perms-count hidden";
        actionCountSpan.textContent = "0/0";
        actionTitleRow.appendChild(actionCountSpan);
        var selectAllBtn = document.createElement("button");
        selectAllBtn.type = "button";
        selectAllBtn.className = "groups-action-perms-select-all hidden";
        var selectAllText = (typeof window !== "undefined" && window.t && window.t("groups_select_all")) || "Select all";
        selectAllBtn.setAttribute("title", selectAllText);
        selectAllBtn.setAttribute("aria-label", selectAllText);
        selectAllBtn.innerHTML = "<i class=\"fa-solid fa-check-double\"></i>";
        actionTitleRow.appendChild(selectAllBtn);
        actionWrap.appendChild(actionTitleRow);
        var actionPlaceholder = document.createElement("div");
        actionPlaceholder.className = "groups-action-perms-empty";
        var noSectionText = (typeof window !== "undefined" && window.t && window.t("groups_no_section_selected")) || "No section selected";
        actionPlaceholder.innerHTML = "<i class=\"fa-solid fa-folder-open\"></i><span>" + noSectionText.replace(/</g, "&lt;") + "</span>";
        if (anySectionChecked) actionPlaceholder.classList.add("hidden");
        actionWrap.appendChild(actionPlaceholder);
        var actionContent = document.createElement("div");
        actionContent.className = "groups-action-perms-content";
        if (!anySectionChecked) actionContent.classList.add("hidden");
        var actionContentLoading = document.createElement("div");
        actionContentLoading.className = "groups-action-perms-content-loading";
        actionContentLoading.innerHTML = "<i class=\"fa-solid fa-spinner fa-spin\"></i><span>" + loadingText.replace(/</g, "&lt;") + "</span>";
        actionContent.appendChild(actionContentLoading);
        actionWrap.appendChild(actionContent);
        containerEl.appendChild(actionWrap);
        var actionScroll = document.createElement("div");
        actionScroll.className = "groups-action-perms-scroll";
        var actionGrid = document.createElement("div");
        actionGrid.className = "groups-action-perms-grid";
        function renderActionCard(p, section, checked) {
            var label = document.createElement("label");
            label.className = "groups-action-perm-card";
            label.setAttribute("data-section", section);
            var iconClass = (p.icon && p.icon.indexOf("fa-") !== -1) ? "fa-solid " + p.icon : "fa-solid fa-circle";
            var descText = (typeof window !== "undefined" && window.t && p.descKey && window.t(p.descKey)) || (p.desc || "");
            var descEsc = descText.replace(/</g, "&lt;").replace(/"/g, "&quot;");
            var labelEsc = ((typeof window !== "undefined" && window.t && p.labelKey && window.t(p.labelKey)) || (p.label || "")).replace(/</g, "&lt;").replace(/"/g, "&quot;");
            label.innerHTML = "<span class=\"groups-action-perm-icon\"><i class=\"" + iconClass + "\"></i></span><span class=\"groups-action-perm-text\"><span class=\"groups-action-perm-label\">" + labelEsc + "</span><span class=\"groups-action-perm-desc\">" + descEsc + "</span></span><span class=\"groups-toggle-wrap\"><input type=\"checkbox\" data-perm=\"" + (p.key || "").replace(/"/g, "&quot;") + "\"" + (checked ? " checked" : "") + "><span class=\"groups-toggle-slider\"></span></span>";
            return label;
        }
        dashboardActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "dashboard", checked);
            if (!dashboardChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        mapActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "map", checked);
            if (!mapChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        playersActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "players", checked);
            if (!playersChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        logTypes.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "logs", checked);
            if (!logsChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        bansActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "bans", checked);
            if (!bansChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        terminalActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "terminal", checked);
            if (!terminalChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        reportesActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "reportes", checked);
            if (!reportesChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        estadisticasActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "estadisticas", checked);
            if (!estadisticasChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        getComandosActionKeys().forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "comandos", checked);
            if (!comandosChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        kickActionMenuActionKeys.forEach(function (p) {
            var checked = perms[p.key] === true || perms[p.key] === "1" || perms[p.key] === 1;
            var card = renderActionCard(p, "kick_action_menu", checked);
            if (!kickActionMenuChecked) card.classList.add("hidden");
            actionGrid.appendChild(card);
        });
        actionScroll.appendChild(actionGrid);
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                actionContent.appendChild(actionScroll);
                if (actionContentLoading.parentNode) actionContentLoading.remove();
                actionLoadingSpan.classList.add("hidden");
                actionCountSpan.classList.remove("hidden");
                selectAllBtn.classList.remove("hidden");
                updateActionPermsCount();
            });
        });
        function updateActionPermsCount() {
            var wrap = containerEl.querySelector(".groups-action-perms-wrap");
            if (!wrap || !actionCountSpan) return;
            var total = getTotalPermsCount();
            var selectedSet = {};
            containerEl.querySelectorAll("input[data-perm]").forEach(function (ch) {
                var key = ch.getAttribute("data-perm");
                if (key && ch.checked) selectedSet[key] = true;
            });
            var selected = Object.keys(selectedSet).length;
            actionCountSpan.textContent = selected + "/" + total;
        }
        selectAllBtn.addEventListener("click", function () {
            var wrap = containerEl.querySelector(".groups-action-perms-wrap");
            if (!wrap) return;
            wrap.querySelectorAll(".groups-action-perm-card").forEach(function (card) {
                if (card.classList.contains("hidden")) return;
                var inp = card.querySelector("input[data-perm]");
                if (inp) inp.checked = true;
            });
            updateActionPermsCount();
        });
        function updateActionPermsVisibility() {
            var wrap = containerEl.querySelector(".groups-action-perms-wrap");
            if (!wrap) return;
            var dashCh = containerEl.querySelector("input[data-perm=\"dashboard\"]");
            var mapCh = containerEl.querySelector("input[data-perm=\"map\"]");
            var playersCh = containerEl.querySelector("input[data-perm=\"players\"]");
            var logsCh = containerEl.querySelector("input[data-perm=\"logs\"]");
            var bansCh = containerEl.querySelector("input[data-perm=\"bans\"]");
            var terminalCh = containerEl.querySelector("input[data-perm=\"terminal\"]");
            var reportesCh = containerEl.querySelector("input[data-perm=\"reportes\"]");
            var estadisticasCh = containerEl.querySelector(".groups-perms-grid input[data-perm=\"estadisticas\"]");
            var comandosCh = containerEl.querySelector("input[data-perm=\"comandos\"]");
            var kickActionMenuCh = containerEl.querySelector("input[data-perm=\"kick_action_menu\"]");
            var dashChecked = dashCh && dashCh.checked;
            var mapCheckedNow = mapCh && mapCh.checked;
            var playersCheckedNow = playersCh && playersCh.checked;
            var logsCheckedNow = logsCh && logsCh.checked;
            var bansCheckedNow = bansCh && bansCh.checked;
            var terminalCheckedNow = terminalCh && terminalCh.checked;
            var reportesCheckedNow = reportesCh && reportesCh.checked;
            var comandosCheckedNow = comandosCh && comandosCh.checked;
            var kickActionMenuCheckedNow = kickActionMenuCh && kickActionMenuCh.checked;
            wrap.querySelectorAll("[data-section=\"dashboard\"]").forEach(function (row) {
                if (dashChecked) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"map\"]").forEach(function (row) {
                if (mapCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"players\"]").forEach(function (row) {
                if (playersCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"logs\"]").forEach(function (row) {
                if (logsCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"bans\"]").forEach(function (row) {
                if (bansCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"terminal\"]").forEach(function (row) {
                if (terminalCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"reportes\"]").forEach(function (row) {
                if (reportesCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            var estadisticasCheckedNow = estadisticasCh && estadisticasCh.checked;
            wrap.querySelectorAll("[data-section=\"estadisticas\"]").forEach(function (row) {
                if (estadisticasCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"comandos\"]").forEach(function (row) {
                if (comandosCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            wrap.querySelectorAll("[data-section=\"kick_action_menu\"]").forEach(function (row) {
                if (kickActionMenuCheckedNow) {
                    row.classList.remove("hidden");
                } else {
                    row.classList.add("hidden");
                    var inp = row.querySelector("input[data-perm]");
                    if (inp) inp.checked = false;
                }
            });
            var anyChecked = dashChecked || mapCheckedNow || playersCheckedNow || logsCheckedNow || bansCheckedNow || terminalCheckedNow || reportesCheckedNow || (estadisticasCh && estadisticasCh.checked) || comandosCheckedNow || kickActionMenuCheckedNow;
            var placeholder = wrap.querySelector(".groups-action-perms-empty");
            var content = wrap.querySelector(".groups-action-perms-content");
            if (anyChecked) {
                if (placeholder) placeholder.classList.add("hidden");
                if (content) content.classList.remove("hidden");
            } else {
                if (placeholder) placeholder.classList.remove("hidden");
                if (content) content.classList.add("hidden");
                wrap.querySelectorAll("input[data-perm]").forEach(function (ch) { ch.checked = false; });
            }
            updateActionPermsCount();
        }
        actionGrid.addEventListener("change", function (e) {
            if (e.target && e.target.matches("input[data-perm]")) updateActionPermsCount();
        });
        updateActionPermsCount();
        sectionGrid.querySelectorAll("input[data-perm=\"dashboard\"]").forEach(function (dashCh) {
            dashCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"map\"]").forEach(function (mapCh) {
            mapCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"players\"]").forEach(function (playersCh) {
            playersCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"logs\"]").forEach(function (logsCh) {
            logsCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"bans\"]").forEach(function (bansCh) {
            bansCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"terminal\"]").forEach(function (terminalCh) {
            terminalCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"reportes\"]").forEach(function (reportesCh) {
            reportesCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"estadisticas\"]").forEach(function (estadisticasCh) {
            estadisticasCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"comandos\"]").forEach(function (comandosCh) {
            comandosCh.addEventListener("change", updateActionPermsVisibility);
        });
        sectionGrid.querySelectorAll("input[data-perm=\"kick_action_menu\"]").forEach(function (kickActionMenuCh) {
            kickActionMenuCh.addEventListener("change", updateActionPermsVisibility);
        });
    }

    function renderList(groups) {
        var listEl = document.getElementById("groups-list");
        var summaryEl = document.getElementById("groups-perms-summary");
        if (summaryEl) summaryEl.classList.add("hidden");
        if (!listEl) return;
        listEl.innerHTML = "";
        groups.forEach(function (g) {
            var perms = g.perms || {};
            var counts = getGroupPermCounts(perms);
            var card = document.createElement("div");
            card.className = "groups-card";
            var permRows = getSectionKeys().map(function (p) {
                var val = perms[p.key];
                var yes = val === true || val === "1" || val === 1;
                var icon = yes ? "<i class=\"fa-solid fa-check groups-perm-icon\"></i>" : "<i class=\"fa-solid fa-xmark groups-perm-icon\"></i>";
                var rowLabel = (typeof window !== "undefined" && window.t && p.labelKey && window.t(p.labelKey)) || (p.label || "");
                return "<div class=\"groups-perm-row\"><span class=\"groups-perm-label\">" + rowLabel.replace(/</g, "&lt;") + "</span><span class=\"groups-perm-value " + (yes ? "yes" : "no") + "\">" + icon + "</span></div>";
            }).join("");
            var grantedTpl = (typeof window !== "undefined" && window.t && window.t("groups_perms_granted")) || "PERMISSIONS GRANTED: %s/%s";
            var badgeText = grantedTpl.replace("%s/%s", counts.selected + "/" + counts.total);
            var editTitle = (typeof window !== "undefined" && window.t && window.t("groups_edit")) || "Edit";
            var deleteTitle = (typeof window !== "undefined" && window.t && window.t("groups_delete")) || "Delete";
            var grupoEsc = (g.grupo || "").replace(/"/g, "&quot;").replace(/</g, "&lt;");
            card.innerHTML =
                "<div class=\"groups-card-header\">" +
                "<div class=\"groups-card-title-wrap\">" +
                "<span class=\"groups-card-icon\"><i class=\"fa-solid fa-users\"></i></span>" +
                "<div><h3 class=\"groups-card-title\">" + (g.grupo || "").replace(/</g, "&lt;") + "</h3><span class=\"groups-card-badge\">" + badgeText + "</span></div>" +
                "</div>" +
                "<div class=\"groups-card-actions\">" +
                "<button type=\"button\" class=\"groups-card-edit\" data-grupo=\"" + grupoEsc + "\" title=\"" + editTitle.replace(/"/g, "&quot;") + "\"><i class=\"fa-solid fa-pen-to-square\"></i></button>" +
                "<button type=\"button\" class=\"groups-card-delete\" data-grupo=\"" + grupoEsc + "\" title=\"" + deleteTitle.replace(/"/g, "&quot;") + "\"><i class=\"fa-solid fa-trash\"></i></button>" +
                "</div>" +
                "</div>" +
                "<div class=\"groups-card-perms\">" + permRows + "</div>";
            listEl.appendChild(card);
        });
        listEl.querySelectorAll(".groups-card-edit").forEach(function (btn) {
            btn.addEventListener("click", function () {
                openEditModal(btn.getAttribute("data-grupo"));
            });
        });
        listEl.querySelectorAll(".groups-card-delete").forEach(function (btn) {
            btn.addEventListener("click", function () {
                var grupo = btn.getAttribute("data-grupo");
                if (grupo) openDeleteGroupConfirmModal(grupo);
            });
        });
    }

    function collectPermsFromContainer(containerEl) {
        var perms = {};
        if (!containerEl) return perms;
        var mapChecked = false;
        var dashboardChecked = false;
        var playersChecked = false;
        var logsChecked = false;
        var bansChecked = false;
        var terminalChecked = false;
        var reportesChecked = false;
        var estadisticasChecked = false;
        var comandosChecked = false;
        var kickActionMenuChecked = false;
        var dashboardKeysSet = {};
        dashboardActionKeys.forEach(function (p) { dashboardKeysSet[p.key] = true; });
        containerEl.querySelectorAll("input[data-perm]").forEach(function (ch) {
            var key = ch.getAttribute("data-perm");
            var actionCard = ch.closest(".groups-action-perm-card");
            if (!actionCard) {
                if (key === "map") mapChecked = ch.checked;
                if (key === "dashboard") dashboardChecked = ch.checked;
                if (key === "players") playersChecked = ch.checked;
                if (key === "logs") logsChecked = ch.checked;
                if (key === "bans") bansChecked = ch.checked;
                if (key === "terminal") terminalChecked = ch.checked;
                if (key === "reportes") reportesChecked = ch.checked;
                if (key === "estadisticas") estadisticasChecked = ch.checked;
                if (key === "comandos") comandosChecked = ch.checked;
                if (key === "kick_action_menu") kickActionMenuChecked = ch.checked;
            }
            if (actionCard && actionCard.classList.contains("hidden")) return;
            var section = actionCard ? actionCard.getAttribute("data-section") : "";
            if (dashboardKeysSet[key] && section !== "dashboard") return;
            perms[key] = (perms[key] === true) || ch.checked;
        });
        var comandosKeysSet = {};
        if (comandosChecked) getComandosActionKeys().forEach(function (p) { comandosKeysSet[p.key] = true; });
        var playersActionKeysSet = {};
        playersActionKeys.forEach(function (p) { playersActionKeysSet[p.key] = true; });
        var bansActionKeysSet = {};
        bansActionKeys.forEach(function (p) { bansActionKeysSet[p.key] = true; });
        if (!mapChecked) {
            mapActionKeys.forEach(function (p) {
                if (playersActionKeysSet[p.key]) return;
                perms[p.key] = false;
            });
        }
        if (!dashboardChecked) {
            dashboardActionKeys.forEach(function (p) {
                if (comandosKeysSet[p.key]) return;
                perms[p.key] = false;
            });
        }
        if (!playersChecked) {
            playersActionKeys.forEach(function (p) {
                if (bansActionKeysSet[p.key]) return;
                perms[p.key] = false;
            });
        }
        if (!logsChecked) {
            logTypes.forEach(function (p) { perms[p.key] = false; });
        }
        if (!bansChecked) {
            bansActionKeys.forEach(function (p) {
                if (playersActionKeysSet[p.key]) return;
                perms[p.key] = false;
            });
        }
        if (!terminalChecked) {
            terminalActionKeys.forEach(function (p) { perms[p.key] = false; });
        }
        if (!reportesChecked) {
            reportesActionKeys.forEach(function (p) { perms[p.key] = false; });
        }
        if (!estadisticasChecked) {
            estadisticasActionKeys.forEach(function (p) { perms[p.key] = false; });
        }
        if (!comandosChecked) {
            getComandosActionKeys().forEach(function (p) { perms[p.key] = false; });
        }
        if (!kickActionMenuChecked) {
            kickActionMenuActionKeys.forEach(function (p) { perms[p.key] = false; });
        }
        var comandosKeys = getComandosActionKeys();
        var allKeyArrays = [getSectionKeys(), dashboardActionKeys, mapActionKeys, playersActionKeys, logTypes, bansActionKeys, terminalActionKeys, comandosKeys, kickActionMenuActionKeys, reportesActionKeys, estadisticasActionKeys];
        var allKeys = {};
        allKeyArrays.forEach(function (arr) {
            arr.forEach(function (p) { if (p && p.key) allKeys[p.key] = true; });
        });
        Object.keys(allKeys).forEach(function (key) {
            if (perms[key] !== true && perms[key] !== "1" && perms[key] !== 1) perms[key] = false;
        });
        return perms;
    }

    function openEditModal(grupo) {
        var modal = document.getElementById("groups-modal-edit");
        var titleEl = document.getElementById("groups-edit-title");
        var grupoInput = document.getElementById("groups-edit-grupo");
        var permsEl = document.getElementById("groups-edit-perms");
        var editPreview = document.getElementById("groups-edit-color-preview");
        var editHexInput = document.getElementById("groups-edit-input-color-hex");
        var editDropdown = document.getElementById("groups-edit-color-dropdown");
        if (!modal || !titleEl || !grupoInput || !permsEl) return;
        grupoInput.value = grupo;
        var editTitleLabel = (typeof window !== "undefined" && window.t && window.t("groups_modal_edit_title")) || "Edit group";
        titleEl.textContent = editTitleLabel + " " + grupo;
        if (editDropdown) editDropdown.classList.add("hidden");
        fetchGroups().then(function (groups) {
            var g = groups.find(function (x) { return x.grupo === grupo; });
            var perms = (g && g.perms) ? g.perms : {};
            var color = (g && g.color && String(g.color).trim() !== "") ? String(g.color).trim() : defaultGroupColor;
            if (editPreview) editPreview.style.backgroundColor = color;
            if (editHexInput) editHexInput.value = color;
            if (groupsEditHexPicker) groupsEditHexPicker.color = color;
            renderPermsBlock(permsEl, perms);
        });
        modal.classList.remove("hidden");
        modal.setAttribute("aria-hidden", "false");
        requestAnimationFrame(function () { modal.classList.add("groups-modal-visible"); });
    }

    function closeEditModal() {
        var modal = document.getElementById("groups-modal-edit");
        var editDropdown = document.getElementById("groups-edit-color-dropdown");
        if (editDropdown) editDropdown.classList.add("hidden");
        if (!modal) return;
        modal.classList.remove("groups-modal-visible");
        modal.addEventListener("transitionend", function onEnd() {
            modal.removeEventListener("transitionend", onEnd);
            modal.classList.add("hidden");
            modal.classList.remove("groups-modal-visible");
            modal.setAttribute("aria-hidden", "true");
        }, { once: true });
    }

    var defaultGroupColor = "#6fabc5";
    var groupsHexPicker = null;
    var groupsEditHexPicker = null;

    function openCreateModal() {
        var modal = document.getElementById("groups-modal-create");
        var input = document.getElementById("groups-input-name");
        var inputColorHex = document.getElementById("groups-input-color-hex");
        var preview = document.getElementById("groups-color-preview");
        var permsEl = document.getElementById("groups-create-perms");
        if (modal && input) {
            input.value = "";
            if (inputColorHex) inputColorHex.value = defaultGroupColor;
            if (preview) preview.style.backgroundColor = defaultGroupColor;
            if (groupsHexPicker) groupsHexPicker.color = defaultGroupColor;
            var dropdown = document.getElementById("groups-color-dropdown");
            if (dropdown) dropdown.classList.add("hidden");
            if (permsEl) renderPermsBlock(permsEl, {});
            modal.classList.remove("hidden");
            modal.setAttribute("aria-hidden", "false");
            requestAnimationFrame(function () {
                modal.classList.add("groups-modal-visible");
                input.focus();
            });
        }
    }

    function closeCreateModal() {
        var modal = document.getElementById("groups-modal-create");
        var dropdown = document.getElementById("groups-color-dropdown");
        if (dropdown) dropdown.classList.add("hidden");
        if (!modal) return;
        modal.classList.remove("groups-modal-visible");
        modal.addEventListener("transitionend", function onEnd() {
            modal.removeEventListener("transitionend", onEnd);
            modal.classList.add("hidden");
            modal.classList.remove("groups-modal-visible");
            modal.setAttribute("aria-hidden", "true");
        }, { once: true });
    }

    function doCreateGroup() {
        var input = document.getElementById("groups-input-name");
        var inputColorHex = document.getElementById("groups-input-color-hex");
        var permsEl = document.getElementById("groups-create-perms");
        var nombre = (input && input.value) ? input.value.trim() : "";
        if (!nombre) return;
        var color = defaultGroupColor;
        if (groupsHexPicker && groupsHexPicker.color) {
            color = groupsHexPicker.color;
        } else if (inputColorHex && inputColorHex.value.trim()) {
            var hex = inputColorHex.value.trim();
            if (/^#[0-9A-Fa-f]{6}$/.test(hex) || /^#[0-9A-Fa-f]{3}$/.test(hex)) color = hex;
        }
        var perms = collectPermsFromContainer(permsEl);
        fetch("https://" + resName() + "/groupsCreate", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ grupo: nombre, color: color, perms: perms })
        });
    }

    function doSaveEdit() {
        var grupoInput = document.getElementById("groups-edit-grupo");
        var permsEl = document.getElementById("groups-edit-perms");
        var editHexInput = document.getElementById("groups-edit-input-color-hex");
        var grupo = grupoInput && grupoInput.value ? grupoInput.value.trim() : "";
        if (!grupo || !permsEl) return;
        var color = defaultGroupColor;
        if (groupsEditHexPicker && groupsEditHexPicker.color) {
            color = groupsEditHexPicker.color;
        } else if (editHexInput && editHexInput.value.trim()) {
            var hex = editHexInput.value.trim();
            if (/^#[0-9A-Fa-f]{6}$/.test(hex) || /^#[0-9A-Fa-f]{3}$/.test(hex)) color = hex;
        }
        var perms = collectPermsFromContainer(permsEl);
        fetch("https://" + resName() + "/groupsUpdate", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ grupo: grupo, color: color, permsJson: JSON.stringify(perms) })
        });
    }

    window.addEventListener("message", function (event) {
        var d = event.data;
        if (!d || !d.action) return;
        if (d.action === "createResultGroups") {
            if (d.ok) {
                closeCreateModal();
                loadAndRender();
            }
        } else if (d.action === "updateResultGroups") {
            if (d.ok) {
                closeEditModal();
                loadAndRender();
            }
        } else if (d.action === "deleteResultGroups") {
            if (d.ok) {
                closeEditModal();
                loadAndRender();
            }
        }
    });

    function loadAndRender() {
        fetchGroups().then(renderList);
    }

    document.querySelectorAll(".menu li").forEach(function (item) {
        if (item.getAttribute("data-page") !== "groups") return;
        item.addEventListener("click", function () {
            setTimeout(function () {
                var groupsPage = document.getElementById("groups");
                if (groupsPage && groupsPage.classList.contains("active")) loadAndRender();
            }, 50);
        });
    });

    var btnCreate = document.getElementById("groups-btn-create");
    if (btnCreate) btnCreate.addEventListener("click", openCreateModal);

    var createCancel = document.getElementById("groups-create-cancel");
    if (createCancel) createCancel.addEventListener("click", closeCreateModal);
    var createConfirm = document.getElementById("groups-create-confirm");
    if (createConfirm) createConfirm.addEventListener("click", doCreateGroup);

    var editCancel = document.getElementById("groups-edit-cancel");
    if (editCancel) editCancel.addEventListener("click", closeEditModal);
    var editSave = document.getElementById("groups-edit-save");
    if (editSave) editSave.addEventListener("click", doSaveEdit);

    var inputName = document.getElementById("groups-input-name");
    if (inputName) {
        inputName.addEventListener("keydown", function (e) {
            if (e.key === "Enter") doCreateGroup();
        });
        inputName.addEventListener("input", function () {
            var start = this.selectionStart;
            var end = this.selectionEnd;
            var val = this.value;
            if (/ /.test(val)) {
                this.value = val.replace(/ /g, "_");
                this.setSelectionRange(start, end);
            }
        });
    }

    var inputColorHex = document.getElementById("groups-input-color-hex");
    var previewEl = document.getElementById("groups-color-preview");
    var dropdownEl = document.getElementById("groups-color-dropdown");

    function setupGroupsColorPicker() {
        var picker = document.getElementById("groups-hex-picker");
        if (!picker || !previewEl || !dropdownEl) return;
        groupsHexPicker = picker;
        picker.color = defaultGroupColor;
        if (previewEl) previewEl.style.backgroundColor = defaultGroupColor;
        if (inputColorHex) inputColorHex.value = defaultGroupColor;

        picker.addEventListener("color-changed", function (e) {
            var hex = e.detail.value;
            if (inputColorHex) inputColorHex.value = hex;
            if (previewEl) previewEl.style.backgroundColor = hex;
        });

        previewEl.addEventListener("click", function (e) {
            e.stopPropagation();
            dropdownEl.classList.toggle("hidden");
        });

        document.addEventListener("click", function closeColorDropdown(e) {
            if (dropdownEl.classList.contains("hidden")) return;
            if (!dropdownEl.contains(e.target) && e.target !== previewEl) {
                dropdownEl.classList.add("hidden");
            }
        });

        if (inputColorHex) {
            inputColorHex.addEventListener("input", function () {
                var hex = this.value.trim();
                if ((/^#[0-9A-Fa-f]{6}$/.test(hex) || /^#[0-9A-Fa-f]{3}$/.test(hex))) {
                    picker.color = hex;
                    if (previewEl) previewEl.style.backgroundColor = hex;
                }
            });
        }

        var editPicker = document.getElementById("groups-edit-hex-picker");
        var editPreviewEl = document.getElementById("groups-edit-color-preview");
        var editDropdownEl = document.getElementById("groups-edit-color-dropdown");
        var editHexInputEl = document.getElementById("groups-edit-input-color-hex");
        if (editPicker && editPreviewEl && editDropdownEl) {
            groupsEditHexPicker = editPicker;
            editPicker.color = defaultGroupColor;
            if (editPreviewEl) editPreviewEl.style.backgroundColor = defaultGroupColor;
            if (editHexInputEl) editHexInputEl.value = defaultGroupColor;

            editPicker.addEventListener("color-changed", function (e) {
                var hex = e.detail.value;
                if (editHexInputEl) editHexInputEl.value = hex;
                if (editPreviewEl) editPreviewEl.style.backgroundColor = hex;
            });

            editPreviewEl.addEventListener("click", function (e) {
                e.stopPropagation();
                editDropdownEl.classList.toggle("hidden");
            });

            document.addEventListener("click", function closeEditColorDropdown(e) {
                if (editDropdownEl.classList.contains("hidden")) return;
                if (!editDropdownEl.contains(e.target) && e.target !== editPreviewEl) {
                    editDropdownEl.classList.add("hidden");
                }
            });

            if (editHexInputEl) {
                editHexInputEl.addEventListener("input", function () {
                    var hex = this.value.trim();
                    if ((/^#[0-9A-Fa-f]{6}$/.test(hex) || /^#[0-9A-Fa-f]{3}$/.test(hex))) {
                        editPicker.color = hex;
                        if (editPreviewEl) editPreviewEl.style.backgroundColor = hex;
                    }
                });
            }
        }
    }

    if (typeof customElements !== "undefined") {
        if (customElements.get("hex-color-picker")) {
            setupGroupsColorPicker();
        } else {
            customElements.whenDefined("hex-color-picker").then(setupGroupsColorPicker);
        }
    }

    document.querySelectorAll("#groups-modal-create .groups-modal-backdrop").forEach(function (el) {
        el.addEventListener("click", closeCreateModal);
    });
    document.querySelectorAll("#groups-modal-edit .groups-modal-backdrop").forEach(function (el) {
        el.addEventListener("click", closeEditModal);
    });

    var deleteGroupConfirmModal = document.getElementById("delete-group-confirm-modal");
    var deleteGroupConfirmMessage = document.getElementById("delete-group-confirm-message");
    var deleteGroupConfirmCancel = document.getElementById("delete-group-confirm-cancel");
    var deleteGroupConfirmConfirm = document.getElementById("delete-group-confirm-confirm");
    var deleteGroupConfirmBackdrop = deleteGroupConfirmModal ? deleteGroupConfirmModal.querySelector(".ban-modal-backdrop") : null;
    var deleteGroupConfirmGrupo = null;

    function openDeleteGroupConfirmModal(grupo) {
        deleteGroupConfirmGrupo = grupo;
        if (deleteGroupConfirmMessage) {
            var msgTpl = (typeof window !== "undefined" && window.t && window.t("groups_delete_confirm_message")) || "¿Estás seguro de que quieres eliminar permanentemente el grupo \"%s\"?";
            deleteGroupConfirmMessage.textContent = msgTpl.replace("%s", (grupo || ""));
        }
        if (deleteGroupConfirmModal) {
            deleteGroupConfirmModal.classList.remove("hidden");
            deleteGroupConfirmModal.setAttribute("aria-hidden", "false");
            requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                    deleteGroupConfirmModal.classList.add("open");
                });
            });
        }
    }

    function closeDeleteGroupConfirmModal() {
        if (!deleteGroupConfirmModal) return;
        var done = false;
        function onFadeOut(ev) {
            if (done) return;
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return;
            done = true;
            deleteGroupConfirmModal.removeEventListener("transitionend", onFadeOut);
            deleteGroupConfirmModal.classList.remove("open", "closing");
            deleteGroupConfirmModal.classList.add("hidden");
            deleteGroupConfirmModal.setAttribute("aria-hidden", "true");
            deleteGroupConfirmGrupo = null;
        }
        deleteGroupConfirmModal.addEventListener("transitionend", onFadeOut);
        deleteGroupConfirmModal.classList.add("closing");
        var duration = parseFloat(getComputedStyle(deleteGroupConfirmModal).transitionDuration) || 0.22;
        if (duration <= 0) onFadeOut();
        else setTimeout(function () { if (!done) onFadeOut(); }, (duration * 1000) + 50);
    }

    if (deleteGroupConfirmBackdrop) deleteGroupConfirmBackdrop.addEventListener("click", closeDeleteGroupConfirmModal);
    if (deleteGroupConfirmCancel) deleteGroupConfirmCancel.addEventListener("click", closeDeleteGroupConfirmModal);
    if (deleteGroupConfirmConfirm) {
        deleteGroupConfirmConfirm.addEventListener("click", function () {
            if (deleteGroupConfirmGrupo == null) return;
            var grupo = deleteGroupConfirmGrupo;
            closeDeleteGroupConfirmModal();
            fetch("https://" + resName() + "/groupsDelete", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ grupo: grupo })
            });
        });
    }

    window.closeGroupsCreateModal = closeCreateModal;
    window.closeGroupsEditModal = closeEditModal;
    window.closeDeleteGroupConfirmModal = closeDeleteGroupConfirmModal;
})();
