const tabletEl = document.getElementById("tablet")
const loginScreenEl = document.getElementById("login-screen")
const panelEl = document.getElementById("panel")
const loginForm = document.getElementById("login-form")
const loginUser = document.getElementById("login-user")
const loginPassword = document.getElementById("login-password")
const loginRemember = document.getElementById("login-remember")
const loginError = document.getElementById("login-error")
const loginPasswordInput = document.getElementById("login-password")
const loginTogglePassword = document.getElementById("login-toggle-password")
const loginPasswordIcon = document.getElementById("login-password-icon")

window.t = function(k) { return (window.translations && window.translations[k]) || k; }

window.revokePlayerDetailAvatarObjectUrl = function() {
    if (window._playerDetailAvatarObjectUrl) {
        try { URL.revokeObjectURL(window._playerDetailAvatarObjectUrl) } catch (e) {}
        window._playerDetailAvatarObjectUrl = null
    }
}

window.preparePlayerDetailRequest = function() {
    window.revokePlayerDetailAvatarObjectUrl()
    window.playerDetailUiNonce = (window.playerDetailUiNonce || 0) + 1
    var uin = window.playerDetailUiNonce
    var av = document.getElementById("player-detail-avatar")
    if (av) {
        av.classList.add("player-detail-avatar-no-photo")
        av.style.backgroundImage = "none"
        av.style.removeProperty("background-size")
        av.style.removeProperty("background-position")
    }
    return uin
}

window.playerDetailMessageMatchesUi = function(msg) {
    if (!msg) return false
    var w = window.playerDetailUiNonce != null ? Number(window.playerDetailUiNonce) : NaN
    var hasW = !isNaN(w) && w > 0
    var m = msg.uiNonce != null ? Number(msg.uiNonce) : NaN
    var hasM = !isNaN(m) && m > 0
    if (hasW) return hasM && m === w
    return !hasM
}

var cameraKeys = { KeyW: 1, KeyS: 1, KeyQ: 1, KeyE: 1, KeyM: 1, ShiftLeft: 1, ShiftRight: 1, Delete: 1, Escape: 1 };
function cameraKeyDown(e) {
    if (!window._cameraInfoActive || !cameraKeys[e.code]) return;
    e.preventDefault();
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin";
    fetch("https://" + resName + "/cameraKeyState", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ key: e.code, pressed: true })
    }).catch(function() {});
}
function cameraKeyUp(e) {
    if (!window._cameraInfoActive || !cameraKeys[e.code]) return;
    e.preventDefault();
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin";
    fetch("https://" + resName + "/cameraKeyState", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ key: e.code, pressed: false })
    }).catch(function() {});
}

function applyTranslations() {
    if (window.locale) document.documentElement.lang = window.locale
    document.querySelectorAll("[data-i18n]").forEach(function(el) {
        var k = el.getAttribute("data-i18n")
        if (k && window.t) el.textContent = window.t(k)
    })
    document.querySelectorAll("[data-i18n-placeholder]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-placeholder")
        if (k && window.t) el.placeholder = window.t(k)
    })
    document.querySelectorAll("[data-i18n-aria-label]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-aria-label")
        if (k && window.t) el.setAttribute("aria-label", window.t(k))
    })
    document.querySelectorAll("[data-i18n-title]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-title")
        if (k && window.t) el.setAttribute("title", window.t(k))
    })
}

function applyTranslationsFor(rootEl) {
    if (!rootEl) return
    rootEl.querySelectorAll("[data-i18n]").forEach(function(el) {
        var k = el.getAttribute("data-i18n")
        if (k && window.t) el.textContent = window.t(k)
    })
    rootEl.querySelectorAll("[data-i18n-placeholder]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-placeholder")
        if (k && window.t) el.placeholder = window.t(k)
    })
    rootEl.querySelectorAll("[data-i18n-aria-label]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-aria-label")
        if (k && window.t) el.setAttribute("aria-label", window.t(k))
    })
    rootEl.querySelectorAll("[data-i18n-title]").forEach(function(el) {
        var k = el.getAttribute("data-i18n-title")
        if (k && window.t) el.setAttribute("title", window.t(k))
    })
}

