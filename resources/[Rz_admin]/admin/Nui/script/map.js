(function () {
    "use strict";

    const center_x = 117.3;
    const center_y = 172.8;
    const scale_x = 0.02072;
    const scale_y = 0.0205;

    const mapCRS = L.extend({}, L.CRS.Simple, {
        projection: L.Projection.LonLat,
        scale: function (zoom) { return Math.pow(2, zoom); },
        zoom: function (sc) { return Math.log(sc) / Math.LN2; },
        distance: function (pos1, pos2) {
            const x = pos2.lng - pos1.lng;
            const y = pos2.lat - pos1.lat;
            return Math.sqrt(x * x + y * y);
        },
        transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y),
        infinite: true
    });

    let adminMap = null;
    let playerMarkers = {};
    let mapPlayers = [];
    let selectedPlayerId = null;
    const MAP_REFRESH_INTERVAL_MS = 5000;
    let mapRefreshTimerId = null;

    function gtaToLeaflet(x, y) {
        return [y, x];
    }

    function ensureMap() {
        const container = document.getElementById("map-leaflet");
        if (!container) return null;
        if (adminMap) return adminMap;
        var worldSize = 256 * Math.pow(2, 3);
        var lngMin = (0 - center_x) / scale_x;
        var lngMax = (worldSize - center_x) / scale_x;
        var latMin = (center_y - worldSize) / scale_y;
        var latMax = center_y / scale_y;
        var lngRange = lngMax - lngMin;
        var latRange = latMax - latMin;
        var pad = 0.25;
        var bounds = L.latLngBounds(
            L.latLng(latMin - latRange * pad, lngMin - lngRange * pad),
            L.latLng(latMax + latRange * pad, lngMax + lngRange * pad)
        );

        adminMap = L.map("map-leaflet", {
            crs: mapCRS,
            minZoom: 2,
            maxZoom: 5,
            zoom: 3,
            center: [0, 0],
            zoomControl: false,
            attributionControl: false,
            preferCanvas: true,
            maxBounds: bounds,
            maxBoundsViscosity: 0.5,
            layers: [
                L.tileLayer("img/map/{z}/{x}/{y}.jpg", {
                    noWrap: true,
                    minZoom: 0,
                    maxZoom: 5,
                    continuousWorld: false
                })
            ]
        });

        adminMap.whenReady(function () {
            setTimeout(function () {
                adminMap.invalidateSize();
                adminMap.panBy([-180, 0], { animate: false });
            }, 100);
        });

        return adminMap;
    }

    function buildPopupContent(player) {
        const x = (player.x != null) ? Number(player.x).toFixed(1) : "—";
        const y = (player.y != null) ? Number(player.y).toFixed(1) : "—";
        const z = (player.z != null) ? Number(player.z).toFixed(1) : "—";
        const name = player.name || "Unknown";
        const coordsText = "X: " + x + " Y: " + y + " Z: " + z;
        const sp = window.sectionPerms || {};
        const mapOrPlayers = (sp.map === true || sp.map === "1" || sp.map === 1) || (sp.players === true || sp.players === "1" || sp.players === 1);
        function btnHtml(action, label, icon) {
            const hasActionPerm = sp[action] === true || sp[action] === "1" || sp[action] === 1;
            const captureCompat = action === "viewScreen" && (sp.capture === true || sp.capture === "1" || sp.capture === 1);
            const allowed = mapOrPlayers && (hasActionPerm || captureCompat);
            const cls = "map-popup-btn" + (allowed ? "" : " map-popup-btn-no-permission");
            const dataPerm = allowed ? "true" : "false";
            return '<button type="button" class="' + cls + '" data-action="' + escapeHtml(action) + '" data-perm-allowed="' + dataPerm + '" data-id="' + escapeHtml(String(player.id)) + '"><i class="fa-solid ' + icon + '"></i> ' + escapeHtml(label) + '</button>';
        }
        return (
            '<div class="map-popup-content">' +
            '<div class="map-popup-name">' + escapeHtml(name) + '</div>' +
            '<div class="map-popup-coords-wrap">' +
            '<span class="map-popup-coords">X: ' + x + ' &nbsp; Y: ' + y + ' &nbsp; Z: ' + z + '</span>' +
            '<button type="button" class="map-popup-copy-coords" title="Copiar coordenadas" data-coords="' + escapeHtml(coordsText) + '"><i class="fa-solid fa-copy"></i></button>' +
            '</div>' +
            '<div class="map-popup-actions">' +
            btnHtml("bring", "Bring here", "fa-user") +
            btnHtml("goto", "Go to Player", "fa-location-dot") +
            btnHtml("freeze", "Freeze", "fa-snowflake") +
            btnHtml("viewScreen", "View screen", "fa-display") +
            '</div>' +
            '</div>'
        );
    }

    function escapeHtml(str) {
        if (str == null) return "";
        var s = String(str);
        return s
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    function getMarkerIcon(isSelected) {
        return L.divIcon({
            className: "admin-map-marker " + (isSelected ? "selected" : ""),
            html: '<div class="admin-marker-dot' + (isSelected ? " selected" : "") + '"></div>',
            iconSize: [20, 20],
            iconAnchor: [10, 10]
        });
    }

    function setCopyButtonSuccessState(copyBtn) {
        var icon = copyBtn.querySelector("i");
        if (icon) {
            icon.className = "fa-solid fa-check";
            setTimeout(function () { icon.className = "fa-solid fa-copy"; }, 1500);
        }
    }

    function copyTextFallback(text) {
        var ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.left = "-9999px";
        ta.style.top = "0";
        ta.setAttribute("readonly", "");
        document.body.appendChild(ta);
        ta.select();
        var ok = false;
        try { ok = document.execCommand("copy"); } catch (e) {}
        document.body.removeChild(ta);
        return ok;
    }

    function attachPopupListeners(marker, el) {
        if (!el) return;
        el.querySelectorAll(".map-popup-btn").forEach(function (btn) {
            btn.addEventListener("click", function () {
                if (btn.getAttribute("data-perm-allowed") === "false") return;
                var action = btn.getAttribute("data-action");
                var id = btn.getAttribute("data-id");
                if (action && id) {
                    var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "";
                    if (resName) {
                        fetch("https://" + resName + "/mapAction", {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify({ action: action, playerId: parseInt(id, 10) || id })
                        });
                    }
                }
            });
        });
        var copyBtn = el.querySelector(".map-popup-copy-coords");
        if (copyBtn) {
            copyBtn.addEventListener("click", function () {
                var coords = copyBtn.getAttribute("data-coords");
                if (!coords) return;
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(coords).then(function () {
                        setCopyButtonSuccessState(copyBtn);
                    }).catch(function () {
                        if (copyTextFallback(coords)) setCopyButtonSuccessState(copyBtn);
                    });
                } else if (copyTextFallback(coords)) {
                    setCopyButtonSuccessState(copyBtn);
                }
            });
        }
    }

    function latLngEqual(a, b) {
        if (!a || !b) return false;
        return Math.abs(a.lat - b.lat) < 1e-4 && Math.abs(a.lng - b.lng) < 1e-4;
    }

    function renderMarkers(players) {
        if (!adminMap) return;

        var currentIds = {};
        players.forEach(function (player) {
            currentIds[String(player.id)] = true;
        });

        Object.keys(playerMarkers).forEach(function (id) {
            if (!currentIds[id]) {
                adminMap.removeLayer(playerMarkers[id]);
                delete playerMarkers[id];
            }
        });

        players.forEach(function (player) {
            var x = player.x != null ? player.x : 0;
            var y = player.y != null ? player.y : 0;
            var newLatLng = gtaToLeaflet(x, y);
            var isSelected = selectedPlayerId !== null && String(player.id) === String(selectedPlayerId);
            var existing = playerMarkers[player.id];

            if (existing) {
                var popup = existing.getPopup();
                var wasOpen = popup.isOpen();
                var oldLatLng = existing.getLatLng();
                var positionChanged = !latLngEqual(oldLatLng, newLatLng);

                if (wasOpen && positionChanged) {
                    existing.closePopup();
                }
                existing.setLatLng(newLatLng);
                existing.setIcon(getMarkerIcon(isSelected));
                popup.setContent(buildPopupContent(player));
                if (wasOpen && !positionChanged) {
                    attachPopupListeners(existing, popup.getElement());
                }
                return;
            }

            var marker = L.marker(newLatLng, { icon: getMarkerIcon(isSelected) }).addTo(adminMap);
            marker._playerId = player.id;
            marker.bindPopup(buildPopupContent(player), {
                className: "admin-map-popup"
            });
            marker.on("popupopen", function () {
                attachPopupListeners(marker, marker.getPopup().getElement());
            });
            playerMarkers[player.id] = marker;
        });
    }

    function renderList(players) {
        var listEl = document.getElementById("map-player-list");
        if (!listEl) return;

        if (!players || players.length === 0) {
            listEl.innerHTML = '<div class="map-player-empty">No players online</div>';
            return;
        }

        listEl.innerHTML = "";
        players.forEach(function (player) {
            var id = player.id;
            var name = player.name || "Unknown";
            var ping = player.ping != null ? parseInt(player.ping, 10) : null;
            var isSelected = selectedPlayerId !== null && String(id) === String(selectedPlayerId);
            var pingClass = "ping-unknown";
            if (ping !== null && !isNaN(ping)) {
                if (ping < 80) pingClass = "ping-good";
                else if (ping < 150) pingClass = "ping-medium";
                else pingClass = "ping-bad";
            }
            var pingLabel = ping !== null && !isNaN(ping) ? String(ping) : "—";

            var item = document.createElement("button");
            item.type = "button";
            item.className = "map-player-item" + (isSelected ? " selected" : "");
            item.dataset.playerId = String(id);
            item.innerHTML =
                '<span class="map-player-item-avatar"><i class="fa-solid fa-user"></i></span>' +
                '<span class="map-player-item-info">' +
                '<span class="map-player-item-name">' + escapeHtml(name) + '</span>' +
                '<span class="map-player-item-id">#' + id + '</span>' +
                '</span>' +
                '<span class="map-player-item-ping ' + pingClass + '" title="Ping">' +
                '<span class="map-player-item-ping-num">' + escapeHtml(pingLabel) + '</span>' +
                '<i class="fa-solid fa-signal map-player-item-ping-icon"></i>' +
                '</span>' +
                '<span class="map-player-item-online" title="Online"></span>';

            item.addEventListener("click", function () {
                selectedPlayerId = id;
                document.querySelectorAll(".map-player-item").forEach(function (i) {
                    i.classList.toggle("selected", i.dataset.playerId === String(id));
                });
                renderMarkers(mapPlayers);

                var marker = playerMarkers[id];
                if (marker && adminMap) {
                    adminMap.panTo(marker.getLatLng());
                    marker.openPopup();
                }
            });

            listEl.appendChild(item);
        });
    }

    function setPlayers(players) {
        mapPlayers = Array.isArray(players) ? players : [];
        renderList(mapPlayers);
        renderMarkers(mapPlayers);
    }

    window.addEventListener("message", function (event) {
        var data = event.data;
        if (!data || !data.action) return;

        if (data.action === "setPlayersMap") {
            setPlayers(data.players || []);
            return;
        }

        if (data.action === "openMap") {
            var pageMap = document.getElementById("map");
            if (pageMap && !pageMap.classList.contains("active")) return;
            ensureMap();
            setTimeout(function () {
                if (adminMap) adminMap.invalidateSize();
            }, 150);
        }

        if (data.action === "screenViewerMap") {
            if (data.targetId != null) {
                var overlay = document.getElementById("map-screen-viewer-overlay");
                var titleEl = document.getElementById("map-screen-viewer-title");
                var frameEl = document.getElementById("map-screen-viewer-frame");
                var liveBadge = document.getElementById("map-screen-viewer-live");
                if (overlay && titleEl && frameEl) {
                    titleEl.textContent = "[" + data.targetId + "] " + (data.targetName || "Player");
                    frameEl.innerHTML = "";
                    frameEl.classList.remove("has-image");
                    if (liveBadge) liveBadge.classList.add("hidden");
                    var msg = document.createElement("div");
                    msg.className = "map-screen-viewer-loading";
                    msg.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Conectando transmisión en vivo...';
                    frameEl.appendChild(msg);
                    overlay.classList.remove("hidden");
                }
            }
            if (data.image != null && data.image.length > 0) {
                var frameEl = document.getElementById("map-screen-viewer-frame");
                var liveBadge = document.getElementById("map-screen-viewer-live");
                if (frameEl) {
                    var src = data.image;
                    if (src.indexOf("http://") === 0 || src.indexOf("https://") === 0) {
                        src = src + (src.indexOf("?") === -1 ? "?" : "&") + "t=" + Date.now();
                    }
                    var img = frameEl.querySelector("img");
                    if (!img) {
                        frameEl.classList.add("has-image");
                        frameEl.innerHTML = "";
                        img = document.createElement("img");
                        img.alt = "Pantalla en vivo del jugador";
                        frameEl.appendChild(img);
                        if (liveBadge) liveBadge.classList.remove("hidden");
                    }
                    img.src = src;
                }
            }
        }
    });

    function closeScreenViewerModal(notifyClient) {
        var overlay = document.getElementById("map-screen-viewer-overlay");
        if (overlay) overlay.classList.add("hidden");
        if (notifyClient) {
            fetch("https://" + GetParentResourceName() + "/mapCloseScreenViewer", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            }).catch(function () {});
        }
    }

    function requestMapPlayers() {
        var resName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "";
        if (!resName) return;
        fetch("https://" + resName + "/mapRequestPlayers", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).catch(function () {});
    }

    function clearMapRefresh() {
        if (mapRefreshTimerId != null) {
            clearInterval(mapRefreshTimerId);
            mapRefreshTimerId = null;
        }
    }

    function onMapPageShown() {
        ensureMap();
        if (adminMap) adminMap.invalidateSize();
        clearMapRefresh();
        requestMapPlayers();
        mapRefreshTimerId = setInterval(function () {
            var mapPage = document.getElementById("map");
            if (!mapPage || !mapPage.classList.contains("active")) {
                clearMapRefresh();
                return;
            }
            requestMapPlayers();
        }, MAP_REFRESH_INTERVAL_MS);
    }

    function onMapPageHidden() {
        clearMapRefresh();
    }

    document.querySelectorAll(".menu li").forEach(function (item) {
        if (item.getAttribute("data-page") !== "map") return;
        item.addEventListener("click", function () {
            setTimeout(function () {
                var mapPage = document.getElementById("map");
                if (mapPage && mapPage.classList.contains("active")) onMapPageShown();
            }, 50);
        });
    });

    var mapPageEl = document.getElementById("map");
    if (mapPageEl) {
        var observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                if (m.attributeName !== "class") return;
                if (mapPageEl.classList.contains("active")) {
                    setTimeout(onMapPageShown, 150);
                } else {
                    onMapPageHidden();
                }
            });
        });
        observer.observe(mapPageEl, { attributes: true });
    }

    var toggleBtn = document.getElementById("map-player-list-toggle");
    var listPanel = document.getElementById("map-player-list-panel");
    if (toggleBtn && listPanel) {
        toggleBtn.addEventListener("click", function () {
            var isOpen = listPanel.classList.toggle("is-open");
            toggleBtn.setAttribute("aria-expanded", isOpen ? "true" : "false");
        });
    }

    var screenViewerOverlay = document.getElementById("map-screen-viewer-overlay");
    var screenViewerClose = document.getElementById("map-screen-viewer-close");
    if (screenViewerClose) {
        screenViewerClose.addEventListener("click", function () { closeScreenViewerModal(true); });
    }
    if (screenViewerOverlay) {
        screenViewerOverlay.addEventListener("click", function (e) {
            if (e.target === screenViewerOverlay) closeScreenViewerModal(true);
        });
    }
})();