window.addEventListener("message", (event) => {
    const action = event.data && event.data.action
    if (!action) return
    switch (action) {
    case "startScreenCapture": {
        function startIframeLiveCapture(uploadUrl) {
            const frame = document.getElementById("jc-capture-frame")
            if (frame && frame.contentWindow) {
                frame.contentWindow.postMessage({ action: "startLive", uploadUrl: uploadUrl || "", intervalMs: 250 }, "*")
            }
        }
        if (event.data.live) {
            function tryStart(attempt) {
                if (window.JcLiveCapture && typeof window.JcLiveCapture.start === "function") {
                    window.JcLiveCapture.start({ intervalMs: 250 });
                    return;
                }
                if ((attempt || 0) < 50) {
                    setTimeout(function () { tryStart((attempt || 0) + 1); }, 100);
                } else {
                    startIframeLiveCapture(event.data.uploadUrl || "")
                }
            }
            tryStart(0);
        } else {
            const frame = document.getElementById("jc-capture-frame")
            if (frame && frame.contentWindow) {
                frame.contentWindow.postMessage({ action: "capture", uploadUrl: event.data.uploadUrl || "" }, "*")
            }
        }
        break
    }
    case "stopScreenCapture": {
        if (window.JcLiveCapture && typeof window.JcLiveCapture.stop === "function") {
            window.JcLiveCapture.stop()
        }
        const frame = document.getElementById("jc-capture-frame")
        if (frame && frame.contentWindow) {
            frame.contentWindow.postMessage({ action: "stopLive" }, "*")
        }
        break
    }
    case "openLogin": {
        window.locale = event.data.locale
        window.translations = event.data.translations || {}
        window.allLocales = event.data.allLocales || {}
        var storedLocaleLogin = localStorage.getItem("admin_locale")
        if (storedLocaleLogin && window.allLocales[storedLocaleLogin]) {
            window.translations = window.allLocales[storedLocaleLogin]
            window.locale = storedLocaleLogin
        }
        const tablet = document.getElementById("tablet")
        const loginScreen = document.getElementById("login-screen")
        const panel = document.getElementById("panel")
        if (tablet) {
            tablet.classList.remove("hidden")
            tablet.classList.remove("tablet-open")
            requestAnimationFrame(function() {
                tablet.classList.add("tablet-open")
            })
            setTimeout(function() {
                tablet.classList.remove("tablet-open")
            }, 400)
        }
        if (loginScreen) loginScreen.classList.remove("hidden")
        if (panel) panel.classList.add("hidden")
        var mustChangeEl = document.getElementById("must-change-credentials-screen")
        if (mustChangeEl) mustChangeEl.classList.add("hidden")
        if (loginError) loginError.classList.add("hidden")
        if (loginUser) loginUser.value = ""
        if (loginPassword) loginPassword.value = ""
        if (loginRemember) loginRemember.checked = false
        const serverNameEl = document.getElementById("login-server-name")
        if (serverNameEl && event.data.serverName) serverNameEl.textContent = event.data.serverName
        applyTranslations()
        break
    }
    case "openMustChangeCredentials": {
        window.locale = event.data.locale
        window.translations = event.data.translations || {}
        const tablet = document.getElementById("tablet")
        const loginScreen = document.getElementById("login-screen")
        const panel = document.getElementById("panel")
        const mustChangeScreen = document.getElementById("must-change-credentials-screen")
        if (tablet) {
            tablet.classList.remove("hidden")
            tablet.style.position = "fixed"
            tablet.style.left = "50%"
            tablet.style.top = "50%"
            tablet.style.transform = "translate(-50%, -50%)"
            tablet.style.margin = "0"
        }
        if (loginScreen) loginScreen.classList.add("hidden")
        if (panel) panel.classList.add("hidden")
        if (mustChangeScreen) mustChangeScreen.classList.remove("hidden")
        var mustChangeError = document.getElementById("must-change-error")
        if (mustChangeError) { mustChangeError.classList.add("hidden"); mustChangeError.textContent = "" }
        var mustChangeUser = document.getElementById("must-change-username")
        var mustChangePw = document.getElementById("must-change-password")
        var mustChangePwConfirm = document.getElementById("must-change-password-confirm")
        if (mustChangeUser) mustChangeUser.value = ""
        if (mustChangePw) mustChangePw.value = ""
        if (mustChangePwConfirm) mustChangePwConfirm.value = ""
        const mustChangeServerEl = document.getElementById("must-change-server-name")
        if (mustChangeServerEl && event.data.serverName) mustChangeServerEl.textContent = event.data.serverName
        applyTranslations()
        break
    }
    case "open": {
        window.locale = event.data.locale
        window.translations = event.data.translations || {}
        window.allLocales = event.data.allLocales || {}
        var storedLocale = localStorage.getItem("admin_locale")
        if (storedLocale && window.allLocales[storedLocale]) {
            window.translations = window.allLocales[storedLocale]
            window.locale = storedLocale
        }
        const tablet = document.getElementById("tablet")
        const loginScreen = document.getElementById("login-screen")
        const panel = document.getElementById("panel")
        var mustChangeEl = document.getElementById("must-change-credentials-screen")
        if (mustChangeEl) mustChangeEl.classList.add("hidden")
        const welcomeOverlay = document.getElementById("welcome-overlay")
        const welcomeNameEl = document.getElementById("welcome-overlay-name")
        var isAfterLogin = event.data.showWelcome === true
        if (tablet) {
            tablet.classList.remove("hidden")
            tablet.style.opacity = isAfterLogin ? "1" : ""
            tablet.classList.remove("tablet-open")
            if (!isAfterLogin) {
                requestAnimationFrame(function() {
                    tablet.classList.add("tablet-open")
                })
                setTimeout(function() {
                    tablet.classList.remove("tablet-open")
                }, 400)
            }
        }
        if (loginScreen) loginScreen.classList.add("hidden")
        if (panel) panel.classList.remove("hidden")
        applyTranslations()
        var langSelectEl = document.getElementById("settings-language-select")
        if (langSelectEl) langSelectEl.value = window.locale || "en"
        if (welcomeOverlay && isAfterLogin) {
            var welcomeTextEl = document.getElementById("welcome-overlay-text")
            var adminName = (event.data.adminUsername != null && event.data.adminUsername !== "") ? String(event.data.adminUsername) : ""
            var welcomeWord = (window.t && window.t("welcome_prefix")) ? window.t("welcome_prefix") : "Welcome"
            var welcomeRest = (window.t && window.t("welcome_rest")) ? window.t("welcome_rest") : ", %s, we're glad to see you here"
            welcomeRest = welcomeRest.replace(/%s/g, adminName).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
            if (welcomeTextEl) welcomeTextEl.innerHTML = "<span class=\"welcome-overlay-accent\">" + welcomeWord + "</span><span class=\"welcome-overlay-rest\">" + welcomeRest + "</span>"
            if (panel) panel.classList.add("welcome-active")
            welcomeOverlay.classList.remove("hidden")
            welcomeOverlay.setAttribute("aria-hidden", "false")
            welcomeOverlay.classList.remove("welcome-overlay-out")
            welcomeOverlay.classList.add("welcome-overlay-visible")
            setTimeout(function() {
                welcomeOverlay.classList.add("welcome-overlay-out")
                if (panel) panel.classList.add("welcome-content-visible")
                setTimeout(function() {
                    welcomeOverlay.classList.remove("welcome-overlay-visible", "welcome-overlay-out")
                    welcomeOverlay.classList.add("hidden")
                    welcomeOverlay.setAttribute("aria-hidden", "true")
                    if (panel) panel.classList.remove("welcome-active", "welcome-content-visible")
                }, 500)
            }, 2200)
        }
        if (tablet && isAfterLogin) setTimeout(function() { tablet.style.opacity = "" }, 100)
        var spectatePanel = document.getElementById("spectate-info-panel")
        if (spectatePanel) {
            spectatePanel.classList.add("hidden")
            spectatePanel.setAttribute("aria-hidden", "true")
        }
        const sectionPerms = event.data.sectionPerms || {}
        window.sectionPerms = sectionPerms
        window.optionalSections = event.data.optionalSections || {}
        window.commandStaffPerms = event.data.commandStaffPerms || []
        const sectionKeys = ["dashboard", "players", "map", "logs", "groups", "bans", "terminal", "estadisticas"]
        sectionKeys.forEach((key) => {
            const li = document.querySelector(".menu li[data-page=\"" + key + "\"]")
            const page = document.getElementById(key)
            const allowed = sectionPerms[key] === true || sectionPerms[key] === "1" || sectionPerms[key] === 1
            if (li) {
                if (allowed) li.classList.remove("sidebar-section-hidden")
                else li.classList.add("sidebar-section-hidden")
            }
            if (page) {
                if (allowed) page.classList.remove("sidebar-section-hidden")
                else page.classList.add("sidebar-section-hidden")
            }
        })
        var dashboardActionToPerm = {
            announcements: "announcements",
            noclip: "noclip",
            servertime: "server_time",
            godmode: "godmode",
            invisibility: "invisibility",
            staffclothing: "staff_clothing",
            tags: "tag_player",
            admintag: "admin_tag",
            deletevehicle: "delete_vehicle",
            fixvehicle: "fix_vehicle",
            infiniteammo: "infiniteammo"
        }
        var kickActionToPerm = {
            noclip: "noclip",
            godmode: "godmode",
            revive: "revive",
            invisibility: "invisibility",
            servertime: "server_time",
            staffclothing: "staff_clothing",
            tags: "tag_player",
            tpm: "tpm",
            copycoords: "copy_coords",
            deletevehicle: "delete_vehicle",
            fixvehicle: "fix_vehicle",
            tunevehicle: "tune_vehicle",
            infiniteammo: "infiniteammo",
            givecarkeys: "fix_vehicle"
        }
        var dashboardAllowed = sectionPerms.dashboard === true || sectionPerms.dashboard === "1" || sectionPerms.dashboard === 1
        document.querySelectorAll(".dashboard-action-btn").forEach(function(btn) {
            var action = btn.getAttribute("data-action")
            var permKey = action ? dashboardActionToPerm[action] : null
            var allowed = dashboardAllowed && permKey && (sectionPerms[permKey] === true || sectionPerms[permKey] === "1" || sectionPerms[permKey] === 1)
            if (allowed) {
                btn.classList.remove("dashboard-action-btn-no-permission")
                btn.setAttribute("data-perm-allowed", "true")
            } else {
                btn.classList.add("dashboard-action-btn-no-permission")
                btn.setAttribute("data-perm-allowed", "false")
                btn.classList.remove("dashboard-action-btn-active")
            }
        })
        var kickActionMenuAllowed = sectionPerms.kick_action_menu === true || sectionPerms.kick_action_menu === "1" || sectionPerms.kick_action_menu === 1
        document.querySelectorAll(".kick-actions-btn").forEach(function(btn) {
            var action = btn.getAttribute("data-action")
            var permKey = action ? kickActionToPerm[action] : null
            var allowed = kickActionMenuAllowed && permKey && (sectionPerms[permKey] === true || sectionPerms[permKey] === "1" || sectionPerms[permKey] === 1)
            btn.classList.toggle("kick-actions-btn-no-permission", !allowed)
            btn.setAttribute("data-perm-allowed", allowed ? "true" : "false")
            if (!allowed) btn.classList.remove("kick-actions-btn-active")
        })
        function updatePlayerDetailButtonsPerms() {
            var sp = window.sectionPerms || {}
            var playersOk = sp.players === true || sp.players === "1" || sp.players === 1
            var mapOk = sp.map === true || sp.map === "1" || sp.map === 1
            document.querySelectorAll(".player-detail-fn-btn").forEach(function(btn) {
                var action = btn.getAttribute("data-player-action")
                if (!action) return
                var permKey = action === "stopSpectate" ? "spectate" : action
                var hasPerm = sp[permKey] === true || sp[permKey] === "1" || sp[permKey] === 1
                if (action === "capture") {
                    hasPerm = hasPerm || sp.viewScreen === true || sp.viewScreen === "1" || sp.viewScreen === 1
                }
                var allowed = (permKey === "bring" || permKey === "goto" || permKey === "freeze" || permKey === "viewScreen") ? ((playersOk || mapOk) && hasPerm) : (playersOk && hasPerm)
                if (allowed) {
                    btn.classList.remove("player-detail-fn-btn-no-permission")
                    btn.setAttribute("data-perm-allowed", "true")
                } else {
                    btn.classList.add("player-detail-fn-btn-no-permission")
                    btn.setAttribute("data-perm-allowed", "false")
                }
            })
        }
        updatePlayerDetailButtonsPerms()
        window.updatePlayerDetailButtonsPerms = updatePlayerDetailButtonsPerms
        var logsTypeOptions = [
            { value: "server_join", perm: "log_server_join", labelKey: "logs_type_server_join", label: "Entradas al servidor" },
            { value: "server_leave", perm: "log_server_leave", labelKey: "logs_type_server_leave", label: "Salidas del servidor" },
            { value: "chat", perm: "log_chat", labelKey: "logs_type_chat", label: "Chat del servidor" },
            { value: "deaths", perm: "log_deaths", labelKey: "logs_type_deaths", label: "Muertes de jugadores" },
            { value: "kills", perm: "log_kills", labelKey: "logs_type_kills", label: "Kills de jugadores" },
            { value: "explosions", perm: "log_explosions", labelKey: "logs_type_explosions", label: "Explosiones" },
            { value: "permissions", perm: "log_permissions", labelKey: "logs_type_permissions", label: "Permisos" },
            { value: "admin_actions", perm: "log_admin_actions", labelKey: "logs_type_admin_actions", label: "Acciones de admin" },
            { value: "bans", perm: "log_bans", labelKey: "logs_type_bans", label: "Baneos" },
            { value: "unbans", perm: "log_unbans", labelKey: "logs_type_unbans", label: "Desbaneos" },
            { value: "tx_admin", perm: "log_tx_admin", labelKey: "logs_type_tx_admin", label: "TX Admin logs" }
        ]
        var terminalInput = document.getElementById("terminalInput")
        if (terminalInput) {
            var consoleAllowed = sectionPerms.terminal_console === true || sectionPerms.terminal_console === "1" || sectionPerms.terminal_console === 1
            terminalInput.disabled = !consoleAllowed
            if (consoleAllowed) {
                terminalInput.classList.remove("terminal-input-no-permission")
            } else {
                terminalInput.classList.add("terminal-input-no-permission")
            }
        }
        var logsSel = document.getElementById("logs-type-select")
        if (logsSel && (sectionPerms.logs === true || sectionPerms.logs === "1" || sectionPerms.logs === 1)) {
            var allLabel = (typeof window !== "undefined" && window.t && window.t("logs_type_all")) || "Todos los Logs"
            logsSel.innerHTML = "<option value=\"all\">" + allLabel.replace(/</g, "&lt;") + "</option>"
            logsTypeOptions.forEach(function(opt) {
                if (sectionPerms[opt.perm] === true || sectionPerms[opt.perm] === "1" || sectionPerms[opt.perm] === 1) {
                    var o = document.createElement("option")
                    o.value = opt.value
                    o.textContent = (typeof window !== "undefined" && window.t && opt.labelKey && window.t(opt.labelKey)) || opt.label
                    logsSel.appendChild(o)
                }
            })
        }
        const menu = document.querySelector(".menu")
        const playersItem = menu ? menu.querySelector("li[data-page=\"players\"]") : null
        const restoreId = window.lastOpenPlayerDetailId
        const restoreOfflineIdent = window.lastOpenPlayerDetailOfflineIdentifier
        const goToPlayers = (restoreId != null || (restoreOfflineIdent != null && String(restoreOfflineIdent).trim() !== "")) && playersItem && !playersItem.classList.contains("sidebar-section-hidden")
        document.querySelectorAll(".menu li.active").forEach((el) => el.classList.remove("active"))
        document.querySelectorAll(".page.active").forEach((el) => el.classList.remove("active"))
        if (goToPlayers) {
            playersItem.classList.add("active")
            var playersPage = document.getElementById("players")
            if (playersPage) playersPage.classList.add("active")
            var listView = document.getElementById("players-list-view")
            var detailView = document.getElementById("player-detail-view")
            if (listView) listView.classList.add("hidden")
            if (detailView) {
                detailView.classList.remove("hidden")
                detailView.setAttribute("aria-hidden", "false")
            }
            requestAnimationFrame(function() { if (typeof moveActiveBackground === "function") moveActiveBackground(playersItem) })
            setTimeout(function() {
                if (typeof moveActiveBackground === "function") moveActiveBackground(playersItem)
                var rn = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
                var _ruin = typeof window.preparePlayerDetailRequest === "function" ? window.preparePlayerDetailRequest() : 0
                var _body = (restoreOfflineIdent != null && String(restoreOfflineIdent).trim() !== "")
                    ? { offlineIdentifier: String(restoreOfflineIdent).trim(), uiNonce: _ruin }
                    : { playerId: restoreId, uiNonce: _ruin }
                fetch("https://" + rn + "/requestPlayerDetails", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(_body) }).catch(function() {})
            }, 50)
        } else {
            const firstVisible = menu ? menu.querySelector("li[data-page]:not(.sidebar-section-hidden)") : null
            if (firstVisible) {
                firstVisible.classList.add("active")
                const pageId = firstVisible.getAttribute("data-page")
                const firstPage = pageId ? document.getElementById(pageId) : null
                if (firstPage) firstPage.classList.add("active")
                requestAnimationFrame(() => moveActiveBackground(firstVisible))
                setTimeout(() => moveActiveBackground(firstVisible), 50)
            }
        }
        if (typeof window.requestSettingsProfile === "function") window.requestSettingsProfile()
        break
    }
    case "setStaffDash": {
        const onlineCount = event.data.onlineCount != null ? event.data.onlineCount : 0
        const staff = event.data.staff || []
        const realStaffCount = event.data.realStaffCount != null ? event.data.realStaffCount : staff.length
        const totalPlayers = event.data.totalPlayers != null ? event.data.totalPlayers : 0
        const totalBans = event.data.totalBans != null ? event.data.totalBans : 0
        const statOnlineEl = document.getElementById("stat-online")
        const statAdminsEl = document.getElementById("stat-admins")
        const statTotalPlayersEl = document.getElementById("stat-total-players")
        const statBansEl = document.getElementById("stat-bans")
        if (statOnlineEl) statOnlineEl.textContent = String(onlineCount)
        if (statAdminsEl) statAdminsEl.textContent = String(realStaffCount)
        if (statTotalPlayersEl) statTotalPlayersEl.textContent = String(totalPlayers)
        if (statBansEl) statBansEl.textContent = String(totalBans)
        const listEl = document.getElementById("dashboard-staff-list")
        if (!listEl) return
        if (staff.length === 0) {
            listEl.innerHTML = "<div class=\"dashboard-staff-placeholder\">No hay staff</div>"
        } else {
            var groupColors = { owner: "#d4a574", admin: "#c98a8a", mod: "#7ba3d4", dev: "#6bb5a0" }
            listEl.innerHTML = staff.map(s => {
                const name = (s.name || "Unknown").replace(/</g, "&lt;")
                const group = (s.group || "—").replace(/</g, "&lt;")
                const avatarUrl = (s.avatar && s.avatar.trim()) ? s.avatar.trim().replace(/"/g, "&quot;") : ""
                const colorRaw = (s.color && s.color.trim()) ? s.color.trim().replace(/"/g, "&quot;") : ""
                const badgeColor = colorRaw || (group !== "—" && groupColors[(s.group || "").toLowerCase()]) || "#94a3b8"
                const badgeStyle = " background-color:" + badgeColor + ";"
                const avatarHtml = avatarUrl
                    ? "<img class=\"dashboard-staff-item-avatar-img\" src=\"" + avatarUrl + "\" alt=\"\">"
                    : "<span class=\"dashboard-staff-item-avatar-placeholder\"><i class=\"fa-solid fa-user\"></i></span>"
                var staffId = (s.id != null) ? String(s.id) : ""
                return "<div class=\"dashboard-staff-item\" data-staff-id=\"" + (staffId.replace(/"/g, "&quot;")) + "\"><span class=\"dashboard-staff-item-avatar\">" + avatarHtml + "</span><span class=\"dashboard-staff-item-name\">" + name + "</span><span class=\"dashboard-staff-item-badge\"" + (badgeStyle ? " style=\"" + badgeStyle + "\"" : "") + ">" + (group === "—" ? "—" : group.toUpperCase()) + "</span></div>"
            }).join("")
        }
        var staffListEl = document.getElementById("dashboard-staff-list")
        if (staffListEl && !staffListEl._adminDetailBound) {
            staffListEl._adminDetailBound = true
            staffListEl.addEventListener("click", function(e) {
                var item = e.target && e.target.closest && e.target.closest(".dashboard-staff-item[data-staff-id]")
                if (!item) return
                var id = item.getAttribute("data-staff-id")
                if (id && parseInt(id, 10) < 0) return
                var sp = window.sectionPerms || {}
                var infoAdminAllowed = sp.info_admin === true || sp.info_admin === "1" || sp.info_admin === 1
                if (!infoAdminAllowed) return
                if (id) fetch("https://" + GetParentResourceName() + "/requestAdminDetail", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ staffId: id }) }).catch(function() {})
            })
        }
        break
    }
    case "setDashboardMonthlyChart":
    if (event.data && event.data.data) {
        window.dashboardMonthlyChartData = event.data.data
        var dashboardPage = document.getElementById("dashboard")
        if (!dashboardPage || !dashboardPage.classList.contains("active")) return
        var chartInner = document.getElementById("dashboard-activity-chart-inner")
        if (!chartInner) return
        chartInner.removeAttribute("data-i18n")
        var data = event.data.data
        var lastDay = typeof data.lastDay === "number" ? data.lastDay : 0
        var daysArr = Array.isArray(data.days) ? data.days : []
        chartInner.className = "dashboard-activity-chart-wrap"
        chartInner.innerHTML = ""
        var availH = Math.max(360, chartInner.clientHeight || chartInner.offsetHeight || 360)
        if (lastDay <= 0 || daysArr.length === 0) {
            var emptySpan = document.createElement("span")
            emptySpan.className = "dashboard-graph-placeholder"
            emptySpan.style.display = "block"
            emptySpan.textContent = "No hay datos del mes"
            chartInner.appendChild(emptySpan)
            return
        }
        var maxSec = 0
        var points = []
        for (var i = 0; i < lastDay && i < daysArr.length; i++) {
            var s = Number(daysArr[i]) || 0
            if (s > maxSec) maxSec = s
            points.push({ day: i + 1, seconds: s, minutes: s / 60 })
        }
        var maxMinutes = Math.max(1, Math.ceil(maxSec / 60))
        var yStep = maxMinutes <= 30 ? 10 : maxMinutes <= 120 ? 30 : 60
        var yMax = Math.ceil(maxMinutes / yStep) * yStep || 1
        var pad = { left: 44, right: 16, top: 8, bottom: 22 }
        var w = chartInner.clientWidth || 400
        var h = availH
        var chartW = w - pad.left - pad.right
        var chartH = h - pad.top - pad.bottom
        var n = points.length
        var xStep = n > 1 ? chartW / (n - 1) : chartW
        var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
        svg.setAttribute("viewBox", "0 0 " + w + " " + h)
        svg.setAttribute("class", "admin-detail-line-chart-svg dashboard-monthly-chart-svg")
        svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
        for (var step = 0; step <= yMax; step += yStep) {
            var yTick = pad.top + chartH - (step / yMax) * chartH
            var line = document.createElementNS("http://www.w3.org/2000/svg", "line")
            line.setAttribute("x1", pad.left)
            line.setAttribute("y1", yTick)
            line.setAttribute("x2", pad.left + chartW)
            line.setAttribute("y2", yTick)
            line.setAttribute("class", "admin-detail-chart-grid")
            svg.appendChild(line)
            var txt = document.createElementNS("http://www.w3.org/2000/svg", "text")
            txt.setAttribute("x", pad.left - 6)
            txt.setAttribute("y", yTick + 4)
            txt.setAttribute("class", "admin-detail-chart-axis")
            txt.setAttribute("text-anchor", "end")
            txt.textContent = step >= 60 ? (Math.floor(step / 60) + " h") : (step + " min")
            svg.appendChild(txt)
        }
        var labelY = h - 4
        for (var di = 0; di < n; di++) {
            var xPos = pad.left + (n > 1 ? di * xStep : chartW / 2)
            var txtX = document.createElementNS("http://www.w3.org/2000/svg", "text")
            txtX.setAttribute("x", xPos)
            txtX.setAttribute("y", labelY)
            txtX.setAttribute("class", "admin-detail-chart-axis dashboard-monthly-chart-axis-label")
            txtX.setAttribute("text-anchor", "middle")
            txtX.textContent = String(di + 1)
            svg.appendChild(txtX)
        }
        var coords = []
        for (var pi = 0; pi < n; pi++) {
            var px = pad.left + (n > 1 ? pi * xStep : chartW / 2)
            var py = pad.top + chartH - (points[pi].minutes / yMax) * chartH
            coords.push({ x: px, y: py })
        }
        function monotoneCubicPath(pts) {
            if (pts.length <= 1) return pts.length ? "M " + pts[0].x + " " + pts[0].y : ""
            var dx = pts[1].x - pts[0].x
            if (dx <= 0) dx = 1
            var secants = []
            for (var i = 0; i < pts.length - 1; i++) {
                var dxi = pts[i + 1].x - pts[i].x
                secants.push(dxi > 0 ? (pts[i + 1].y - pts[i].y) / dxi : 0)
            }
            var m = []
            m[0] = secants[0]
            for (var j = 1; j < pts.length - 1; j++) {
                m[j] = (secants[j - 1] + secants[j]) * 0.5
            }
            m[pts.length - 1] = secants[pts.length - 2]
            for (var k = 0; k < pts.length - 1; k++) {
                if (Math.abs(secants[k]) < 1e-10) {
                    m[k] = 0
                    m[k + 1] = 0
                } else {
                    var a = m[k] / secants[k]
                    var b = m[k + 1] / secants[k]
                    var h = Math.sqrt(a * a + b * b)
                    if (h > 3) {
                        var t = 3 / h
                        m[k] = t * a * secants[k]
                        m[k + 1] = t * b * secants[k]
                    }
                }
            }
            var d = "M " + pts[0].x + " " + pts[0].y
            for (var s = 0; s < pts.length - 1; s++) {
                var x0 = pts[s].x
                var y0 = pts[s].y
                var x1 = pts[s + 1].x
                var y1 = pts[s + 1].y
                var dxSeg = x1 - x0
                var cp1x = x0 + dxSeg / 3
                var cp1y = y0 + m[s] * dxSeg / 3
                var cp2x = x1 - dxSeg / 3
                var cp2y = y1 - m[s + 1] * dxSeg / 3
                d += " C " + cp1x + " " + cp1y + " " + cp2x + " " + cp2y + " " + x1 + " " + y1
            }
            return d
        }
        function segmentToCubic(x0, y0, x1, y1, m0, m1) {
            var dxSeg = x1 - x0
            var cp1x = x0 + dxSeg / 3
            var cp1y = y0 + m0 * dxSeg / 3
            var cp2x = x1 - dxSeg / 3
            var cp2y = y1 - m1 * dxSeg / 3
            return " C " + cp1x + " " + cp1y + " " + cp2x + " " + cp2y + " " + x1 + " " + y1
        }
        var lineD = "M " + coords[0].x + " " + coords[0].y
        if (n <= 1) {
        } else if (n === 2) {
            if (points[0].minutes <= 0 && points[1].minutes <= 0) {
                lineD += " L " + coords[1].x + " " + coords[1].y
            } else {
                var m0 = points[0].minutes <= 0 ? 0 : (coords[1].y - coords[0].y) / (coords[1].x - coords[0].x || 1)
                var m1 = points[1].minutes <= 0 ? 0 : m0
                lineD += segmentToCubic(coords[0].x, coords[0].y, coords[1].x, coords[1].y, m0, m1)
            }
        } else {
            var idx = 0
            while (idx < n - 1) {
                var a0 = points[idx].minutes <= 0
                var a1 = points[idx + 1].minutes <= 0
                if (a0 && a1) {
                    lineD += " L " + coords[idx + 1].x + " " + coords[idx + 1].y
                    idx++
                } else if (a0 || a1) {
                    var m0 = a0 ? 0 : 0
                    var m1 = a1 ? 0 : 0
                    lineD += segmentToCubic(coords[idx].x, coords[idx].y, coords[idx + 1].x, coords[idx + 1].y, m0, m1)
                    idx++
                } else {
                    var runEnd = idx + 1
                    while (runEnd < n && points[runEnd].minutes > 0) runEnd++
                    var chunk = coords.slice(idx, runEnd + 1)
                    var curvePath = monotoneCubicPath(chunk)
                    lineD += curvePath.replace(/^M\s*[\d.-]+\s*[\d.-]+\s*/, "")
                    idx = runEnd
                }
            }
        }
        var baseY = pad.top + chartH
        var firstX = coords[0].x
        var lastX = coords[coords.length - 1].x
        var areaD = lineD + " L " + lastX + " " + baseY + " L " + firstX + " " + baseY + " Z"
        var area = document.createElementNS("http://www.w3.org/2000/svg", "path")
        area.setAttribute("d", areaD)
        area.setAttribute("class", "admin-detail-chart-area")
        svg.appendChild(area)
        var linePath = document.createElementNS("http://www.w3.org/2000/svg", "path")
        linePath.setAttribute("d", lineD)
        linePath.setAttribute("class", "admin-detail-chart-line dashboard-monthly-chart-line")
        svg.appendChild(linePath)
        var tooltipEl = document.getElementById("dashboard-chart-tooltip")
        var tabletEl = document.getElementById("tablet")
        if (!tooltipEl) {
            tooltipEl = document.createElement("div")
            tooltipEl.id = "dashboard-chart-tooltip"
            tooltipEl.className = "dashboard-chart-tooltip"
            if (tabletEl) tabletEl.appendChild(tooltipEl)
            else document.body.appendChild(tooltipEl)
        } else if (tabletEl && tooltipEl.parentNode !== tabletEl) {
            tabletEl.appendChild(tooltipEl)
        }
        for (var ci = 0; ci < n; ci++) {
            var cx = coords[ci].x
            var cy = coords[ci].y
            var sec = points[ci].seconds
            var label = sec >= 3600 ? (Math.floor(sec / 3600) + " h " + Math.floor((sec % 3600) / 60) + " min") : (sec >= 60 ? (Math.floor(sec / 60) + " min") : (sec + " s"))
            var tooltipText = "Día " + (ci + 1) + ": " + label
            var g = document.createElementNS("http://www.w3.org/2000/svg", "g")
            g.setAttribute("data-tooltip", tooltipText)
            var hit = document.createElementNS("http://www.w3.org/2000/svg", "circle")
            hit.setAttribute("cx", cx)
            hit.setAttribute("cy", cy)
            hit.setAttribute("r", 14)
            hit.setAttribute("class", "dashboard-monthly-chart-hit")
            g.appendChild(hit)
            var dot = document.createElementNS("http://www.w3.org/2000/svg", "circle")
            dot.setAttribute("cx", cx)
            dot.setAttribute("cy", cy)
            dot.setAttribute("r", 6)
            dot.setAttribute("class", "admin-detail-chart-dot dashboard-monthly-chart-dot")
            g.appendChild(dot)
            g.addEventListener("mouseenter", function(ev) {
                ev.currentTarget.classList.add("dashboard-monthly-chart-point-hover")
                var dot = ev.currentTarget.querySelector(".dashboard-monthly-chart-dot")
                if (dot) dot.setAttribute("r", "8")
                var tt = document.getElementById("dashboard-chart-tooltip")
                if (tt) {
                    tt.textContent = ev.currentTarget.getAttribute("data-tooltip") || ""
                    tt.style.display = "block"
                }
            })
            g.addEventListener("mousemove", function(ev) {
                var tt = document.getElementById("dashboard-chart-tooltip")
                if (tt && tt.style.display === "block") {
                    var tablet = document.getElementById("tablet")
                    var rect = tablet ? tablet.getBoundingClientRect() : { left: 0, top: 0 }
                    var offset = 10
                    tt.style.left = (ev.clientX - rect.left + offset) + "px"
                    tt.style.top = (ev.clientY - rect.top + offset) + "px"
                }
            })
            g.addEventListener("mouseleave", function(ev) {
                ev.currentTarget.classList.remove("dashboard-monthly-chart-point-hover")
                var dot = ev.currentTarget.querySelector(".dashboard-monthly-chart-dot")
                if (dot) dot.setAttribute("r", "6")
                var tt = document.getElementById("dashboard-chart-tooltip")
                if (tt) tt.style.display = "none"
            })
            svg.appendChild(g)
        }
        chartInner.appendChild(svg)
        break
    }
    case "adminDetailData":
    if (event.data && event.data.data) {
        var d = event.data.data
        var modal = document.getElementById("admin-detail-modal")
        if (!modal) return
        window._adminDetailLicense = d.license || null
        window._adminDetailStaffId = (d.srcId != null) ? d.srcId : null
        var resetTimeBtn = document.getElementById("admin-detail-reset-time-btn")
        var logoutSessionBtn = document.getElementById("admin-detail-logout-session-btn")
        var spAd = window.sectionPerms || {}
        var infoResetAllowed = spAd.info_admin === true || spAd.info_admin === "1" || spAd.info_admin === 1
        var staffSid = (d.srcId != null) ? d.srcId : null
        if (resetTimeBtn) {
            resetTimeBtn.classList.toggle("hidden", !infoResetAllowed || !window._adminDetailLicense)
        }
        if (logoutSessionBtn) {
            logoutSessionBtn.classList.toggle("hidden", !(infoResetAllowed && staffSid != null))
        }
        var nameEl = document.getElementById("admin-detail-name")
        var idEl = document.getElementById("admin-detail-id")
        var connectedEl = document.getElementById("admin-detail-connected")
        var totalTimeEl = document.getElementById("admin-detail-total-time")
        var chartEl = document.getElementById("admin-detail-daily-chart")
        var usernameEl = document.getElementById("admin-detail-username")
        var passwordEl = document.getElementById("admin-detail-password")
        if (nameEl) nameEl.textContent = (d.name != null && d.name !== "") ? String(d.name) : "—"
        if (idEl) idEl.textContent = (d.id != null) ? "#" + d.id : "—"
        var connectedSec = typeof d.connectedSeconds === "number" ? d.connectedSeconds : 0
        var connectedStr = ""
        if (connectedSec >= 3600) connectedStr = Math.floor(connectedSec / 3600) + " h " + Math.floor((connectedSec % 3600) / 60) + " min"
        else if (connectedSec >= 60) connectedStr = Math.floor(connectedSec / 60) + " min"
        else if (connectedSec > 0) connectedStr = connectedSec + " s"
        else connectedStr = "—"
        if (connectedEl) connectedEl.textContent = connectedStr
        var totalSec = typeof d.totalAdminSeconds === "number" ? d.totalAdminSeconds : 0
        var totalH = Math.floor(totalSec / 3600)
        var totalM = Math.floor((totalSec % 3600) / 60)
        if (totalTimeEl) totalTimeEl.textContent = (totalH > 0 ? totalH + " h " : "") + totalM + " min"
        if (chartEl) {
            chartEl.innerHTML = ""
            var dailyStats = Array.isArray(d.dailyStats) ? d.dailyStats.slice() : []
            if (dailyStats.length === 0) {
                var emptyMsg = document.createElement("span")
                emptyMsg.className = "admin-detail-chart-empty"
                emptyMsg.textContent = (typeof window !== "undefined" && window.t && window.t("admin_detail_no_daily_usage")) || "No daily usage data"
                chartEl.appendChild(emptyMsg)
            } else {
                dailyStats.reverse()
                var maxSec = 0
                var dayLabels = []
                var points = []
                for (var i = 0; i < dailyStats.length; i++) {
                    var s = dailyStats[i].seconds || 0
                    if (s > maxSec) maxSec = s
                    var dayStr = String(dailyStats[i].day || "")
                    var lbl
                    if (/^\d{4}-\d{2}-\d{2}$/.test(dayStr)) {
                        var parts = dayStr.split("-")
                        lbl = parts[2] + "/" + parts[1]
                    } else if (/^\d+(\.\d+)?$/.test(dayStr)) {
                        var dt = new Date(parseFloat(dayStr) > 1e12 ? parseFloat(dayStr) : parseFloat(dayStr) * 1000)
                        lbl = !isNaN(dt.getTime()) ? dt.getDate() + "/" + (dt.getMonth() + 1) : dayStr
                    } else lbl = dayStr
                    dayLabels.push(lbl)
                    points.push({ minutes: Math.round(s / 60), seconds: s })
                }
                var maxMinutes = Math.max(1, Math.ceil(maxSec / 60))
                var yStep = maxMinutes <= 30 ? 10 : maxMinutes <= 120 ? 30 : 60
                var yMax = Math.ceil(maxMinutes / yStep) * yStep || 1
                var pad = { left: 52, right: 20, top: 36, bottom: 40 }
                var w = 420
                var h = 260
                var chartW = w - pad.left - pad.right
                var chartH = h - pad.top - pad.bottom
                var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
                svg.setAttribute("class", "admin-detail-line-chart-svg")
                svg.setAttribute("viewBox", "0 0 " + w + " " + h)
                svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
                for (var step = 0; step <= yMax; step += yStep) {
                    var yTick = pad.top + chartH - (step / yMax) * chartH
                    var line = document.createElementNS("http://www.w3.org/2000/svg", "line")
                    line.setAttribute("x1", pad.left)
                    line.setAttribute("y1", yTick)
                    line.setAttribute("x2", pad.left + chartW)
                    line.setAttribute("y2", yTick)
                    line.setAttribute("class", "admin-detail-chart-grid")
                    svg.appendChild(line)
                    var txt = document.createElementNS("http://www.w3.org/2000/svg", "text")
                    txt.setAttribute("x", pad.left - 8)
                    txt.setAttribute("y", yTick + 5)
                    txt.setAttribute("class", "admin-detail-chart-axis")
                    txt.setAttribute("text-anchor", "end")
                    txt.textContent = step >= 60 ? (Math.floor(step / 60) + " h") : (step + " min")
                    svg.appendChild(txt)
                }
                var n = points.length
                var xStep = n > 1 ? chartW / (n - 1) : chartW
                for (var xi = 0; xi < n; xi++) {
                    var xPos = pad.left + (n > 1 ? xi * xStep : chartW / 2)
                    var txtX = document.createElementNS("http://www.w3.org/2000/svg", "text")
                    txtX.setAttribute("x", xPos)
                    txtX.setAttribute("y", h - 10)
                    txtX.setAttribute("class", "admin-detail-chart-axis")
                    txtX.setAttribute("text-anchor", "middle")
                    txtX.textContent = dayLabels[xi]
                    svg.appendChild(txtX)
                }
                var pathPoints = []
                var areaPoints = "M " + (pad.left) + " " + (pad.top + chartH)
                for (var pi = 0; pi < n; pi++) {
                    var px = pad.left + (n > 1 ? pi * xStep : chartW / 2)
                    var py = pad.top + chartH - (points[pi].minutes / yMax) * chartH
                    pathPoints.push(px + "," + py)
                    areaPoints += " L " + px + " " + py
                }
                areaPoints += " L " + (pad.left + (n > 1 ? (n - 1) * xStep : chartW / 2)) + " " + (pad.top + chartH) + " Z"
                var area = document.createElementNS("http://www.w3.org/2000/svg", "path")
                area.setAttribute("d", areaPoints)
                area.setAttribute("class", "admin-detail-chart-area")
                svg.appendChild(area)
                var linePath = document.createElementNS("http://www.w3.org/2000/svg", "path")
                linePath.setAttribute("d", "M " + pathPoints.join(" L "))
                linePath.setAttribute("class", "admin-detail-chart-line")
                svg.appendChild(linePath)
                for (var ci = 0; ci < n; ci++) {
                    var cx = pad.left + (n > 1 ? ci * xStep : chartW / 2)
                    var cy = pad.top + chartH - (points[ci].minutes / yMax) * chartH
                    var dot = document.createElementNS("http://www.w3.org/2000/svg", "circle")
                    dot.setAttribute("cx", cx)
                    dot.setAttribute("cy", cy)
                    dot.setAttribute("r", 5)
                    dot.setAttribute("class", "admin-detail-chart-dot")
                    svg.appendChild(dot)
                }
                chartEl.appendChild(svg)
            }
        }
        if (usernameEl) usernameEl.textContent = (d.username != null && d.username !== "") ? String(d.username) : "—"
        if (passwordEl) passwordEl.textContent = (d.password != null && d.password !== "") ? String(d.password) : "—"
        var groupEl = document.getElementById("admin-detail-group")
        if (groupEl) groupEl.textContent = (d.group != null && d.group !== "") ? String(d.group) : "—"
        var changeWrap = document.getElementById("admin-detail-change-pw-wrap")
        var changeUserWrap = document.getElementById("admin-detail-change-user-wrap")
        var changeGroupWrap = document.getElementById("admin-detail-change-group-wrap")
        if (changeWrap) changeWrap.classList.add("hidden")
        if (changeUserWrap) changeUserWrap.classList.add("hidden")
        if (changeGroupWrap) changeGroupWrap.classList.add("hidden")
        modal.classList.remove("hidden")
        modal.setAttribute("aria-hidden", "false")
        if (typeof applyTranslationsFor === "function") applyTranslationsFor(modal)
        requestAnimationFrame(function() { requestAnimationFrame(function() { modal.classList.add("open") }) })
        break
    }
    case "adminDetailTimeReset": {
        var ttEl = document.getElementById("admin-detail-total-time")
        if (ttEl) ttEl.textContent = "0 min"
        var chartResetEl = document.getElementById("admin-detail-daily-chart")
        if (chartResetEl) {
            chartResetEl.innerHTML = ""
            var emptySpan = document.createElement("span")
            emptySpan.className = "admin-detail-chart-empty"
            emptySpan.textContent = (typeof window !== "undefined" && window.t && window.t("admin_detail_no_daily_usage")) || "No daily usage data"
            chartResetEl.appendChild(emptySpan)
        }
        break
    }
    case "changeAdminPasswordResult":
    if (event.data) {
        if (event.data.success && window._adminDetailLastNewPassword != null) {
            var pwEl = document.getElementById("admin-detail-password")
            if (pwEl) pwEl.textContent = window._adminDetailLastNewPassword
            window._adminDetailLastNewPassword = null
            window.showToast((window.t && window.t("toast_password_changed")) || "Password changed successfully", "success")
        } else if (!event.data.success) {
            window.showToast((window.t && window.t("toast_password_change_failed")) || "Failed to change password", "error")
        }
        var newEl = document.getElementById("admin-detail-new-password")
        var repeatEl = document.getElementById("admin-detail-repeat-password")
        if (newEl) newEl.value = ""
        if (repeatEl) repeatEl.value = ""
        var wrap = document.getElementById("admin-detail-change-pw-wrap")
        if (wrap) wrap.classList.add("hidden")
        break
    }
    case "changeAdminUserResult":
    if (event.data) {
        if (event.data.success && event.data.newUser != null) {
            var userEl = document.getElementById("admin-detail-username")
            if (userEl) userEl.textContent = String(event.data.newUser)
            if (window._settingsPendingUsername != null) {
                var settingsNameEl = document.getElementById("settings-profile-name")
                if (settingsNameEl) settingsNameEl.textContent = window._settingsPendingUsername
                var settingsWrap = document.getElementById("settings-change-username-wrap")
                if (settingsWrap) settingsWrap.classList.add("hidden")
                var settingsInput = document.getElementById("settings-new-username")
                if (settingsInput) settingsInput.value = ""
                var settingsErr = document.getElementById("settings-username-error")
                if (settingsErr) settingsErr.classList.add("hidden")
                window._settingsPendingUsername = null
            }
            window.showToast((window.t && window.t("toast_username_changed")) || "Username saved", "success")
        } else if (!event.data.success) {
            var isProtected = event.data.newUser === "admin"
            var errMsg = isProtected
                ? ((window.t && window.t("toast_username_reserved")) || "That username is reserved")
                : ((window.t && window.t("toast_username_taken")) || "Username already in use")
            if (window._settingsPendingUsername != null) {
                var settingsErrFail = document.getElementById("settings-username-error")
                if (settingsErrFail) { settingsErrFail.textContent = errMsg; settingsErrFail.classList.remove("hidden") }
                window._settingsPendingUsername = null
            } else {
                window.showToast(errMsg, "error")
            }
        }
        var newUserEl = document.getElementById("admin-detail-new-username")
        if (newUserEl) newUserEl.value = ""
        var userWrap = document.getElementById("admin-detail-change-user-wrap")
        if (userWrap) userWrap.classList.add("hidden")
        break
    }
    case "assignAdminGroupResult": {
        if (event.data && typeof window.showToast === "function") {
            if (event.data.ok) {
                window.showToast("Grupo asignado: " + (event.data.groupName || ""), "success")
            } else {
                window.showToast("Error al asignar grupo", "error")
            }
        }
        break
    }
    case "setPlayersList": {
        const online = event.data.online || []
        const offline = event.data.offline || []
        window.playersListData = { online: online, offline: offline }
        if (typeof renderPlayersList === "function") renderPlayersList()
        break
    }
    case "removeOfflinePlayerFromList": {
        var roid = event.data && event.data.offlineIdentifier != null ? String(event.data.offlineIdentifier).trim() : ""
        if (roid === "") break
        var pr = window.playersListData || { online: [], offline: [] }
        var off = pr.offline || []
        pr.offline = off.filter(function(p) {
            return String(p.identifier || "").trim() !== roid
        })
        window.playersListData = pr
        if (typeof renderPlayersList === "function") renderPlayersList()
        if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && String(window.playerDetailOfflineIdentifier).trim() === roid) {
            var rb = document.getElementById("player-detail-back")
            if (rb) rb.click()
        }
        break
    }
    case "setBansList": {
        window.bansListData = event.data.bans || []
        if (typeof renderBansList === "function") renderBansList()
        requestAnimationFrame(function() { if (typeof updateBansFilterPill === "function") updateBansFilterPill() })
        break
    }
    case "setLogsList": {
        window.logsListData = event.data.logs || []
        window.logsDisplayFields = event.data.displayFields || {}
        window.logsCurrentPage = 1
        if (typeof renderLogsList === "function") renderLogsList()
        break
    }
    case "setStatisticsData": {
        window.statisticsData = event.data.data || null
        if (typeof renderStatisticsData === "function") renderStatisticsData(window.statisticsData)
        break
    }
    case "setPlayerStatsHistory": {
        var payload = event.data.data || { points: [], max: 0, avg: 0 }
        if (typeof renderPlayerStatsChart === "function") renderPlayerStatsChart(payload)
        break
    }
    case "loginFailed": {
        loginError.classList.remove("hidden")
        break
    }
    case "setNewCredentialsResult": {
        var errEl = document.getElementById("must-change-error")
        if (!errEl) return
        errEl.classList.remove("hidden")
        if (event.data.success) {
            errEl.textContent = ""
            errEl.classList.add("hidden")
            // Return to the login screen so the admin can sign in with their new credentials
            var mustChangeScreen = document.getElementById("must-change-credentials-screen")
            var loginScreenEl = document.getElementById("login-screen")
            if (mustChangeScreen) mustChangeScreen.classList.add("hidden")
            if (loginScreenEl) loginScreenEl.classList.remove("hidden")
            if (loginError) loginError.classList.add("hidden")
            if (loginUser) loginUser.value = ""
            if (loginPassword) loginPassword.value = ""
            if (loginRemember) loginRemember.checked = false
            if (typeof window.showToast === "function") {
                window.showToast((window.t && window.t("must_change_success")) || "Credentials updated. Please log in with your new username and password.", "success")
            }
        } else {
            var reason = event.data.reason || "error"
            var msg = (window.t && window.t("must_change_error_" + reason)) || window.t("must_change_error_error") || "Error"
            errEl.textContent = msg
        }
        break
    }
    case "closeForSpectate": {
        if (typeof savePlayerDetailStateBeforeClose === "function") savePlayerDetailStateBeforeClose()
        var tab = document.getElementById("tablet")
        if (tab) {
            tab.classList.remove("tablet-open", "tablet-closing")
            tab.classList.add("hidden")
        }
        var rn = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
        fetch("https://" + rn + "/terminalPageClosed", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
        break
    }
    case "close": {
        if (typeof savePlayerDetailStateBeforeClose === "function") savePlayerDetailStateBeforeClose()
        var groupsCreateModal = document.getElementById("groups-modal-create")
        var groupsEditModal = document.getElementById("groups-modal-edit")
        if (groupsCreateModal && !groupsCreateModal.classList.contains("hidden")) {
            groupsCreateModal.classList.add("hidden")
            groupsCreateModal.classList.remove("groups-modal-visible")
            groupsCreateModal.setAttribute("aria-hidden", "true")
        }
        if (groupsEditModal && !groupsEditModal.classList.contains("hidden")) {
            groupsEditModal.classList.add("hidden")
            groupsEditModal.classList.remove("groups-modal-visible")
            groupsEditModal.setAttribute("aria-hidden", "true")
        }
        var deleteGroupConfirmModal = document.getElementById("delete-group-confirm-modal")
        if (deleteGroupConfirmModal && !deleteGroupConfirmModal.classList.contains("hidden")) {
            deleteGroupConfirmModal.classList.add("hidden")
            deleteGroupConfirmModal.classList.remove("open", "closing")
            deleteGroupConfirmModal.setAttribute("aria-hidden", "true")
        }
        var passwordModal = document.getElementById("settings-change-password-modal")
        if (passwordModal && !passwordModal.classList.contains("hidden") && typeof window.closePasswordModal === "function") window.closePasswordModal()
        var tabClose = document.getElementById("tablet")
        var rnClose = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
        if (tabClose && !tabClose.classList.contains("hidden")) {
            tabClose.classList.remove("tablet-open")
            tabClose.classList.add("tablet-closing")
            setTimeout(function() {
                tabClose.classList.add("hidden")
                tabClose.classList.remove("tablet-closing")
                fetch("https://" + rnClose + "/close", { method: "POST", body: JSON.stringify({}) }).catch(function() {})
            }, 400)
        } else if (tabClose) {
            tabClose.classList.add("hidden")
            fetch("https://" + rnClose + "/close", { method: "POST", body: JSON.stringify({}) }).catch(function() {})
        }
        if (window.spectateInfoVisible) {
            var sp = document.getElementById("spectate-info-panel")
            if (sp) {
                sp.classList.remove("hidden")
                sp.setAttribute("aria-hidden", "false")
            }
        }
        fetch("https://" + rnClose + "/terminalPageClosed", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
        break
    }
    case "openKickActions": {
        var tabletEl = document.getElementById("tablet")
        if (tabletEl && !tabletEl.classList.contains("hidden") && !tabletEl.classList.contains("tablet-closing")) {
            tabletEl.classList.remove("tablet-open")
            tabletEl.classList.add("tablet-closing")
            setTimeout(function() {
                tabletEl.classList.add("hidden")
                tabletEl.classList.remove("tablet-closing")
            }, 400)
        }
        if (event.data.locale) window.locale = event.data.locale
        if (event.data.allLocales) window.allLocales = event.data.allLocales
        if (event.data.translations) {
            var storedLocaleKa = localStorage ? localStorage.getItem("admin_locale") : null
            if (storedLocaleKa && window.allLocales && window.allLocales[storedLocaleKa]) {
                window.translations = window.allLocales[storedLocaleKa]
                window.locale = storedLocaleKa
            } else {
                window.translations = event.data.translations
            }
            applyTranslations()
        }
        const sectionPerms = (event.data && event.data.sectionPerms) ? event.data.sectionPerms : {}
        window.sectionPerms = sectionPerms
        var kickActionToPerm = {
            noclip: "noclip", godmode: "godmode", revive: "revive", invisibility: "invisibility",
            servertime: "server_time", staffclothing: "staff_clothing", tags: "tag_player",
            tpm: "tpm", copycoords: "copy_coords", deletevehicle: "delete_vehicle",
            fixvehicle: "fix_vehicle", tunevehicle: "tune_vehicle", infiniteammo: "infiniteammo",
            givecarkeys: "fix_vehicle"
        }
        var kickActionMenuAllowed = sectionPerms.kick_action_menu === true || sectionPerms.kick_action_menu === "1" || sectionPerms.kick_action_menu === 1
        document.querySelectorAll(".kick-actions-btn").forEach(function(btn) {
            var action = btn.getAttribute("data-action")
            var permKey = action ? kickActionToPerm[action] : null
            var allowed = kickActionMenuAllowed && permKey && (sectionPerms[permKey] === true || sectionPerms[permKey] === "1" || sectionPerms[permKey] === 1)
            btn.classList.toggle("kick-actions-btn-no-permission", !allowed)
            btn.setAttribute("data-perm-allowed", allowed ? "true" : "false")
            if (!allowed) btn.classList.remove("kick-actions-btn-active")
        })
        const kickEl = document.getElementById("kick-actions")
        if (kickEl) kickEl.classList.remove("hidden")
        const binds = event.data && event.data.binds
        document.querySelectorAll(".kick-actions-bind-key").forEach(function(btn) {
            const act = btn.getAttribute("data-action")
            if (!act) return
            btn.textContent = (binds && binds[act]) ? binds[act] : "-"
        })
        if (binds && typeof binds === "object") {
            var current = JSON.parse(localStorage.getItem("adminpanel_binds") || "{}")
            for (var k in binds) { current[k] = binds[k] }
            localStorage.setItem("adminpanel_binds", JSON.stringify(current))
        }
        break
    }
    case "keybindSet":
    if (event.data && event.data.action === "keybindSet") {
        const act = event.data.bindAction
        const keyDisplay = event.data.keyDisplay
        const btn = document.querySelector(".kick-actions-bind-key[data-action=\"" + act + "\"]")
        if (btn) {
            btn.textContent = keyDisplay || "-"
            btn.classList.remove("waiting-key")
        }
        if (act && keyDisplay) {
            var binds = JSON.parse(localStorage.getItem("adminpanel_binds") || "{}")
            binds[act] = keyDisplay
            localStorage.setItem("adminpanel_binds", JSON.stringify(binds))
        }
        isWaitingForKey = false
        currentBindButton = null
        break
    }
    case "keybindCancel":
    if (event.data && event.data.action === "keybindCancel") {
        const act = event.data.bindAction
        const btn = document.querySelector(".kick-actions-bind-key[data-action=\"" + act + "\"]")
        if (btn) {
            btn.textContent = btn.dataset.originalKey || "-"
            btn.classList.remove("waiting-key")
        }
        isWaitingForKey = false
        currentBindButton = null
        break
    }
    case "closeKickActions": {
        const kickEl = document.getElementById("kick-actions")
        if (kickEl) kickEl.classList.add("hidden")
        break
    }
    case "noclipHints": {
        if (event.data.locale != null && event.data.translations != null) {
            window.locale = event.data.locale
            window.translations = event.data.translations
        }
        const hintsEl = document.getElementById("noclip-hints")
        const modeLabelEl = document.getElementById("noclip-hints-mode-label")
        if (hintsEl && event.data.locale != null && event.data.translations != null) {
            applyTranslationsFor(hintsEl)
        }
        if (event.data.show === false) {
            if (hintsEl) {
                hintsEl.classList.remove("hidden")
                hintsEl.classList.add("noclip-hints--closing")
                const onEnd = function() {
                    hintsEl.removeEventListener("animationend", onEnd)
                    hintsEl.classList.remove("noclip-hints--closing")
                    hintsEl.classList.add("hidden")
                }
                hintsEl.addEventListener("animationend", onEnd)
            }
        } else {
            if (hintsEl) {
                hintsEl.classList.remove("hidden")
                hintsEl.classList.remove("noclip-hints--closing")
            }
            var modeKey = event.data.mode === 1 ? "noclip_mode_normal" : event.data.mode === 2 ? "noclip_mode_medium" : event.data.mode === 3 ? "noclip_mode_fast" : "noclip_mode_normal"
            var fallback = event.data.mode === 1 ? "Normal" : event.data.mode === 2 ? "Medium" : event.data.mode === 3 ? "Fast" : "Normal"
            var msgTranslations = event.data && event.data.translations && typeof event.data.translations === "object" ? event.data.translations : null
            var translated = (msgTranslations && msgTranslations[modeKey]) || (typeof window !== "undefined" && window.t && window.t(modeKey))
            if (modeLabelEl) modeLabelEl.textContent = (translated && translated !== modeKey) ? translated : fallback
        }
        break
    }
    case "setStaffClothingState": {
        const on = !!event.data.on
        const kickBtn = document.getElementById("kick-actions-staff-clothing-btn")
        if (kickBtn) kickBtn.classList.toggle("kick-actions-btn-active", on)
        document.querySelectorAll(".dashboard-action-btn[data-action=\"staffclothing\"]").forEach(function(btn) {
            btn.classList.toggle("dashboard-action-btn-active", on)
        })
        break
    }
    case "setGodmodeState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"godmode\"]").forEach(function(btn) {
            btn.classList.toggle("dashboard-action-btn-active", on)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"godmode\"]").forEach(function(btn) {
            btn.classList.toggle("kick-actions-btn-active", on)
        })
        break
    }
    case "setNoclipState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"noclip\"]").forEach(function(btn) {
            btn.classList.toggle("dashboard-action-btn-active", on)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"noclip\"]").forEach(function(btn) {
            btn.classList.toggle("kick-actions-btn-active", on)
        })
        break
    }
    case "setInvisibilityState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"invisibility\"]").forEach(function(btn) {
            btn.classList.toggle("dashboard-action-btn-active", on)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"invisibility\"]").forEach(function(btn) {
            btn.classList.toggle("kick-actions-btn-active", on)
        })
        break
    }
    case "setTagsState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"tags\"]").forEach(function(btn) {
            var can = btn.getAttribute("data-perm-allowed") !== "false"
            btn.classList.toggle("dashboard-action-btn-active", on && can)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"tags\"]").forEach(function(btn) {
            var can = btn.getAttribute("data-perm-allowed") !== "false"
            btn.classList.toggle("kick-actions-btn-active", on && can)
        })
        break
    }
    case "setAdminHeadTagState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"admintag\"]").forEach(function(btn) {
            var can = btn.getAttribute("data-perm-allowed") !== "false"
            btn.classList.toggle("dashboard-action-btn-active", on && can)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"admintag\"]").forEach(function(btn) {
            var can = btn.getAttribute("data-perm-allowed") !== "false"
            btn.classList.toggle("kick-actions-btn-active", on && can)
        })
        break
    }
    case "setInfiniteAmmoState": {
        const on = !!event.data.on
        document.querySelectorAll(".dashboard-action-btn[data-action=\"infiniteammo\"]").forEach(function(btn) {
            btn.classList.toggle("dashboard-action-btn-active", on)
        })
        document.querySelectorAll(".kick-actions-btn[data-action=\"infiniteammo\"]").forEach(function(btn) {
            btn.classList.toggle("kick-actions-btn-active", on)
        })
        break
    }
    case "copyToClipboard":
    if (event.data.text) {
        var text = event.data.text
        var textarea = document.createElement("textarea")
        textarea.value = text
        textarea.style.position = "fixed"
        textarea.style.left = "-9999px"
        textarea.style.top = "0"
        textarea.setAttribute("readonly", "")
        document.body.appendChild(textarea)
        textarea.select()
        try {
            document.execCommand("copy")
        } catch (e) {}
        document.body.removeChild(textarea)
        break
    }
    case "addTerminalLog":
    if (event.data.data) {
        if (typeof addTerminalLogLine === "function") addTerminalLogLine(event.data.data)
        break
    }
    case "setTerminalResources":
    if (event.data.resources) {
        if (typeof renderTerminalResources === "function") renderTerminalResources(event.data.resources)
        break
    }
    case "updateConsoleBuffer":
    if (event.data.buffer != null) {
        if (typeof updateTerminalConsoleBuffer === "function") updateTerminalConsoleBuffer(event.data.buffer)
        break
    }
    case "openPlayerDetail":
    if (event.data.player) {
        var p = event.data.player
        if (typeof window.playerDetailMessageMatchesUi === "function" && !window.playerDetailMessageMatchesUi(event.data)) break
        if (event.data.detailReqSeq != null && !isNaN(Number(event.data.detailReqSeq))) window.playerDetailDetailReqSeq = Number(event.data.detailReqSeq)
        var avatarOpen = document.getElementById("player-detail-avatar")
        var avatarFallbackIcon = document.getElementById("player-detail-avatar-fallback-icon")
        if (avatarOpen) {
            avatarOpen.classList.add("player-detail-avatar-no-photo")
            avatarOpen.style.backgroundImage = "none"
            avatarOpen.style.removeProperty("background-size")
            avatarOpen.style.removeProperty("background-position")
        }
        if (avatarFallbackIcon) {
            avatarFallbackIcon.className = "fa-solid player-detail-avatar-fallback-icon " + (p.offline === true ? "fa-user-slash" : "fa-user")
        }
        window.playerDetailOffline = p.offline === true
        window.playerDetailOfflineIdentifier = (p.offline && p.offlineIdentifier) ? String(p.offlineIdentifier) : null
        window.playerDetailCurrentId = (p.offline === true) ? null : (p.id != null ? p.id : null)
        var nameEl = document.getElementById("player-detail-name")
        var idBadgeEl = document.getElementById("player-detail-id-badge")
        var firstnameEl = document.getElementById("player-detail-firstname")
        var lastnameEl = document.getElementById("player-detail-lastname")
        var jobEl = document.getElementById("player-detail-job")
        var jobGradeEl = document.getElementById("player-detail-job-grade")
        var orgEl = document.getElementById("player-detail-organization")
        var moneyEl = document.getElementById("player-detail-money")
        var bankEl = document.getElementById("player-detail-bank")
        var groupEl = document.getElementById("player-detail-group")
        if (nameEl) nameEl.textContent = p.name || "—"
        if (idBadgeEl) {
            if (p.offline === true && p.offlineIdentifier) {
                var oid = String(p.offlineIdentifier)
                idBadgeEl.textContent = oid.length > 22 ? (oid.substring(0, 10) + "…" + oid.substring(oid.length - 8)) : oid
                idBadgeEl.setAttribute("title", oid)
            } else {
                idBadgeEl.textContent = "#" + (p.id != null ? p.id : "0")
                idBadgeEl.removeAttribute("title")
            }
        }
        if (firstnameEl) firstnameEl.textContent = p.firstname != null ? p.firstname : "—"
        if (lastnameEl) lastnameEl.textContent = p.lastname != null ? p.lastname : "—"
        if (jobEl) jobEl.textContent = p.job != null ? p.job : "—"
        if (jobGradeEl) jobGradeEl.textContent = p.job_grade != null ? p.job_grade : "—"
        if (orgEl) orgEl.textContent = p.organization != null ? p.organization : "—"
        function fmtMoney(n) {
            if (n == null || isNaN(n)) return "—"
            var s = String(Math.floor(Number(n)))
            var out = ""
            for (var i = 0; i < s.length; i++) {
                if (i > 0 && (s.length - i) % 3 === 0) out += " "
                out += s[i]
            }
            return "$ " + out
        }
        if (moneyEl) moneyEl.textContent = fmtMoney(p.money)
        if (bankEl) bankEl.textContent = fmtMoney(p.bank)
        if (groupEl) groupEl.textContent = (p.group != null && p.group !== "") ? String(p.group) : "—"
        var propsTbody = document.getElementById("player-detail-properties-tbody")
        if (propsTbody) {
            var props = Array.isArray(p.properties) ? p.properties : []
            if (props.length === 0) propsTbody.innerHTML = "<tr class=\"player-detail-table-empty\"><td colspan=\"2\" class=\"player-detail-table-empty-cell\"><div class=\"player-detail-empty-properties\"><i class=\"fa-solid fa-house\"></i><span>" + ((typeof window !== "undefined" && window.t && window.t("player_no_properties")) || "This player has no properties") + "</span></div></td></tr>"
            else propsTbody.innerHTML = props.map(function(row) {
                var name = String(row.name || row.apartment || row.label || "—").replace(/</g, "&lt;")
                var num = row.houseNumber != null ? row.houseNumber : (row.number != null ? row.number : "—")
                return "<tr class=\"player-detail-table-data-row\"><td>" + name + "</td><td>#" + num + "</td></tr>"
            }).join("")
        }
        renderPlayerDetailVehicles(p.vehicles)
        updatePlayerDetailVehicleAddPermission()
        var vehiclesTbodyClick = document.getElementById("player-detail-vehicles-tbody")
        if (vehiclesTbodyClick) {
            vehiclesTbodyClick.removeEventListener("click", window._playerDetailVehicleRemoveHandler)
            window._playerDetailVehicleRemoveHandler = function(e) {
                var btn = e.target && e.target.closest && e.target.closest("button.player-detail-table-remove-btn")
                if (!btn) return
                if (btn.classList.contains("player-detail-table-remove-btn-no-permission")) return
                var plate = btn.getAttribute("data-plate")
                if (!plate) return
                var row = btn.closest("tr")
                var offlineOid = (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier) ? String(window.playerDetailOfflineIdentifier).trim() : ""
                if (offlineOid === "") {
                    if (!window.playerDetailCurrentId) return
                    if (typeof window.openVehicleDeleteConfirmModal === "function") {
                        window.openVehicleDeleteConfirmModal(window.playerDetailCurrentId, plate, row)
                    } else {
                        if (row && row.parentNode) row.parentNode.removeChild(row)
                        fetch("https://" + GetParentResourceName() + "/deletePlayerVehicle", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: window.playerDetailCurrentId, plate: plate }) }).catch(function() {})
                    }
                } else {
                    if (typeof window.openVehicleDeleteConfirmModal === "function") {
                        window.openVehicleDeleteConfirmModal(null, plate, row, offlineOid)
                    } else {
                        if (row && row.parentNode) row.parentNode.removeChild(row)
                        fetch("https://" + GetParentResourceName() + "/deletePlayerVehicle", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ offlineIdentifier: offlineOid, plate: plate }) }).catch(function() {})
                    }
                }
            }
            vehiclesTbodyClick.addEventListener("click", window._playerDetailVehicleRemoveHandler)
        }
        var listView = document.getElementById("players-list-view")
        var detailView = document.getElementById("player-detail-view")
        if (listView) listView.classList.add("hidden")
        if (detailView) {
            detailView.classList.remove("hidden")
            detailView.classList.toggle("player-detail-offline", p.offline === true)
            detailView.setAttribute("aria-hidden", "false")
        }
        if (typeof updateFreezeButtonState === "function") updateFreezeButtonState()
        if (typeof window.updatePlayerDetailButtonsPerms === "function") window.updatePlayerDetailButtonsPerms()
        break
    }
    case "playerVehiclesList":
    if (event.data && event.data.vehicles) {
        renderPlayerDetailVehicles(event.data.vehicles)
        break
    }
    case "spectateStarted": {
        var btnSpectate = document.getElementById("player-detail-btn-spectate")
        var btnStop = document.getElementById("player-detail-btn-stop-spectate")
        if (btnSpectate) btnSpectate.classList.add("hidden")
        if (btnStop) btnStop.classList.remove("hidden")
        var panel = document.getElementById("spectate-info-panel")
        var nameEl = document.getElementById("spectate-info-name")
        var idEl = document.getElementById("spectate-info-id")
        var jobEl = document.getElementById("spectate-info-job")
        var groupEl = document.getElementById("spectate-info-group")
        if (nameEl) nameEl.textContent = (event.data && event.data.name != null && event.data.name !== "") ? String(event.data.name) : "—"
        if (idEl) idEl.textContent = (event.data && event.data.id != null) ? String(event.data.id) : "—"
        if (jobEl) jobEl.textContent = (event.data && event.data.job != null && event.data.job !== "") ? String(event.data.job) : "—"
        if (groupEl) groupEl.textContent = (event.data && event.data.group != null && event.data.group !== "") ? String(event.data.group) : "—"
        if (panel) {
            panel.classList.remove("hidden")
            panel.setAttribute("aria-hidden", "false")
        }
        window.spectateInfoVisible = true
        break
    }
    case "spectateStopped": {
        window.spectateInfoVisible = false
        var btnSpectate = document.getElementById("player-detail-btn-spectate")
        var btnStop = document.getElementById("player-detail-btn-stop-spectate")
        if (btnSpectate) btnSpectate.classList.remove("hidden")
        if (btnStop) btnStop.classList.add("hidden")
        var panel = document.getElementById("spectate-info-panel")
        if (panel) {
            panel.classList.add("hidden")
            panel.setAttribute("aria-hidden", "true")
        }
        break
    }
    case "setPlayerDetailHeadshot": {
        if (typeof window.playerDetailMessageMatchesUi === "function" && !window.playerDetailMessageMatchesUi(event.data)) break
        if (event.data.detailReqSeq != null && window.playerDetailDetailReqSeq != null && Number(event.data.detailReqSeq) !== Number(window.playerDetailDetailReqSeq)) break
        if (event.data.forPlayerId == null || window.playerDetailCurrentId == null || String(event.data.forPlayerId) !== String(window.playerDetailCurrentId)) break
        var avatarEl = document.getElementById("player-detail-avatar")
        if (avatarEl) {
            if (event.data.base64) {
                if (typeof window.revokePlayerDetailAvatarObjectUrl === "function") window.revokePlayerDetailAvatarObjectUrl()
                try {
                    var binStr = atob(event.data.base64)
                    var blen = binStr.length
                    var u8 = new Uint8Array(blen)
                    for (var bi = 0; bi < blen; bi++) u8[bi] = binStr.charCodeAt(bi)
                    var blob = new Blob([u8], { type: "image/png" })
                    var objUrl = URL.createObjectURL(blob)
                    window._playerDetailAvatarObjectUrl = objUrl
                    avatarEl.style.backgroundImage = 'url("' + objUrl + '")'
                } catch (e) {
                    avatarEl.style.backgroundImage = "url(data:image/png;base64," + event.data.base64 + ")"
                }
            } else if (event.data.url) {
                var _u = event.data.url
                var _frag = _u.indexOf("#") >= 0 ? "&" : "#"
                avatarEl.style.backgroundImage = "url(" + _u + _frag + "jcDetail=" + String(event.data.detailReqSeq || 0) + "&u=" + String(event.data.uiNonce || 0) + ")"
            }
            avatarEl.classList.remove("player-detail-avatar-no-photo")
            avatarEl.style.backgroundSize = "cover"
            avatarEl.style.backgroundPosition = "center"
        }
        break
    }
    case "setGiveItemsList": {
        if (typeof window.setGiveItemsListData === "function") window.setGiveItemsListData(event.data.items || [])
        break
    }
    case "setPlayerInventory":
    if (event.data) {
        if (typeof window.setGiveItemsPlayerInventory === "function") window.setGiveItemsPlayerInventory(event.data.playerId, event.data.inventory || [])
        break
    }
    case "setPlayerNotes":
    if (event.data) {
        if (typeof window.setPlayerNotesData === "function") window.setPlayerNotesData(event.data.playerId, event.data.offlineIdentifier, event.data.notes || [])
        break
    }
    case "setAssignAdminList": {
        if (typeof window.setAssignAdminListData === "function") window.setAssignAdminListData(event.data.groups || [])
        break
    }
    case "setAssignJobList": {
        if (typeof window.setAssignJobListData === "function") window.setAssignJobListData(event.data.jobs || [])
        break
    }
    case "setAssignGangList": {
        if (typeof window.setAssignGangListData === "function") window.setAssignGangListData(event.data.gangs || [])
        break
    }
    case "processHeadshot":
    if (event.data.url) {
        var url = event.data.url
        var reqId = event.data.requestId
        var img = new Image()
        img.onload = function() {
            function sendRes(b64) {
                fetch("https://" + GetParentResourceName() + "/headshotResult", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ base64: b64 || "", requestId: reqId })
                }).catch(function() {})
            }
            try {
                var canvas = document.createElement("canvas")
                canvas.width = img.naturalWidth || img.width
                canvas.height = img.naturalHeight || img.height
                var ctx = canvas.getContext("2d")
                if (!ctx) {
                    sendRes("")
                    return
                }
                ctx.drawImage(img, 0, 0)
                var imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
                var pixels = imageData.data
                for (var i = 0; i < pixels.length; i += 4) {
                    if (pixels[i] < 15 && pixels[i + 1] < 15 && pixels[i + 2] < 15) {
                        pixels[i + 3] = 0
                    }
                }
                ctx.putImageData(imageData, 0, 0)
                var dataUrl = canvas.toDataURL("image/png")
                var base64 = dataUrl.indexOf("base64,") >= 0 ? dataUrl.split("base64,")[1] : dataUrl
                sendRes(base64)
            } catch (e) {
                sendRes("")
            }
        }
        img.onerror = function() {
            fetch("https://" + GetParentResourceName() + "/headshotResult", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ base64: "", requestId: reqId })
            }).catch(function() {})
        }
        img.src = url
        break
    }
    case "openCoordsUI":
    if (event.data.coords) {
        if (event.data.locale != null) window.locale = event.data.locale
        if (event.data.translations != null) window.translations = event.data.translations
        if (window.translations) applyTranslations()
        var c = event.data.coords
        var luaEl = document.getElementById("coords-lua")
        var normalEl = document.getElementById("coords-normal")
        var v3El = document.getElementById("coords-vector3")
        var v4El = document.getElementById("coords-vector4")
        if (luaEl) luaEl.textContent = c.lua || ""
        if (normalEl) normalEl.textContent = c.normal || ""
        if (v3El) v3El.textContent = c.vector3 || ""
        if (v4El) v4El.textContent = c.vector4 || ""
        var laserBtn = document.getElementById("coords-ui-laser-btn")
        var cameraBtn = document.getElementById("coords-ui-camera-btn")
        if (laserBtn) {
            laserBtn.classList.toggle("active", !!event.data.laserOn)
            laserBtn.setAttribute("aria-pressed", !!event.data.laserOn)
        }
        if (cameraBtn) {
            cameraBtn.classList.toggle("active", !!event.data.cameraOn)
            cameraBtn.setAttribute("aria-pressed", !!event.data.cameraOn)
        }
        var coordsEl = document.getElementById("coords-ui")
        if (coordsEl) coordsEl.classList.remove("hidden")
        break
    }
    case "coordsUiSetLaser": {
        var laserBtn = document.getElementById("coords-ui-laser-btn")
        if (laserBtn) {
            laserBtn.classList.toggle("active", !!event.data.on)
            laserBtn.setAttribute("aria-pressed", !!event.data.on)
        }
        break
    }
    case "coordsUiSetCamera": {
        var cameraBtn = document.getElementById("coords-ui-camera-btn")
        if (cameraBtn) {
            cameraBtn.classList.toggle("active", !!event.data.on)
            cameraBtn.setAttribute("aria-pressed", !!event.data.on)
        }
        break
    }
    case "closeCoordsUI": {
        var coordsEl = document.getElementById("coords-ui")
        if (coordsEl) coordsEl.classList.add("hidden")
        break
    }
    case "entityLaserShow": {
        var entityLaserEl = document.getElementById("entity-laser-ui")
        if (entityLaserEl) {
            if (event.data.show) entityLaserEl.classList.remove("hidden")
            else entityLaserEl.classList.add("hidden")
        }
        break
    }
    case "entityLaserUpdate": {
        var entityLaserEl = document.getElementById("entity-laser-ui")
        if (!entityLaserEl) return
        if (event.data.show) entityLaserEl.classList.remove("hidden")
        var typeEl = document.getElementById("entity-laser-type")
        var hashEl = document.getElementById("entity-laser-hash")
        var healthEl = document.getElementById("entity-laser-health")
        var entityIdEl = document.getElementById("entity-laser-entityid")
        var netIdEl = document.getElementById("entity-laser-netid")
        var distEl = document.getElementById("entity-laser-dist")
        if (event.data.hasEntity) {
            if (typeEl) typeEl.textContent = event.data.entityType || "—"
            if (hashEl) hashEl.textContent = event.data.hash != null ? String(event.data.hash) : "—"
            if (healthEl) healthEl.textContent = (event.data.health != null && event.data.maxHealth != null) ? (event.data.health + "/" + event.data.maxHealth) : "—"
            if (entityIdEl) entityIdEl.textContent = event.data.entityId != null ? String(event.data.entityId) : "—"
            if (netIdEl) netIdEl.textContent = event.data.netId != null ? String(event.data.netId) : "—"
            if (distEl) distEl.textContent = event.data.dist != null ? event.data.dist : "—"
        } else {
            if (typeEl) typeEl.textContent = "—"
            if (hashEl) hashEl.textContent = "—"
            if (healthEl) healthEl.textContent = "—"
            if (entityIdEl) entityIdEl.textContent = "—"
            if (netIdEl) netIdEl.textContent = "—"
            if (distEl) distEl.textContent = event.data.dist || "—"
        }
        break
    }
    case "showCameraInfo": {
        var cameraInfoEl = document.getElementById("camera-info-ui")
        if (cameraInfoEl) {
            if (event.data.show) {
                cameraInfoEl.classList.remove("hidden")
                window._cameraInfoActive = true
                if (!window._cameraKeyBound) {
                    window._cameraKeyBound = true
                    document.addEventListener("keydown", cameraKeyDown)
                    document.addEventListener("keyup", cameraKeyUp)
                }
                var trap = document.getElementById("camera-info-key-trap")
                if (trap) trap.focus()
                var modeLabel = document.getElementById("camera-info-mode-label")
                if (modeLabel) modeLabel.textContent = String(event.data.mode != null ? event.data.mode : 1)
            } else {
                cameraInfoEl.classList.add("hidden")
                window._cameraInfoActive = false
            }
        }
        break
    }
    case "cameraInfoSetMode": {
        var modeLabel = document.getElementById("camera-info-mode-label")
        if (modeLabel) modeLabel.textContent = String(event.data.mode != null ? event.data.mode : 1)
        break
    }
    case "openServerTimeModal": {
        if (typeof window.openServerTimeModal === "function") window.openServerTimeModal()
        break
    }
    case "openAnnouncementsModal": {
        if (typeof window.openAnnouncementsModal === "function") window.openAnnouncementsModal()
        break
    }
    case "showAnnouncementNotification":
    if (event.data && event.data.text != null) {
        var el = document.getElementById("announcement-notification")
        var descEl = document.getElementById("announcement-notification-desc")
        if (el && descEl) {
            descEl.textContent = String(event.data.text)
            el.setAttribute("aria-hidden", "false")
            el.classList.add("visible")
            if (window._announcementNotificationTimer) clearTimeout(window._announcementNotificationTimer)
            window._announcementNotificationTimer = setTimeout(function() {
                el.classList.remove("visible")
                el.setAttribute("aria-hidden", "true")
                window._announcementNotificationTimer = null
            }, 12000)
        }
    }
    break
    case "captureResult": {
        const result = event.data.result
        if (!result || result.error) break
        const resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
        const image = result.url || result.dataUrl
        if (image) {
            fetch("https://" + resName + "/captureResult", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ url: image })
            }).catch(() => {})
        }
        break
    }
    }
})

if (loginTogglePassword && loginPasswordInput && loginPasswordIcon) {
    loginTogglePassword.addEventListener("click", () => {
        const isPassword = loginPasswordInput.type === "password"
        loginPasswordInput.type = isPassword ? "text" : "password"
        loginPasswordIcon.classList.toggle("fa-eye", !isPassword)
        loginPasswordIcon.classList.toggle("fa-eye-slash", isPassword)
        loginTogglePassword.setAttribute("aria-label", isPassword ? "Ocultar contraseña" : "Mostrar contraseña")
    })
}

loginForm.addEventListener("submit", (e) => {
    e.preventDefault()
    loginError.classList.add("hidden")
    const isChecked = loginRemember && loginRemember.checked === true
    const remember = isChecked ? 1 : 0
    fetch(`https://${GetParentResourceName()}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            user: loginUser.value.trim(),
            password: loginPassword.value,
            remember: remember
        })
    })
})

var mustChangeForm = document.getElementById("must-change-form")
var mustChangeTogglePw = document.getElementById("must-change-toggle-password")
var mustChangePwIcon = document.getElementById("must-change-password-icon")
if (mustChangeTogglePw && mustChangePwIcon) {
    mustChangeTogglePw.addEventListener("click", function() {
        var inp = document.getElementById("must-change-password")
        if (!inp) return
        var isPassword = inp.type === "password"
        inp.type = isPassword ? "text" : "password"
        mustChangePwIcon.classList.toggle("fa-eye", !isPassword)
        mustChangePwIcon.classList.toggle("fa-eye-slash", isPassword)
    })
}
if (mustChangeForm) {
    mustChangeForm.addEventListener("submit", function(e) {
        e.preventDefault()
        var errEl = document.getElementById("must-change-error")
        var userEl = document.getElementById("must-change-username")
        var pwEl = document.getElementById("must-change-password")
        var pwConfirmEl = document.getElementById("must-change-password-confirm")
        if (errEl) errEl.classList.add("hidden")
        var user = (userEl && userEl.value) ? userEl.value.trim() : ""
        var pw = (pwEl && pwEl.value) ? pwEl.value : ""
        var pwConfirm = (pwConfirmEl && pwConfirmEl.value) ? pwConfirmEl.value : ""
        if (user.length < 2) {
            if (errEl) { errEl.textContent = (window.t && window.t("must_change_error_user")) || "Usuario demasiado corto"; errEl.classList.remove("hidden") }
            return
        }
        if (pw.length < 4) {
            if (errEl) { errEl.textContent = (window.t && window.t("must_change_error_password")) || "La contraseña debe tener al menos 4 caracteres"; errEl.classList.remove("hidden") }
            return
        }
        if (pw !== pwConfirm) {
            if (errEl) { errEl.textContent = (window.t && window.t("must_change_error_confirm")) || "Las contraseñas no coinciden"; errEl.classList.remove("hidden") }
            return
        }
        fetch("https://" + GetParentResourceName() + "/setNewCredentials", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ newUsername: user, newPassword: pw })
        }).catch(function() {})
    })
}

window.showToast = function(message, type) {
    var container = document.getElementById("jc-toast-container")
    if (!container) {
        container = document.createElement("div")
        container.id = "jc-toast-container"
        container.style.cssText = "position:fixed;bottom:24px;right:24px;z-index:99999;display:flex;flex-direction:column;gap:8px;pointer-events:none;"
        document.body.appendChild(container)
    }
    var toast = document.createElement("div")
    var bg = type === "success" ? "#22c55e" : type === "error" ? "#ef4444" : "var(--jc-accent, #6fabc5)"
    toast.style.cssText = "background:" + bg + ";color:#fff;padding:10px 18px;border-radius:8px;font-size:14px;font-weight:500;box-shadow:0 4px 16px rgba(0,0,0,0.35);opacity:0;transform:translateY(8px);transition:opacity 0.18s,transform 0.18s;max-width:320px;"
    toast.textContent = message
    container.appendChild(toast)
    requestAnimationFrame(function() {
        requestAnimationFrame(function() { toast.style.opacity = "1"; toast.style.transform = "translateY(0)" })
    })
    setTimeout(function() {
        toast.style.opacity = "0"; toast.style.transform = "translateY(8px)"
        setTimeout(function() { if (toast.parentNode) toast.parentNode.removeChild(toast) }, 220)
    }, 3000)
}

const menu = document.querySelector(".menu")
const menuItems = Array.from(document.querySelectorAll(".menu li, .sidebar-nav-item"))
const pages = document.querySelectorAll(".page")

window.playersListData = { online: [], offline: [] }
window.playersFilter = "all"
window.lastOpenPlayerDetailOfflineIdentifier = null
window.bansListData = []
window.bansFilter = "all"
window.logsListData = []
window.logsCurrentPage = 1
var LOGS_PER_PAGE = 12

function getLogUserDataLines(log, displayFields) {
    var ids = log.identifiers || {}
    var info = log.info || {}
    var name = info.player_name || info.victim_name || info.killer_name || info.banned_player_name || info.unbanned_player_name || info.target_name || info.admin_name
    var lines = []
    var L = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    if (displayFields && typeof displayFields === "object") {
        if (displayFields.player_name && name && log.log_type !== "admin_actions") lines.push({ label: L("logs_label_name", "Nombre"), value: String(name).substring(0, 64) })
        if (displayFields.license && ids.identifier) lines.push({ label: L("logs_label_license", "License"), value: String(ids.identifier).substring(0, 48) })
        if (displayFields.steam && ids.steam) lines.push({ label: L("logs_label_steam", "Steam"), value: String(ids.steam).substring(0, 48) })
        if (displayFields.discord && ids.discord) lines.push({ label: L("logs_label_discord", "Discord"), value: String(ids.discord).substring(0, 48) })
        if (displayFields.ip && ids.ip) lines.push({ label: L("logs_label_ip", "IP"), value: String(ids.ip).substring(0, 24) })
    }
    if (log.log_type === "ban") {
        lines.push({ label: L("bans_banned_by", "Banned by"), value: (info.admin_name || "—").substring(0, 64) })
        lines.push({ label: L("bans_until", "Until"), value: info.is_permanent ? (L("bans_permanent", "Permanent")) : (info.expires_at_formatted || info.duration_text || info.expires_at || "—") })
    }
    if (log.log_type === "explosion") {
        var expTypeName = getExplosionTypeName(info.explosion_type)
        lines.push({ label: L("logs_label_explosion_type", "El tipo de explosión ha sido"), value: expTypeName })
        var posStr = formatExplosionPosition(info.pos_x, info.pos_y, info.pos_z)
        if (posStr) lines.push({ label: L("logs_label_position", "Posición"), value: posStr })
    }
    if (log.log_type === "death" || log.log_type === "kill") {
        var causeRaw = info.cause_of_death != null ? info.cause_of_death : (info.cause != null ? info.cause : null)
        if (causeRaw != null && String(causeRaw) !== "") {
            lines.push({ label: L("logs_label_cause_of_death", "Causa de muerte"), value: getCauseOfDeathLabel(causeRaw) })
        }
        var hasCoords = (info.pos_x != null && info.pos_y != null && info.pos_z != null)
        if (hasCoords) {
            var x = Number(info.pos_x)
            var y = Number(info.pos_y)
            var z = Number(info.pos_z)
            var xyz = [x, y, z].map(function(v) { return isNaN(v) ? "?" : (Math.round(v * 1000) / 1000).toString() }).join(" ")
            var postal = (info.nearest_postal != null && String(info.nearest_postal) !== "") ? String(info.nearest_postal) : null
            var value = postal ? (L("logs_label_nearest_postal", "Nearest Postal") + ": " + postal + " | " + xyz) : xyz
            lines.push({ label: L("logs_label_position", "Posición"), value: value })
        }
    }
    if (log.log_type === "unban") {
        lines.push({ label: L("logs_label_ban_id", "Id de baneo"), value: String(info.ban_id != null ? info.ban_id : "—") })
        lines.push({ label: L("logs_label_unbanned_by", "Desbaneado por"), value: (info.admin_name || "—").substring(0, 64) })
    }
    if (log.log_type === "tx_admin") {
        if (info.author) lines.push({ label: L("logs_label_author", "Autor"), value: String(info.author).substring(0, 64) })
        if (info.target_name) lines.push({ label: L("logs_label_target", "Objetivo"), value: String(info.target_name).substring(0, 64) })
        if (info.admin_name) lines.push({ label: L("logs_label_admin", "Admin"), value: String(info.admin_name).substring(0, 64) })
        if (info.player_name) lines.push({ label: L("logs_label_player", "Jugador"), value: String(info.player_name).substring(0, 64) })
        if (info.action) lines.push({ label: L("logs_label_action", "Acción"), value: String(info.action).substring(0, 64) })
        if (info.action_id) lines.push({ label: L("logs_label_action_id", "ID acción"), value: String(info.action_id) })
    }
    if (log.log_type === "admin_actions") {
        if (info.admin_name) lines.push({ label: L("logs_label_admin", "Admin"), value: String(info.admin_name).substring(0, 64) })
        if (info.target_name) lines.push({ label: L("logs_label_target", "Objetivo"), value: String(info.target_name).substring(0, 64) })
        var act = info.action
        if (act === "manage_money" || act === "give" || act === "withdraw") {
            if (info.money_type != null && info.money_type !== "") lines.push({ label: L("logs_label_type", "Tipo"), value: String(info.money_type) })
            if (info.amount != null) lines.push({ label: L("logs_label_amount", "Cantidad"), value: String(info.amount) })
            if (act === "give" || act === "withdraw") lines.push({ label: L("logs_label_action", "Acción"), value: act === "give" ? L("logs_label_give", "Dar") : L("logs_label_remove", "Quitar") })
        }
    }
    return lines
}

var CAUSE_OF_DEATH_LABELS = {
    0: "Desconocido",
    "-842959696": "Caída",
    "453432689": "Pistola",
    "-1569615261": "Puños / cuerpo a cuerpo",
    "-1716189206": "Cuchillo",
    "-2084633992": "Rifle de asalto",
    "-1553120962": "Atropello",
    "-1355977831": "Ahogamiento",
    "324215364": "Pistola combat",
    "-619010992": "Micro SMG",
    "584646201": "Escopeta",
    "-1074790487": "Rifle de asalto",
    "-1063057011": "Carabina",
    "1119849093": "Minigun",
    "-1813897027": "Granada",
    "615608432": "Lanzacohetes",
    "-494615257": "Lanzagranadas",
    "-275439685": "SMG",
    "736523883": "Sniper pesado",
    "100416529": "Sniper",
    "911657153": "Pistola pesada",
    "-598887786": "Petardo",
    "-1746263880": "Bola de fuego",
    "-102323637": "Lanzallamas",
    "-879347409": "Minigun",
    "101631238": "Fusil de francotirador",
    "1233104067": "Fusil táctico",
    "-1768145561": "Granada adhesiva",
    "-1420407917": "Molotov",
    "125959754": "Pistola AP",
    "-1716589765": "Pistola calibre 50",
    "-2067956739": "Escopeta automática",
    "317205821": "Escopeta de combate",
    "-952879014": "SMG mini",
    "-1466123874": "Escopeta pesada",
    "984333226": "Fusil de asalto pesado",
    "-86904375": "Lanzacohetes homing",
    "-1312131151": "RPG",
    "2132975508": "Lanzamisiles",
    "1834241177": "Rifle de francotirador",
    "-1121678507": "Rifle pesado",
    "1672152130": "Hacha",
    "1737195953": "Bate",
    "1317494643": "Pie de cabra",
    "-1786099057": "Porra",
    "1141786504": "Martillo",
    "-102973651": "Navaja",
    "-656458692": "Machete",
    "-581044007": "Linterna",
    "-1951375401": "Bote de gasolina",
    "419712736": "Ácido",
    "-275439685": "SMG",
    "-879347409": "Minigun",
    "2024373456": "Pistola SNS",
    "-37975472": "Pistola vintage",
    "324536364": "Revólver pesado",
    "-1045183535": "Revólver",
    "1593441988": "Pistola doble acción",
    "584646201": "Escopeta recortada",
    "317205821": "Escopeta de combate",
    "1432025498": "SMG",
    "1198879012": "SMG de combate",
    "-619010992": "Micro SMG",
    "171789620": "Rifle de asalto",
    "3231910285": "Carabina",
    "-1063057011": "Carabina avanzada",
    "2138341713": "Fusil táctico",
    "100416529": "Rifle de francotirador",
    "205991906": "Rifle pesado",
    "177293209": "Rifle de francotirador pesado",
    "2726580491": "RPG",
    "2982836145": "Lanzagranadas",
    "1119849093": "Minigun",
    "2481070269": "Granada",
    "741814745": "Granada adhesiva",
    "-1420407917": "Cóctel Molotov",
    "615608432": "Lanzacohetes",
    "125959754": "Pistola AP",
    "3218215474": "Bola de fuego",
    "101631238": "Fusil de francotirador",
    "1223143800": "Explosión",
    "-1568386805": "Quemado",
    "133987706": "Electrocutado",
    "-544306709": "Gas lacrimógeno",
    "2460120199": "Bote de humo",
    "2694266206": "Barril explosivo",
    "-1813897027": "Granada de fragmentación",
    "741814745": "C4 / explosivo plástico",
    "-1654528753": "Bola de boliche",
    "-1813897027": "Granada de gas",
    "600439132": "Lanzacohetes",
    "1233104067": "Fusil de asalto",
    "-37975472": "Pistola vintage",
    "324536364": "Revólver",
    "736523883": "Sniper pesado",
    "-2067956739": "Escopeta automática",
    "2017895192": "Escopeta de asalto",
    "-952879014": "SMG mini",
    "3173288789": "Pistola máquina",
    "137902532": "Revólver de combate",
    "-598887786": "Petardo",
    "2132975508": "Lanzamisiles",
    "-86904375": "Misil guiado",
    "1752584910": "Explosión de vehículo",
    "-10959621": "Colisión",
    "133987706": "Electrocución",
    "910830060": "Drogas / sobredosis"
}

function getCauseOfDeathLabel(cause) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    if (cause == null || cause === undefined) return T("logs_cause_unknown", "desconocida")
    var key = String(cause)
    return CAUSE_OF_DEATH_LABELS[key] != null ? CAUSE_OF_DEATH_LABELS[key] : T("logs_cause_unknown", "desconocida")
}

var EXPLOSION_TYPE_NAMES = {
    0: "Grenade", 1: "GrenadeLauncher", 2: "C4", 3: "Molotov", 4: "Rocket", 5: "TankShell",
    6: "Hi_Octane", 7: "Car", 8: "Plance", 9: "PetrolPump", 10: "Bike", 11: "Dir_Steam",
    12: "Dir_Flame", 13: "Dir_Water_Hydrant", 14: "Dir_Gas_Canister", 15: "Boat", 16: "Ship_Destroy",
    17: "Truck", 18: "Bullet", 19: "SmokeGrenadeLauncher", 20: "SmokeGrenade", 21: "BZGAS",
    22: "Flare", 23: "Gas_Canister", 24: "Extinguisher", 25: "Programmablear", 26: "Train",
    27: "Barrel", 28: "PROPANE", 29: "Blimp", 30: "Dir_Flame_Explode", 31: "Tanker",
    32: "PlaneRocket", 33: "VehicleBullet", 34: "Gas_Tank", 35: "FireWork", 36: "SnowBall",
    37: "ProxMine", 38: "Valkyrie_Cannon"
}

function getExplosionTypeName(typeId) {
    if (typeId == null || typeId === undefined) return "—"
    var key = String(typeId)
    return EXPLOSION_TYPE_NAMES[key] != null ? EXPLOSION_TYPE_NAMES[key] : key
}

function formatExplosionPosition(x, y, z) {
    if (x == null && y == null && z == null) return ""
    function num(v) {
        if (v == null || v === undefined) return "—"
        var n = Number(v)
        if (isNaN(n)) return "—"
        return n.toFixed(2)
    }
    var px = num(x)
    var py = num(y)
    var pz = num(z)
    if (px === "—" && py === "—" && pz === "—") return ""
    return "X: " + px + ", Y: " + py + ", Z: " + pz
}

function formatLogDate(created) {
    if (created == null || created === undefined || created === "") return "—"
    try {
        var ts = Number(created)
        var d = isNaN(ts) ? new Date(created) : new Date(ts)
        if (isNaN(d.getTime())) return "—"
        var loc = (typeof window !== "undefined" && window.locale && window.locale.substring(0, 2)) || "en"
        var locStr = loc + "-" + (loc.toUpperCase())
        return d.toLocaleDateString(locStr, { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" })
    } catch (e) {
        return "—"
    }
}

function getTxAdminLogTitle(info) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    var sub = (info.subtype || "").toLowerCase()
    if (sub === "restart") return T("logs_tx_title_restart", "Reinicio programado")
    if (sub === "dm") return T("logs_tx_title_dm", "Mensaje directo")
    if (sub === "revoke") return T("logs_tx_title_revoke", "Acción revocada")
    if (sub === "kick") return T("logs_tx_title_kick", "Kick")
    if (sub === "ban") return T("logs_tx_title_ban", "Baneo TX")
    if (sub === "warn") return T("logs_tx_title_warn", "Aviso")
    if (sub === "heal") return T("logs_tx_title_heal", "Curación")
    if (sub === "announcement") return T("logs_tx_title_announcement", "Anuncio")
    if (sub === "whitelist") return T("logs_tx_title_whitelist", "Whitelist")
    return T("logs_tx_title_default", "TX Admin")
}

function getTxAdminLogReason(info) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    var sub = (info.subtype || "").toLowerCase()
    var msg = (info.message || "").substring(0, 150)
    if (msg.length && (info.message || "").length > 150) msg += "..."
    if (sub === "restart") return (T("logs_tx_reason_restart", "Reinicio en %s min")).replace("%s", info.time_remaining || "—")
    if (sub === "dm") return (info.author || "—") + " → " + (info.target_name || "—") + ": " + (msg || "—")
    if (sub === "revoke") return (T("logs_tx_reason_revoke", "%s revocó %s #%s")).replace("%s", info.revoked_by || "—").replace("%s", info.action_type || "—").replace("%s", info.action_id || "—")
    if (sub === "kick") return (T("logs_tx_reason_kick", "%s expulsó a %s. %s")).replace("%s", info.author || "—").replace("%s", info.target_name || "—").replace("%s", info.reason || "—")
    if (sub === "ban") return (T("logs_tx_reason_ban", "%s baneó a %s. %s · %s")).replace("%s", info.author || "—").replace("%s", info.target_name || "—").replace("%s", info.reason || "—").replace("%s", info.expiration || "—")
    if (sub === "warn") return (T("logs_tx_reason_warn", "%s avisó a %s. %s")).replace("%s", info.author || "—").replace("%s", info.target_name || "—").replace("%s", info.reason || "—")
    if (sub === "heal") return (T("logs_tx_reason_heal", "%s curó a %s")).replace("%s", info.author || "—").replace("%s", info.target_name || "—")
    if (sub === "announcement") return (info.author || "—") + ": " + (msg || "—")
    if (sub === "whitelist") return (info.admin_name || "—") + " · " + (info.action || "—") + " · " + (info.player_name || "—")
    return msg || JSON.stringify(info).substring(0, 100)
}

function getTxAdminLogExtra(info) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    var sub = (info.subtype || "").toLowerCase()
    if (sub === "kick" && info.identifiers_text) return info.identifiers_text.substring(0, 120)
    if (sub === "warn" && info.identifiers_text) return info.identifiers_text.substring(0, 120)
    if (sub === "ban" && info.action_id) return T("logs_label_action_id", "ID acción") + ": " + info.action_id
    if (sub === "whitelist" && info.license) return T("logs_label_license", "License") + ": " + info.license.substring(0, 48)
    return ""
}

var ADMIN_ACTION_TITLES = {
    kick: "Kick",
    ban: "Ban",
    unban: "Unban",
    revive: "Revivir",
    spectate: "Espectear",
    take_capture: "Captura de pantalla",
    change_skin: "Cambiar skin",
    assign_job: "Asignar trabajo",
    bring: "Traer jugador",
    return_player: "Devolver jugador",
    giveitems: "Inventario",
    assign_gangs: "Asignar banda",
    tp: "Teleportar",
    manage_money: "Gestionar dinero",
    assing_admin: "Asignar admin",
    freeze: "Congelar",
    kill: "Matar",
    clean_inventory: "Limpiar inventario",
    ck_player: "Character kill",
    instancia: "Mover a instancia",
    spawn_vehicle: "Spawear vehículo",
    add_vehicle: "Añadir vehículo",
    remove_vehicle: "Quitar vehículo",
    delete_vehicle: "Eliminar vehículo",
    announcement: "Anuncio",
    noclip: "Noclip",
    server_time: "Cambiar hora",
    godmode: "Godmode",
    invisible: "Invisible",
    staff_clothing: "Ropa staff",
    tag_player: "Tags",
    fix_vehicle: "Arreglar vehículo",
    tpm: "TP a waypoint",
    copy_coords: "Copiar coords",
    tuning_vehicle: "Tuning vehículo",
    change_password: "Cambiar contraseña",
    reset_admin_time: "Reiniciar tiempo admin",
    player_notes: "Notas administrativas",
    player_notes_delete: "Eliminar nota administrativa",
    give_car_keys: "Dar llaves del vehículo"
}

function getAdminActionTitle(actionKey) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    if (!actionKey) return T("logs_admin_action_default", "Acción de admin")
    var key = String(actionKey).toLowerCase().replace(/\s/g, "_")
    if (key === "give" || key === "withdraw") key = "manage_money"
    var tKey = "logs_admin_title_" + key
    return T(tKey, ADMIN_ACTION_TITLES[key] || (key.charAt(0).toUpperCase() + key.slice(1).replace(/_/g, " ")))
}

var ADMIN_ACTION_DESCRIPTIONS = {
    kick: "Ha expulsado a un jugador",
    ban: "Ha baneado a un jugador",
    unban: "Ha desbaneado a un jugador",
    revive: "Ha revivido a un jugador",
    spectate: "Ha especteado a un jugador",
    take_capture: "Ha realizado una captura de pantalla a un jugador",
    change_skin: "Ha abierto el menú de skin a un jugador",
    assign_job: "Ha asignado trabajo a un jugador",
    bring: "Ha traído a un jugador",
    return_player: "Ha devuelto a un jugador",
    giveitems: "Ha dado objetos a un jugador",
    assign_gangs: "Ha asignado banda a un jugador",
    tp: "Se ha teleportado a un jugador",
    manage_money: "Ha gestionado el dinero de un jugador",
    assing_admin: "Ha asignado grupo de admin a un jugador",
    freeze: "Ha congelado a un jugador",
    kill: "Ha matado a un jugador",
    clean_inventory: "Ha limpiado el inventario de un jugador",
    ck_player: "Ha hecho character kill a un jugador",
    instancia: "Ha movido a un jugador de instancia",
    spawn_vehicle: "Ha spawneado un vehículo a un jugador",
    add_vehicle: "Ha añadido un vehículo a un jugador",
    remove_vehicle: "Ha quitado un vehículo a un jugador",
    delete_vehicle: "Ha eliminado un vehículo a un jugador",
    announcement: "Ha enviado un anuncio",
    noclip: "Ha activado noclip",
    server_time: "Ha cambiado la hora del servidor",
    godmode: "Ha activado godmode",
    invisible: "Ha activado modo invisible",
    staff_clothing: "Ha cambiado la ropa de staff",
    tag_player: "Ha activado los tags",
    fix_vehicle: "Ha arreglado un vehículo",
    tpm: "Se ha teleportado al waypoint",
    copy_coords: "Ha copiado las coordenadas",
    tuning_vehicle: "Ha aplicado tuning a un vehículo",
    change_password: "Ha cambiado su contraseña",
    reset_admin_time: "Ha reiniciado el tiempo registrado de un staff",
    player_notes: "Ha añadido una nota administrativa",
    player_notes_delete: "Ha eliminado una nota administrativa",
    give_car_keys: "Ha dado llaves a su vehículo actual"
}

function getAdminActionDescription(actionKey) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    if (!actionKey) return T("logs_admin_desc_default", "Acción de administrador")
    var key = String(actionKey).toLowerCase().replace(/\s/g, "_")
    if (key === "give" || key === "withdraw") key = "manage_money"
    var tKey = "logs_admin_desc_" + key
    return T(tKey, ADMIN_ACTION_DESCRIPTIONS[key] || "Ha realizado una acción sobre un jugador")
}

function formatAdminActionParams(info) {
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    var actionKey = info.action
    if (actionKey === "give" || actionKey === "withdraw") actionKey = "manage_money"
    var lines = [getAdminActionDescription(actionKey)]
    if (info.reason != null && info.reason !== "") lines.push(T("logs_admin_reason", "Razón") + ": " + String(info.reason))
    if (info.job != null && info.job !== "") lines.push(T("logs_admin_job", "Trabajo") + ": " + String(info.job))
    if (info.grade != null) lines.push(T("logs_admin_grade", "Grado") + ": " + info.grade)
    if (info.group != null && info.group !== "") lines.push(T("logs_admin_group", "Grupo") + ": " + String(info.group))
    if (actionKey !== "manage_money") {
        if (info.money_type != null && info.money_type !== "") lines.push(T("logs_label_type", "Tipo") + ": " + String(info.money_type))
        if (info.amount != null) lines.push(T("logs_label_amount", "Cantidad") + ": " + info.amount)
    }
    if (info.item != null && info.item !== "") lines.push(T("logs_admin_item", "Objeto") + ": " + String(info.item))
    if (info.items_count != null) lines.push(T("logs_admin_items_count", "Objetos") + ": " + info.items_count)
    if (info.model != null && info.model !== "") lines.push(T("logs_admin_model", "Modelo") + ": " + String(info.model))
    if (info.plate != null && info.plate !== "") lines.push(T("logs_admin_plate", "Matrícula") + ": " + String(info.plate))
    if (info.message != null && info.message !== "") lines.push(T("logs_admin_message", "Mensaje") + ": " + String(info.message).substring(0, 120))
    if (info.ban_id != null) lines.push(T("logs_label_ban_id", "ID baneo") + ": " + info.ban_id)
    if (info.is_permanent === true) lines.push(T("logs_admin_permanent_yes", "Permanente: Sí"))
    if (info.hour != null) lines.push(T("logs_admin_hour", "Hora") + ": " + info.hour)
    if (info.freeze === true) lines.push(T("logs_admin_freeze_yes", "Hora congelada: Sí"))
    if (info.weather != null && info.weather !== "") lines.push(T("logs_admin_weather", "Clima") + ": " + String(info.weather))
    return lines.length > 1 ? lines.join("\n") : lines[0]
}

function getLogCardData(log) {
    var info = log.info || {}
    var dateText = formatLogDate(log.created_at)
    var title = "—"
    var reason = ""
    var extra = ""
    var T = function(k, d) { return (typeof window !== "undefined" && window.t && window.t(k)) || d }
    switch (log.log_type) {
        case "server_join":
            title = T("logs_card_title_server_join", "Entrada al servidor")
            reason = T("logs_card_reason_server_join", "El usuario se está conectando al servidor")
            break
        case "server_leave":
            title = T("logs_card_title_server_leave", "Salida del servidor")
            reason = (T("logs_card_reason_server_leave", "Ha salido por la razón %s")).replace("%s", info.reason || "—")
            break
        case "chat":
            title = info.player_name || T("logs_card_title_chat", "Chat")
            reason = (info.message || "—").substring(0, 120)
            if ((info.message || "").length > 120) reason += "..."
            break
        case "death":
            title = T("logs_card_title_death", "Muertes")
            reason = (T("logs_card_reason_death", "El usuario ha muerto por la razón %s")).replace("%s", getCauseOfDeathLabel(info.cause_of_death))
            break
        case "kill":
            title = info.killer_name || T("logs_label_player", "Jugador")
            reason = (T("logs_card_reason_kill", "Mató a %s")).replace("%s", info.victim_name || "—")
            extra = (T("logs_card_extra_victim", "Víctima: %s")).replace("%s", info.victim_name || "—")
            break
        case "explosion":
            title = T("logs_card_title_explosion", "Explosión")
            reason = T("logs_card_reason_explosion", "El jugador ha ocasionado una explosión")
            break
        case "ban":
            title = T("logs_card_title_ban", "Baneado")
            reason = (info.reason || "—").substring(0, 100)
            if ((info.reason || "").length > 100) reason += "..."
            break
        case "unban":
            title = T("logs_card_title_unban", "Desbaneado")
            reason = (info.ban_reason || "—").substring(0, 120)
            if ((info.ban_reason || "").length > 120) reason += "..."
            break
        case "tx_admin":
            title = getTxAdminLogTitle(info)
            reason = getTxAdminLogReason(info)
            extra = getTxAdminLogExtra(info)
            break
        case "admin_actions":
            title = getAdminActionTitle(info.action)
            reason = formatAdminActionParams(info)
            extra = ""
            break
        default:
            title = log.log_type || T("logs_card_title_default", "Log")
            reason = JSON.stringify(info).substring(0, 100)
    }
    return { title: title, dateText: dateText, reason: reason, extra: extra }
}

function renderLogsList() {
    var data = window.logsListData || []
    var listEl = document.getElementById("logs-list")
    var placeholderEl = document.getElementById("logs-list-placeholder")
    var paginationEl = document.getElementById("logs-pagination")
    var paginationPrev = document.getElementById("logs-pagination-prev")
    var paginationNext = document.getElementById("logs-pagination-next")
    var paginationInfo = document.getElementById("logs-pagination-info")
    if (!listEl) return
    if (data.length === 0) {
        listEl.innerHTML = ""
        if (placeholderEl) {
            placeholderEl.classList.remove("hidden")
            placeholderEl.textContent = (typeof window !== "undefined" && window.t && window.t("logs_no_logs")) || "No hay logs para mostrar"
        }
        if (paginationEl) paginationEl.classList.add("hidden")
        return
    }
    if (placeholderEl) placeholderEl.classList.add("hidden")
    var totalPages = Math.max(1, Math.ceil(data.length / LOGS_PER_PAGE))
    var page = Math.min(Math.max(1, window.logsCurrentPage || 1), totalPages)
    window.logsCurrentPage = page
    var start = (page - 1) * LOGS_PER_PAGE
    var pageData = data.slice(start, start + LOGS_PER_PAGE)
    var maxReasonLen = 80
    var displayFields = window.logsDisplayFields || {}
    listEl.innerHTML = pageData.map(function(log) {
        var card = getLogCardData(log)
        var title = String(card.title || "—").replace(/</g, "&lt;").substring(0, 64)
        var dateText = String(card.dateText || "—").replace(/</g, "&lt;")
        var reasonRaw = String(card.reason || "—").replace(/</g, "&lt;")
        var isAdminAction = log.log_type === "admin_actions"
        var reason = isAdminAction ? reasonRaw : (reasonRaw.length > maxReasonLen ? reasonRaw.substring(0, maxReasonLen) + "..." : reasonRaw)
        var extra = String(card.extra || "").replace(/</g, "&lt;")
        var extraHtml = extra ? "<span class=\"bans-card-banned-by\">" + extra + "</span>" : ""
        var userLines = getLogUserDataLines(log, displayFields)
        var userBlock = ""
        if (userLines.length > 0) {
            userBlock = "<div class=\"logs-card-identifiers\">" + userLines.map(function(l) {
                var v = String(l.value || "").replace(/</g, "&lt;")
                return "<span class=\"logs-card-identifiers-item\"><span class=\"logs-card-identifiers-label\">" + String(l.label || "").replace(/</g, "&lt;") + ":</span> " + v + "</span>"
            }).join("") + "</div>"
        }
        var cardClass = "bans-card logs-card" + (isAdminAction ? " logs-card--admin-action" : "")
        return "<div class=\"" + cardClass + "\"><div class=\"bans-card-header\"><h3 class=\"bans-card-name\">" + title + "</h3><span class=\"bans-card-expiry\">" + dateText + "</span></div><p class=\"bans-card-reason\">" + reason + "</p>" + userBlock + "<div class=\"bans-card-actions\">" + extraHtml + "</div></div>"
    }).join("")
    if (paginationEl) {
        paginationEl.classList.remove("hidden")
        if (paginationInfo) {
            var pageMsg = (typeof window !== "undefined" && window.t && window.t("logs_page_info")) || "Página %s de %s"
            paginationInfo.textContent = pageMsg.replace("%s", String(page)).replace("%s", String(totalPages))
        }
        if (paginationPrev) {
            paginationPrev.disabled = page <= 1
            paginationPrev.style.opacity = page <= 1 ? "0.5" : "1"
        }
        if (paginationNext) {
            paginationNext.disabled = page >= totalPages
            paginationNext.style.opacity = page >= totalPages ? "0.5" : "1"
        }
    }
}

function renderBansList() {
    var data = window.bansListData || []
    var filter = window.bansFilter || "all"
    if (filter === "permanent") data = data.filter(function(b) { return b.is_permanent === true })
    else if (filter === "date") data = data.filter(function(b) { return b.is_permanent !== true })
    var query = (document.getElementById("bans-search") && document.getElementById("bans-search").value) ? String(document.getElementById("bans-search").value).trim().toLowerCase() : ""
    if (query) {
        data = data.filter(function(b) {
            var name = String(b.player_name || "").toLowerCase()
            var ident = String(b.identifier || "").toLowerCase()
            return name.indexOf(query) !== -1 || ident.indexOf(query) !== -1
        })
    }
    var listEl = document.getElementById("bans-list")
    var placeholderEl = document.getElementById("bans-list-placeholder")
    if (!listEl) return
    if (data.length === 0) {
        listEl.innerHTML = ""
        if (placeholderEl) {
            placeholderEl.classList.remove("hidden")
            var placeholderTextEl = document.getElementById("bans-list-placeholder-text")
            var msg = (query || filter !== "all") ? ((typeof window !== "undefined" && window.t && window.t("bans_no_bans_match")) || "No hay baneos que coincidan") : ((typeof window !== "undefined" && window.t && window.t("bans_no_bans")) || "No hay baneos")
            if (placeholderTextEl) placeholderTextEl.textContent = msg
        }
        return
    }
    if (placeholderEl) placeholderEl.classList.add("hidden")
    var sp = window.sectionPerms || {}
    var unbanAllowed = sp.bans_unban === true || sp.bans_unban === "1" || sp.bans_unban === 1
    var modifyAllowed = sp.bans_modify === true || sp.bans_modify === "1" || sp.bans_modify === 1
    var editCls = "bans-item-btn bans-item-btn-edit" + (modifyAllowed ? "" : " bans-item-btn-no-permission")
    var editDataPerm = modifyAllowed ? "true" : "false"
    var unbanCls = "bans-item-btn bans-item-btn-unban" + (unbanAllowed ? "" : " bans-item-btn-no-permission")
    var unbanDataPerm = unbanAllowed ? "true" : "false"
    var maxReasonLen = 80
    listEl.innerHTML = data.map(function(b) {
        var name = (b.player_name || "—").replace(/</g, "&lt;")
        var permanentLabel = (window.t && window.t("bans_permanent")) || "Permanent"
        var expiryText = b.is_permanent ? permanentLabel : (b.expires_at ? (function() {
            try {
                var ts = Number(b.expires_at)
                var d = isNaN(ts) ? new Date(b.expires_at) : new Date(ts)
                if (isNaN(d.getTime())) return "—"
                var loc = (window.locale && window.locale.substring(0, 2)) || "en"
                return d.toLocaleDateString(loc + "-" + loc.toUpperCase(), { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" })
            } catch (e) { return "—" }
        })() : "—")
        var reasonRaw = (b.reason || "").replace(/</g, "&lt;")
        var reason = reasonRaw.length > maxReasonLen ? reasonRaw.substring(0, maxReasonLen) + "..." : (reasonRaw || "—")
        var bannedBy = (b.banned_by || "—").replace(/</g, "&lt;")
        var bid = String(b.id)
        var bannedByLabel = (window.t && window.t("bans_banned_by")) || "Banned by"
        var modifyTitle = (window.t && window.t("bans_modify")) || "Modify ban"
        var unbanTitle = (window.t && window.t("bans_unban")) || "Unban"
        return "<div class=\"bans-card\"><div class=\"bans-card-header\"><h3 class=\"bans-card-name\">" + name + "</h3><span class=\"bans-card-expiry\">" + expiryText.replace(/</g, "&lt;") + "</span></div><p class=\"bans-card-reason\">" + reason + "</p><div class=\"bans-card-actions\"><button type=\"button\" class=\"" + editCls + "\" data-perm-allowed=\"" + editDataPerm + "\" data-ban-id=\"" + bid + "\" title=\"" + modifyTitle.replace(/"/g, "&quot;") + "\"><i class=\"fa-solid fa-pen-to-square\"></i></button><button type=\"button\" class=\"" + unbanCls + "\" data-perm-allowed=\"" + unbanDataPerm + "\" data-ban-id=\"" + bid + "\" title=\"" + unbanTitle.replace(/"/g, "&quot;") + "\"><i class=\"fa-solid fa-unlock\"></i></button><span class=\"bans-card-banned-by\">" + bannedByLabel + " " + bannedBy + "</span></div></div>"
    }).join("")
}

function formatMoney(n) {
    if (n == null || isNaN(Number(n))) return "0"
    return Number(n).toLocaleString("es-ES", { maximumFractionDigits: 0 })
}

function renderStatisticsData(data) {
    var economyEl = document.getElementById("stat-economy-total")
    var topListEl = document.getElementById("stat-top-money-list")
    var reportsPlaceholder = document.getElementById("stat-reports-placeholder")
    var reportsBox = document.getElementById("stat-reports-box")
    var resourcesAlert = document.getElementById("stat-resources-alert")
    var resourcesCountEl = document.getElementById("stat-resources-count")
    var resourcesListEl = document.getElementById("stat-resources-list")
    var searchInput = document.getElementById("stat-resources-search")
    if (!data) {
        if (economyEl) economyEl.textContent = "0"
        if (topListEl) topListEl.innerHTML = ""
        if (reportsBox) reportsBox.classList.add("hidden")
        if (reportsPlaceholder) { reportsPlaceholder.classList.remove("hidden"); reportsPlaceholder.textContent = "Sin datos" }
        if (resourcesCountEl) resourcesCountEl.textContent = "0"
        if (resourcesListEl) resourcesListEl.innerHTML = ""
        if (resourcesAlert) resourcesAlert.classList.add("hidden")
        return
    }
    window.statisticsData = data
    if (economyEl) economyEl.textContent = formatMoney(data.economyTotal || 0)
    var topMoney = data.topMoney || []
    if (topListEl) {
        topListEl.innerHTML = topMoney.length === 0 ? "<li class=\"estadisticas-empty\">No hay jugadores</li>" : topMoney.map(function(p) {
            return "<li><span class=\"estadisticas-top-name\">" + (p.name || "—").replace(/</g, "&lt;") + "</span><span class=\"estadisticas-top-value\">" + formatMoney(p.total) + "</span></li>"
        }).join("")
    }
    var jobs = data.jobsOnline || {}
    var policeN = document.getElementById("stat-job-police-n")
    var emsN = document.getElementById("stat-job-ems-n")
    var mechanicN = document.getElementById("stat-job-mechanic-n")
    var taxiN = document.getElementById("stat-job-taxi-n")
    if (policeN) policeN.textContent = jobs.police != null ? jobs.police : 0
    if (emsN) emsN.textContent = jobs.ems != null ? jobs.ems : 0
    if (mechanicN) mechanicN.textContent = jobs.mechanic != null ? jobs.mechanic : 0
    if (taxiN) taxiN.textContent = jobs.taxi != null ? jobs.taxi : 0
    var reports = data.reportsStats
    if (reportsPlaceholder) reportsPlaceholder.classList.toggle("hidden", !!reports)
    if (reportsBox) reportsBox.classList.toggle("hidden", !reports)
    if (reports) {
        var totalEl = document.getElementById("stat-reports-total")
        var openEl = document.getElementById("stat-reports-open")
        var closedEl = document.getElementById("stat-reports-closed")
        var todayEl = document.getElementById("stat-reports-today")
        if (totalEl) totalEl.textContent = reports.total != null ? reports.total : 0
        if (openEl) openEl.textContent = reports.open != null ? reports.open : 0
        if (closedEl) closedEl.textContent = reports.closed != null ? reports.closed : 0
        if (todayEl) todayEl.textContent = reports.today != null ? reports.today : 0
    }
    var count = data.resourceCount != null ? data.resourceCount : 0
    if (resourcesAlert) {
        resourcesAlert.classList.toggle("hidden", !data.resourceAlert)
        var alertCountEl = document.getElementById("stat-resources-alert-count")
        if (alertCountEl) alertCountEl.textContent = count
    }
    var resourcesMetaEl = document.getElementById("stat-resources-meta")
    if (resourcesMetaEl) resourcesMetaEl.classList.toggle("hidden", !!data.resourceAlert)
    if (resourcesCountEl) resourcesCountEl.textContent = count
    var resources = data.resources || []
    var query = (searchInput && searchInput.value) ? String(searchInput.value).trim().toLowerCase() : ""
    var filtered = query ? resources.filter(function(r) { return (r.name || "").toLowerCase().indexOf(query) !== -1 }) : resources
    if (resourcesListEl) {
        var items = filtered.slice(0, 100).map(function(r) {
            var state = (r.state || "unknown").toLowerCase()
            var stateCls = state === "started" ? "estadisticas-res-state-started" : "estadisticas-res-state-stopped"
            return "<li class=\"estadisticas-res-item\"><span class=\"estadisticas-res-name\">" + (r.name || "").replace(/</g, "&lt;") + "</span><span class=\"estadisticas-res-state " + stateCls + "\">" + state + "</span></li>"
        })
        if (filtered.length > 100) items.push("<li class=\"estadisticas-res-more\">+ " + (filtered.length - 100) + " más (usa el buscador)</li>")
        resourcesListEl.innerHTML = items.length === 0 ? "<li class=\"estadisticas-empty\">Ningún recurso</li>" : items.join("")
    }
}

function updateStatisticsResourcesFilter() {
    if (window.statisticsData && typeof renderStatisticsData === "function") renderStatisticsData(window.statisticsData)
}

function requestPlayerStatsHistory(days) {
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
    fetch("https://" + resName + "/requestPlayerStatsHistory", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ days: days || 7 })
    }).catch(function() {})
}

var statPlayersChartInstance = null

function formatPlayerStatLabel(t) {
    if (t == null || t === "") return ""
    if (typeof t === "number") {
        var d = new Date(t < 1e12 ? t * 1000 : t)
        if (isNaN(d.getTime())) return String(t)
        var day = d.getDate()
        var mon = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"][d.getMonth()]
        var h = d.getHours()
        var m = d.getMinutes()
        return day + " " + mon + " " + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }
    var s = String(t).trim()
    if (!s) return ""
    var match = s.match(/^(\d{4})-(\d{2})-(\d{2})[T\s](\d{1,2}):(\d{2})/)
    if (match) {
        var day = parseInt(match[3], 10)
        var mon = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"][parseInt(match[2], 10) - 1]
        var h = parseInt(match[4], 10)
        var m = parseInt(match[5], 10)
        return day + " " + mon + " " + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }
    return s.replace("T", " ").substring(0, 16)
}

function renderPlayerStatsChart(data) {
    var points = (data && data.points) ? data.points : []
    var maxVal = (data && data.max != null) ? data.max : 0
    var avgVal = (data && data.avg != null) ? data.avg : 0
    var maxEl = document.getElementById("stat-players-max")
    var avgEl = document.getElementById("stat-players-avg")
    var subtitleEl = document.getElementById("stat-players-subtitle")
    var rangeSel = document.getElementById("stat-players-range")
    var days = (rangeSel && rangeSel.value) ? parseInt(rangeSel.value, 10) : 7
    if (maxEl) maxEl.textContent = maxVal
    if (avgEl) avgEl.textContent = avgVal
    if (subtitleEl && window.t) {
        if (days === 1) subtitleEl.textContent = window.t("stats_players_chart_subtitle_24")
        else if (days === 30) subtitleEl.textContent = window.t("stats_players_chart_subtitle_30")
        else subtitleEl.textContent = window.t("stats_players_chart_subtitle")
    }
    var canvas = document.getElementById("stat-players-chart")
    if (!canvas) return
    if (statPlayersChartInstance) {
        statPlayersChartInstance.destroy()
        statPlayersChartInstance = null
    }
    var labels = points.map(function(p) { return formatPlayerStatLabel(p.t) })
    var values = points.map(function(p) { return p.count != null ? p.count : 0 })
    var yMax = Math.max(maxVal + 2, 5)
    var themeEl = document.getElementById("tablet") || document.documentElement
    var computed = getComputedStyle(themeEl)
    var chartLine = (computed.getPropertyValue("--jc-chart-line") || computed.getPropertyValue("--jc-accent") || "#6fabc5").trim()
    var chartFill = (computed.getPropertyValue("--jc-chart-fill") || computed.getPropertyValue("--jc-chart-area-fill") || "rgba(111, 171, 197, 0.25)").trim()
    var chartGrid = (computed.getPropertyValue("--jc-chart-grid") || "rgba(255,255,255,0.06)").trim()
    var chartTicks = (computed.getPropertyValue("--jc-chart-ticks") || "rgba(255,255,255,0.6)").trim()
    statPlayersChartInstance = new Chart(canvas, {
        type: "line",
        data: {
            labels: labels,
            datasets: [{
                label: "Jugadores",
                data: values,
                fill: true,
                borderColor: chartLine,
                backgroundColor: chartFill,
                tension: 0.3,
                pointRadius: 0,
                pointHoverRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: {
                    grid: { color: chartGrid },
                    ticks: { color: chartTicks, maxTicksLimit: 14, font: { size: 11 } }
                },
                y: {
                    min: 0,
                    suggestedMax: yMax,
                    grid: { color: chartGrid },
                    ticks: {
                        color: chartTicks,
                        stepSize: 1,
                        callback: function(v) { return Number.isInteger(v) ? v : "" }
                    }
                }
            }
        }
    })
}

function updateBansFilterPill() {
    var filterBtns = document.getElementById("bans-filter-btns")
    var pill = document.getElementById("bans-filter-pill")
    if (!filterBtns || !pill) return
    var activeBtn = filterBtns.querySelector(".bans-filter-btn.active")
    if (!activeBtn) return
    var cr = filterBtns.getBoundingClientRect()
    var br = activeBtn.getBoundingClientRect()
    var left = Math.round(br.left - cr.left) - 4
    var width = Math.round(br.width)
    filterBtns.style.setProperty("--bans-pill-width", width + "px")
    filterBtns.style.setProperty("--bans-pill-left", Math.max(0, left) + "px")
}

function renderPlayersList() {
    const data = window.playersListData || { online: [], offline: [] }
    const filter = window.playersFilter || "all"
    const query = (document.getElementById("players-search") && document.getElementById("players-search").value) ? String(document.getElementById("players-search").value).trim().toLowerCase() : ""
    let list = []
    if (filter === "online") list = data.online.slice()
    else if (filter === "offline") list = data.offline.slice()
    else list = data.online.slice().concat(data.offline.slice())
    if (query) {
        list = list.filter(function(p) {
            const idStr = String(p.id || "")
            const nameStr = String(p.name || "").toLowerCase()
            const identStr = String(p.identifier || "").toLowerCase()
            return idStr.indexOf(query) !== -1 || nameStr.indexOf(query) !== -1 || identStr.indexOf(query) !== -1
        })
    }
    const listEl = document.getElementById("players-list")
    const placeholderEl = document.getElementById("players-list-placeholder")
    if (!listEl) return
    if (list.length === 0) {
        listEl.innerHTML = ""
        if (placeholderEl) {
            placeholderEl.classList.remove("hidden")
            placeholderEl.textContent = "No hay jugadores"
        }
        return
    }
    if (placeholderEl) placeholderEl.classList.add("hidden")
    var sp = window.sectionPerms || {}
    var banAllowed = sp.ban === true || sp.ban === "1" || sp.ban === 1
    listEl.innerHTML = list.map(function(p) {
        const online = p.online === true
        const idPart = online ? ("<span class=\"players-item-id\">#" + ((p.id != null) ? p.id : "") + "</span>") : "<span class=\"players-item-id players-item-id-offline\" title=\"Offline\"><i class=\"fa-solid fa-user-slash\"></i></span>"
        const idRaw = online ? String(p.id != null ? p.id : "") : ""
        const identRaw = (!online && p.identifier) ? String(p.identifier) : ""
        const identAttr = identRaw ? encodeURIComponent(identRaw) : ""
        const namePlain = String(p.name || "Unknown")
        const name = namePlain.replace(/</g, "&lt;")
        const nameAttr = encodeURIComponent(namePlain)
        const ping = (p.ping != null) ? p.ping : ""
        const pingHtml = (online && ping !== "") ? "<span class=\"players-item-ping\">" + ping + " ms</span>" : ""
        var configOfflineClass = (!online && !identRaw) ? " players-item-btn-config-offline" : ""
        var banBtnClass = "players-item-btn players-item-btn-ban" + (banAllowed ? "" : " players-item-btn-ban-no-permission")
        var banDisabled = !banAllowed
        var itemClass = "players-list-item" + (online ? "" : " players-list-item-offline")
        var cfgTitle = online ? "Config" : (identRaw ? "Config" : "Offline")
        var banTitle = banAllowed ? (online ? "Banear" : "Banear (offline)") : "Sin permiso"
        return "<li class=\"" + itemClass + "\"><div class=\"players-item-container\"><span class=\"players-item-id-name\">" + idPart + "<span class=\"players-item-name\">" + name + "</span></span><span class=\"players-item-actions\"><button type=\"button\" class=\"players-item-btn players-item-btn-config" + configOfflineClass + "\" data-player-id=\"" + idRaw + "\" data-player-identifier=\"" + identAttr + "\" data-player-online=\"" + (online ? "1" : "0") + "\" title=\"" + cfgTitle + "\" aria-label=\"Config\"><i class=\"fa-solid fa-gear\"></i></button><button type=\"button\" class=\"" + banBtnClass + "\" data-player-id=\"" + idRaw + "\" data-player-identifier=\"" + identAttr + "\" data-player-display-name=\"" + nameAttr + "\" data-player-online=\"" + (online ? "1" : "0") + "\" title=\"" + banTitle + "\" aria-label=\"Banear\" " + (banDisabled ? "disabled " : "") + "><i class=\"fa-solid fa-ban\"></i></button></span>" + pingHtml + "</div></li>"
    }).join("")
}

;(function() {
    const searchEl = document.getElementById("players-search")
    if (searchEl) {
        searchEl.addEventListener("input", function() {
            if (typeof renderPlayersList === "function") renderPlayersList()
        })
        searchEl.addEventListener("keydown", function(e) {
            if (e.key === "Escape") { searchEl.value = ""; if (typeof renderPlayersList === "function") renderPlayersList() }
        })
    }
    var filterBtns = document.getElementById("players-filter-btns")
    var filterPill = document.getElementById("players-filter-pill")
    function updatePlayersFilterPill() {
        if (!filterBtns || !filterPill) return
        var activeBtn = filterBtns.querySelector(".players-filter-btn.active")
        if (!activeBtn) return
        var left = Math.max(0, activeBtn.offsetLeft - 3)
        var width = activeBtn.offsetWidth
        filterBtns.style.setProperty("--players-pill-width", width + "px")
        filterBtns.style.setProperty("--players-pill-left", left + "px")
    }
    var filterPillHover = document.getElementById("players-filter-pill-hover")
    function moveHoverPillToButton(btn) {
        if (!filterBtns || !filterPillHover || !btn) return
        var left = Math.max(0, btn.offsetLeft - 3)
        var width = btn.offsetWidth
        filterBtns.style.setProperty("--players-hover-pill-width", width + "px")
        filterBtns.style.setProperty("--players-hover-pill-left", left + "px")
        filterPillHover.classList.add("players-filter-hover-visible")
    }
    function hideHoverPill() {
        if (filterPillHover) filterPillHover.classList.remove("players-filter-hover-visible")
    }
    document.querySelectorAll(".players-filter-btn").forEach(function(btn) {
        btn.addEventListener("mouseenter", function() {
            moveHoverPillToButton(btn)
        })
        btn.addEventListener("mouseleave", function() {
            hideHoverPill()
        })
        btn.addEventListener("click", function() {
            var filter = btn.getAttribute("data-filter") || "all"
            window.playersFilter = filter
            document.querySelectorAll(".players-filter-btn").forEach(function(b) { b.classList.remove("active") })
            btn.classList.add("active")
            updatePlayersFilterPill()
            if (typeof renderPlayersList === "function") renderPlayersList()
        })
    })
    window.updatePlayersFilterPill = updatePlayersFilterPill
    requestAnimationFrame(function() { updatePlayersFilterPill() })
    setTimeout(updatePlayersFilterPill, 50)
})()

function moveActiveBackground(target) {
    if (!menu || !target) return

    const menuRect = menu.getBoundingClientRect()
    const liRect = target.getBoundingClientRect()

    const pillHeight = 44
    const offset = liRect.top - menuRect.top + (liRect.height - pillHeight) / 2

    menu.style.setProperty("--active-offset", Math.round(offset) + "px")
}

const initialActive = document.querySelector(".menu li.active")
if (initialActive) {
    requestAnimationFrame(() => moveActiveBackground(initialActive))
}

var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
menuItems.forEach(item => {
    item.addEventListener("click", () => {
        if (item.classList.contains("sidebar-section-hidden")) return
        var prevPageEl = document.querySelector(".page.active")
        var previousPageId = prevPageEl ? prevPageEl.id : null
        var terminalWasActive = document.getElementById("terminal") && document.getElementById("terminal").classList.contains("active")
        var pageId = item.dataset.page
        if (terminalWasActive && pageId !== "terminal") {
            fetch("https://" + resName + "/terminalPageClosed", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
        }
        menuItems.forEach(i => i.classList.remove("active"))
        pages.forEach(p => p.classList.remove("active"))

        item.classList.add("active")
        const pageEl = document.getElementById(pageId)
        if (pageEl) pageEl.classList.add("active")
        if (pageId === "terminal") {
            if (typeof requestTerminalResources === "function") requestTerminalResources()
            fetch("https://" + resName + "/terminalPageOpened", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
        }
        if (pageId === "estadisticas") {
            fetch("https://" + resName + "/requestStatisticsData", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
            if (typeof requestPlayerStatsHistory === "function") requestPlayerStatsHistory(window.statPlayersRangeDays || 7)
            var statSearch = document.getElementById("stat-resources-search")
            if (statSearch && !statSearch._statBound) {
                statSearch._statBound = true
                statSearch.addEventListener("input", function() { if (typeof updateStatisticsResourcesFilter === "function") updateStatisticsResourcesFilter() })
            }
            var statRangeSel = document.getElementById("stat-players-range")
            if (statRangeSel && !statRangeSel._statBound) {
                statRangeSel._statBound = true
                statRangeSel.addEventListener("change", function() {
                    var days = parseInt(statRangeSel.value, 10) || 7
                    window.statPlayersRangeDays = days
                    if (typeof requestPlayerStatsHistory === "function") requestPlayerStatsHistory(days)
                })
            }
        }

        moveActiveBackground(item)
        if (previousPageId === "settings" && pageId !== "settings") {
            var saved = window.savedInterfaceColorPrimary
            if (saved === "#6fabc5" || !saved) {
                if (typeof resetInterfaceColor === "function") resetInterfaceColor()
            } else if (typeof applyInterfaceColor === "function") {
                applyInterfaceColor(saved)
            }
        }
        if (pageId === "dashboard" && window.dashboardMonthlyChartData) {
            setTimeout(function() {
                window.dispatchEvent(new MessageEvent("message", { data: { action: "setDashboardMonthlyChart", data: window.dashboardMonthlyChartData } }))
            }, 80)
        }
        if (pageId === "logs") {
            var logTypeSel = document.getElementById("logs-type-select")
            var logSearchEl = document.getElementById("logs-search")
            var logType = (logTypeSel && logTypeSel.value) ? logTypeSel.value : "all"
            var search = (logSearchEl && logSearchEl.value) ? String(logSearchEl.value).trim() : ""
            fetch("https://" + GetParentResourceName() + "/requestLogsList", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ logType: logType, search: search })
            }).catch(function() {})
        }
        if (pageId === "bans") {
            fetch("https://" + GetParentResourceName() + "/requestBansList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
            requestAnimationFrame(function() { if (typeof updateBansFilterPill === "function") updateBansFilterPill() })
            setTimeout(function() { if (typeof updateBansFilterPill === "function") updateBansFilterPill() }, 80)
            var bansAddOfflineBtn = document.getElementById("bans-add-offline-btn")
            if (bansAddOfflineBtn) {
                var sp = window.sectionPerms || {}
                var canBan = sp.ban === true || sp.ban === "1" || sp.ban === 1
                bansAddOfflineBtn.classList.toggle("bans-add-offline-btn-no-permission", !canBan)
                bansAddOfflineBtn.setAttribute("data-perm-allowed", canBan ? "true" : "false")
            }
            var bansListEl = document.getElementById("bans-list")
            if (bansListEl && !bansListEl._bansBound) {
                bansListEl._bansBound = true
                bansListEl.addEventListener("click", function(e) {
                    var unbanBtn = e.target && e.target.closest && e.target.closest(".bans-item-btn-unban")
                    if (unbanBtn) {
                        if (unbanBtn.getAttribute("data-perm-allowed") === "false") return
                        var banId = unbanBtn.getAttribute("data-ban-id")
                        if (banId && typeof window.openUnbanConfirmModal === "function") window.openUnbanConfirmModal(banId)
                        return
                    }
                    var editBtn = e.target && e.target.closest && e.target.closest(".bans-item-btn-edit")
                    if (editBtn) {
                        if (editBtn.getAttribute("data-perm-allowed") === "false") return
                        var banId = editBtn.getAttribute("data-ban-id")
                        if (!banId) return
                        var data = window.bansListData || []
                        var ban = data.find(function(b) { return String(b.id) === String(banId) })
                        if (ban && typeof window.openBanModal === "function") window.openBanModal(null, ban)
                    }
                })
            }
        }
        if (pageId === "players") {
            var listView = document.getElementById("players-list-view")
            var detailView = document.getElementById("player-detail-view")
            if (listView) listView.classList.remove("hidden")
            if (detailView) detailView.classList.add("hidden")
            if (typeof renderPlayersList === "function") renderPlayersList()
            var listEl = document.getElementById("players-list")
            if (listEl && !listEl._playerDetailBound) {
                listEl._playerDetailBound = true
                listEl.addEventListener("click", function(e) {
                    var cfgBtn = e.target && e.target.closest && e.target.closest(".players-item-btn-config:not(.players-item-btn-config-offline)")
                    if (cfgBtn) {
                        var _cuin = typeof window.preparePlayerDetailRequest === "function" ? window.preparePlayerDetailRequest() : 0
                        var onlineCfg = cfgBtn.getAttribute("data-player-online") === "1"
                        if (onlineCfg) {
                            var id = cfgBtn.getAttribute("data-player-id")
                            if (id) {
                                fetch("https://" + GetParentResourceName() + "/requestPlayerDetails", {
                                    method: "POST",
                                    headers: { "Content-Type": "application/json" },
                                    body: JSON.stringify({ playerId: id, uiNonce: _cuin })
                                }).catch(function() {})
                            }
                        } else {
                            var oi = cfgBtn.getAttribute("data-player-identifier")
                            if (oi) {
                                try {
                                    oi = decodeURIComponent(oi)
                                } catch (e1) { oi = "" }
                                if (oi) {
                                    fetch("https://" + GetParentResourceName() + "/requestPlayerDetails", {
                                        method: "POST",
                                        headers: { "Content-Type": "application/json" },
                                        body: JSON.stringify({ offlineIdentifier: oi, uiNonce: _cuin })
                                    }).catch(function() {})
                                }
                            }
                        }
                        return
                    }
                    var banBtn = e.target && e.target.closest && e.target.closest(".players-item-btn-ban:not(.players-item-btn-ban-no-permission)")
                    if (banBtn) {
                        var onlineBan = banBtn.getAttribute("data-player-online") === "1"
                        if (onlineBan) {
                            var banId = banBtn.getAttribute("data-player-id")
                            if (banId != null && typeof window.openBanModal === "function") window.openBanModal(banId)
                        } else {
                            var boi = banBtn.getAttribute("data-player-identifier")
                            var bname = banBtn.getAttribute("data-player-display-name")
                            if (boi && typeof window.openBanModal === "function") {
                                try { boi = decodeURIComponent(boi) } catch (e2) { boi = "" }
                                try { bname = bname ? decodeURIComponent(bname) : "" } catch (e3) { bname = "" }
                                if (boi) window.openBanModal(null, null, { player_name: bname || "", banFrameworkIdentifier: boi })
                            }
                        }
                    }
                })
            }
            fetch(`https://${GetParentResourceName()}/playersRequestList`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            }).catch(function() {})
            requestAnimationFrame(function() {
                if (typeof window.updatePlayersFilterPill === "function") window.updatePlayersFilterPill()
            })
            setTimeout(function() {
                if (typeof window.updatePlayersFilterPill === "function") window.updatePlayersFilterPill()
            }, 80)
        }
        if (pageId === "settings") {
            if (typeof window.requestSettingsProfile === "function") window.requestSettingsProfile()
            if (typeof window.applyKickActionsSavedBinds === "function") window.applyKickActionsSavedBinds()
        }
    })
})

function formatAdminTime(totalSeconds) {
    var sec = parseInt(totalSeconds, 10)
    if (isNaN(sec) || sec < 0) return "0 h 0 min"
    var h = Math.floor(sec / 3600)
    var m = Math.floor((sec % 3600) / 60)
    if (h > 0 && m > 0) return h + " h " + m + " min"
    if (h > 0) return h + " h"
    if (m > 0) return m + " min"
    return sec + " s"
}

function requestSettingsProfile() {
    fetch("https://" + GetParentResourceName() + "/getProfile", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    }).then(function(r) { return r.json() }).then(function(profile) {
        if (!profile || typeof profile !== "object") return
        window._settingsProfileLicense = profile.license || null
        var nameEl = document.getElementById("settings-profile-name")
        if (nameEl) nameEl.textContent = profile.username || profile.user || "—"
        var avatarImg = document.getElementById("settings-avatar-img")
        var avatarPlaceholder = document.getElementById("settings-avatar-placeholder")
        var avatarUrl = profile.avatar && String(profile.avatar).trim()
        if (avatarImg && avatarPlaceholder) {
            if (avatarUrl) {
                avatarImg.onerror = function() {
                    avatarImg.classList.add("hidden")
                    avatarPlaceholder.classList.remove("hidden")
                }
                avatarImg.onload = function() {
                    avatarImg.classList.remove("hidden")
                    avatarPlaceholder.classList.add("hidden")
                }
                avatarImg.classList.add("hidden")
                avatarPlaceholder.classList.remove("hidden")
                avatarImg.src = avatarUrl
            } else {
                avatarImg.src = ""
                avatarImg.classList.add("hidden")
                avatarPlaceholder.classList.remove("hidden")
            }
            var wrap = document.getElementById("settings-avatar-wrap")
            if (wrap) wrap.setAttribute("data-current-url", avatarUrl || "")
        }
        var timeEl = document.getElementById("settings-admin-time")
        if (timeEl) timeEl.textContent = formatAdminTime(profile.total_admin_seconds)
        var rangoEl = document.getElementById("settings-rango")
        if (rangoEl) rangoEl.textContent = (profile.group && String(profile.group).trim()) ? String(profile.group).trim() : "—"
        var pwEl = document.getElementById("settings-password-display")
        if (pwEl) {
            pwEl.dataset.realPassword = (profile.password != null && profile.password !== undefined) ? String(profile.password) : ""
            pwEl.value = ""
            pwEl.placeholder = "••••••••"
            pwEl.type = "password"
        }
        var iconEl = document.getElementById("settings-password-icon")
        if (iconEl) {
            iconEl.className = "fa-solid fa-eye-slash"
        }
        var s = profile.settings || {}
        var tags = s.tags || {}
        var lineasEl = document.getElementById("settings-tags-lineas")
        var cajasEl = document.getElementById("settings-tags-cajas")
        var nombresEl = document.getElementById("settings-tags-nombres")
        var infoEl = document.getElementById("settings-tags-info")
        if (lineasEl) lineasEl.checked = tags.lineas === true
        if (cajasEl) cajasEl.checked = tags.cajas === true
        if (nombresEl) nombresEl.checked = tags.nombres === true
        if (infoEl) infoEl.checked = tags.info === true
        var distEl = document.getElementById("settings-tags-distancia")
        if (distEl) {
            distEl.value = String(clampEspDistanciaUi(tags.distancia != null ? tags.distancia : 600))
            updateSettingsEspDistanciaDisplay()
        }
        var prim = (s.color_primary && /^#[0-9A-Fa-f]{6}$/.test(s.color_primary)) ? s.color_primary : "#6fabc5"
        var sec = (s.color_secondary && /^#[0-9A-Fa-f]{6}$/.test(s.color_secondary)) ? s.color_secondary : "#334155"
        var ter = (s.color_tertiary && /^#[0-9A-Fa-f]{6}$/.test(s.color_tertiary)) ? s.color_tertiary : "#1e293b"
        var primColor = document.getElementById("settings-color-primary")
        var primHex = document.getElementById("settings-color-primary-hex")
        var secColor = document.getElementById("settings-color-secondary")
        var secHex = document.getElementById("settings-color-secondary-hex")
        var terColor = document.getElementById("settings-color-tertiary")
        var terHex = document.getElementById("settings-color-tertiary-hex")
        if (primColor) primColor.value = prim
        if (primHex) primHex.value = prim
        if (secColor) secColor.value = sec
        if (secHex) secHex.value = sec
        if (terColor) terColor.value = ter
        if (terHex) terHex.value = ter
        if (prim === "#6fabc5" && typeof resetInterfaceColor === "function") {
            resetInterfaceColor()
        } else {
            applyInterfaceColor(prim)
        }
        window.savedInterfaceColorPrimary = prim
    }).catch(function() {})
}

function clampEspDistanciaUi(n) {
    var x = parseInt(n, 10)
    if (isNaN(x)) return 600
    if (x < 50) return 50
    if (x > 2000) return 2000
    return x
}

function updateSettingsEspDistanciaDisplay() {
    var el = document.getElementById("settings-tags-distancia")
    var disp = document.getElementById("settings-tags-distancia-display")
    if (!el || !disp) return
    var v = clampEspDistanciaUi(el.value)
    el.value = String(v)
    disp.textContent = v + " m"
}

function getSettingsPayload() {
    var tags = {}
    var lineasEl = document.getElementById("settings-tags-lineas")
    var cajasEl = document.getElementById("settings-tags-cajas")
    var nombresEl = document.getElementById("settings-tags-nombres")
    var infoEl = document.getElementById("settings-tags-info")
    var distEl = document.getElementById("settings-tags-distancia")
    if (lineasEl) tags.lineas = lineasEl.checked
    if (cajasEl) tags.cajas = cajasEl.checked
    if (nombresEl) tags.nombres = nombresEl.checked
    if (infoEl) tags.info = infoEl.checked
    if (distEl) tags.distancia = clampEspDistanciaUi(distEl.value)
    var primHex = document.getElementById("settings-color-primary-hex")
    var secHex = document.getElementById("settings-color-secondary-hex")
    var terHex = document.getElementById("settings-color-tertiary-hex")
    var prim = (primHex && primHex.value && /^#[0-9A-Fa-f]{6}$/.test(primHex.value)) ? primHex.value : "#6fabc5"
    var sec = (secHex && secHex.value && /^#[0-9A-Fa-f]{6}$/.test(secHex.value)) ? secHex.value : "#334155"
    var ter = (terHex && terHex.value && /^#[0-9A-Fa-f]{6}$/.test(terHex.value)) ? terHex.value : "#1e293b"
    return { tags: tags, color_primary: prim, color_secondary: sec, color_tertiary: ter }
}

function mixColor(hex, baseR, baseG, baseB, amount) {
    var n = parseInt(hex.slice(1), 16)
    var r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255
    r = Math.round(amount * r + (1 - amount) * baseR)
    g = Math.round(amount * g + (1 - amount) * baseG)
    b = Math.round(amount * b + (1 - amount) * baseB)
    return "#" + (0x1000000 + (r << 16) + (g << 8) + b).toString(16).slice(1)
}
function mixColorRgba(hex, baseR, baseG, baseB, amount, alpha) {
    var n = parseInt(hex.slice(1), 16)
    var r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255
    r = Math.round(amount * r + (1 - amount) * baseR)
    g = Math.round(amount * g + (1 - amount) * baseG)
    b = Math.round(amount * b + (1 - amount) * baseB)
    return "rgba(" + r + "," + g + "," + b + "," + alpha + ")"
}
function hexToRgba(hex, alpha) {
    var n = parseInt(hex.slice(1), 16)
    var r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255
    return "rgba(" + r + "," + g + "," + b + "," + alpha + ")"
}
function applyInterfaceColor(hex) {
    var tabletEl = document.getElementById("tablet")
    if (!hex || !/^#[0-9A-Fa-f]{6}$/.test(hex)) return
    var accentBorder = mixColor(hex, 10, 12, 17, 0.38)
    if (tabletEl) {
        tabletEl.style.setProperty("--jc-accent", hex)
        tabletEl.style.setProperty("--jc-chart-area-fill", hexToRgba(hex, 0.12))
        tabletEl.style.setProperty("--jc-chart-line", hex)
        tabletEl.style.setProperty("--jc-chart-fill", hexToRgba(hex, 0.25))
        tabletEl.style.setProperty("--jc-chart-grid", "rgba(255, 255, 255, 0.06)")
        tabletEl.style.setProperty("--jc-chart-ticks", "rgba(255, 255, 255, 0.6)")
        tabletEl.style.setProperty("--jc-accent-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-accent-bg2", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-accent-border", accentBorder)
        tabletEl.style.setProperty("--jc-accent-bg-cmd", mixColor(hex, 10, 12, 17, 0.26))
        tabletEl.style.setProperty("--jc-content-bg", mixColorRgba(hex, 11, 15, 22, 0.16, 0.99))
        tabletEl.style.setProperty("--jc-content-border", mixColor(hex, 11, 13, 17, 0.07))
        tabletEl.style.setProperty("--jc-text-primary", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-text-secondary", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-text-muted", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-text-muted-dark", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-staff-item-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-divider", hexToRgba(hex, 0.10))
        tabletEl.style.setProperty("--jc-players-search-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-players-search-border", accentBorder)
        tabletEl.style.setProperty("--jc-players-search-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-players-search-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-players-search-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-players-filter-border", accentBorder)
        tabletEl.style.setProperty("--jc-players-filter-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-players-filter-pill", mixColor(hex, 20, 30, 40, 0.70))
        tabletEl.style.setProperty("--jc-players-filter-pill-hover", hexToRgba(hex, 0.164))
        tabletEl.style.setProperty("--jc-players-filter-btn", mixColor(hex, 207, 212, 219, 0.25))
        tabletEl.style.setProperty("--jc-players-filter-btn-hover", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-players-list-wrap-border", accentBorder)
        tabletEl.style.setProperty("--jc-players-list-wrap-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-players-item-container-border", accentBorder)
        tabletEl.style.setProperty("--jc-players-item-container-bg", mixColor(hex, 15, 19, 25, 0.18))
        tabletEl.style.setProperty("--jc-players-item-id", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-players-item-name", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-players-item-offline", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-players-item-btn-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-players-item-btn-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-players-item-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-players-item-btn-hover-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-players-item-btn-disabled-bg", mixColorRgba(hex, 30, 41, 59, 0.20, 0.6))
        tabletEl.style.setProperty("--jc-players-item-btn-disabled-color", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-players-ping", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-players-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-map-list-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-map-list-border", accentBorder)
        tabletEl.style.setProperty("--jc-map-list-header-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-map-list-header-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-map-list-chevron", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-map-list-inner-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-map-list-inner-border", accentBorder)
        tabletEl.style.setProperty("--jc-map-list-scroll-track", mixColor(hex, 15, 23, 42, 0.95))
        tabletEl.style.setProperty("--jc-map-list-scroll-thumb", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-map-list-scroll-thumb-hover", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-map-list-scroll-thumb-active", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-map-item-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-map-item-hover-bg", mixColorRgba(hex, 30, 41, 59, 0.25, 0.25))
        tabletEl.style.setProperty("--jc-map-item-avatar-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-map-item-id", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-map-ping-unknown", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-map-empty-color", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-sidebar-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-back-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-player-detail-back-hover-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-avatar-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-player-detail-avatar-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-avatar-fallback-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-name-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-field-bg", mixColor(hex, 15, 19, 25, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-field-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-field-icon-bg", mixColor(hex, 10, 12, 17, 0.42))
        tabletEl.style.setProperty("--jc-player-detail-field-icon-color", mixColor(hex, 176, 188, 204, 0.5))
        tabletEl.style.setProperty("--jc-player-detail-field-label-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-player-detail-field-value-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-section-title-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-section-title-add-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-section-title-add-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-spectate-stop-bg", hexToRgba(hex, 0.2))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-spectate-stop-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-freeze-active-bg", hexToRgba(hex, 0.2))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-freeze-active-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-noperm-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-player-detail-fn-btn-noperm-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-table-scroll-track-bg", mixColorRgba(hex, 15, 23, 42, 0.25, 0.6))
        tabletEl.style.setProperty("--jc-player-detail-table-scroll-thumb-start", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-player-detail-table-scroll-thumb-end", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-table-scroll-thumb-active", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-table-wrap-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-table-wrap-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-player-detail-table-th-color", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-table-th-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-table-td-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-player-detail-table-td-bg", mixColorRgba(hex, 15, 23, 42, 0.20, 0.5))
        tabletEl.style.setProperty("--jc-player-detail-table-td-border", accentBorder)
        tabletEl.style.setProperty("--jc-player-detail-table-remove-btn-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-player-detail-empty-text", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-player-detail-empty-icon", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-logs-search-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-logs-search-border", accentBorder)
        tabletEl.style.setProperty("--jc-logs-search-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-logs-search-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-logs-search-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-logs-search-focus-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-logs-type-select-border", accentBorder)
        tabletEl.style.setProperty("--jc-logs-type-select-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-logs-type-select-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-logs-type-select-hover-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-logs-list-wrap-border", accentBorder)
        tabletEl.style.setProperty("--jc-logs-list-wrap-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-logs-identifiers-color", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-logs-identifiers-border", accentBorder)
        tabletEl.style.setProperty("--jc-logs-identifiers-label-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-logs-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-logs-pagination-btn-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-logs-pagination-btn-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-logs-pagination-btn-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-logs-pagination-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-logs-pagination-btn-hover-border", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-logs-pagination-info", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-logs-card-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-logs-card-border", accentBorder)
        tabletEl.style.setProperty("--jc-logs-card-name-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-logs-card-expiry-color", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-logs-card-reason-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-logs-card-banned-by-color", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-groups-perms-summary", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-groups-btn-create-border", accentBorder)
        tabletEl.style.setProperty("--jc-groups-btn-create-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-groups-btn-create-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-groups-btn-create-hover-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-groups-btn-create-hover-border", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-groups-card-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-groups-card-border", accentBorder)
        tabletEl.style.setProperty("--jc-groups-card-icon-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-groups-card-icon-color", mixColor(hex, 20, 30, 40, 0.65))
        tabletEl.style.setProperty("--jc-groups-card-title", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-groups-card-badge", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-groups-card-btn-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-groups-card-btn-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-groups-card-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-groups-card-btn-hover-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-groups-perm-label", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-groups-perm-value-no", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-bans-search-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-bans-search-border", accentBorder)
        tabletEl.style.setProperty("--jc-bans-search-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-bans-search-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-bans-search-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-bans-filter-border", accentBorder)
        tabletEl.style.setProperty("--jc-bans-filter-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-bans-filter-pill", mixColor(hex, 95, 151, 175, 0.9))
        tabletEl.style.setProperty("--jc-bans-filter-pill-hover", hexToRgba(hex, 0.164))
        tabletEl.style.setProperty("--jc-bans-filter-btn", mixColor(hex, 207, 212, 219, 0.42))
        tabletEl.style.setProperty("--jc-bans-filter-btn-hover", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-bans-list-wrap-border", accentBorder)
        tabletEl.style.setProperty("--jc-bans-list-wrap-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-bans-card-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-bans-card-border", accentBorder)
        tabletEl.style.setProperty("--jc-bans-card-name", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-bans-card-expiry", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-bans-card-reason", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-bans-card-banned-by", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-bans-item-btn-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-bans-item-btn-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-bans-item-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.38))
        tabletEl.style.setProperty("--jc-bans-item-btn-hover-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-bans-item-btn-edit-hover-bg", hexToRgba(hex, 0.2))
        tabletEl.style.setProperty("--jc-bans-item-btn-edit-hover-color", mixColor(hex, 95, 130, 153, 0.9))
        tabletEl.style.setProperty("--jc-bans-item-btn-unban-hover-bg", "rgba(34, 197, 94, 0.2)")
        tabletEl.style.setProperty("--jc-bans-item-btn-unban-hover-color", "#22c55e")
        tabletEl.style.setProperty("--jc-bans-item-btn-noperm-hover-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-bans-item-btn-noperm-hover-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-bans-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-terminal-section-border", accentBorder)
        tabletEl.style.setProperty("--jc-terminal-section-bg", mixColor(hex, 10, 12, 17, 0.14))
        tabletEl.style.setProperty("--jc-terminal-section-title", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-terminal-section-title-border", accentBorder)
        tabletEl.style.setProperty("--jc-terminal-section-title-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-terminal-output-color", mixColor(hex, 203, 213, 225, 0.42))
        tabletEl.style.setProperty("--jc-terminal-output-bg", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-terminal-output-scroll-track", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-terminal-output-scroll-thumb", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-terminal-line-command", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-terminal-line-info", mixColor(hex, 203, 213, 225, 0.42))
        tabletEl.style.setProperty("--jc-terminal-line-success", "#22c55e")
        tabletEl.style.setProperty("--jc-terminal-line-error", "#ef4444")
        tabletEl.style.setProperty("--jc-terminal-line-warning", "#f59e0b")
        tabletEl.style.setProperty("--jc-terminal-input-wrap-bg", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-terminal-input-wrap-border", accentBorder)
        tabletEl.style.setProperty("--jc-terminal-prompt", mixColor(hex, 34, 197, 94, 0.9))
        tabletEl.style.setProperty("--jc-terminal-input-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-terminal-input-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-terminal-resources-search-bg", mixColorRgba(hex, 30, 41, 59, 0.8, 0.8))
        tabletEl.style.setProperty("--jc-terminal-resources-search-border", accentBorder)
        tabletEl.style.setProperty("--jc-terminal-resources-search-icon", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-terminal-resources-search-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-terminal-resources-search-placeholder", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-terminal-refresh-btn-bg", mixColorRgba(hex, 30, 41, 59, 0.8, 0.8))
        tabletEl.style.setProperty("--jc-terminal-refresh-btn-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-terminal-refresh-btn-hover-bg", mixColor(hex, 10, 12, 17, 0.22))
        tabletEl.style.setProperty("--jc-terminal-refresh-btn-hover-color", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-terminal-resources-list-scroll-track", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-terminal-resources-list-scroll-thumb", mixColor(hex, 71, 85, 105, 0.35))
        tabletEl.style.setProperty("--jc-terminal-resource-item-bg", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-terminal-resource-item-border", accentBorder)
        tabletEl.style.setProperty("--jc-terminal-resource-name", mixColor(hex, 226, 232, 240, 0.18))
        tabletEl.style.setProperty("--jc-terminal-resource-dot-started", "#22c55e")
        tabletEl.style.setProperty("--jc-terminal-resource-dot-stopped", "#ef4444")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-restart-bg", "rgba(245, 158, 11, 0.25)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-restart-color", "#f59e0b")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-restart-hover-bg", "rgba(245, 158, 11, 0.4)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-start-bg", "rgba(34, 197, 94, 0.25)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-start-color", "#22c55e")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-start-hover-bg", "rgba(34, 197, 94, 0.4)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-stop-bg", "rgba(239, 68, 68, 0.25)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-stop-color", "#ef4444")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-stop-hover-bg", "rgba(239, 68, 68, 0.4)")
        tabletEl.style.setProperty("--jc-terminal-resource-btn-noperm-hover-bg", mixColorRgba(hex, 30, 41, 59, 0.8, 0.8))
        tabletEl.style.setProperty("--jc-terminal-resource-btn-noperm-hover-color", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-terminal-loading-empty", mixColor(hex, 100, 116, 139, 0.38))
        tabletEl.style.setProperty("--jc-settings-btn-confirm-hover", mixColor(hex, 90, 154, 181, 0.9))
        tabletEl.style.setProperty("--jc-settings-toggle-track-bg", accentBorder)
        tabletEl.style.setProperty("--jc-settings-toggle-thumb-bg", mixColor(hex, 148, 163, 184, 0.42))
        tabletEl.style.setProperty("--jc-settings-commands-scroll-track", mixColorRgba(hex, 15, 23, 42, 0.6, 0.6))
        tabletEl.style.setProperty("--jc-settings-commands-scroll-thumb", mixColor(hex, 51, 65, 85, 0.35))
    }
    var kickActionsEl = document.getElementById("kick-actions")
    if (kickActionsEl) {
        kickActionsEl.style.setProperty("--jc-accent", hex)
        kickActionsEl.style.setProperty("--jc-accent-body-bg", mixColor(hex, 7, 10, 15, 0.06))
        kickActionsEl.style.setProperty("--jc-accent-bg", mixColor(hex, 10, 12, 17, 0.03))
        kickActionsEl.style.setProperty("--jc-accent-bg2", mixColor(hex, 10, 12, 17, 0.05))
        kickActionsEl.style.setProperty("--jc-accent-border", accentBorder)
        kickActionsEl.style.setProperty("--jc-accent-border-dark", mixColor(hex, 10, 12, 17, 0.12))
        kickActionsEl.style.setProperty("--jc-accent-hover", mixColor(hex, 10, 12, 17, 0.08))
        kickActionsEl.style.setProperty("--jc-accent-active-bg", hexToRgba(hex, 0.10))
        kickActionsEl.style.setProperty("--jc-accent-waiting-bg", hexToRgba(hex, 0.12))
    }
}

function resetInterfaceColor() {
    var tabletEl = document.getElementById("tablet")
    if (tabletEl && tabletEl.style) {
        tabletEl.style.removeProperty("--jc-accent")
        tabletEl.style.removeProperty("--jc-chart-area-fill")
        tabletEl.style.removeProperty("--jc-chart-line")
        tabletEl.style.removeProperty("--jc-chart-fill")
        tabletEl.style.removeProperty("--jc-chart-grid")
        tabletEl.style.removeProperty("--jc-chart-ticks")
        tabletEl.style.removeProperty("--jc-accent-bg")
        tabletEl.style.removeProperty("--jc-accent-bg2")
        tabletEl.style.removeProperty("--jc-accent-border")
        tabletEl.style.removeProperty("--jc-accent-bg-cmd")
        tabletEl.style.removeProperty("--jc-content-bg")
        tabletEl.style.removeProperty("--jc-content-border")
        tabletEl.style.removeProperty("--jc-text-primary")
        tabletEl.style.removeProperty("--jc-text-secondary")
        tabletEl.style.removeProperty("--jc-text-muted")
        tabletEl.style.removeProperty("--jc-text-muted-dark")
        tabletEl.style.removeProperty("--jc-staff-item-border")
        tabletEl.style.removeProperty("--jc-divider")
        tabletEl.style.removeProperty("--jc-players-search-icon")
        tabletEl.style.removeProperty("--jc-players-search-border")
        tabletEl.style.removeProperty("--jc-players-search-bg")
        tabletEl.style.removeProperty("--jc-players-search-color")
        tabletEl.style.removeProperty("--jc-players-search-placeholder")
        tabletEl.style.removeProperty("--jc-players-filter-border")
        tabletEl.style.removeProperty("--jc-players-filter-bg")
        tabletEl.style.removeProperty("--jc-players-filter-pill")
        tabletEl.style.removeProperty("--jc-players-filter-pill-hover")
        tabletEl.style.removeProperty("--jc-players-filter-btn")
        tabletEl.style.removeProperty("--jc-players-filter-btn-hover")
        tabletEl.style.removeProperty("--jc-players-list-wrap-border")
        tabletEl.style.removeProperty("--jc-players-list-wrap-bg")
        tabletEl.style.removeProperty("--jc-players-item-container-border")
        tabletEl.style.removeProperty("--jc-players-item-container-bg")
        tabletEl.style.removeProperty("--jc-players-item-id")
        tabletEl.style.removeProperty("--jc-players-item-name")
        tabletEl.style.removeProperty("--jc-players-item-offline")
        tabletEl.style.removeProperty("--jc-players-item-btn-bg")
        tabletEl.style.removeProperty("--jc-players-item-btn-color")
        tabletEl.style.removeProperty("--jc-players-item-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-players-item-btn-hover-color")
        tabletEl.style.removeProperty("--jc-players-item-btn-disabled-bg")
        tabletEl.style.removeProperty("--jc-players-item-btn-disabled-color")
        tabletEl.style.removeProperty("--jc-players-ping")
        tabletEl.style.removeProperty("--jc-players-placeholder")
        tabletEl.style.removeProperty("--jc-map-list-bg")
        tabletEl.style.removeProperty("--jc-map-list-border")
        tabletEl.style.removeProperty("--jc-map-list-header-bg")
        tabletEl.style.removeProperty("--jc-map-list-header-color")
        tabletEl.style.removeProperty("--jc-map-list-chevron")
        tabletEl.style.removeProperty("--jc-map-list-inner-bg")
        tabletEl.style.removeProperty("--jc-map-list-inner-border")
        tabletEl.style.removeProperty("--jc-map-list-scroll-track")
        tabletEl.style.removeProperty("--jc-map-list-scroll-thumb")
        tabletEl.style.removeProperty("--jc-map-list-scroll-thumb-hover")
        tabletEl.style.removeProperty("--jc-map-list-scroll-thumb-active")
        tabletEl.style.removeProperty("--jc-map-item-color")
        tabletEl.style.removeProperty("--jc-map-item-hover-bg")
        tabletEl.style.removeProperty("--jc-map-item-avatar-bg")
        tabletEl.style.removeProperty("--jc-map-item-id")
        tabletEl.style.removeProperty("--jc-map-ping-unknown")
        tabletEl.style.removeProperty("--jc-map-empty-color")
        tabletEl.style.removeProperty("--jc-player-detail-sidebar-border")
        tabletEl.style.removeProperty("--jc-player-detail-back-color")
        tabletEl.style.removeProperty("--jc-player-detail-back-hover-color")
        tabletEl.style.removeProperty("--jc-player-detail-avatar-bg")
        tabletEl.style.removeProperty("--jc-player-detail-avatar-border")
        tabletEl.style.removeProperty("--jc-player-detail-avatar-fallback-icon")
        tabletEl.style.removeProperty("--jc-player-detail-name-color")
        tabletEl.style.removeProperty("--jc-player-detail-field-bg")
        tabletEl.style.removeProperty("--jc-player-detail-field-border")
        tabletEl.style.removeProperty("--jc-player-detail-field-icon-bg")
        tabletEl.style.removeProperty("--jc-player-detail-field-icon-color")
        tabletEl.style.removeProperty("--jc-player-detail-field-label-color")
        tabletEl.style.removeProperty("--jc-player-detail-field-value-color")
        tabletEl.style.removeProperty("--jc-player-detail-section-title-color")
        tabletEl.style.removeProperty("--jc-player-detail-section-title-add-border")
        tabletEl.style.removeProperty("--jc-player-detail-section-title-add-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-border")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-color")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-spectate-stop-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-spectate-stop-color")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-freeze-active-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-freeze-active-color")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-noperm-bg")
        tabletEl.style.removeProperty("--jc-player-detail-fn-btn-noperm-border")
        tabletEl.style.removeProperty("--jc-player-detail-table-scroll-track-bg")
        tabletEl.style.removeProperty("--jc-player-detail-table-scroll-thumb-start")
        tabletEl.style.removeProperty("--jc-player-detail-table-scroll-thumb-end")
        tabletEl.style.removeProperty("--jc-player-detail-table-scroll-thumb-active")
        tabletEl.style.removeProperty("--jc-player-detail-table-wrap-border")
        tabletEl.style.removeProperty("--jc-player-detail-table-wrap-bg")
        tabletEl.style.removeProperty("--jc-player-detail-table-th-color")
        tabletEl.style.removeProperty("--jc-player-detail-table-th-border")
        tabletEl.style.removeProperty("--jc-player-detail-table-td-color")
        tabletEl.style.removeProperty("--jc-player-detail-table-td-bg")
        tabletEl.style.removeProperty("--jc-player-detail-table-td-border")
        tabletEl.style.removeProperty("--jc-player-detail-table-remove-btn-color")
        tabletEl.style.removeProperty("--jc-player-detail-empty-text")
        tabletEl.style.removeProperty("--jc-player-detail-empty-icon")
        tabletEl.style.removeProperty("--jc-logs-search-icon")
        tabletEl.style.removeProperty("--jc-logs-search-border")
        tabletEl.style.removeProperty("--jc-logs-search-bg")
        tabletEl.style.removeProperty("--jc-logs-search-color")
        tabletEl.style.removeProperty("--jc-logs-search-placeholder")
        tabletEl.style.removeProperty("--jc-logs-search-focus-border")
        tabletEl.style.removeProperty("--jc-logs-type-select-border")
        tabletEl.style.removeProperty("--jc-logs-type-select-bg")
        tabletEl.style.removeProperty("--jc-logs-type-select-color")
        tabletEl.style.removeProperty("--jc-logs-type-select-hover-border")
        tabletEl.style.removeProperty("--jc-logs-list-wrap-border")
        tabletEl.style.removeProperty("--jc-logs-list-wrap-bg")
        tabletEl.style.removeProperty("--jc-logs-identifiers-color")
        tabletEl.style.removeProperty("--jc-logs-identifiers-border")
        tabletEl.style.removeProperty("--jc-logs-identifiers-label-color")
        tabletEl.style.removeProperty("--jc-logs-placeholder")
        tabletEl.style.removeProperty("--jc-logs-pagination-btn-border")
        tabletEl.style.removeProperty("--jc-logs-pagination-btn-bg")
        tabletEl.style.removeProperty("--jc-logs-pagination-btn-color")
        tabletEl.style.removeProperty("--jc-logs-pagination-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-logs-pagination-btn-hover-border")
        tabletEl.style.removeProperty("--jc-logs-pagination-info")
        tabletEl.style.removeProperty("--jc-logs-card-bg")
        tabletEl.style.removeProperty("--jc-logs-card-border")
        tabletEl.style.removeProperty("--jc-logs-card-name-color")
        tabletEl.style.removeProperty("--jc-logs-card-expiry-color")
        tabletEl.style.removeProperty("--jc-logs-card-reason-color")
        tabletEl.style.removeProperty("--jc-logs-card-banned-by-color")
        tabletEl.style.removeProperty("--jc-groups-perms-summary")
        tabletEl.style.removeProperty("--jc-groups-btn-create-border")
        tabletEl.style.removeProperty("--jc-groups-btn-create-bg")
        tabletEl.style.removeProperty("--jc-groups-btn-create-color")
        tabletEl.style.removeProperty("--jc-groups-btn-create-hover-bg")
        tabletEl.style.removeProperty("--jc-groups-btn-create-hover-border")
        tabletEl.style.removeProperty("--jc-groups-card-bg")
        tabletEl.style.removeProperty("--jc-groups-card-border")
        tabletEl.style.removeProperty("--jc-groups-card-icon-bg")
        tabletEl.style.removeProperty("--jc-groups-card-icon-color")
        tabletEl.style.removeProperty("--jc-groups-card-title")
        tabletEl.style.removeProperty("--jc-groups-card-badge")
        tabletEl.style.removeProperty("--jc-groups-card-btn-bg")
        tabletEl.style.removeProperty("--jc-groups-card-btn-color")
        tabletEl.style.removeProperty("--jc-groups-card-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-groups-card-btn-hover-color")
        tabletEl.style.removeProperty("--jc-groups-perm-label")
        tabletEl.style.removeProperty("--jc-groups-perm-value-no")
        tabletEl.style.removeProperty("--jc-bans-search-icon")
        tabletEl.style.removeProperty("--jc-bans-search-border")
        tabletEl.style.removeProperty("--jc-bans-search-bg")
        tabletEl.style.removeProperty("--jc-bans-search-color")
        tabletEl.style.removeProperty("--jc-bans-search-placeholder")
        tabletEl.style.removeProperty("--jc-bans-filter-border")
        tabletEl.style.removeProperty("--jc-bans-filter-bg")
        tabletEl.style.removeProperty("--jc-bans-filter-pill")
        tabletEl.style.removeProperty("--jc-bans-filter-pill-hover")
        tabletEl.style.removeProperty("--jc-bans-filter-btn")
        tabletEl.style.removeProperty("--jc-bans-filter-btn-hover")
        tabletEl.style.removeProperty("--jc-bans-list-wrap-border")
        tabletEl.style.removeProperty("--jc-bans-list-wrap-bg")
        tabletEl.style.removeProperty("--jc-bans-card-bg")
        tabletEl.style.removeProperty("--jc-bans-card-border")
        tabletEl.style.removeProperty("--jc-bans-card-name")
        tabletEl.style.removeProperty("--jc-bans-card-expiry")
        tabletEl.style.removeProperty("--jc-bans-card-reason")
        tabletEl.style.removeProperty("--jc-bans-card-banned-by")
        tabletEl.style.removeProperty("--jc-bans-item-btn-bg")
        tabletEl.style.removeProperty("--jc-bans-item-btn-color")
        tabletEl.style.removeProperty("--jc-bans-item-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-bans-item-btn-hover-color")
        tabletEl.style.removeProperty("--jc-bans-item-btn-edit-hover-bg")
        tabletEl.style.removeProperty("--jc-bans-item-btn-edit-hover-color")
        tabletEl.style.removeProperty("--jc-bans-item-btn-unban-hover-bg")
        tabletEl.style.removeProperty("--jc-bans-item-btn-unban-hover-color")
        tabletEl.style.removeProperty("--jc-bans-item-btn-noperm-hover-bg")
        tabletEl.style.removeProperty("--jc-bans-item-btn-noperm-hover-color")
        tabletEl.style.removeProperty("--jc-bans-placeholder")
        tabletEl.style.removeProperty("--jc-terminal-section-border")
        tabletEl.style.removeProperty("--jc-terminal-section-bg")
        tabletEl.style.removeProperty("--jc-terminal-section-title")
        tabletEl.style.removeProperty("--jc-terminal-section-title-border")
        tabletEl.style.removeProperty("--jc-terminal-section-title-icon")
        tabletEl.style.removeProperty("--jc-terminal-output-color")
        tabletEl.style.removeProperty("--jc-terminal-output-bg")
        tabletEl.style.removeProperty("--jc-terminal-output-scroll-track")
        tabletEl.style.removeProperty("--jc-terminal-output-scroll-thumb")
        tabletEl.style.removeProperty("--jc-terminal-line-command")
        tabletEl.style.removeProperty("--jc-terminal-line-info")
        tabletEl.style.removeProperty("--jc-terminal-line-success")
        tabletEl.style.removeProperty("--jc-terminal-line-error")
        tabletEl.style.removeProperty("--jc-terminal-line-warning")
        tabletEl.style.removeProperty("--jc-terminal-input-wrap-bg")
        tabletEl.style.removeProperty("--jc-terminal-input-wrap-border")
        tabletEl.style.removeProperty("--jc-terminal-prompt")
        tabletEl.style.removeProperty("--jc-terminal-input-color")
        tabletEl.style.removeProperty("--jc-terminal-input-placeholder")
        tabletEl.style.removeProperty("--jc-terminal-resources-search-bg")
        tabletEl.style.removeProperty("--jc-terminal-resources-search-border")
        tabletEl.style.removeProperty("--jc-terminal-resources-search-icon")
        tabletEl.style.removeProperty("--jc-terminal-resources-search-color")
        tabletEl.style.removeProperty("--jc-terminal-resources-search-placeholder")
        tabletEl.style.removeProperty("--jc-terminal-refresh-btn-bg")
        tabletEl.style.removeProperty("--jc-terminal-refresh-btn-color")
        tabletEl.style.removeProperty("--jc-terminal-refresh-btn-hover-bg")
        tabletEl.style.removeProperty("--jc-terminal-refresh-btn-hover-color")
        tabletEl.style.removeProperty("--jc-terminal-resources-list-scroll-track")
        tabletEl.style.removeProperty("--jc-terminal-resources-list-scroll-thumb")
        tabletEl.style.removeProperty("--jc-terminal-resource-item-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-item-border")
        tabletEl.style.removeProperty("--jc-terminal-resource-name")
        tabletEl.style.removeProperty("--jc-terminal-resource-dot-started")
        tabletEl.style.removeProperty("--jc-terminal-resource-dot-stopped")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-restart-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-restart-color")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-restart-hover-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-start-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-start-color")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-start-hover-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-stop-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-stop-color")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-stop-hover-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-noperm-hover-bg")
        tabletEl.style.removeProperty("--jc-terminal-resource-btn-noperm-hover-color")
        tabletEl.style.removeProperty("--jc-terminal-loading-empty")
        tabletEl.style.removeProperty("--jc-settings-btn-confirm-hover")
        tabletEl.style.removeProperty("--jc-settings-toggle-track-bg")
        tabletEl.style.removeProperty("--jc-settings-toggle-thumb-bg")
        tabletEl.style.removeProperty("--jc-settings-commands-scroll-track")
        tabletEl.style.removeProperty("--jc-settings-commands-scroll-thumb")
    }
    var kickActionsEl = document.getElementById("kick-actions")
    if (kickActionsEl && kickActionsEl.style) {
        kickActionsEl.style.removeProperty("--jc-accent")
        kickActionsEl.style.removeProperty("--jc-accent-body-bg")
        kickActionsEl.style.removeProperty("--jc-accent-bg")
        kickActionsEl.style.removeProperty("--jc-accent-bg2")
        kickActionsEl.style.removeProperty("--jc-accent-border")
        kickActionsEl.style.removeProperty("--jc-accent-border-dark")
        kickActionsEl.style.removeProperty("--jc-accent-hover")
        kickActionsEl.style.removeProperty("--jc-accent-active-bg")
        kickActionsEl.style.removeProperty("--jc-accent-waiting-bg")
    }
}

;(function settingsInit() {
    document.querySelectorAll(".settings-color-swatch").forEach(function(el) {
        var c = el.getAttribute("data-color")
        if (c) el.style.backgroundColor = c
        el.addEventListener("click", function() {
            document.querySelectorAll(".settings-color-swatch").forEach(function(s) { s.classList.remove("selected") })
            el.classList.add("selected")
            var primHex = document.getElementById("settings-color-primary-hex")
            if (primHex) primHex.value = c
            if (el.getAttribute("data-default") === "true") {
                resetInterfaceColor()
            } else {
                applyInterfaceColor(c)
            }
        })
    })
    var editUsernameBtn = document.getElementById("settings-edit-username-btn")
    var changeUsernameWrap = document.getElementById("settings-change-username-wrap")
    var newUsernameInput = document.getElementById("settings-new-username")
    var usernameErrorEl = document.getElementById("settings-username-error")
    var usernameCancelBtn = document.getElementById("settings-username-cancel-btn")
    var usernameSaveBtn = document.getElementById("settings-username-save-btn")
    if (editUsernameBtn) {
        editUsernameBtn.addEventListener("click", function() {
            if (newUsernameInput) { newUsernameInput.value = ""; newUsernameInput.focus() }
            if (usernameErrorEl) { usernameErrorEl.classList.add("hidden"); usernameErrorEl.textContent = "" }
            if (changeUsernameWrap) changeUsernameWrap.classList.remove("hidden")
        })
    }
    if (usernameCancelBtn) {
        usernameCancelBtn.addEventListener("click", function() {
            if (changeUsernameWrap) changeUsernameWrap.classList.add("hidden")
            if (newUsernameInput) newUsernameInput.value = ""
            if (usernameErrorEl) { usernameErrorEl.classList.add("hidden"); usernameErrorEl.textContent = "" }
        })
    }
    if (usernameSaveBtn) {
        usernameSaveBtn.addEventListener("click", function() {
            var license = window._settingsProfileLicense
            if (!license) { if (usernameErrorEl) { usernameErrorEl.textContent = (window.t && window.t("settings_error_no_license")) || "Error: no license"; usernameErrorEl.classList.remove("hidden") }; return }
            var newUser = (newUsernameInput ? newUsernameInput.value : "").trim()
            if (newUser.length < 2) {
                if (usernameErrorEl) { usernameErrorEl.textContent = (window.t && window.t("settings_error_min_chars")) || "Minimum 2 characters"; usernameErrorEl.classList.remove("hidden") }
                return
            }
            if (usernameErrorEl) usernameErrorEl.classList.add("hidden")
            window._settingsPendingUsername = newUser
            fetch("https://" + GetParentResourceName() + "/changeAdminUser", {
                method: "POST", headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ license: license, newUser: newUser })
            }).catch(function() {})
        })
    }
    var togglePw = document.getElementById("settings-toggle-password")
    var pwInput = document.getElementById("settings-password-display")
    var pwIcon = document.getElementById("settings-password-icon")
    if (togglePw && pwInput && pwIcon) {
        togglePw.addEventListener("click", function() {
            var isPw = pwInput.type === "password"
            if (isPw) {
                pwInput.type = "text"
                pwInput.value = pwInput.dataset.realPassword || ""
                pwInput.placeholder = ""
                pwIcon.className = "fa-solid fa-eye"
            } else {
                pwInput.type = "password"
                pwInput.value = ""
                pwInput.placeholder = "••••••••"
                pwIcon.className = "fa-solid fa-eye-slash"
            }
        })
    }
    var changePwBtn = document.getElementById("settings-change-password-btn")
    var modal = document.getElementById("settings-change-password-modal")
    var backdrop = modal && (modal.querySelector(".ban-modal-backdrop") || modal.querySelector(".groups-modal-backdrop"))
    var cancelBtn = document.getElementById("settings-modal-password-cancel")
    var confirmBtn = document.getElementById("settings-modal-password-confirm")
    var errEl = document.getElementById("settings-password-error")
    var inputCurrent = document.getElementById("settings-modal-current-password")
    var inputNew = document.getElementById("settings-modal-new-password")
    var inputRepeat = document.getElementById("settings-modal-repeat-password")
    function closePasswordModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            if (inputCurrent) inputCurrent.value = ""
            if (inputNew) inputNew.value = ""
            if (inputRepeat) inputRepeat.value = ""
            if (errEl) { errEl.classList.add("hidden"); errEl.textContent = "" }
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut() }, (duration * 1000) + 50)
    }
    if (changePwBtn && modal) {
        changePwBtn.addEventListener("click", function() {
            if (modal) {
                modal.classList.remove("hidden")
                modal.setAttribute("aria-hidden", "false")
                requestAnimationFrame(function() {
                    requestAnimationFrame(function() { modal.classList.add("open") })
                })
            }
        })
    }
    if (backdrop) backdrop.addEventListener("click", closePasswordModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closePasswordModal)
    window.closePasswordModal = closePasswordModal
    if (confirmBtn && inputCurrent && inputNew && inputRepeat && errEl) {
        confirmBtn.addEventListener("click", function() {
            var cur = (inputCurrent && inputCurrent.value) || ""
            var newP = (inputNew && inputNew.value) || ""
            var rep = (inputRepeat && inputRepeat.value) || ""
            if (newP.length < 4) {
                errEl.textContent = (window.t && window.t("settings_password_min_length")) || "New password must be at least 4 characters."
                errEl.classList.remove("hidden")
                return
            }
            if (newP !== rep) {
                errEl.textContent = (window.t && window.t("settings_password_mismatch")) || "New password and confirmation do not match."
                errEl.classList.remove("hidden")
                return
            }
            errEl.classList.add("hidden")
            fetch("https://" + GetParentResourceName() + "/changePassword", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ currentPassword: cur, newPassword: newP })
            }).then(function(r) { return r.json() }).then(function(ok) {
                if (ok) {
                    closePasswordModal()
                    window.showToast((window.t && window.t("toast_password_changed")) || "Password changed successfully", "success")
                } else {
                    errEl.textContent = (typeof window !== "undefined" && window.t && window.t("settings_current_password_incorrect")) || "Current password is incorrect."
                    errEl.classList.remove("hidden")
                }
            }).catch(function() {
                errEl.textContent = (window.t && window.t("settings_password_change_error")) || "Error changing password."
                errEl.classList.remove("hidden")
            })
        })
    }
    var primColor = document.getElementById("settings-color-primary")
    var primHex = document.getElementById("settings-color-primary-hex")
    var secColor = document.getElementById("settings-color-secondary")
    var secHex = document.getElementById("settings-color-secondary-hex")
    var terColor = document.getElementById("settings-color-tertiary")
    var terHex = document.getElementById("settings-color-tertiary-hex")
    function syncColorToHex(picker, hexInput) {
        if (!picker || !hexInput) return
        picker.addEventListener("input", function() { hexInput.value = picker.value })
        hexInput.addEventListener("input", function() {
            if (/^#[0-9A-Fa-f]{6}$/.test(hexInput.value)) picker.value = hexInput.value
        })
    }
    syncColorToHex(primColor, primHex)
    syncColorToHex(secColor, secHex)
    syncColorToHex(terColor, terHex)
    var distRange = document.getElementById("settings-tags-distancia")
    if (distRange) {
        distRange.addEventListener("input", function() { updateSettingsEspDistanciaDisplay() })
        distRange.addEventListener("change", function() { updateSettingsEspDistanciaDisplay() })
    }
    var saveBtn = document.getElementById("settings-save-btn")
    if (saveBtn) {
        saveBtn.addEventListener("click", function() {
            var payload = getSettingsPayload()
            fetch("https://" + GetParentResourceName() + "/saveSettings", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ settings: payload })
            }).then(function(r) { return r.json() }).then(function(ok) {
                if (ok) requestSettingsProfile()
            }).catch(function() {})
        })
    }
    var avatarWrap = document.getElementById("settings-avatar-wrap")
    var avatarModal = document.getElementById("settings-avatar-modal")
    var avatarModalBackdrop = avatarModal && avatarModal.querySelector(".groups-modal-backdrop")
    var avatarModalCancel = document.getElementById("settings-avatar-modal-cancel")
    var avatarModalConfirm = document.getElementById("settings-avatar-modal-confirm")
    var avatarUrlInput = document.getElementById("settings-avatar-url-input")
    function closeAvatarModal() {
        if (avatarModal) avatarModal.classList.add("hidden")
        if (avatarModal) avatarModal.setAttribute("aria-hidden", "true")
        if (avatarUrlInput) avatarUrlInput.value = ""
    }
    if (avatarWrap && avatarModal) {
        avatarWrap.addEventListener("click", function() {
            if (avatarModal) avatarModal.classList.remove("hidden")
            if (avatarModal) avatarModal.setAttribute("aria-hidden", "false")
            if (avatarUrlInput && avatarWrap) {
                avatarUrlInput.value = avatarWrap.getAttribute("data-current-url") || ""
                avatarUrlInput.focus()
            }
        })
    }
    if (avatarModalBackdrop) avatarModalBackdrop.addEventListener("click", closeAvatarModal)
    if (avatarModalCancel) avatarModalCancel.addEventListener("click", closeAvatarModal)
    if (avatarModalConfirm && avatarUrlInput) {
        avatarModalConfirm.addEventListener("click", function() {
            var url = (avatarUrlInput.value && String(avatarUrlInput.value).trim()) || ""
            fetch("https://" + GetParentResourceName() + "/saveAvatar", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ avatarUrl: url })
            }).then(function(r) { return r.json() }).then(function(ok) {
                if (ok) {
                    closeAvatarModal()
                    requestSettingsProfile()
                }
            }).catch(function() {})
        })
    }
    var langSelect = document.getElementById("settings-language-select")
    if (langSelect) {
        langSelect.addEventListener("change", function() {
            var lang = langSelect.value
            if (window.allLocales && window.allLocales[lang]) {
                window.translations = window.allLocales[lang]
                window.locale = lang
                localStorage.setItem("admin_locale", lang)
                applyTranslations()
            }
        })
    }
})()
window.requestSettingsProfile = requestSettingsProfile

;(function() {
    var searchEl = document.getElementById("bans-search")
    var addOfflineBtn = document.getElementById("bans-add-offline-btn")
    if (searchEl) {
        searchEl.addEventListener("input", function() { if (typeof renderBansList === "function") renderBansList() })
        searchEl.addEventListener("keydown", function(e) { if (e.key === "Escape") { searchEl.value = ""; if (typeof renderBansList === "function") renderBansList() } })
    }
    if (addOfflineBtn) {
        addOfflineBtn.addEventListener("click", function() {
            if (addOfflineBtn.getAttribute("data-perm-allowed") === "false") return
            if (typeof window.openBanModal === "function") window.openBanModal(null, null, {})
        })
    }
    var filterBtns = document.getElementById("bans-filter-btns")
    var filterPillHover = document.getElementById("bans-filter-pill-hover")
    function moveHoverPill(btn) {
        if (!filterBtns || !filterPillHover || !btn) return
        var left = btn.offsetLeft
        var width = btn.offsetWidth
        filterBtns.style.setProperty("--bans-hover-pill-width", width + "px")
        filterBtns.style.setProperty("--bans-hover-pill-left", left + "px")
        filterPillHover.classList.add("bans-filter-hover-visible")
    }
    function hideHoverPill() {
        if (filterPillHover) filterPillHover.classList.remove("bans-filter-hover-visible")
    }
    if (filterBtns) {
        document.querySelectorAll(".bans-filter-btn").forEach(function(btn) {
            btn.addEventListener("mouseenter", function() { moveHoverPill(btn) })
            btn.addEventListener("mouseleave", function() { hideHoverPill() })
            btn.addEventListener("click", function() {
                var filter = btn.getAttribute("data-filter") || "all"
                window.bansFilter = filter
                document.querySelectorAll(".bans-filter-btn").forEach(function(b) { b.classList.remove("active") })
                btn.classList.add("active")
                if (typeof updateBansFilterPill === "function") updateBansFilterPill()
                if (typeof renderBansList === "function") renderBansList()
            })
        })
    }
})()

;(function() {
    function requestLogsList() {
        var logTypeSel = document.getElementById("logs-type-select")
        var logSearchEl = document.getElementById("logs-search")
        var logType = (logTypeSel && logTypeSel.value) ? logTypeSel.value : "all"
        var search = (logSearchEl && logSearchEl.value) ? String(logSearchEl.value).trim() : ""
        fetch("https://" + GetParentResourceName() + "/requestLogsList", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ logType: logType, search: search })
        }).catch(function() {})
    }
    var logTypeSel = document.getElementById("logs-type-select")
    if (logTypeSel) logTypeSel.addEventListener("change", requestLogsList)
    var logSearchEl = document.getElementById("logs-search")
    if (logSearchEl) {
        var logSearchT = null
        logSearchEl.addEventListener("input", function() {
            if (logSearchT) clearTimeout(logSearchT)
            logSearchT = setTimeout(requestLogsList, 400)
        })
        logSearchEl.addEventListener("keydown", function(e) {
            if (e.key === "Enter") { if (logSearchT) clearTimeout(logSearchT); requestLogsList() }
            if (e.key === "Escape") { logSearchEl.value = ""; requestLogsList() }
        })
    }
    var logsPagPrev = document.getElementById("logs-pagination-prev")
    if (logsPagPrev) logsPagPrev.addEventListener("click", function() {
        if (window.logsCurrentPage > 1) { window.logsCurrentPage--; renderLogsList() }
    })
    var logsPagNext = document.getElementById("logs-pagination-next")
    if (logsPagNext) logsPagNext.addEventListener("click", function() {
        var data = window.logsListData || []
        var totalPages = Math.max(1, Math.ceil(data.length / LOGS_PER_PAGE))
        if (window.logsCurrentPage < totalPages) { window.logsCurrentPage++; renderLogsList() }
    })
})()

document.querySelectorAll(".dashboard-stat-card-btn").forEach(btn => {
    const targetId = btn.getAttribute("data-scroll-target")
    if (!targetId) return
    btn.addEventListener("click", () => {
        const el = document.getElementById(targetId)
        if (el) el.scrollIntoView({ behavior: "smooth", block: "start" })
    })
})

document.getElementById("btn-logout").addEventListener("click", () => {
    fetch(`https://${GetParentResourceName()}/logout`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    })
})

var btnOpenKickActions = document.getElementById("btn-open-kick-actions")
if (btnOpenKickActions) {
    btnOpenKickActions.addEventListener("click", function() {
        fetch("https://" + GetParentResourceName() + "/requestOpenKickActions", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).catch(function() {})
    })
}

var coordsUICloseBtn = document.getElementById("coords-ui-close")
if (coordsUICloseBtn) {
    coordsUICloseBtn.addEventListener("click", function() {
        fetch("https://" + GetParentResourceName() + "/closeCoordsUI", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).catch(function() {})
        var coordsEl = document.getElementById("coords-ui")
        if (coordsEl) coordsEl.classList.add("hidden")
    })
}

var coordsUiLaserBtn = document.getElementById("coords-ui-laser-btn")
if (coordsUiLaserBtn) {
    coordsUiLaserBtn.addEventListener("click", function() {
        fetch("https://" + GetParentResourceName() + "/coordsUiToggleLaser", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).then(function(r) { return r.json() }).then(function(data) {
            if (data && data.on !== undefined) {
                coordsUiLaserBtn.classList.toggle("active", data.on)
                coordsUiLaserBtn.setAttribute("aria-pressed", !!data.on)
            }
        }).catch(function() {})
    })
}

var coordsUiCameraBtn = document.getElementById("coords-ui-camera-btn")
if (coordsUiCameraBtn) {
    coordsUiCameraBtn.addEventListener("click", function() {
        fetch("https://" + GetParentResourceName() + "/coordsUiToggleCamera", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).then(function(r) { return r.json() }).then(function(data) {
            if (data && data.on !== undefined) {
                coordsUiCameraBtn.classList.toggle("active", data.on)
                coordsUiCameraBtn.setAttribute("aria-pressed", !!data.on)
            }
        }).catch(function() {})
    })
}

var coordsUiEntityLaserBtn = document.getElementById("coords-ui-entity-laser-btn")
if (coordsUiEntityLaserBtn) {
    coordsUiEntityLaserBtn.addEventListener("click", function() {
        fetch("https://" + GetParentResourceName() + "/entityLaserStart", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).then(function() {
            var coordsEl = document.getElementById("coords-ui")
            if (coordsEl) coordsEl.classList.add("hidden")
        }).catch(function() {})
    })
}

function copyCoordsText(text) {
    if (!text) return
    var textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.left = "-9999px"
    textarea.style.top = "0"
    textarea.setAttribute("readonly", "")
    document.body.appendChild(textarea)
    textarea.select()
    try { document.execCommand("copy") } catch (e) {}
    document.body.removeChild(textarea)
}

document.querySelectorAll(".coords-ui-copy").forEach(function(btn) {
    btn.addEventListener("click", function() {
        var id = btn.getAttribute("data-copy-id")
        if (!id) return
        var el = document.getElementById("coords-" + id)
        if (el) copyCoordsText(el.textContent)
    })
})

var playerDetailBackBtn = document.getElementById("player-detail-back")
if (playerDetailBackBtn) {
    playerDetailBackBtn.addEventListener("click", function() {
        window.lastOpenPlayerDetailId = null
        window.lastOpenPlayerDetailOfflineIdentifier = null
        window.playerDetailOffline = false
        window.playerDetailOfflineIdentifier = null
        window.playerDetailCurrentId = null
        window.playerDetailDetailReqSeq = null
        window.playerDetailUiNonce = (window.playerDetailUiNonce || 0) + 1
        if (typeof window.revokePlayerDetailAvatarObjectUrl === "function") window.revokePlayerDetailAvatarObjectUrl()
        var avatarBack = document.getElementById("player-detail-avatar")
        var avatarBackIcon = document.getElementById("player-detail-avatar-fallback-icon")
        if (avatarBack) {
            avatarBack.classList.add("player-detail-avatar-no-photo")
            avatarBack.style.backgroundImage = "none"
            avatarBack.style.removeProperty("background-size")
            avatarBack.style.removeProperty("background-position")
        }
        if (avatarBackIcon) {
            avatarBackIcon.className = "fa-solid fa-user player-detail-avatar-fallback-icon"
        }
        var listView = document.getElementById("players-list-view")
        var detailView = document.getElementById("player-detail-view")
        if (listView) listView.classList.remove("hidden")
        if (detailView) {
            detailView.classList.add("hidden")
            detailView.classList.remove("player-detail-offline")
            detailView.setAttribute("aria-hidden", "true")
        }
    })
}

;(function banModalModule() {
    var modal = document.getElementById("ban-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var titleEl = modal ? modal.querySelector(".ban-modal-title") : null
    var descEl = modal ? modal.querySelector(".ban-modal-desc") : null
    var reasonEl = document.getElementById("ban-modal-reason")
    var expiresEl = document.getElementById("ban-modal-expires")
    var permanentEl = document.getElementById("ban-modal-permanent")
    var offlineFieldsWrap = document.getElementById("ban-modal-offline-fields")
    var playerNameEl = document.getElementById("ban-modal-player-name")
    var licenseEl = document.getElementById("ban-modal-license")
    var discordEl = document.getElementById("ban-modal-discord")
    var steamEl = document.getElementById("ban-modal-steam")
    var license2El = document.getElementById("ban-modal-license2")
    var liveEl = document.getElementById("ban-modal-live")
    var ipEl = document.getElementById("ban-modal-ip")
    var hardwareEl = document.getElementById("ban-modal-hardware")
    var cancelBtn = document.getElementById("ban-modal-cancel")
    var confirmBtn = document.getElementById("ban-modal-confirm")
    var banModalPlayerId = null
    var banModalEditId = null
    var banModalOffline = false
    var banModalBanByIdentifier = null
    var banModalBanPlayerName = null
    var expiresPicker = null

    function initExpiresPicker() {
        if (!expiresEl || expiresPicker) return
        expiresPicker = window.flatpickr(expiresEl, {
            enableTime: true,
            dateFormat: "d/m/Y H:i",
            time_24hr: true,
            allowInput: false
        })
    }

    function parseBanExpiresAt(value) {
        if (value == null || value === "") return null
        var n = Number(value)
        if (!isNaN(n)) {
            if (n < 1e12) { n = n * 1000 }
            var d1 = new Date(n)
            return (d1 && !isNaN(d1.getTime())) ? d1 : null
        }
        var s = String(value).trim()
        var sql = s.match(/^(\d{4})-(\d{2})-(\d{2})[\sT](\d{2}):(\d{2}):(\d{2})/)
        if (sql) {
            var y = parseInt(sql[1], 10)
            var mo = parseInt(sql[2], 10) - 1
            var da = parseInt(sql[3], 10)
            var ho = parseInt(sql[4], 10)
            var mi = parseInt(sql[5], 10)
            var se = parseInt(sql[6], 10)
            var d2 = new Date(y, mo, da, ho, mi, se)
            return (d2 && !isNaN(d2.getTime())) ? d2 : null
        }
        var d3 = new Date(s)
        return (d3 && !isNaN(d3.getTime())) ? d3 : null
    }

    function banDisplayedExpiryToMysql(displayStr) {
        if (displayStr == null) return null
        var s = String(displayStr).trim()
        if (!s) return null
        var pad = function(x) { return (x < 10 ? "0" : "") + x }
        var m12 = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{2})\s*(AM|PM)$/i)
        if (m12) {
            var day = parseInt(m12[1], 10)
            var month = parseInt(m12[2], 10)
            var year = parseInt(m12[3], 10)
            var hour = parseInt(m12[4], 10)
            var minute = parseInt(m12[5], 10)
            var ap = String(m12[6]).toUpperCase()
            if (hour < 1 || hour > 12 || minute > 59) return null
            if (ap === "PM" && hour !== 12) hour += 12
            if (ap === "AM" && hour === 12) hour = 0
            if (month < 1 || month > 12 || day < 1 || day > 31) return null
            return year + "-" + pad(month) + "-" + pad(day) + " " + pad(hour) + ":" + pad(minute) + ":00"
        }
        var m = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$/)
        if (!m) return null
        var day1 = parseInt(m[1], 10)
        var month1 = parseInt(m[2], 10)
        var year1 = parseInt(m[3], 10)
        var hour1 = parseInt(m[4], 10)
        var minute1 = parseInt(m[5], 10)
        var second1 = m[6] ? parseInt(m[6], 10) : 0
        if (month1 < 1 || month1 > 12 || day1 < 1 || day1 > 31 || hour1 > 23 || minute1 > 59 || second1 > 59) return null
        return year1 + "-" + pad(month1) + "-" + pad(day1) + " " + pad(hour1) + ":" + pad(minute1) + ":" + pad(second1)
    }

    function getBanExpiresMysqlFromPicker() {
        if (!expiresEl || !expiresEl.value) return null
        return banDisplayedExpiryToMysql(expiresEl.value)
    }

    function setBanModalOfflineMode(on) {
        banModalOffline = on === true
        if (offlineFieldsWrap) offlineFieldsWrap.classList.toggle("hidden", !banModalOffline)
        if (titleEl) titleEl.textContent = banModalOffline ? ((window.t && window.t("ban_modal_offline_title")) || "Ban offline") : ((window.t && window.t("ban_modal_title")) || "Ban from server")
        if (descEl) descEl.textContent = banModalOffline ? ((window.t && window.t("ban_modal_offline_desc")) || "Banear con identifiers manuales.") : ((window.t && window.t("ban_modal_desc")) || "Impide que vuelva a conectarse con sus identificadores.")
    }

    function getOfflineIdentifiersPayload() {
        return {
            player_name: playerNameEl ? String(playerNameEl.value || "").trim() : "",
            license: licenseEl ? String(licenseEl.value || "").trim() : "",
            discord: discordEl ? String(discordEl.value || "").trim() : "",
            steam: steamEl ? String(steamEl.value || "").trim() : "",
            license2: license2El ? String(license2El.value || "").trim() : "",
            libebox: liveEl ? String(liveEl.value || "").trim() : "",
            ip: ipEl ? String(ipEl.value || "").trim() : "",
            hardware: hardwareEl ? String(hardwareEl.value || "").trim() : ""
        }
    }

    function clearOfflineLicenseError() {
        if (licenseEl) licenseEl.classList.remove("ban-modal-license-required-error")
    }

    function openBanModal(playerId, editBanData, offlineData) {
        banModalEditId = editBanData && editBanData.id != null ? String(editBanData.id) : null
        banModalPlayerId = (editBanData ? null : playerId)
        banModalBanByIdentifier = null
        banModalBanPlayerName = null
        var fwId = offlineData && offlineData.banFrameworkIdentifier != null ? String(offlineData.banFrameworkIdentifier).trim() : ""
        var useFrameworkBan = !editBanData && playerId == null && fwId !== ""
        if (useFrameworkBan) {
            banModalBanByIdentifier = fwId
            banModalBanPlayerName = (offlineData && offlineData.player_name) ? String(offlineData.player_name).trim() : ""
            setBanModalOfflineMode(false)
        } else {
            setBanModalOfflineMode(!editBanData && (playerId == null))
        }
        if (reasonEl) reasonEl.value = (editBanData && editBanData.reason) ? String(editBanData.reason) : ""
        if (playerNameEl) playerNameEl.value = (!useFrameworkBan && offlineData && offlineData.player_name) ? String(offlineData.player_name) : ""
        if (licenseEl) licenseEl.value = (!useFrameworkBan && offlineData && offlineData.license) ? String(offlineData.license) : ""
        if (discordEl) discordEl.value = (!useFrameworkBan && offlineData && offlineData.discord) ? String(offlineData.discord) : ""
        if (steamEl) steamEl.value = (!useFrameworkBan && offlineData && offlineData.steam) ? String(offlineData.steam) : ""
        if (license2El) license2El.value = (!useFrameworkBan && offlineData && offlineData.license2) ? String(offlineData.license2) : ""
        if (liveEl) liveEl.value = (!useFrameworkBan && offlineData && offlineData.libebox) ? String(offlineData.libebox) : ""
        if (ipEl) ipEl.value = (!useFrameworkBan && offlineData && offlineData.ip) ? String(offlineData.ip) : ""
        if (hardwareEl) hardwareEl.value = (!useFrameworkBan && offlineData && offlineData.hardware) ? String(offlineData.hardware) : ""
        clearOfflineLicenseError()
        if (expiresEl) {
            expiresEl.disabled = false
            if (!expiresPicker) initExpiresPicker()
            if (expiresPicker) expiresPicker.clear()
            if (editBanData && editBanData.expires_at) {
                var d = parseBanExpiresAt(editBanData.expires_at)
                if (d && expiresPicker) {
                    expiresPicker.setDate(d)
                } else {
                    expiresEl.value = ""
                }
            } else { expiresEl.value = "" }
        }
        if (permanentEl) permanentEl.checked = !!(editBanData && editBanData.is_permanent)
        updateExpiresDisabled()
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeBanModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            banModalPlayerId = null
            banModalEditId = null
            banModalOffline = false
            banModalBanByIdentifier = null
            banModalBanPlayerName = null
            setBanModalOfflineMode(false)
            if (expiresPicker) expiresPicker.close()
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    function updateExpiresDisabled() {
        if (!expiresEl || !permanentEl) return
        expiresEl.disabled = permanentEl.checked
        if (expiresPicker && permanentEl.checked) expiresPicker.close()
    }

    if (permanentEl) permanentEl.addEventListener("change", updateExpiresDisabled)
    if (licenseEl) {
        licenseEl.addEventListener("input", clearOfflineLicenseError)
        licenseEl.addEventListener("change", clearOfflineLicenseError)
    }
    if (backdrop) backdrop.addEventListener("click", closeBanModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeBanModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            var reason = reasonEl ? reasonEl.value.trim() : ""
            var permanent = permanentEl ? permanentEl.checked : false
            var expiresAt = null
            if (!permanent && expiresPicker && expiresPicker.selectedDates && expiresPicker.selectedDates[0]) {
                expiresAt = getBanExpiresMysqlFromPicker()
            }
            if (banModalEditId) {
                fetch("https://" + GetParentResourceName() + "/submitUpdateBan", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ banId: banModalEditId, reason: reason, permanent: permanent, expiresAt: expiresAt })
                }).catch(function() {})
                closeBanModal()
                setTimeout(function() {
                    fetch("https://" + GetParentResourceName() + "/requestBansList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
                }, 200)
            } else if (banModalBanByIdentifier != null && banModalBanByIdentifier !== "") {
                fetch("https://" + GetParentResourceName() + "/submitBan", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        offlineIdentifier: banModalBanByIdentifier,
                        playerName: banModalBanPlayerName || "",
                        reason: reason,
                        permanent: permanent,
                        expiresAt: expiresAt
                    })
                }).catch(function() {})
                closeBanModal()
                setTimeout(function() {
                    fetch("https://" + GetParentResourceName() + "/requestBansList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
                }, 200)
            } else if (banModalPlayerId != null) {
                fetch("https://" + GetParentResourceName() + "/submitBan", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ playerId: banModalPlayerId, reason: reason, permanent: permanent, expiresAt: expiresAt })
                }).catch(function() {})
                closeBanModal()
            } else if (banModalOffline) {
                var identifiers = getOfflineIdentifiersPayload()
                if (!identifiers.license) {
                    if (licenseEl) {
                        licenseEl.classList.add("ban-modal-license-required-error")
                        licenseEl.focus()
                    }
                    return
                }
                fetch("https://" + GetParentResourceName() + "/submitOfflineBan", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ identifiers: identifiers, reason: reason, permanent: permanent, expiresAt: expiresAt })
                }).catch(function() {})
                closeBanModal()
                setTimeout(function() {
                    fetch("https://" + GetParentResourceName() + "/requestBansList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
                }, 200)
            }
        })
    }

    window.openBanModal = openBanModal
    window.closeBanModal = closeBanModal
})()

;(function kickModalModule() {
    var modal = document.getElementById("kick-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var reasonEl = document.getElementById("kick-modal-reason")
    var cancelBtn = document.getElementById("kick-modal-cancel")
    var confirmBtn = document.getElementById("kick-modal-confirm")
    var kickModalPlayerId = null

    function openKickModal(playerId) {
        kickModalPlayerId = playerId
        if (reasonEl) reasonEl.value = ""
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeKickModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            kickModalPlayerId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeKickModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeKickModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (kickModalPlayerId == null) return
            var reason = reasonEl ? reasonEl.value.trim() : ""
            fetch("https://" + GetParentResourceName() + "/submitKick", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: kickModalPlayerId, reason: reason })
            }).catch(function() {})
            closeKickModal()
        })
    }

    window.openKickModal = openKickModal
    window.closeKickModal = closeKickModal
})()

;(function announcementsModalModule() {
    var modal = document.getElementById("announcements-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var textEl = document.getElementById("announcements-modal-text")
    var cancelBtn = document.getElementById("announcements-modal-cancel")
    var confirmBtn = document.getElementById("announcements-modal-confirm")

    function openAnnouncementsModal() {
        if (textEl) textEl.value = ""
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeAnnouncementsModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeAnnouncementsModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeAnnouncementsModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            var text = textEl ? textEl.value.trim() : ""
            if (text) {
                fetch("https://" + GetParentResourceName() + "/submitAnnouncement", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ text: text })
                }).catch(function() {})
            }
            closeAnnouncementsModal()
        })
    }

    window.openAnnouncementsModal = openAnnouncementsModal
    window.closeAnnouncementsModal = closeAnnouncementsModal
})()

;(function serverTimeModalModule() {
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
    var tabletEl = document.getElementById("tablet")
    var kickEl = document.getElementById("kick-actions")
    var modal = document.getElementById("modal-changetime")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var timeSlider = document.getElementById("time-slider")
    var timeValue = document.getElementById("time-value")
    var freezeCheckbox = document.getElementById("freeze-time-checkbox")
    var weatherSelect = document.getElementById("weather-select")
    var cancelBtn = document.getElementById("modal-changetime-cancel")
    var confirmBtn = document.getElementById("modal-changetime-confirm")
    var openedFromKickActions = false

    function sendChangeTime(showNotification) {
        var hour = timeSlider ? parseInt(timeSlider.value, 10) : 12
        var freeze = freezeCheckbox ? freezeCheckbox.checked : false
        var weather = weatherSelect ? weatherSelect.value : "CLEAR"
        fetch("https://" + resName + "/changeTime", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ hour: hour, freeze: freeze, weather: weather, showNotification: !!showNotification })
        }).catch(function() {})
    }

    function openServerTimeModal() {
        if (!modal) return
        openedFromKickActions = !!(kickEl && !kickEl.classList.contains("hidden"))
        if (tabletEl) tabletEl.classList.add("hidden")
        if (kickEl) kickEl.classList.add("hidden")
        if (timeValue && timeSlider) timeValue.textContent = (parseInt(timeSlider.value, 10) + "").padStart(2, "0") + ":00"
        modal.classList.remove("hidden")
        modal.setAttribute("aria-hidden", "false")
        requestAnimationFrame(function() {
            requestAnimationFrame(function() {
                modal.classList.add("open")
            })
        })
    }

    function closeChangeTimeModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            if (openedFromKickActions && kickEl) kickEl.classList.remove("hidden")
            else if (tabletEl) tabletEl.classList.remove("hidden")
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut() }, (duration * 1000) + 50)
    }

    if (timeSlider && timeValue) {
        timeSlider.addEventListener("input", function() {
            var h = parseInt(this.value, 10)
            timeValue.textContent = (h + "").padStart(2, "0") + ":00"
            sendChangeTime(false)
        })
    }
    if (weatherSelect) {
        weatherSelect.addEventListener("change", function() {
            sendChangeTime(false)
        })
    }
    if (freezeCheckbox) {
        freezeCheckbox.addEventListener("change", function() {
            sendChangeTime(false)
        })
    }
    if (backdrop) backdrop.addEventListener("click", closeChangeTimeModal)
    modal.addEventListener("click", function(e) {
        if (e.target === modal) closeChangeTimeModal()
    })
    if (cancelBtn) cancelBtn.addEventListener("click", closeChangeTimeModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            sendChangeTime(true)
            closeChangeTimeModal()
        })
    }

    window.openServerTimeModal = openServerTimeModal
    window.closeChangeTimeModal = closeChangeTimeModal
})()

;(function spawnVehicleModalModule() {
    var modal = document.getElementById("spawn-vehicle-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var modelEl = document.getElementById("spawn-vehicle-modal-model")
    var customPlateEl = document.getElementById("spawn-vehicle-modal-customplate")
    var plateWrapEl = document.getElementById("spawn-vehicle-modal-plate-wrap")
    var plateEl = document.getElementById("spawn-vehicle-modal-plate")
    var cancelBtn = document.getElementById("spawn-vehicle-modal-cancel")
    var confirmBtn = document.getElementById("spawn-vehicle-modal-confirm")
    var spawnVehicleModalPlayerId = null

    function openSpawnVehicleModal(playerId) {
        spawnVehicleModalPlayerId = playerId
        if (modelEl) modelEl.value = ""
        if (plateEl) plateEl.value = ""
        if (customPlateEl) customPlateEl.checked = false
        if (plateWrapEl) plateWrapEl.classList.add("hidden")
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeSpawnVehicleModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            spawnVehicleModalPlayerId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (customPlateEl && plateWrapEl) {
        customPlateEl.addEventListener("change", function() {
            if (customPlateEl.checked) plateWrapEl.classList.remove("hidden")
            else plateWrapEl.classList.add("hidden")
        })
    }
    if (backdrop) backdrop.addEventListener("click", closeSpawnVehicleModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeSpawnVehicleModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (spawnVehicleModalPlayerId == null) return
            var model = modelEl ? modelEl.value.trim().toLowerCase() : ""
            if (!model) model = "t20"
            var plate = null
            if (customPlateEl && customPlateEl.checked) {
                var p = plateEl ? plateEl.value.trim() : ""
                plate = p || "jotadev"
            }
            fetch("https://" + GetParentResourceName() + "/submitSpawnVehicle", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: spawnVehicleModalPlayerId, model: model, plate: plate })
            }).catch(function() {})
            closeSpawnVehicleModal()
        })
    }

    window.openSpawnVehicleModal = openSpawnVehicleModal
    window.closeSpawnVehicleModal = closeSpawnVehicleModal
})()

;(function addVehicleGarageModalModule() {
    var modal = document.getElementById("add-vehicle-garage-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var modelEl = document.getElementById("add-vehicle-garage-modal-model")
    var customPlateEl = document.getElementById("add-vehicle-garage-modal-customplate")
    var plateWrapEl = document.getElementById("add-vehicle-garage-modal-plate-wrap")
    var plateEl = document.getElementById("add-vehicle-garage-modal-plate")
    var cancelBtn = document.getElementById("add-vehicle-garage-modal-cancel")
    var confirmBtn = document.getElementById("add-vehicle-garage-modal-confirm")
    var addVehicleGarageModalPlayerId = null

    function openAddVehicleGarageModal(playerId) {
        addVehicleGarageModalPlayerId = playerId
        if (modelEl) modelEl.value = ""
        if (plateEl) plateEl.value = ""
        if (customPlateEl) customPlateEl.checked = false
        if (plateWrapEl) plateWrapEl.classList.add("hidden")
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeAddVehicleGarageModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            addVehicleGarageModalPlayerId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (customPlateEl && plateWrapEl) {
        customPlateEl.addEventListener("change", function() {
            if (customPlateEl.checked) plateWrapEl.classList.remove("hidden")
            else plateWrapEl.classList.add("hidden")
        })
    }
    if (backdrop) backdrop.addEventListener("click", closeAddVehicleGarageModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeAddVehicleGarageModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (addVehicleGarageModalPlayerId == null) return
            var model = modelEl ? modelEl.value.trim().toLowerCase() : ""
            if (!model) model = "t20"
            var plate = null
            if (customPlateEl && customPlateEl.checked) {
                var p = plateEl ? plateEl.value.trim() : ""
                plate = p || "jotadev"
            }
            var pid = addVehicleGarageModalPlayerId
            fetch("https://" + GetParentResourceName() + "/submitAddVehicleToGarage", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: pid, model: model, plate: plate })
            }).then(function() {
                closeAddVehicleGarageModal()
                if (pid != null) {
                    fetch("https://" + GetParentResourceName() + "/requestPlayerVehicles", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ playerId: pid })
                    }).catch(function() {})
                }
            }).catch(function() {
                closeAddVehicleGarageModal()
            })
        })
    }

    window.openAddVehicleGarageModal = openAddVehicleGarageModal
    window.closeAddVehicleGarageModal = closeAddVehicleGarageModal
})()

var playerDetailAddVehicleBtn = document.getElementById("player-detail-add-vehicle-btn")
if (playerDetailAddVehicleBtn) {
    playerDetailAddVehicleBtn.addEventListener("click", function() {
        if (playerDetailAddVehicleBtn.classList.contains("player-detail-section-title-add-no-permission")) return
        var id = window.playerDetailCurrentId
        if (id != null && typeof window.openAddVehicleGarageModal === "function") window.openAddVehicleGarageModal(id)
    })
}

;(function adminDetailModalModule() {
    var modal = document.getElementById("admin-detail-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var closeBtn = document.getElementById("admin-detail-close-btn")
    var saveBtn = document.getElementById("admin-detail-save-btn")
    var changeWrap = document.getElementById("admin-detail-change-pw-wrap")
    var changeUserWrap = document.getElementById("admin-detail-change-user-wrap")
    var editUserBtn = document.getElementById("admin-detail-edit-username-btn")
    var editPwBtn = document.getElementById("admin-detail-edit-password-btn")
    var pwCancelBtn = document.getElementById("admin-detail-pw-cancel-btn")
    var userCancelBtn = document.getElementById("admin-detail-user-cancel-btn")
    var newPwEl = document.getElementById("admin-detail-new-password")
    var repeatPwEl = document.getElementById("admin-detail-repeat-password")
    var newUserEl = document.getElementById("admin-detail-new-username")
    var pwErrorEl = document.getElementById("admin-detail-pw-error")
    var userErrorEl = document.getElementById("admin-detail-user-error")
    function closeAdminDetailModal() {
        if (!modal) return
        var done = false
        function onEnd(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onEnd)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
        }
        modal.addEventListener("transitionend", onEnd)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onEnd()
        else setTimeout(function() { if (!done) onEnd() }, (duration * 1000) + 50)
    }
    if (backdrop) backdrop.addEventListener("click", closeAdminDetailModal)
    if (closeBtn) closeBtn.addEventListener("click", closeAdminDetailModal)
    if (editUserBtn) {
        editUserBtn.addEventListener("click", function() {
            if (changeWrap) changeWrap.classList.add("hidden")
            if (newPwEl) newPwEl.value = ""
            if (repeatPwEl) repeatPwEl.value = ""
            if (pwErrorEl) { pwErrorEl.classList.add("hidden"); pwErrorEl.textContent = "" }
            if (changeUserWrap) changeUserWrap.classList.remove("hidden")
            if (newUserEl) { newUserEl.value = ""; newUserEl.focus() }
            if (userErrorEl) { userErrorEl.classList.add("hidden"); userErrorEl.textContent = "" }
        })
    }
    if (editPwBtn) {
        editPwBtn.addEventListener("click", function() {
            if (changeUserWrap) changeUserWrap.classList.add("hidden")
            if (newUserEl) newUserEl.value = ""
            if (userErrorEl) { userErrorEl.classList.add("hidden"); userErrorEl.textContent = "" }
            if (changeWrap) changeWrap.classList.remove("hidden")
            if (newPwEl) { newPwEl.value = ""; newPwEl.focus() }
            if (repeatPwEl) repeatPwEl.value = ""
            if (pwErrorEl) { pwErrorEl.classList.add("hidden"); pwErrorEl.textContent = "" }
        })
    }
    if (userCancelBtn) {
        userCancelBtn.addEventListener("click", function() {
            if (changeUserWrap) changeUserWrap.classList.add("hidden")
            if (newUserEl) newUserEl.value = ""
            if (userErrorEl) { userErrorEl.classList.add("hidden"); userErrorEl.textContent = "" }
        })
    }
    if (pwCancelBtn) {
        pwCancelBtn.addEventListener("click", function() {
            if (changeWrap) changeWrap.classList.add("hidden")
            if (newPwEl) newPwEl.value = ""
            if (repeatPwEl) repeatPwEl.value = ""
            if (pwErrorEl) { pwErrorEl.classList.add("hidden"); pwErrorEl.textContent = "" }
        })
    }
    var newPwToggle = document.getElementById("admin-detail-new-pw-toggle")
    var newPwIcon = document.getElementById("admin-detail-new-pw-icon")
    var repeatPwToggle = document.getElementById("admin-detail-repeat-pw-toggle")
    var repeatPwIcon = document.getElementById("admin-detail-repeat-pw-icon")
    if (newPwToggle && newPwEl && newPwIcon) {
        newPwToggle.addEventListener("click", function() {
            var isPw = newPwEl.type === "password"
            newPwEl.type = isPw ? "text" : "password"
            newPwIcon.classList.toggle("fa-eye", !isPw)
            newPwIcon.classList.toggle("fa-eye-slash", isPw)
            newPwToggle.setAttribute("aria-label", isPw ? "Ocultar contraseña" : "Mostrar contraseña")
        })
    }
    if (repeatPwToggle && repeatPwEl && repeatPwIcon) {
        repeatPwToggle.addEventListener("click", function() {
            var isPw = repeatPwEl.type === "password"
            repeatPwEl.type = isPw ? "text" : "password"
            repeatPwIcon.classList.toggle("fa-eye", !isPw)
            repeatPwIcon.classList.toggle("fa-eye-slash", isPw)
            repeatPwToggle.setAttribute("aria-label", isPw ? "Ocultar contraseña" : "Mostrar contraseña")
        })
    }
    var changeGroupWrap = document.getElementById("admin-detail-change-group-wrap")
    var editGroupBtn = document.getElementById("admin-detail-edit-group-btn")
    var groupCancelBtn = document.getElementById("admin-detail-group-cancel-btn")
    var groupConfirmBtn = document.getElementById("admin-detail-group-confirm-btn")
    var newGroupSelect = document.getElementById("admin-detail-new-group")
    var groupErrorEl = document.getElementById("admin-detail-group-error")
    if (editGroupBtn) {
        editGroupBtn.addEventListener("click", function() {
            if (changeWrap) changeWrap.classList.add("hidden")
            if (changeUserWrap) changeUserWrap.classList.add("hidden")
            if (newGroupSelect) newGroupSelect.innerHTML = "<option value=\"\">Cargando...</option>"
            if (groupErrorEl) { groupErrorEl.classList.add("hidden"); groupErrorEl.textContent = "" }
            if (changeGroupWrap) changeGroupWrap.classList.remove("hidden")
            fetch("https://" + GetParentResourceName() + "/groupsGetList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) })
                .then(function(r) { return r.json() })
                .then(function(groups) {
                    if (!newGroupSelect) return
                    newGroupSelect.innerHTML = "<option value=\"\">-- Seleccionar grupo --</option>"
                    if (Array.isArray(groups)) {
                        groups.forEach(function(g) {
                            var name = g.grupo || g.name || ""
                            if (!name) return
                            var opt = document.createElement("option")
                            opt.value = name
                            opt.textContent = name
                            newGroupSelect.appendChild(opt)
                        })
                    }
                })
                .catch(function() {
                    if (newGroupSelect) newGroupSelect.innerHTML = "<option value=\"\">Error al cargar grupos</option>"
                })
        })
    }
    if (groupCancelBtn) {
        groupCancelBtn.addEventListener("click", function() {
            if (changeGroupWrap) changeGroupWrap.classList.add("hidden")
            if (groupErrorEl) { groupErrorEl.classList.add("hidden"); groupErrorEl.textContent = "" }
        })
    }
    if (groupConfirmBtn) {
        groupConfirmBtn.addEventListener("click", function() {
            var license = window._adminDetailLicense
            if (!license) return
            var newGroup = newGroupSelect ? (newGroupSelect.value || "").trim() : ""
            if (!newGroup) {
                if (groupErrorEl) { groupErrorEl.textContent = "Selecciona un grupo"; groupErrorEl.classList.remove("hidden") }
                return
            }
            fetch("https://" + GetParentResourceName() + "/changeAdminGroupByLicense", {
                method: "POST", headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ license: license, newGroup: newGroup })
            }).then(function(r) { return r.json() }).then(function(res) {
                if (res && res.ok) {
                    var groupEl = document.getElementById("admin-detail-group")
                    if (groupEl) groupEl.textContent = newGroup
                    if (changeGroupWrap) changeGroupWrap.classList.add("hidden")
                    if (groupErrorEl) { groupErrorEl.classList.add("hidden"); groupErrorEl.textContent = "" }
                } else {
                    if (groupErrorEl) { groupErrorEl.textContent = "Error al cambiar grupo"; groupErrorEl.classList.remove("hidden") }
                }
            }).catch(function() {
                if (groupErrorEl) { groupErrorEl.textContent = "Error al cambiar grupo"; groupErrorEl.classList.remove("hidden") }
            })
        })
    }
    if (saveBtn) {
        saveBtn.addEventListener("click", function() {
            var license = window._adminDetailLicense
            if (!license) return
            var resName = GetParentResourceName()
            var sendUser = changeUserWrap && !changeUserWrap.classList.contains("hidden") && newUserEl
            var sendPw = changeWrap && !changeWrap.classList.contains("hidden") && newPwEl && repeatPwEl
            if (sendUser) {
                var newUser = (newUserEl.value || "").trim()
                if (newUser.length < 2) {
                    if (userErrorEl) { userErrorEl.textContent = "Mínimo 2 caracteres"; userErrorEl.classList.remove("hidden") }
                    return
                }
                if (userErrorEl) userErrorEl.classList.add("hidden")
            }
            if (sendPw) {
                var newPw = (newPwEl.value || "").trim()
                var repeat = (repeatPwEl.value || "").trim()
                if (newPw.length < 4) {
                    if (pwErrorEl) { pwErrorEl.textContent = "Mínimo 4 caracteres"; pwErrorEl.classList.remove("hidden") }
                    return
                }
                if (newPw !== repeat) {
                    if (pwErrorEl) { pwErrorEl.textContent = "Las contraseñas no coinciden"; pwErrorEl.classList.remove("hidden") }
                    return
                }
                if (pwErrorEl) pwErrorEl.classList.add("hidden")
            }
            if (sendUser) fetch("https://" + resName + "/changeAdminUser", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ license: license, newUser: (newUserEl.value || "").trim() }) }).catch(function() {})
            if (sendPw) {
                window._adminDetailLastNewPassword = (newPwEl.value || "").trim()
                fetch("https://" + resName + "/changeAdminPassword", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ license: license, newPassword: (newPwEl.value || "").trim() }) }).catch(function() {})
            }
            closeAdminDetailModal()
        })
    }
    window.closeAdminDetailModal = closeAdminDetailModal
    var resetTimeBtn = document.getElementById("admin-detail-reset-time-btn")
    var resetConfirmModal = document.getElementById("admin-detail-reset-confirm-modal")
    var resetConfirmBackdrop = resetConfirmModal ? resetConfirmModal.querySelector(".ban-modal-backdrop") : null
    var resetConfirmCancel = document.getElementById("admin-detail-reset-confirm-cancel")
    var resetConfirmOk = document.getElementById("admin-detail-reset-confirm-ok")
    function openAdminResetTimeConfirmModal() {
        if (!resetConfirmModal) return
        if (typeof applyTranslationsFor === "function") applyTranslationsFor(resetConfirmModal)
        resetConfirmModal.classList.remove("hidden")
        resetConfirmModal.setAttribute("aria-hidden", "false")
        requestAnimationFrame(function() {
            requestAnimationFrame(function() { resetConfirmModal.classList.add("open") })
        })
    }
    function closeAdminResetTimeConfirmModal() {
        if (!resetConfirmModal) return
        var rd = false
        function onEnd(ev) {
            if (rd) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            rd = true
            resetConfirmModal.removeEventListener("transitionend", onEnd)
            resetConfirmModal.classList.remove("open", "closing")
            resetConfirmModal.classList.add("hidden")
            resetConfirmModal.setAttribute("aria-hidden", "true")
        }
        resetConfirmModal.addEventListener("transitionend", onEnd)
        resetConfirmModal.classList.add("closing")
        var dur = parseFloat(getComputedStyle(resetConfirmModal).transitionDuration) || 0.22
        if (dur <= 0) onEnd()
        else setTimeout(function() { if (!rd) onEnd() }, (dur * 1000) + 50)
    }
    if (resetTimeBtn) {
        resetTimeBtn.addEventListener("click", function() {
            if (!window._adminDetailLicense) return
            openAdminResetTimeConfirmModal()
        })
    }
    if (resetConfirmBackdrop) resetConfirmBackdrop.addEventListener("click", closeAdminResetTimeConfirmModal)
    if (resetConfirmCancel) resetConfirmCancel.addEventListener("click", closeAdminResetTimeConfirmModal)
    if (resetConfirmOk) {
        resetConfirmOk.addEventListener("click", function() {
            var lic = window._adminDetailLicense
            if (!lic) {
                closeAdminResetTimeConfirmModal()
                return
            }
            fetch("https://" + GetParentResourceName() + "/resetAdminTimeStats", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ license: lic }) }).catch(function() {})
            closeAdminResetTimeConfirmModal()
        })
    }
    window.closeAdminResetTimeConfirmModal = closeAdminResetTimeConfirmModal
    var logoutSessionBtn = document.getElementById("admin-detail-logout-session-btn")
    var logoutConfirmModal = document.getElementById("admin-detail-logout-confirm-modal")
    var logoutConfirmBackdrop = logoutConfirmModal ? logoutConfirmModal.querySelector(".ban-modal-backdrop") : null
    var logoutConfirmCancel = document.getElementById("admin-detail-logout-confirm-cancel")
    var logoutConfirmOk = document.getElementById("admin-detail-logout-confirm-ok")
    function openAdminLogoutSessionConfirmModal() {
        if (!logoutConfirmModal) return
        if (typeof applyTranslationsFor === "function") applyTranslationsFor(logoutConfirmModal)
        logoutConfirmModal.classList.remove("hidden")
        logoutConfirmModal.setAttribute("aria-hidden", "false")
        requestAnimationFrame(function() {
            requestAnimationFrame(function() { logoutConfirmModal.classList.add("open") })
        })
    }
    function closeAdminLogoutSessionConfirmModal() {
        if (!logoutConfirmModal) return
        var ld = false
        function onEnd(ev) {
            if (ld) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            ld = true
            logoutConfirmModal.removeEventListener("transitionend", onEnd)
            logoutConfirmModal.classList.remove("open", "closing")
            logoutConfirmModal.classList.add("hidden")
            logoutConfirmModal.setAttribute("aria-hidden", "true")
        }
        logoutConfirmModal.addEventListener("transitionend", onEnd)
        logoutConfirmModal.classList.add("closing")
        var ldur = parseFloat(getComputedStyle(logoutConfirmModal).transitionDuration) || 0.22
        if (ldur <= 0) onEnd()
        else setTimeout(function() { if (!ld) onEnd() }, (ldur * 1000) + 50)
    }
    if (logoutSessionBtn) {
        logoutSessionBtn.addEventListener("click", function() {
            if (window._adminDetailStaffId == null) return
            openAdminLogoutSessionConfirmModal()
        })
    }
    if (logoutConfirmBackdrop) logoutConfirmBackdrop.addEventListener("click", closeAdminLogoutSessionConfirmModal)
    if (logoutConfirmCancel) logoutConfirmCancel.addEventListener("click", closeAdminLogoutSessionConfirmModal)
    if (logoutConfirmOk) {
        logoutConfirmOk.addEventListener("click", function() {
            var sid = window._adminDetailStaffId
            if (sid == null) {
                closeAdminLogoutSessionConfirmModal()
                return
            }
            fetch("https://" + GetParentResourceName() + "/logoutAdminStaffSession", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: sid }) }).catch(function() {})
            closeAdminLogoutSessionConfirmModal()
            closeAdminDetailModal()
        })
    }
    window.closeAdminLogoutSessionConfirmModal = closeAdminLogoutSessionConfirmModal
})()

function formatVehicleModelToName(model) {
    if (!model || typeof model !== "string") return "Vehicle"
    var s = String(model).trim().replace(/_/g, " ")
    if (!s) return "Vehicle"
    return s.split(/\s+/).map(function(w) { return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase() }).join(" ")
}

function renderPlayerDetailVehicles(vehicles) {
    var vehiclesTbody = document.getElementById("player-detail-vehicles-tbody")
    if (!vehiclesTbody) return
    var list = Array.isArray(vehicles) ? vehicles : []
    if (list.length === 0) vehiclesTbody.innerHTML = "<tr class=\"player-detail-table-empty\"><td colspan=\"4\" class=\"player-detail-table-empty-cell\"><div class=\"player-detail-empty-vehicles\"><i class=\"fa-solid fa-car\"></i><span>" + ((typeof window !== "undefined" && window.t && window.t("player_no_vehicles_in_garage")) || "There are no vehicles in this garage") + "</span></div></td></tr>"
    else {
        var sp = window.sectionPerms || {}
        var playersAllowed = sp.players === true || sp.players === "1" || sp.players === 1
        var deleteVehicleAllowed = playersAllowed && (sp.delete_player_vehicle === true || sp.delete_player_vehicle === "1" || sp.delete_player_vehicle === 1)
        var noPermClass = deleteVehicleAllowed ? "" : " player-detail-table-remove-btn-no-permission"
        vehiclesTbody.innerHTML = list.map(function(row) {
            var name = (row.name && row.name !== "Vehicle" ? row.name : null) || (row.model ? formatVehicleModelToName(row.model) : null) || row.label || "—"
            name = String(name).replace(/</g, "&lt;")
            var plate = String(row.plate != null ? row.plate : (row.plateNumber != null ? row.plateNumber : "—")).replace(/</g, "&lt;")
            var plateRaw = (row.plate != null ? row.plate : row.plateNumber) || ""
            var parking = String(row.parking != null ? row.parking : (row.garage != null ? row.garage : "—")).replace(/</g, "&lt;")
            return "<tr class=\"player-detail-table-data-row\"><td>" + name + "</td><td>" + plate + "</td><td>" + parking + "</td><td class=\"player-detail-table-cell-action\"><button type=\"button\" class=\"player-detail-table-remove-btn" + noPermClass + "\" data-plate=\"" + String(plateRaw).replace(/"/g, "&quot;") + "\" title=\"Eliminar vehículo\"><i class=\"fa-solid fa-xmark\"></i></button></td></tr>"
        }).join("")
    }
}

function updatePlayerDetailVehicleAddPermission() {
    var addBtn = document.getElementById("player-detail-add-vehicle-btn")
    if (!addBtn) return
    if (window.playerDetailOffline === true) {
        addBtn.classList.add("player-detail-section-title-add-no-permission")
        addBtn.setAttribute("data-perm-allowed", "false")
        return
    }
    var sp = window.sectionPerms || {}
    var playersAllowed = sp.players === true || sp.players === "1" || sp.players === 1
    var addAllowed = playersAllowed && (sp.add_player_vehicle === true || sp.add_player_vehicle === "1" || sp.add_player_vehicle === 1)
    addBtn.classList.toggle("player-detail-section-title-add-no-permission", !addAllowed)
    addBtn.setAttribute("data-perm-allowed", addAllowed ? "true" : "false")
}

window.frozenPlayerIds = window.frozenPlayerIds || {}

function updateFreezeButtonState() {
    var freezeBtn = document.querySelector(".player-detail-fn-btn-freeze[data-player-action=\"freeze\"]")
    if (!freezeBtn) return
    if (window.playerDetailOffline === true) {
        freezeBtn.classList.remove("player-detail-fn-btn-active")
        var spanOff = freezeBtn.querySelector("span")
        if (spanOff) spanOff.textContent = "Freeze"
        return
    }
    var id = window.playerDetailCurrentId
    var isFrozen = id != null && window.frozenPlayerIds[id]
    if (isFrozen) {
        freezeBtn.classList.add("player-detail-fn-btn-active")
        var span = freezeBtn.querySelector("span")
        if (span) span.textContent = "Unfreeze"
    } else {
        freezeBtn.classList.remove("player-detail-fn-btn-active")
        var span = freezeBtn.querySelector("span")
        if (span) span.textContent = "Freeze"
    }
}

;(function ckConfirmModalModule() {
    var modal = document.getElementById("ck-confirm-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var cancelBtn = document.getElementById("ck-confirm-modal-cancel")
    var confirmBtn = document.getElementById("ck-confirm-modal-confirm")
    var ckConfirmModalPlayerId = null
    var ckConfirmModalOfflineIdentifier = null

    function openCKConfirmModal(playerId, offlineIdentifier) {
        var oid = offlineIdentifier != null ? String(offlineIdentifier).trim() : ""
        if (oid !== "") {
            ckConfirmModalPlayerId = null
            ckConfirmModalOfflineIdentifier = oid
        } else {
            ckConfirmModalPlayerId = playerId
            ckConfirmModalOfflineIdentifier = null
        }
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeCKConfirmModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            ckConfirmModalPlayerId = null
            ckConfirmModalOfflineIdentifier = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeCKConfirmModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeCKConfirmModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (ckConfirmModalPlayerId == null && ckConfirmModalOfflineIdentifier == null) return
            var ckBody = { action: "ck" }
            if (ckConfirmModalOfflineIdentifier != null) ckBody.offlineIdentifier = ckConfirmModalOfflineIdentifier
            else ckBody.playerId = ckConfirmModalPlayerId
            fetch("https://" + GetParentResourceName() + "/playerDetailAction", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(ckBody)
            }).catch(function() {})
            closeCKConfirmModal()
        })
    }

    window.openCKConfirmModal = openCKConfirmModal
    window.closeCKConfirmModal = closeCKConfirmModal
})()

;(function clearInvConfirmModalModule() {
    var modal = document.getElementById("clearinv-confirm-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var cancelBtn = document.getElementById("clearinv-confirm-modal-cancel")
    var confirmBtn = document.getElementById("clearinv-confirm-modal-confirm")
    var clearInvConfirmModalPlayerId = null

    function openClearInvConfirmModal(playerId) {
        clearInvConfirmModalPlayerId = playerId
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeClearInvConfirmModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            clearInvConfirmModalPlayerId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeClearInvConfirmModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeClearInvConfirmModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (clearInvConfirmModalPlayerId == null) return
            fetch("https://" + GetParentResourceName() + "/playerDetailAction", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ action: "clearinv", playerId: clearInvConfirmModalPlayerId })
            }).catch(function() {})
            closeClearInvConfirmModal()
        })
    }

    window.openClearInvConfirmModal = openClearInvConfirmModal
    window.closeClearInvConfirmModal = closeClearInvConfirmModal
})()

;(function vehicleDeleteConfirmModalModule() {
    var modal = document.getElementById("vehicle-delete-confirm-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var cancelBtn = document.getElementById("vehicle-delete-confirm-modal-cancel")
    var confirmBtn = document.getElementById("vehicle-delete-confirm-modal-confirm")
    var messageEl = document.getElementById("vehicle-delete-confirm-modal-message")
    var vehicleDeleteConfirmPlayerId = null
    var vehicleDeleteConfirmOfflineIdentifier = null
    var vehicleDeleteConfirmPlate = null
    var vehicleDeleteConfirmRow = null

    function openVehicleDeleteConfirmModal(playerId, plate, rowEl, offlineIdentifier) {
        var oid = offlineIdentifier != null ? String(offlineIdentifier).trim() : ""
        if (oid !== "") {
            vehicleDeleteConfirmPlayerId = null
            vehicleDeleteConfirmOfflineIdentifier = oid
        } else {
            vehicleDeleteConfirmPlayerId = playerId
            vehicleDeleteConfirmOfflineIdentifier = null
        }
        vehicleDeleteConfirmPlate = plate
        vehicleDeleteConfirmRow = rowEl || null
        if (messageEl) {
            var txtPlate = String(plate || "—").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var template = ((typeof window !== "undefined" && window.t && window.t("modal_delete_vehicle_message_with_plate")) || "¿Estás seguro de que quieres eliminar el vehículo con matrícula %s del jugador?")
            messageEl.innerHTML = template.replace("%s", "<b>" + txtPlate + "</b>")
        }
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeVehicleDeleteConfirmModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            vehicleDeleteConfirmPlayerId = null
            vehicleDeleteConfirmOfflineIdentifier = null
            vehicleDeleteConfirmPlate = null
            vehicleDeleteConfirmRow = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeVehicleDeleteConfirmModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeVehicleDeleteConfirmModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (!vehicleDeleteConfirmPlate) return
            if (vehicleDeleteConfirmPlayerId == null && (vehicleDeleteConfirmOfflineIdentifier == null || vehicleDeleteConfirmOfflineIdentifier === "")) return
            var delBody = { plate: vehicleDeleteConfirmPlate }
            if (vehicleDeleteConfirmOfflineIdentifier != null && String(vehicleDeleteConfirmOfflineIdentifier).trim() !== "") {
                delBody.offlineIdentifier = String(vehicleDeleteConfirmOfflineIdentifier).trim()
            } else {
                delBody.playerId = vehicleDeleteConfirmPlayerId
            }
            fetch("https://" + GetParentResourceName() + "/deletePlayerVehicle", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(delBody)
            }).catch(function() {})
            if (vehicleDeleteConfirmRow && vehicleDeleteConfirmRow.parentNode) {
                var tbody = vehicleDeleteConfirmRow.parentNode
                tbody.removeChild(vehicleDeleteConfirmRow)
                if (!tbody.querySelector("tr")) {
                    tbody.innerHTML = "<tr class=\"player-detail-table-empty\"><td colspan=\"4\" class=\"player-detail-table-empty-cell\"><div class=\"player-detail-empty-vehicles\"><i class=\"fa-solid fa-car\"></i><span>" + ((typeof window !== "undefined" && window.t && window.t("player_no_vehicles_in_garage")) || "There are no vehicles in this garage") + "</span></div></td></tr>"
                }
            }
            closeVehicleDeleteConfirmModal()
        })
    }

    window.openVehicleDeleteConfirmModal = openVehicleDeleteConfirmModal
    window.closeVehicleDeleteConfirmModal = closeVehicleDeleteConfirmModal
})()

;(function instanciaModalModule() {
    var modal = document.getElementById("instancia-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var bucketInput = document.getElementById("instancia-modal-bucket")
    var cancelBtn = document.getElementById("instancia-modal-cancel")
    var confirmBtn = document.getElementById("instancia-modal-confirm")
    var instanciaModalPlayerId = null

    function openInstanciaModal(playerId) {
        instanciaModalPlayerId = playerId
        if (bucketInput) bucketInput.value = "0"
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                    if (bucketInput) bucketInput.focus()
                })
            })
        }
    }

    function closeInstanciaModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            instanciaModalPlayerId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut() }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeInstanciaModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeInstanciaModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (instanciaModalPlayerId == null) return
            var bucket = parseInt(bucketInput && bucketInput.value !== "" ? bucketInput.value : "0", 10)
            if (isNaN(bucket) || bucket < 0) bucket = 0
            fetch("https://" + GetParentResourceName() + "/playerDetailAction", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ action: "instancia", playerId: instanciaModalPlayerId, bucket: bucket })
            }).catch(function() {})
            closeInstanciaModal()
        })
    }

    window.openInstanciaModal = openInstanciaModal
    window.closeInstanciaModal = closeInstanciaModal
})()

;(function unbanConfirmModalModule() {
    var modal = document.getElementById("unban-confirm-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var cancelBtn = document.getElementById("unban-confirm-modal-cancel")
    var confirmBtn = document.getElementById("unban-confirm-modal-confirm")
    var unbanConfirmModalBanId = null

    function openUnbanConfirmModal(banId) {
        unbanConfirmModalBanId = banId
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeUnbanConfirmModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            unbanConfirmModalBanId = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeUnbanConfirmModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeUnbanConfirmModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (unbanConfirmModalBanId == null) return
            fetch("https://" + GetParentResourceName() + "/unbanBan", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ banId: unbanConfirmModalBanId }) }).catch(function() {})
            closeUnbanConfirmModal()
            setTimeout(function() {
                fetch("https://" + GetParentResourceName() + "/requestBansList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
            }, 200)
        })
    }

    window.openUnbanConfirmModal = openUnbanConfirmModal
    window.closeUnbanConfirmModal = closeUnbanConfirmModal
})()

;(function playerNotesModalModule() {
    var modal = document.getElementById("player-notes-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var listEl = document.getElementById("player-notes-list")
    var emptyEl = document.getElementById("player-notes-empty")
    var inputEl = document.getElementById("player-notes-input")
    var cancelBtn = document.getElementById("player-notes-modal-cancel")
    var confirmBtn = document.getElementById("player-notes-modal-confirm")
    var playerNotesModalPlayerId = null
    var playerNotesModalOfflineIdentifier = null
    var currentNotes = []

    function esc(s) {
        return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
    }

    function renderNotesList() {
        if (!listEl) return
        var notes = Array.isArray(currentNotes) ? currentNotes : []
        if (notes.length === 0) {
            listEl.innerHTML = ""
            if (emptyEl) emptyEl.classList.remove("hidden")
            return
        }
        if (emptyEl) emptyEl.classList.add("hidden")
        listEl.innerHTML = notes.map(function(note) {
            var noteId = esc(note && note.note_id ? note.note_id : "")
            var noteTs = note && note.timestamp != null ? Number(note.timestamp) : ""
            var author = esc(note && note.author ? note.author : "—")
            var date = esc(note && note.date ? note.date : "—")
            var text = esc(note && note.text ? note.text : "")
            var byLabel = ((typeof window !== "undefined" && window.t && window.t("player_notes_by")) || "By")
            var deleteTitle = ((typeof window !== "undefined" && window.t && window.t("player_notes_delete")) || "Delete note")
            return "<div class=\"player-notes-item\" data-note-id=\"" + noteId + "\" data-note-ts=\"" + esc(noteTs) + "\" data-note-author=\"" + author + "\" data-note-text=\"" + text + "\"><div class=\"player-notes-item-head\"><div class=\"player-notes-item-meta\">" + esc(byLabel) + " " + author + " - " + date + "</div><button type=\"button\" class=\"player-notes-item-delete\" title=\"" + esc(deleteTitle) + "\" aria-label=\"" + esc(deleteTitle) + "\"><i class=\"fa-solid fa-trash\"></i></button></div><div class=\"player-notes-item-text\">" + text + "</div></div>"
        }).join("")
    }

    function openPlayerNotesModal(playerId, offlineIdentifier) {
        var oid = offlineIdentifier != null ? String(offlineIdentifier).trim() : ""
        if (oid !== "") {
            playerNotesModalPlayerId = null
            playerNotesModalOfflineIdentifier = oid
        } else {
            playerNotesModalPlayerId = playerId
            playerNotesModalOfflineIdentifier = null
        }
        currentNotes = []
        if (inputEl) inputEl.value = ""
        renderNotesList()
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
        var reqBody = oid !== "" ? { offlineIdentifier: oid } : { playerId: playerId }
        fetch("https://" + GetParentResourceName() + "/requestPlayerNotes", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(reqBody)
        }).catch(function() {})
    }

    function closePlayerNotesModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            playerNotesModalPlayerId = null
            playerNotesModalOfflineIdentifier = null
            currentNotes = []
            if (inputEl) inputEl.value = ""
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut() }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closePlayerNotesModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closePlayerNotesModal)
    if (listEl) {
        listEl.addEventListener("click", function(e) {
            var btn = e.target && e.target.closest && e.target.closest(".player-notes-item-delete")
            if (!btn || (playerNotesModalPlayerId == null && playerNotesModalOfflineIdentifier == null)) return
            var row = btn.closest(".player-notes-item")
            if (!row) return
            var noteId = row.getAttribute("data-note-id") || ""
            var noteTs = row.getAttribute("data-note-ts")
            var noteAuthor = row.getAttribute("data-note-author") || ""
            var noteText = row.getAttribute("data-note-text") || ""
            var delBody = {
                noteId: noteId,
                noteTimestamp: noteTs ? Number(noteTs) : null,
                noteAuthor: noteAuthor,
                noteText: noteText
            }
            if (playerNotesModalOfflineIdentifier != null) delBody.offlineIdentifier = playerNotesModalOfflineIdentifier
            else delBody.playerId = playerNotesModalPlayerId
            fetch("https://" + GetParentResourceName() + "/deletePlayerNote", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(delBody)
            }).catch(function() {})
        })
    }
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (playerNotesModalPlayerId == null && playerNotesModalOfflineIdentifier == null) return
            var text = inputEl ? String(inputEl.value || "").trim() : ""
            if (!text) return
            var addBody = { text: text }
            if (playerNotesModalOfflineIdentifier != null) addBody.offlineIdentifier = playerNotesModalOfflineIdentifier
            else addBody.playerId = playerNotesModalPlayerId
            fetch("https://" + GetParentResourceName() + "/addPlayerNote", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(addBody)
            }).catch(function() {})
        })
    }

    window.openPlayerNotesModal = openPlayerNotesModal
    window.closePlayerNotesModal = closePlayerNotesModal
    window.setPlayerNotesData = function(playerId, offlineIdentifier, notes) {
        var match = false
        if (playerNotesModalOfflineIdentifier != null) {
            match = offlineIdentifier != null && String(offlineIdentifier) === String(playerNotesModalOfflineIdentifier)
        } else {
            match = playerNotesModalPlayerId != null && Number(playerNotesModalPlayerId) === Number(playerId)
        }
        if (!match) return
        currentNotes = Array.isArray(notes) ? notes : []
        if (inputEl) inputEl.value = ""
        renderNotesList()
    }
})()

;(function manageMoneyModalModule() {
    var modal = document.getElementById("manage-money-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var actionEl = document.getElementById("manage-money-modal-action")
    var typeEl = document.getElementById("manage-money-modal-type")
    var amountEl = document.getElementById("manage-money-modal-amount")
    var cancelBtn = document.getElementById("manage-money-modal-cancel")
    var confirmBtn = document.getElementById("manage-money-modal-confirm")
    var manageMoneyModalPlayerId = null
    var manageMoneyModalOfflineIdentifier = null

    function openManageMoneyModal(playerId, offlineIdentifier) {
        var oid = offlineIdentifier != null ? String(offlineIdentifier).trim() : ""
        if (oid !== "") {
            manageMoneyModalPlayerId = null
            manageMoneyModalOfflineIdentifier = oid
        } else {
            manageMoneyModalPlayerId = playerId
            manageMoneyModalOfflineIdentifier = null
        }
        if (actionEl) actionEl.value = "give"
        if (typeEl) typeEl.value = "cash"
        if (amountEl) amountEl.value = ""
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
    }

    function closeManageMoneyModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            manageMoneyModalPlayerId = null
            manageMoneyModalOfflineIdentifier = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    if (backdrop) backdrop.addEventListener("click", closeManageMoneyModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeManageMoneyModal)
    function formatMoney(n) {
        if (n == null || isNaN(n)) return "—"
        var s = String(Math.floor(Number(n)))
        var out = ""
        for (var i = 0; i < s.length; i++) {
            if (i > 0 && (s.length - i) % 3 === 0) out += " "
            out += s[i]
        }
        return "$ " + out
    }

    function parseDisplayedMoney(text) {
        if (!text || typeof text !== "string") return 0
        var num = text.replace(/\$/g, "").replace(/\s/g, "").replace(/,/g, "").trim()
        var n = parseInt(num, 10)
        return isNaN(n) ? 0 : n
    }

    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (manageMoneyModalPlayerId == null && manageMoneyModalOfflineIdentifier == null) return
            var action = actionEl ? actionEl.value : "give"
            if (action !== "withdraw") action = "give"
            var moneyType = typeEl ? typeEl.value : "cash"
            if (moneyType !== "bank" && moneyType !== "black_money") moneyType = "cash"
            var amount = amountEl ? parseInt(amountEl.value, 10) : 0
            if (!amount || amount < 1) return
            var moneyBody = { action: action, moneyType: moneyType, amount: amount }
            if (manageMoneyModalOfflineIdentifier != null) moneyBody.offlineIdentifier = manageMoneyModalOfflineIdentifier
            else moneyBody.playerId = manageMoneyModalPlayerId
            fetch("https://" + GetParentResourceName() + "/submitManageMoney", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(moneyBody)
            }).catch(function() {})
            var offlineMoneyMatch = window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && manageMoneyModalOfflineIdentifier != null && String(window.playerDetailOfflineIdentifier) === String(manageMoneyModalOfflineIdentifier)
            if (manageMoneyModalPlayerId === window.playerDetailCurrentId || offlineMoneyMatch) {
                var moneyEl = document.getElementById("player-detail-money")
                var bankEl = document.getElementById("player-detail-bank")
                var delta = action === "give" ? amount : -amount
                if (moneyType === "cash" && moneyEl) {
                    var current = parseDisplayedMoney(moneyEl.textContent)
                    moneyEl.textContent = formatMoney(Math.max(0, current + delta))
                }
                if (moneyType === "bank" && bankEl) {
                    var currentBank = parseDisplayedMoney(bankEl.textContent)
                    bankEl.textContent = formatMoney(Math.max(0, currentBank + delta))
                }
                if (moneyType === "black_money") {
                    var blackEl = document.getElementById("player-detail-blackmoney")
                    if (blackEl) {
                        var currentBlack = parseDisplayedMoney(blackEl.textContent)
                        blackEl.textContent = formatMoney(Math.max(0, currentBlack + delta))
                    }
                }
            }
            closeManageMoneyModal()
        })
    }

    window.openManageMoneyModal = openManageMoneyModal
    window.closeManageMoneyModal = closeManageMoneyModal
})()

;(function giveItemsModalModule() {
    var modal = document.getElementById("give-items-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var listEl = document.getElementById("give-items-modal-list")
    var searchEl = document.getElementById("give-items-modal-search")
    var cartListEl = document.getElementById("give-items-modal-cart-list")
    var cartEmptyEl = document.getElementById("give-items-modal-cart-empty")
    var inventoryListEl = document.getElementById("give-items-modal-inventory")
    var inventoryEmptyEl = document.getElementById("give-items-modal-inventory-empty")
    var inventoryLoadingEl = document.getElementById("give-items-modal-inventory-loading")
    var cancelBtn = document.getElementById("give-items-modal-cancel")
    var confirmBtn = document.getElementById("give-items-modal-confirm")
    var giveItemsModalPlayerId = null
    var giveItemsModalItems = []
    var giveItemsModalSelected = []
    var giveItemsModalPlayerInventory = []

    function isItemInCart(itemName) {
        return giveItemsModalSelected.some(function(entry) { return entry.name === itemName })
    }

    function renderList() {
        if (!listEl) return
        var q = (searchEl && searchEl.value) ? searchEl.value.trim().toLowerCase() : ""
        var filtered = giveItemsModalItems
        if (q) {
            filtered = giveItemsModalItems.filter(function(item) {
                var name = (item.name || "").toLowerCase()
                var label = (item.label || "").toLowerCase()
                return name.indexOf(q) !== -1 || label.indexOf(q) !== -1
            })
        }
        listEl.innerHTML = ""
        if (filtered.length === 0) {
            var emptyDiv = document.createElement("div")
            emptyDiv.className = "give-items-item give-items-list-empty"
            emptyDiv.style.cursor = "default"
            var msg = q ? "No se han encontrado ítems en su búsqueda" : "No hay ítems disponibles"
            emptyDiv.innerHTML = "<i class=\"fa-solid fa-magnifying-glass give-items-list-empty-icon\"></i><span>" + msg + "</span>"
            listEl.appendChild(emptyDiv)
            return
        }
        filtered.forEach(function(item) {
            var name = (item.name || "").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var label = (item.label != null && item.label !== item.name) ? (item.label || "").replace(/</g, "&lt;").replace(/>/g, "&gt;") : ""
            var isSelected = isItemInCart(item.name)
            var div = document.createElement("div")
            div.className = "give-items-item" + (isSelected ? " selected" : "")
            div.setAttribute("data-item-name", item.name)
            div.innerHTML = "<span class=\"give-items-item-name\">" + name + "</span>" + (label ? "<span class=\"give-items-item-label\">" + label + "</span>" : "")
            div.addEventListener("click", function() {
                if (isItemInCart(item.name)) return
                giveItemsModalSelected.push({ name: item.name, label: item.label || item.name, amount: 1 })
                renderList()
                renderCart()
            })
            listEl.appendChild(div)
        })
    }

    function renderCart() {
        if (!cartListEl) return
        cartListEl.innerHTML = ""
        giveItemsModalSelected.forEach(function(entry, index) {
            var row = document.createElement("div")
            row.className = "give-items-cart-item"
            var labelSpan = document.createElement("span")
            labelSpan.className = "give-items-cart-item-label"
            labelSpan.textContent = entry.label || entry.name || ""
            var qtyInput = document.createElement("input")
            qtyInput.type = "number"
            qtyInput.className = "give-items-cart-item-qty"
            qtyInput.min = 1
            qtyInput.value = entry.amount
            qtyInput.addEventListener("input", function() {
                var val = parseInt(qtyInput.value, 10)
                if (val >= 1) giveItemsModalSelected[index].amount = val
            })
            qtyInput.addEventListener("change", function() {
                var val = parseInt(qtyInput.value, 10)
                if (!val || val < 1) { qtyInput.value = 1; giveItemsModalSelected[index].amount = 1 }
            })
            var removeBtn = document.createElement("button")
            removeBtn.type = "button"
            removeBtn.className = "give-items-cart-item-remove"
            removeBtn.setAttribute("aria-label", "Quitar")
            removeBtn.innerHTML = "<i class=\"fa-solid fa-xmark\"></i>"
            removeBtn.addEventListener("click", function() {
                giveItemsModalSelected.splice(index, 1)
                renderList()
                renderCart()
            })
            row.appendChild(labelSpan)
            row.appendChild(qtyInput)
            row.appendChild(removeBtn)
            cartListEl.appendChild(row)
        })
        if (cartEmptyEl) cartEmptyEl.style.display = giveItemsModalSelected.length ? "none" : "block"
    }

    function requestPlayerInventoryRefresh() {
        if (giveItemsModalPlayerId == null || !inventoryLoadingEl) return
        if (inventoryLoadingEl) inventoryLoadingEl.classList.remove("hidden")
        if (inventoryEmptyEl) inventoryEmptyEl.classList.add("hidden")
        if (inventoryListEl) inventoryListEl.innerHTML = ""
        fetch("https://" + GetParentResourceName() + "/requestPlayerInventory", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: giveItemsModalPlayerId }) }).catch(function() {
            if (inventoryLoadingEl) inventoryLoadingEl.classList.add("hidden")
        })
    }

    function renderPlayerInventory(inventory) {
        if (inventoryLoadingEl) inventoryLoadingEl.classList.add("hidden")
        giveItemsModalPlayerInventory = Array.isArray(inventory) ? inventory : []
        if (!inventoryListEl) return
        inventoryListEl.innerHTML = ""
        if (giveItemsModalPlayerInventory.length === 0) {
            if (inventoryEmptyEl) inventoryEmptyEl.classList.remove("hidden")
            return
        }
        if (inventoryEmptyEl) inventoryEmptyEl.classList.add("hidden")
        giveItemsModalPlayerInventory.forEach(function(item) {
            var name = (item.name || "").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var label = (item.label || item.name || "").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var count = parseInt(item.count, 10) || 1
            var slot = item.slot
            var row = document.createElement("div")
            row.className = "give-items-inventory-item"
            row.innerHTML = "<span class=\"give-items-inventory-item-label\">" + label + "</span><span class=\"give-items-inventory-item-count\">x" + count + "</span>"
            var removeOne = document.createElement("button")
            removeOne.type = "button"
            removeOne.className = "give-items-inventory-item-remove"
            removeOne.setAttribute("aria-label", "Quitar 1")
            removeOne.innerHTML = "<i class=\"fa-solid fa-minus\"></i>"
            removeOne.addEventListener("click", function() {
                fetch("https://" + GetParentResourceName() + "/removePlayerItem", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: giveItemsModalPlayerId, itemName: item.name, amount: 1, slot: slot }) }).catch(function() {})
                setTimeout(requestPlayerInventoryRefresh, 300)
            })
            var removeAll = document.createElement("button")
            removeAll.type = "button"
            removeAll.className = "give-items-inventory-item-remove give-items-inventory-item-remove-all"
            removeAll.setAttribute("aria-label", "Quitar todo")
            removeAll.innerHTML = "<i class=\"fa-solid fa-trash\"></i>"
            removeAll.addEventListener("click", function() {
                fetch("https://" + GetParentResourceName() + "/removePlayerItem", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: giveItemsModalPlayerId, itemName: item.name, amount: count, slot: slot }) }).catch(function() {})
                setTimeout(requestPlayerInventoryRefresh, 300)
            })
            row.appendChild(removeOne)
            row.appendChild(removeAll)
            inventoryListEl.appendChild(row)
        })
    }

    function openGiveItemsModal(playerId) {
        giveItemsModalPlayerId = playerId
        giveItemsModalItems = []
        giveItemsModalSelected = []
        giveItemsModalPlayerInventory = []
        if (searchEl) searchEl.value = ""
        if (listEl) listEl.innerHTML = "<div class=\"give-items-item give-items-list-loading\"><i class=\"fa-solid fa-spinner give-items-list-loading-icon\"></i><span>" + ((typeof window !== "undefined" && window.t && window.t("modal_give_items_loading")) || "Cargando ítems...") + "</span></div>"
        if (cartListEl) cartListEl.innerHTML = ""
        if (cartEmptyEl) cartEmptyEl.style.display = "block"
        if (inventoryListEl) inventoryListEl.innerHTML = ""
        if (inventoryEmptyEl) inventoryEmptyEl.classList.add("hidden")
        if (inventoryLoadingEl) inventoryLoadingEl.classList.remove("hidden")
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
        fetch("https://" + GetParentResourceName() + "/requestItemsList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
        fetch("https://" + GetParentResourceName() + "/requestPlayerInventory", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: playerId }) }).catch(function() {
            if (inventoryLoadingEl) inventoryLoadingEl.classList.add("hidden")
        })
    }

    function closeGiveItemsModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            giveItemsModalPlayerId = null
            giveItemsModalItems = []
            giveItemsModalSelected = []
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    window.setGiveItemsListData = function(items) {
        giveItemsModalItems = Array.isArray(items) ? items : []
        renderList()
    }

    if (searchEl) searchEl.addEventListener("input", renderList)
    if (backdrop) backdrop.addEventListener("click", closeGiveItemsModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeGiveItemsModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (giveItemsModalPlayerId == null || giveItemsModalSelected.length === 0) return
            var items = giveItemsModalSelected.map(function(entry) {
                var amount = entry.amount || 1
                if (amount < 1) amount = 1
                return { itemName: entry.name, amount: amount }
            })
            var self = this
            fetch("https://" + GetParentResourceName() + "/submitGiveItem", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: giveItemsModalPlayerId, items: items })
            }).then(function() {
                giveItemsModalSelected = []
                renderList()
                renderCart()
                requestPlayerInventoryRefresh()
            }).catch(function() {})
        })
    }

    window.openGiveItemsModal = openGiveItemsModal
    window.closeGiveItemsModal = closeGiveItemsModal
    window.setGiveItemsPlayerInventory = function(playerId, inventory) {
        if (giveItemsModalPlayerId !== playerId) return
        renderPlayerInventory(inventory)
    }
})()

;(function assignJobModalModule() {
    var modal = document.getElementById("assign-job-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var jobSelect = document.getElementById("assign-job-modal-job")
    var jobTrigger = document.getElementById("assign-job-modal-job-trigger")
    var jobTriggerText = document.getElementById("assign-job-modal-job-trigger-text")
    var jobDropdown = document.getElementById("assign-job-modal-job-dropdown")
    var jobSelectWrap = jobTrigger ? jobTrigger.closest(".assign-job-select-wrap") : null
    var gradesListEl = document.getElementById("assign-job-modal-grades-list")
    var cancelBtn = document.getElementById("assign-job-modal-cancel")
    var confirmBtn = document.getElementById("assign-job-modal-confirm")
    var assignJobModalPlayerId = null
    var assignJobModalJobs = []
    var assignJobModalSelectedGrade = null

    function setJobTriggerText(t) {
        if (jobTriggerText) jobTriggerText.textContent = t || ""
    }

    function closeJobDropdown() {
        if (jobSelectWrap) jobSelectWrap.classList.remove("open")
        if (jobDropdown) jobDropdown.classList.add("hidden")
        if (jobTrigger) jobTrigger.setAttribute("aria-expanded", "false")
    }

    function openJobDropdown() {
        if (jobSelectWrap) jobSelectWrap.classList.add("open")
        if (jobDropdown) jobDropdown.classList.remove("hidden")
        if (jobTrigger) jobTrigger.setAttribute("aria-expanded", "true")
    }

    function syncTriggerFromSelect() {
        if (!jobSelect || !jobTriggerText) return
        var opt = jobSelect.options[jobSelect.selectedIndex]
        setJobTriggerText(opt ? opt.textContent : "")
    }

    function renderGradeList(jobName) {
        if (!gradesListEl) return
        assignJobModalSelectedGrade = null
        gradesListEl.innerHTML = ""
        if (!jobName) {
            var empty = document.createElement("div")
            empty.className = "assign-job-grade-item assign-job-grades-empty"
            empty.textContent = (typeof window !== "undefined" && window.t && window.t("modal_assign_job_select_first")) || "Selecciona un trabajo para ver los rangos"
            gradesListEl.appendChild(empty)
            return
        }
        var job = assignJobModalJobs.find(function(j) { return j.name === jobName })
        if (!job || !job.grades || job.grades.length === 0) {
            var empty = document.createElement("div")
            empty.className = "assign-job-grade-item assign-job-grades-empty"
            empty.textContent = (typeof window !== "undefined" && window.t && window.t("modal_assign_job_no_grades")) || "No hay rangos para este trabajo."
            gradesListEl.appendChild(empty)
            return
        }
        job.grades.forEach(function(g) {
            var div = document.createElement("div")
            div.className = "assign-job-grade-item"
            div.setAttribute("data-grade", g.grade)
            div.innerHTML = "<span class=\"assign-job-grade-label\">" + (g.label || ("Rango " + g.grade)).replace(/</g, "&lt;").replace(/>/g, "&gt;") + "</span>"
            div.addEventListener("click", function() {
                assignJobModalSelectedGrade = g.grade
                gradesListEl.querySelectorAll(".assign-job-grade-item.selected").forEach(function(el) { el.classList.remove("selected") })
                div.classList.add("selected")
            })
            gradesListEl.appendChild(div)
        })
    }

    function openAssignJobModal(playerId) {
        assignJobModalPlayerId = playerId
        assignJobModalJobs = []
        assignJobModalSelectedGrade = null
        closeJobDropdown()
        var loadingText = (typeof window !== "undefined" && window.t && window.t("modal_assign_job_loading")) || "Cargando trabajos..."
        if (jobSelect) jobSelect.innerHTML = "<option value=\"\">" + loadingText + "</option>"
        setJobTriggerText(loadingText)
        if (jobDropdown) jobDropdown.innerHTML = ""
        if (gradesListEl) {
            gradesListEl.innerHTML = "<div class=\"assign-job-grade-item assign-job-grades-empty\">" + ((typeof window !== "undefined" && window.t && window.t("modal_assign_job_grades_loading")) || "Cargando...") + "</div>"
        }
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
        fetch("https://" + GetParentResourceName() + "/requestJobsList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
    }

    function closeAssignJobModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            assignJobModalPlayerId = null
            assignJobModalSelectedGrade = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    window.setAssignJobListData = function(jobs) {
        assignJobModalJobs = Array.isArray(jobs) ? jobs : []
        var placeholder = (typeof window !== "undefined" && window.t && window.t("modal_job_select_placeholder")) || "Seleccionar trabajo..."
        if (!jobSelect) return
        jobSelect.innerHTML = "<option value=\"\">" + placeholder + "</option>"
        assignJobModalJobs.forEach(function(j) {
            var opt = document.createElement("option")
            opt.value = j.name
            opt.textContent = j.label || j.name || ""
            jobSelect.appendChild(opt)
        })
        setJobTriggerText(placeholder)
        if (jobDropdown) {
            jobDropdown.innerHTML = ""
            var emptyOpt = document.createElement("div")
            emptyOpt.className = "assign-job-select-option"
            emptyOpt.setAttribute("data-value", "")
            emptyOpt.setAttribute("role", "option")
            emptyOpt.textContent = placeholder
            emptyOpt.addEventListener("click", function() {
                if (jobSelect) jobSelect.value = ""
                syncTriggerFromSelect()
                closeJobDropdown()
                renderGradeList("")
            })
            jobDropdown.appendChild(emptyOpt)
            assignJobModalJobs.forEach(function(j) {
                var div = document.createElement("div")
                div.className = "assign-job-select-option"
                div.setAttribute("data-value", j.name)
                div.setAttribute("role", "option")
                div.textContent = j.label || j.name || ""
                div.addEventListener("click", function() {
                    if (jobSelect) jobSelect.value = j.name
                    syncTriggerFromSelect()
                    closeJobDropdown()
                    renderGradeList(jobSelect.value || "")
                })
                jobDropdown.appendChild(div)
            })
        }
        renderGradeList("")
    }

    if (jobTrigger) {
        jobTrigger.addEventListener("click", function() {
            if (jobSelectWrap && jobDropdown) {
                if (jobDropdown.classList.contains("hidden")) openJobDropdown()
                else closeJobDropdown()
            }
        })
        jobTrigger.addEventListener("keydown", function(e) {
            if (e.key === "Enter" || e.key === " ") {
                e.preventDefault()
                jobTrigger.click()
            }
        })
    }
    if (jobDropdown && jobSelectWrap) {
        document.addEventListener("click", function(e) {
            if (jobDropdown.classList.contains("hidden")) return
            if (jobSelectWrap.contains(e.target)) return
            closeJobDropdown()
        })
    }
    if (jobSelect) {
        jobSelect.addEventListener("change", function() {
            syncTriggerFromSelect()
            renderGradeList(jobSelect.value || "")
        })
    }
    if (backdrop) backdrop.addEventListener("click", closeAssignJobModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeAssignJobModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (assignJobModalPlayerId == null) return
            var jobName = jobSelect ? jobSelect.value : ""
            if (!jobName) return
            var grade = assignJobModalSelectedGrade
            if (grade === null || grade === undefined) grade = 0
            if (typeof grade !== "number" || grade < 0) grade = 0
            var jobLabel = jobName
            var gradeLabel = "—"
            var jobData = assignJobModalJobs.find(function(j) { return j.name === jobName })
            if (jobData) {
                jobLabel = jobData.label || jobName
                if (jobData.grades && jobData.grades.length) {
                    var g = jobData.grades.find(function(gr) { return gr.grade === grade })
                    if (g) gradeLabel = g.label || ("Rango " + grade)
                }
            }
            fetch("https://" + GetParentResourceName() + "/submitAssignJob", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: assignJobModalPlayerId, jobName: jobName, grade: grade })
            }).catch(function() {})
            if (assignJobModalPlayerId === window.playerDetailCurrentId) {
                var jobEl = document.getElementById("player-detail-job")
                var jobGradeEl = document.getElementById("player-detail-job-grade")
                if (jobEl) jobEl.textContent = jobLabel
                if (jobGradeEl) jobGradeEl.textContent = gradeLabel
            }
            closeAssignJobModal()
        })
    }

    window.openAssignJobModal = openAssignJobModal
    window.closeAssignJobModal = closeAssignJobModal
})()

;(function assignGangModalModule() {
    var modal = document.getElementById("assign-gang-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var gangSelect = document.getElementById("assign-gang-modal-gang")
    var gangTrigger = document.getElementById("assign-gang-modal-gang-trigger")
    var gangTriggerText = document.getElementById("assign-gang-modal-gang-trigger-text")
    var gangDropdown = document.getElementById("assign-gang-modal-gang-dropdown")
    var gangSelectWrap = gangTrigger ? gangTrigger.closest(".assign-job-select-wrap") : null
    var gradesListEl = document.getElementById("assign-gang-modal-grades-list")
    var cancelBtn = document.getElementById("assign-gang-modal-cancel")
    var confirmBtn = document.getElementById("assign-gang-modal-confirm")
    var assignGangModalPlayerId = null
    var assignGangModalGangs = []
    var assignGangModalSelectedGrade = null

    function setGangTriggerText(t) {
        if (gangTriggerText) gangTriggerText.textContent = t || ""
    }

    function closeGangDropdown() {
        if (gangSelectWrap) gangSelectWrap.classList.remove("open")
        if (gangDropdown) gangDropdown.classList.add("hidden")
        if (gangTrigger) gangTrigger.setAttribute("aria-expanded", "false")
    }

    function openGangDropdown() {
        if (gangSelectWrap) gangSelectWrap.classList.add("open")
        if (gangDropdown) gangDropdown.classList.remove("hidden")
        if (gangTrigger) gangTrigger.setAttribute("aria-expanded", "true")
    }

    function syncTriggerFromSelect() {
        if (!gangSelect || !gangTriggerText) return
        var opt = gangSelect.options[gangSelect.selectedIndex]
        setGangTriggerText(opt ? opt.textContent : "")
    }

    function renderGradeList(gangName) {
        if (!gradesListEl) return
        assignGangModalSelectedGrade = null
        gradesListEl.innerHTML = ""
        if (!gangName) {
            var empty = document.createElement("div")
            empty.className = "assign-job-grade-item assign-job-grades-empty"
            empty.textContent = (typeof window !== "undefined" && window.t && window.t("modal_assign_gang_select_first")) || "Selecciona una banda para ver los rangos"
            gradesListEl.appendChild(empty)
            return
        }
        var gang = assignGangModalGangs.find(function(g) { return g.name === gangName })
        if (!gang || !gang.grades || gang.grades.length === 0) {
            var empty = document.createElement("div")
            empty.className = "assign-job-grade-item assign-job-grades-empty"
            empty.textContent = (typeof window !== "undefined" && window.t && window.t("modal_assign_gang_no_grades")) || "No hay rangos para esta banda."
            gradesListEl.appendChild(empty)
            return
        }
        gang.grades.forEach(function(g) {
            var div = document.createElement("div")
            div.className = "assign-job-grade-item"
            div.setAttribute("data-grade", g.grade)
            div.innerHTML = "<span class=\"assign-job-grade-label\">" + (g.label || ("Rango " + g.grade)).replace(/</g, "&lt;").replace(/>/g, "&gt;") + "</span>"
            div.addEventListener("click", function() {
                assignGangModalSelectedGrade = g.grade
                gradesListEl.querySelectorAll(".assign-job-grade-item.selected").forEach(function(el) { el.classList.remove("selected") })
                div.classList.add("selected")
            })
            gradesListEl.appendChild(div)
        })
    }

    function openAssignGangModal(playerId) {
        assignGangModalPlayerId = playerId
        assignGangModalGangs = []
        assignGangModalSelectedGrade = null
        closeGangDropdown()
        var loadingText = (typeof window !== "undefined" && window.t && window.t("modal_assign_gang_loading")) || "Cargando bandas..."
        if (gangSelect) gangSelect.innerHTML = "<option value=\"\">" + loadingText + "</option>"
        setGangTriggerText(loadingText)
        if (gangDropdown) gangDropdown.innerHTML = ""
        if (gradesListEl) {
            gradesListEl.innerHTML = "<div class=\"assign-job-grade-item assign-job-grades-empty\">" + ((typeof window !== "undefined" && window.t && window.t("modal_assign_gang_grades_loading")) || "Cargando...") + "</div>"
        }
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
        fetch("https://" + GetParentResourceName() + "/requestGangsList", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
    }

    function closeAssignGangModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            assignGangModalPlayerId = null
            assignGangModalSelectedGrade = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    window.setAssignGangListData = function(gangs) {
        assignGangModalGangs = Array.isArray(gangs) ? gangs : []
        var placeholder = (typeof window !== "undefined" && window.t && window.t("modal_gang_select_placeholder")) || "Seleccionar banda..."
        if (!gangSelect) return
        gangSelect.innerHTML = "<option value=\"\">" + placeholder + "</option>"
        assignGangModalGangs.forEach(function(g) {
            var opt = document.createElement("option")
            opt.value = g.name
            opt.textContent = g.label || g.name || ""
            gangSelect.appendChild(opt)
        })
        setGangTriggerText(placeholder)
        if (gangDropdown) {
            gangDropdown.innerHTML = ""
            var emptyOpt = document.createElement("div")
            emptyOpt.className = "assign-job-select-option"
            emptyOpt.setAttribute("data-value", "")
            emptyOpt.setAttribute("role", "option")
            emptyOpt.textContent = placeholder
            emptyOpt.addEventListener("click", function() {
                if (gangSelect) gangSelect.value = ""
                syncTriggerFromSelect()
                closeGangDropdown()
                renderGradeList("")
            })
            gangDropdown.appendChild(emptyOpt)
            assignGangModalGangs.forEach(function(g) {
                var div = document.createElement("div")
                div.className = "assign-job-select-option"
                div.setAttribute("data-value", g.name)
                div.setAttribute("role", "option")
                div.textContent = g.label || g.name || ""
                div.addEventListener("click", function() {
                    if (gangSelect) gangSelect.value = g.name
                    syncTriggerFromSelect()
                    closeGangDropdown()
                    renderGradeList(gangSelect.value || "")
                })
                gangDropdown.appendChild(div)
            })
        }
        renderGradeList("")
    }

    if (gangTrigger) {
        gangTrigger.addEventListener("click", function() {
            if (gangSelectWrap && gangDropdown) {
                if (gangDropdown.classList.contains("hidden")) openGangDropdown()
                else closeGangDropdown()
            }
        })
        gangTrigger.addEventListener("keydown", function(e) {
            if (e.key === "Enter" || e.key === " ") {
                e.preventDefault()
                gangTrigger.click()
            }
        })
    }
    if (gangDropdown && gangSelectWrap) {
        document.addEventListener("click", function(e) {
            if (gangDropdown.classList.contains("hidden")) return
            if (gangSelectWrap.contains(e.target)) return
            closeGangDropdown()
        })
    }
    if (gangSelect) {
        gangSelect.addEventListener("change", function() {
            syncTriggerFromSelect()
            renderGradeList(gangSelect.value || "")
        })
    }
    if (backdrop) backdrop.addEventListener("click", closeAssignGangModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeAssignGangModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (assignGangModalPlayerId == null) return
            var gangName = gangSelect ? gangSelect.value : ""
            if (!gangName) return
            var grade = assignGangModalSelectedGrade
            if (grade === null || grade === undefined) grade = 0
            if (typeof grade !== "number" || grade < 0) grade = 0
            var gangLabel = gangName
            var gradeLabel = "—"
            var gangData = assignGangModalGangs.find(function(g) { return g.name === gangName })
            if (gangData) {
                gangLabel = gangData.label || gangName
                if (gangData.grades && gangData.grades.length) {
                    var g = gangData.grades.find(function(gr) { return gr.grade === grade })
                    if (g) gradeLabel = g.label || ("Rango " + grade)
                }
            }
            fetch("https://" + GetParentResourceName() + "/submitAssignGang", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: assignGangModalPlayerId, gangName: gangName, grade: grade })
            }).catch(function() {})
            if (assignGangModalPlayerId === window.playerDetailCurrentId) {
                var gangEl = document.getElementById("player-detail-gang")
                var gangGradeEl = document.getElementById("player-detail-gang-grade")
                if (gangEl) gangEl.textContent = gangLabel
                if (gangGradeEl) gangGradeEl.textContent = gradeLabel
            }
            closeAssignGangModal()
        })
    }

    window.openAssignGangModal = openAssignGangModal
    window.closeAssignGangModal = closeAssignGangModal
})()

;(function assignAdminModalModule() {
    var modal = document.getElementById("assign-admin-modal")
    var backdrop = modal ? modal.querySelector(".ban-modal-backdrop") : null
    var listEl = document.getElementById("assign-admin-modal-list")
    var searchEl = document.getElementById("assign-admin-modal-search")
    var cancelBtn = document.getElementById("assign-admin-modal-cancel")
    var confirmBtn = document.getElementById("assign-admin-modal-confirm")
    var assignAdminModalPlayerId = null
    var assignAdminModalGroups = []
    var assignAdminModalSelected = null

    function renderList() {
        if (!listEl) return
        var q = (searchEl && searchEl.value) ? searchEl.value.trim().toLowerCase() : ""
        var filtered = assignAdminModalGroups
        if (q) {
            filtered = assignAdminModalGroups.filter(function(g) {
                var grupo = (g.grupo || "").toLowerCase()
                return grupo.indexOf(q) !== -1
            })
        }
        listEl.innerHTML = ""
        if (filtered.length === 0) {
            var emptyDiv = document.createElement("div")
            emptyDiv.className = "give-items-item give-items-list-empty"
            emptyDiv.style.cursor = "default"
            var msg = (typeof window !== "undefined" && window.t) ? (q ? window.t("modal_assign_admin_no_ranks") : window.t("modal_assign_admin_no_ranks_available")) : (q ? "No se han encontrado rangos" : "No hay rangos disponibles")
            emptyDiv.innerHTML = "<i class=\"fa-solid fa-magnifying-glass give-items-list-empty-icon\"></i><span>" + msg + "</span>"
            listEl.appendChild(emptyDiv)
            return
        }
        filtered.forEach(function(g) {
            var grupo = (g.grupo || "").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var isSelected = assignAdminModalSelected && assignAdminModalSelected.grupo === g.grupo
            var div = document.createElement("div")
            div.className = "give-items-item" + (isSelected ? " selected" : "")
            div.setAttribute("data-grupo", g.grupo)
            div.innerHTML = "<span class=\"give-items-item-name\">" + grupo + "</span>"
            div.addEventListener("click", function() {
                assignAdminModalSelected = { grupo: g.grupo }
                listEl.querySelectorAll(".give-items-item.selected").forEach(function(el) { el.classList.remove("selected") })
                div.classList.add("selected")
            })
            listEl.appendChild(div)
        })
    }

    function openAssignAdminModal(playerId) {
        assignAdminModalPlayerId = playerId
        assignAdminModalGroups = []
        assignAdminModalSelected = null
        if (searchEl) searchEl.value = ""
        if (listEl) listEl.innerHTML = "<div class=\"give-items-item give-items-list-loading\"><i class=\"fa-solid fa-spinner give-items-list-loading-icon\"></i><span>" + ((typeof window !== "undefined" && window.t && window.t("modal_assign_admin_loading")) || "Cargando rangos...") + "</span></div>"
        if (modal) {
            modal.classList.remove("hidden")
            modal.setAttribute("aria-hidden", "false")
            requestAnimationFrame(function() {
                requestAnimationFrame(function() {
                    modal.classList.add("open")
                })
            })
        }
        fetch("https://" + GetParentResourceName() + "/requestGroupsForAssignAdmin", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
    }

    function closeAssignAdminModal() {
        if (!modal) return
        var done = false
        function onFadeOut(ev) {
            if (done) return
            if (ev && ev.propertyName && ev.propertyName !== "opacity") return
            done = true
            modal.removeEventListener("transitionend", onFadeOut)
            modal.classList.remove("open", "closing")
            modal.classList.add("hidden")
            modal.setAttribute("aria-hidden", "true")
            assignAdminModalPlayerId = null
            assignAdminModalGroups = []
            assignAdminModalSelected = null
        }
        modal.addEventListener("transitionend", onFadeOut)
        modal.classList.add("closing")
        var duration = parseFloat(getComputedStyle(modal).transitionDuration) || 0.22
        if (duration <= 0) onFadeOut()
        else setTimeout(function() { if (!done) onFadeOut(); }, (duration * 1000) + 50)
    }

    window.setAssignAdminListData = function(groups) {
        assignAdminModalGroups = Array.isArray(groups) ? groups : []
        renderList()
    }

    if (searchEl) searchEl.addEventListener("input", function() { renderList() })
    if (backdrop) backdrop.addEventListener("click", closeAssignAdminModal)
    if (cancelBtn) cancelBtn.addEventListener("click", closeAssignAdminModal)
    if (confirmBtn) {
        confirmBtn.addEventListener("click", function() {
            if (assignAdminModalPlayerId == null || !assignAdminModalSelected || !assignAdminModalSelected.grupo) return
            fetch("https://" + GetParentResourceName() + "/submitAssignAdmin", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ playerId: assignAdminModalPlayerId, groupName: assignAdminModalSelected.grupo })
            }).catch(function() {})
            closeAssignAdminModal()
        })
    }

    window.openAssignAdminModal = openAssignAdminModal
    window.closeAssignAdminModal = closeAssignAdminModal
})()

document.addEventListener("mouseover", function(e) {
    var btn = e.target.closest && e.target.closest(".dashboard-action-btn[data-perm-allowed=\"false\"], .player-detail-fn-btn[data-perm-allowed=\"false\"]")
    if (btn) document.body.style.cursor = "not-allowed"
})
document.addEventListener("mouseout", function(e) {
    var related = e.relatedTarget
    var stillOver = related && related.closest && related.closest(".dashboard-action-btn[data-perm-allowed=\"false\"], .player-detail-fn-btn[data-perm-allowed=\"false\"]")
    if (!stillOver) document.body.style.cursor = ""
})

document.querySelectorAll(".player-detail-fn-btn").forEach(function(btn) {
    btn.addEventListener("click", function() {
        if (btn.getAttribute("data-perm-allowed") === "false") return
        var action = btn.getAttribute("data-player-action")
        var id = window.playerDetailCurrentId
        if (!action) return
        if (action === "stopSpectate") {
            fetch("https://" + GetParentResourceName() + "/cancelSpectate", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {})
            return
        }
        if (action === "ban") {
            if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && typeof window.openBanModal === "function") {
                var fnb = (document.getElementById("player-detail-firstname") && document.getElementById("player-detail-firstname").textContent) ? String(document.getElementById("player-detail-firstname").textContent).trim() : ""
                var lnb = (document.getElementById("player-detail-lastname") && document.getElementById("player-detail-lastname").textContent) ? String(document.getElementById("player-detail-lastname").textContent).trim() : ""
                var fullb = (fnb + " " + lnb).trim()
                if (!fullb && document.getElementById("player-detail-name")) fullb = String(document.getElementById("player-detail-name").textContent || "").trim()
                window.openBanModal(null, null, { player_name: fullb, banFrameworkIdentifier: window.playerDetailOfflineIdentifier })
                return
            }
            if (id != null && typeof window.openBanModal === "function") window.openBanModal(id)
            return
        }
        if (action === "kick") {
            if (id != null && typeof window.openKickModal === "function") window.openKickModal(id)
            return
        }
        if (action === "spawnvehicle") {
            if (id != null && typeof window.openSpawnVehicleModal === "function") window.openSpawnVehicleModal(id)
            return
        }
        if (action === "ck") {
            if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && typeof window.openCKConfirmModal === "function") {
                window.openCKConfirmModal(null, window.playerDetailOfflineIdentifier)
                return
            }
            if (id != null && typeof window.openCKConfirmModal === "function") window.openCKConfirmModal(id)
            return
        }
        if (action === "clearinv") {
            if (id != null && typeof window.openClearInvConfirmModal === "function") window.openClearInvConfirmModal(id)
            return
        }
        if (action === "instancia") {
            if (id != null && typeof window.openInstanciaModal === "function") window.openInstanciaModal(id)
            return
        }
        if (action === "money") {
            if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && typeof window.openManageMoneyModal === "function") {
                window.openManageMoneyModal(null, window.playerDetailOfflineIdentifier)
                return
            }
            if (id != null && typeof window.openManageMoneyModal === "function") window.openManageMoneyModal(id)
            return
        }
        if (action === "items") {
            if (id != null && typeof window.openGiveItemsModal === "function") window.openGiveItemsModal(id)
            return
        }
        if (action === "job") {
            if (id != null && typeof window.openAssignJobModal === "function") window.openAssignJobModal(id)
            return
        }
        if (action === "gang") {
            if (id != null && typeof window.openAssignGangModal === "function") window.openAssignGangModal(id)
            return
        }
        if (action === "admin") {
            if (id != null && typeof window.openAssignAdminModal === "function") window.openAssignAdminModal(id)
            return
        }
        if (action === "notes") {
            if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier && typeof window.openPlayerNotesModal === "function") {
                window.openPlayerNotesModal(null, window.playerDetailOfflineIdentifier)
                return
            }
            if (id != null && typeof window.openPlayerNotesModal === "function") window.openPlayerNotesModal(id)
            return
        }
        if (id == null) return
        if (action === "freeze") {
            window.frozenPlayerIds[id] = !window.frozenPlayerIds[id]
            updateFreezeButtonState()
        }
        fetch("https://" + GetParentResourceName() + "/playerDetailAction", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: action, playerId: id })
        }).catch(function() {})
    })
})

;(function terminalModule() {
    var terminalHistory = []
    var terminalHistoryIndex = -1
    var terminalResourcesFullList = []
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"

    function addTerminalLine(type, prefix, text) {
        var output = document.getElementById("terminalOutput")
        if (!output) return
        var line = document.createElement("div")
        line.className = "terminal-line terminal-" + (type || "info")
        if (prefix && text) {
            var prefixSpan = document.createElement("span")
            prefixSpan.className = "terminal-prefix"
            prefixSpan.textContent = "[" + prefix + "] "
            var textSpan = document.createElement("span")
            textSpan.className = "terminal-text"
            textSpan.textContent = text
            line.appendChild(prefixSpan)
            line.appendChild(textSpan)
        } else {
            line.textContent = prefix || text || ""
        }
        output.appendChild(line)
        output.scrollTop = output.scrollHeight
    }

    window.addTerminalLogLine = function(logData) {
        if (!logData) return
        var type = logData.type || "info"
        var prefix = "SERVER"
        if (type === "error") prefix = "ERROR"
        else if (type === "warning") prefix = "WARN"
        else if (type === "success") prefix = "OK"
        addTerminalLine(type, prefix, logData.message || logData.text || "")
    }

    window.updateTerminalConsoleBuffer = function(buffer) {
        if (!buffer) return
        var output = document.getElementById("terminalOutput")
        if (!output) return
        var lines = (typeof buffer === "string" ? buffer : String(buffer)).split("\n")
        var recentLines = lines.slice(-500)
        output.innerHTML = ""
        recentLines.forEach(function(line) {
            if (!line || line.trim() === "") return
            var type = "info"
            var displayLine = line.replace(/\^\d/g, "")
            if (line.indexOf("^1") !== -1) type = "error"
            else if (line.indexOf("^3") !== -1) type = "warning"
            else if (line.indexOf("^2") !== -1) type = "success"
            else if (line.indexOf("^5") !== -1) type = "info"
            var lower = displayLine.toLowerCase()
            if (lower.indexOf("error") !== -1 || lower.indexOf("failed") !== -1) type = "error"
            else if (lower.indexOf("warning") !== -1 || lower.indexOf("warn") !== -1) type = "warning"
            else if (lower.indexOf("started") !== -1 || lower.indexOf("loaded") !== -1 || lower.indexOf("success") !== -1) type = "success"
            var div = document.createElement("div")
            div.className = "terminal-line terminal-" + type
            div.style.whiteSpace = "pre-wrap"
            div.style.wordBreak = "break-word"
            div.textContent = displayLine
            output.appendChild(div)
        })
        output.scrollTop = output.scrollHeight
    }

    window.renderTerminalResources = function(resources) {
        if (resources && resources.length >= 0) terminalResourcesFullList = resources
        var listEl = document.getElementById("terminalResourcesList")
        if (!listEl) return
        var sp = window.sectionPerms || {}
        var restartAllowed = sp.terminal_restart === true || sp.terminal_restart === "1" || sp.terminal_restart === 1
        var stopAllowed = sp.terminal_stop === true || sp.terminal_stop === "1" || sp.terminal_stop === 1
        var searchEl = document.getElementById("terminalResourcesSearch")
        var q = (searchEl && searchEl.value) ? searchEl.value.trim().toLowerCase() : ""
        var toRender = q === "" ? terminalResourcesFullList : terminalResourcesFullList.filter(function(r) {
            return (r.name || "").toLowerCase().indexOf(q) !== -1
        })
        if (!toRender || toRender.length === 0) {
            listEl.innerHTML = "<div class=\"terminal-resources-empty\">" + (q ? "No matching resources" : "No resources") + "</div>"
            return
        }
        var restartCls = "terminal-resource-btn restart" + (restartAllowed ? "" : " terminal-resource-btn-no-permission")
        var restartDataPerm = restartAllowed ? "true" : "false"
        var startCls = "terminal-resource-btn start" + (stopAllowed ? "" : " terminal-resource-btn-no-permission")
        var stopCls = "terminal-resource-btn stop" + (stopAllowed ? "" : " terminal-resource-btn-no-permission")
        var startStopDataPerm = stopAllowed ? "true" : "false"
        var html = toRender.map(function(r) {
            var name = (r.name || "").replace(/</g, "&lt;")
            var state = (r.state || "stopped")
            var dotClass = state === "started" ? "started" : "stopped"
            var startStop = state === "started"
                ? "<button type=\"button\" class=\"" + stopCls + "\" data-perm-allowed=\"" + startStopDataPerm + "\" data-resource=\"" + name + "\" title=\"Stop\"><i class=\"fa-solid fa-stop\"></i></button>"
                : "<button type=\"button\" class=\"" + startCls + "\" data-perm-allowed=\"" + startStopDataPerm + "\" data-resource=\"" + name + "\" title=\"Start\"><i class=\"fa-solid fa-play\"></i></button>"
            return "<div class=\"terminal-resource-item\"><div class=\"terminal-resource-name\"><span class=\"terminal-resource-dot " + dotClass + "\"></span><span>" + name + "</span></div><div class=\"terminal-resource-actions\"><button type=\"button\" class=\"" + restartCls + "\" data-perm-allowed=\"" + restartDataPerm + "\" data-resource=\"" + name + "\" title=\"Restart\"><i class=\"fa-solid fa-rotate-right\"></i></button>" + startStop + "</div></div>"
        }).join("")
        listEl.innerHTML = html
        listEl.querySelectorAll(".terminal-resource-btn").forEach(function(btn) {
            btn.addEventListener("click", function() {
                if (btn.getAttribute("data-perm-allowed") === "false") return
                var name = btn.getAttribute("data-resource")
                if (!name) return
                if (btn.classList.contains("restart")) {
                    fetch("https://" + resName + "/terminalRestartResource", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ resourceName: name }) }).then(function() { requestTerminalResources() }).catch(function() {})
                } else if (btn.classList.contains("start")) {
                    fetch("https://" + resName + "/terminalStartResource", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ resourceName: name }) }).then(function() { requestTerminalResources() }).catch(function() {})
                } else if (btn.classList.contains("stop")) {
                    fetch("https://" + resName + "/terminalStopResource", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ resourceName: name }) }).then(function() { requestTerminalResources() }).catch(function() {})
                }
            })
        })
    }

    window.requestTerminalResources = function() {
        var listEl = document.getElementById("terminalResourcesList")
        if (listEl) listEl.innerHTML = "<div class=\"terminal-resources-loading\">Loading...</div>"
        fetch("https://" + resName + "/terminalGetResources", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({}) }).catch(function() {
            if (listEl) listEl.innerHTML = "<div class=\"terminal-resources-empty\">Error loading resources</div>"
        })
    }

    function executeTerminalCommand(cmd) {
        if (!cmd || !cmd.trim()) return
        var sp = window.sectionPerms || {}
        if (!(sp.terminal_console === true || sp.terminal_console === "1" || sp.terminal_console === 1)) return
        terminalHistory.push(cmd)
        terminalHistoryIndex = terminalHistory.length
        addTerminalLine("command", ">", cmd)
        if (cmd.trim().toLowerCase() === "clear" || cmd.trim().toLowerCase() === "cls") {
            var out = document.getElementById("terminalOutput")
            if (out) out.innerHTML = ""
            return
        }
        if (cmd.trim().toLowerCase() === "help") {
            addTerminalLine("info", null, "clear/cls - Clear console | help - This help")
            return
        }
        fetch("https://" + resName + "/terminalExecuteCommand", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ command: cmd }) }).catch(function() {})
    }

    var terminalInput = document.getElementById("terminalInput")
    if (terminalInput) {
        terminalInput.addEventListener("keydown", function(e) {
            if (e.key === "Enter") {
                var cmd = this.value.trim()
                if (cmd) executeTerminalCommand(cmd)
                this.value = ""
            } else if (e.key === "ArrowUp") {
                e.preventDefault()
                if (terminalHistoryIndex > 0) {
                    terminalHistoryIndex--
                    this.value = terminalHistory[terminalHistoryIndex]
                }
            } else if (e.key === "ArrowDown") {
                e.preventDefault()
                if (terminalHistoryIndex < terminalHistory.length - 1) {
                    terminalHistoryIndex++
                    this.value = terminalHistory[terminalHistoryIndex]
                } else {
                    terminalHistoryIndex = terminalHistory.length
                    this.value = ""
                }
            }
        })
    }

    var refreshBtn = document.getElementById("terminal-refresh-resources")
    if (refreshBtn) refreshBtn.addEventListener("click", requestTerminalResources)
    var searchInput = document.getElementById("terminalResourcesSearch")
    if (searchInput) searchInput.addEventListener("input", function() {
        renderTerminalResources(terminalResourcesFullList)
    })
})()

function savePlayerDetailStateBeforeClose() {
    var activeMenuItem = document.querySelector(".menu li.active")
    var isOnPlayersPage = activeMenuItem && activeMenuItem.getAttribute("data-page") === "players"
    if (!isOnPlayersPage) {
        window.lastOpenPlayerDetailId = null
        window.lastOpenPlayerDetailOfflineIdentifier = null
        return
    }
    var detailView = document.getElementById("player-detail-view")
    if (detailView && !detailView.classList.contains("hidden")) {
        if (window.playerDetailOffline === true && window.playerDetailOfflineIdentifier) {
            window.lastOpenPlayerDetailId = null
            window.lastOpenPlayerDetailOfflineIdentifier = window.playerDetailOfflineIdentifier
        } else if (window.playerDetailCurrentId != null) {
            window.lastOpenPlayerDetailId = window.playerDetailCurrentId
            window.lastOpenPlayerDetailOfflineIdentifier = null
        }
    }
}

document.addEventListener("keydown", (e) => {
    var isBackspace = e.key === "Backspace"
    var isEscapeOrDelete = e.key === "Escape" || e.key === "Delete"
    var inInput = e.target && (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA" || e.target.isContentEditable)
    if (e.key === "Escape") {
        e.preventDefault()
        e.stopPropagation()
        if (typeof e.stopImmediatePropagation === "function") e.stopImmediatePropagation()
    }
    if (isEscapeOrDelete || (isBackspace && !inInput)) {
        var groupsCreateModal = document.getElementById("groups-modal-create")
        var groupsEditModal = document.getElementById("groups-modal-edit")
        if (groupsCreateModal && !groupsCreateModal.classList.contains("hidden")) {
            if (typeof window.closeGroupsCreateModal === "function") window.closeGroupsCreateModal()
            return
        }
        if (groupsEditModal && !groupsEditModal.classList.contains("hidden")) {
            if (typeof window.closeGroupsEditModal === "function") window.closeGroupsEditModal()
            return
        }
        var deleteGroupConfirmModal = document.getElementById("delete-group-confirm-modal")
        if (deleteGroupConfirmModal && !deleteGroupConfirmModal.classList.contains("hidden") && deleteGroupConfirmModal.classList.contains("open")) {
            if (typeof window.closeDeleteGroupConfirmModal === "function") window.closeDeleteGroupConfirmModal()
            return
        }
        var passwordModal = document.getElementById("settings-change-password-modal")
        if (passwordModal && !passwordModal.classList.contains("hidden") && passwordModal.classList.contains("open")) {
            if (typeof window.closePasswordModal === "function") window.closePasswordModal()
            return
        }
        var banModal = document.getElementById("ban-modal")
        if (banModal && !banModal.classList.contains("hidden") && banModal.classList.contains("open")) {
            if (typeof window.closeBanModal === "function") window.closeBanModal()
            savePlayerDetailStateBeforeClose()
            if (tabletEl && !tabletEl.classList.contains("hidden")) {
                tabletEl.classList.remove("tablet-open")
                tabletEl.classList.add("tablet-closing")
                setTimeout(function() {
                    tabletEl.classList.add("hidden")
                    tabletEl.classList.remove("tablet-closing")
                    fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
                }, 400)
            } else if (tabletEl) {
                tabletEl.classList.add("hidden")
                fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
            }
            return
        }
        var kickModal = document.getElementById("kick-modal")
        if (kickModal && !kickModal.classList.contains("hidden") && kickModal.classList.contains("open")) {
            if (typeof window.closeKickModal === "function") window.closeKickModal()
            return
        }
        var announcementsModal = document.getElementById("announcements-modal")
        if (announcementsModal && !announcementsModal.classList.contains("hidden") && announcementsModal.classList.contains("open")) {
            if (typeof window.closeAnnouncementsModal === "function") window.closeAnnouncementsModal()
            return
        }
        var spawnVehicleModal = document.getElementById("spawn-vehicle-modal")
        if (spawnVehicleModal && !spawnVehicleModal.classList.contains("hidden") && spawnVehicleModal.classList.contains("open")) {
            if (typeof window.closeSpawnVehicleModal === "function") window.closeSpawnVehicleModal()
            return
        }
        var addVehicleGarageModal = document.getElementById("add-vehicle-garage-modal")
        if (addVehicleGarageModal && !addVehicleGarageModal.classList.contains("hidden") && addVehicleGarageModal.classList.contains("open")) {
            if (typeof window.closeAddVehicleGarageModal === "function") window.closeAddVehicleGarageModal()
            return
        }
        var adminLogoutConfirmModal = document.getElementById("admin-detail-logout-confirm-modal")
        if (adminLogoutConfirmModal && !adminLogoutConfirmModal.classList.contains("hidden") && adminLogoutConfirmModal.classList.contains("open")) {
            if (typeof window.closeAdminLogoutSessionConfirmModal === "function") window.closeAdminLogoutSessionConfirmModal()
            return
        }
        var adminResetConfirmModal = document.getElementById("admin-detail-reset-confirm-modal")
        if (adminResetConfirmModal && !adminResetConfirmModal.classList.contains("hidden") && adminResetConfirmModal.classList.contains("open")) {
            if (typeof window.closeAdminResetTimeConfirmModal === "function") window.closeAdminResetTimeConfirmModal()
            return
        }
        var adminDetailModal = document.getElementById("admin-detail-modal")
        if (adminDetailModal && !adminDetailModal.classList.contains("hidden") && adminDetailModal.classList.contains("open")) {
            if (typeof window.closeAdminDetailModal === "function") window.closeAdminDetailModal()
            return
        }
        var ckConfirmModal = document.getElementById("ck-confirm-modal")
        if (ckConfirmModal && !ckConfirmModal.classList.contains("hidden") && ckConfirmModal.classList.contains("open")) {
            if (typeof window.closeCKConfirmModal === "function") window.closeCKConfirmModal()
            return
        }
        var clearInvConfirmModal = document.getElementById("clearinv-confirm-modal")
        if (clearInvConfirmModal && !clearInvConfirmModal.classList.contains("hidden") && clearInvConfirmModal.classList.contains("open")) {
            if (typeof window.closeClearInvConfirmModal === "function") window.closeClearInvConfirmModal()
            return
        }
        var playerNotesModal = document.getElementById("player-notes-modal")
        if (playerNotesModal && !playerNotesModal.classList.contains("hidden") && playerNotesModal.classList.contains("open")) {
            if (typeof window.closePlayerNotesModal === "function") window.closePlayerNotesModal()
            return
        }
        var vehicleDeleteConfirmModal = document.getElementById("vehicle-delete-confirm-modal")
        if (vehicleDeleteConfirmModal && !vehicleDeleteConfirmModal.classList.contains("hidden") && vehicleDeleteConfirmModal.classList.contains("open")) {
            if (typeof window.closeVehicleDeleteConfirmModal === "function") window.closeVehicleDeleteConfirmModal()
            return
        }
        var instanciaModal = document.getElementById("instancia-modal")
        if (instanciaModal && !instanciaModal.classList.contains("hidden") && instanciaModal.classList.contains("open")) {
            if (typeof window.closeInstanciaModal === "function") window.closeInstanciaModal()
            return
        }
        var unbanConfirmModal = document.getElementById("unban-confirm-modal")
        if (unbanConfirmModal && !unbanConfirmModal.classList.contains("hidden") && unbanConfirmModal.classList.contains("open")) {
            if (typeof window.closeUnbanConfirmModal === "function") window.closeUnbanConfirmModal()
            return
        }
        var manageMoneyModal = document.getElementById("manage-money-modal")
        if (manageMoneyModal && !manageMoneyModal.classList.contains("hidden") && manageMoneyModal.classList.contains("open")) {
            if (typeof window.closeManageMoneyModal === "function") window.closeManageMoneyModal()
            return
        }
        var giveItemsModal = document.getElementById("give-items-modal")
        if (giveItemsModal && !giveItemsModal.classList.contains("hidden") && giveItemsModal.classList.contains("open")) {
            if (typeof window.closeGiveItemsModal === "function") window.closeGiveItemsModal()
            return
        }
        var assignJobModal = document.getElementById("assign-job-modal")
        if (assignJobModal && !assignJobModal.classList.contains("hidden") && assignJobModal.classList.contains("open")) {
            if (typeof window.closeAssignJobModal === "function") window.closeAssignJobModal()
            return
        }
        var assignGangModal = document.getElementById("assign-gang-modal")
        if (assignGangModal && !assignGangModal.classList.contains("hidden") && assignGangModal.classList.contains("open")) {
            if (typeof window.closeAssignGangModal === "function") window.closeAssignGangModal()
            return
        }
        var assignAdminModal = document.getElementById("assign-admin-modal")
        if (assignAdminModal && !assignAdminModal.classList.contains("hidden") && assignAdminModal.classList.contains("open")) {
            if (typeof window.closeAssignAdminModal === "function") window.closeAssignAdminModal()
            return
        }
        var coordsElKickOrder = document.getElementById("coords-ui")
        if (coordsElKickOrder && !coordsElKickOrder.classList.contains("hidden")) {
            fetch("https://" + GetParentResourceName() + "/closeCoordsUI", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            }).catch(function() {})
            coordsElKickOrder.classList.add("hidden")
            return
        }
        var kickElEsc = document.getElementById("kick-actions")
        if (kickElEsc && !kickElEsc.classList.contains("hidden")) {
            kickElEsc.classList.add("hidden")
            fetch("https://" + GetParentResourceName() + "/closeKickActions", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            }).catch(function() {})
            return
        }
        var playerDetailView = document.getElementById("player-detail-view")
        if (tabletEl && !tabletEl.classList.contains("hidden") && playerDetailView && !playerDetailView.classList.contains("hidden")) {
            savePlayerDetailStateBeforeClose()
            if (tabletEl && !tabletEl.classList.contains("hidden")) {
                tabletEl.classList.remove("tablet-open")
                tabletEl.classList.add("tablet-closing")
                setTimeout(function() {
                    tabletEl.classList.add("hidden")
                    tabletEl.classList.remove("tablet-closing")
                    fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
                }, 400)
            } else if (tabletEl) {
                tabletEl.classList.add("hidden")
                fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
            }
            return
        }
        savePlayerDetailStateBeforeClose()
        if (tabletEl && !tabletEl.classList.contains("hidden")) {
            tabletEl.classList.remove("tablet-open")
            tabletEl.classList.add("tablet-closing")
            setTimeout(function() {
                tabletEl.classList.add("hidden")
                tabletEl.classList.remove("tablet-closing")
                fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
            }, 400)
        } else if (tabletEl) {
            tabletEl.classList.add("tablet-closing")
            setTimeout(function() {
                tabletEl.classList.add("hidden")
                tabletEl.classList.remove("tablet-closing")
                fetch(`https://${GetParentResourceName()}/close`, { method: "POST", body: JSON.stringify({}) }).catch(function() {})
            }, 400)
        }
    }
})

;(function() {
    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "admin"
    function bindQuickAction(btn) {
        if (btn.getAttribute("data-perm-allowed") === "false") return
        var action = btn.getAttribute("data-action")
        if (!action) return
        fetch("https://" + resName + "/quickAction", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: action })
        }).catch(function() {})
    }
    document.querySelectorAll(".kick-actions-btn").forEach(function(btn) {
        btn.addEventListener("click", function() { bindQuickAction(btn) })
    })
    document.querySelectorAll(".dashboard-action-btn").forEach(function(btn) {
        btn.addEventListener("click", function() { bindQuickAction(btn) })
    })

    var isWaitingForKey = false
    var currentBindButton = null
    var keyMap = { " ": "SPACE", "ARROWUP": "↑", "ARROWDOWN": "↓", "ARROWLEFT": "←", "ARROWRIGHT": "→", "DELETE": "DEL", "INSERT": "INS", "HOME": "HOME", "END": "END", "PAGEUP": "PG UP", "PAGEDOWN": "PG DN" }

    window.applyKickActionsSavedBinds = function() {
        var savedBinds = JSON.parse(localStorage.getItem("adminpanel_binds") || "{}")
        var savedBindKeys = JSON.parse(localStorage.getItem("adminpanel_bindKeys") || "{}")
        document.querySelectorAll(".kick-actions-bind-key").forEach(function(btn) {
            var action = btn.getAttribute("data-action")
            if (!action) return
            if (savedBinds[action]) btn.textContent = savedBinds[action]
            else btn.textContent = "-"
            if (savedBindKeys[action]) {
                fetch("https://" + resName + "/updateKeybind", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ action: action, key: savedBindKeys[action], silent: true })
                }).catch(function() {})
            }
        })
    }

    document.querySelectorAll(".kick-actions-bind-key").forEach(function(button) {
        button.addEventListener("click", function(e) {
            e.stopPropagation()
            if (isWaitingForKey && currentBindButton === button) {
                fetch("https://" + resName + "/cancelWaitingForKey", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ action: button.getAttribute("data-action") })
                }).catch(function() {})
                button.textContent = button.dataset.originalKey || "-"
                button.classList.remove("waiting-key")
                isWaitingForKey = false
                currentBindButton = null
                return
            }
            button.dataset.originalKey = button.textContent
            isWaitingForKey = true
            currentBindButton = button
            button.textContent = "..."
            button.classList.add("waiting-key")
            var action = button.getAttribute("data-action")
            fetch("https://" + resName + "/startWaitingForKey", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ action: action })
            }).catch(function() {})
            var bindInput = button.closest("#settings") ? document.getElementById("settings-bind-input") : document.getElementById("kick-actions-bind-input")
            if (bindInput) {
                bindInput.value = ""
                setTimeout(function() { bindInput.focus() }, 50)
            }
        })
    })

    function setupBindInputListener(inputEl) {
        if (!inputEl) return
        inputEl.addEventListener("keydown", function(e) {
            if (!isWaitingForKey || !currentBindButton) return
            e.preventDefault()
            e.stopPropagation()
            if (e.key === "Escape") {
                fetch("https://" + resName + "/cancelWaitingForKey", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ action: currentBindButton.getAttribute("data-action") })
                }).catch(function() {})
                currentBindButton.textContent = currentBindButton.dataset.originalKey || "-"
                currentBindButton.classList.remove("waiting-key")
                inputEl.blur()
                isWaitingForKey = false
                currentBindButton = null
                return
            }
            if (["Tab", "Enter", "Shift", "Control", "Alt", "Meta"].indexOf(e.key) !== -1) return
            var keyDisplay = e.key.length === 1 ? e.key.toUpperCase() : (keyMap[e.key.toUpperCase()] || e.key)
            var action = currentBindButton.getAttribute("data-action")
            var binds = JSON.parse(localStorage.getItem("adminpanel_binds") || "{}")
            var bindKeys = JSON.parse(localStorage.getItem("adminpanel_bindKeys") || "{}")
            binds[action] = keyDisplay
            bindKeys[action] = e.code
            localStorage.setItem("adminpanel_binds", JSON.stringify(binds))
            localStorage.setItem("adminpanel_bindKeys", JSON.stringify(bindKeys))
            fetch("https://" + resName + "/updateKeybind", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ action: action, key: e.code, silent: false })
            }).catch(function() {})
            currentBindButton.textContent = keyDisplay
            currentBindButton.classList.remove("waiting-key")
            inputEl.blur()
            inputEl.value = ""
            isWaitingForKey = false
            currentBindButton = null
        })
    }

    var bindInputEl = document.getElementById("kick-actions-bind-input")
    setupBindInputListener(bindInputEl)
    var settingsBindInputEl = document.getElementById("settings-bind-input")
    setupBindInputListener(settingsBindInputEl)
})()
