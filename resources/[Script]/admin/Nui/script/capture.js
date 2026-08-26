(function () {
    "use strict";

    var THREE = window.THREE;
    var CfxTexture = window.CfxTexture;
    if (!THREE || !CfxTexture) {
        console.warn("[admin capture] THREE o CfxTexture no disponibles.");
        return;
    }

    var renderer, rtTexture, sceneRTT, cameraRTT, material, gameTexture;
    var outW = 854;
    var outH = 480;
    var liveActive = false;
    var liveUploadUrl = "";
    var liveInterval = null;

    function init() {
        var w = Math.max(window.innerWidth || 640, 640);
        var h = Math.max(window.innerHeight || 360, 360);

        cameraRTT = new THREE.OrthographicCamera(w / -2, w / 2, h / 2, h / -2, -10000, 10000);
        cameraRTT.position.z = 100;

        sceneRTT = new THREE.Scene();
        gameTexture = new CfxTexture();
        gameTexture.needsUpdate = true;

        material = new THREE.ShaderMaterial({
            uniforms: { tDiffuse: { value: gameTexture } },
            vertexShader: [
                "varying vec2 vUv;",
                "void main() {",
                "  vUv = vec2(uv.x, 1.0 - uv.y);",
                "  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
                "}"
            ].join("\n"),
            fragmentShader: [
                "varying vec2 vUv;",
                "uniform sampler2D tDiffuse;",
                "void main() { gl_FragColor = texture2D(tDiffuse, vUv); }"
            ].join("\n")
        });

        var plane = new THREE.PlaneBufferGeometry(w, h);
        var quad = new THREE.Mesh(plane, material);
        quad.position.z = -100;
        sceneRTT.add(quad);

        rtTexture = new THREE.WebGLRenderTarget(w, h, {
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter,
            format: THREE.RGBAFormat,
            type: THREE.UnsignedByteType
        });

        renderer = new THREE.WebGLRenderer({ alpha: true, preserveDrawingBuffer: true });
        renderer.setSize(w, h);
        renderer.setPixelRatio(1);
        renderer.autoClear = false;
        var app = document.getElementById("app");
        if (app) {
            app.appendChild(renderer.domElement);
            renderer.domElement.style.cssText = "position:fixed;left:0;top:0;width:1px;height:1px;opacity:0;pointer-events:none;";
        }
        tick();
    }

    function tick() {
        requestAnimationFrame(tick);
        if (!renderer || !sceneRTT || !cameraRTT || !rtTexture) return;
        gameTexture.needsUpdate = true;
        renderer.setRenderTarget(rtTexture);
        renderer.clear();
        renderer.render(sceneRTT, cameraRTT);
        renderer.setRenderTarget(null);
    }

    function dataURItoBlob(dataURI) {
        var byteString = atob(dataURI.split(",")[1]);
        var mime = dataURI.split(",")[0].split(":")[1].split(";")[0];
        var ab = new ArrayBuffer(byteString.length);
        var ia = new Uint8Array(ab);
        for (var i = 0; i < byteString.length; i++) ia[i] = byteString.charCodeAt(i);
        return new Blob([ab], { type: mime });
    }

    function readAndSend(uploadUrl, callback) {
        if (!renderer || !rtTexture) {
            if (callback) callback({ error: "not ready" });
            return;
        }
        var w = rtTexture.width;
        var h = rtTexture.height;
        var read = new Uint8Array(w * h * 4);
        renderer.readRenderTargetPixels(rtTexture, 0, 0, w, h, read);

        var canvas = document.createElement("canvas");
        canvas.width = outW;
        canvas.height = outH;
        var ctx = canvas.getContext("2d");
        var temp = document.createElement("canvas");
        temp.width = w;
        temp.height = h;
        var tctx = temp.getContext("2d");
        var imageData = new ImageData(new Uint8ClampedArray(read.buffer), w, h);
        tctx.putImageData(imageData, 0, 0);
        ctx.drawImage(temp, 0, 0, w, h, 0, 0, outW, outH);

        var dataURL = canvas.toDataURL("image/jpeg", uploadUrl ? 0.82 : 0.72);

        if (uploadUrl && uploadUrl.length > 0) {
            var formData = new FormData();
            formData.append("file", dataURItoBlob(dataURL), "screen.jpg");
            fetch(uploadUrl, { method: "POST", mode: "cors", body: formData })
                .then(function (r) { return r.json ? r.json() : r.text(); })
                .then(function (data) {
                    var url = (data && data.url) ? data.url : (typeof data === "string" ? data : null);
                    if (callback) callback(url ? { url: url } : { error: "No url" });
                })
                .catch(function (err) {
                    if (callback) callback({ error: String(err && err.message || err) });
                });
        } else {
            if (callback) callback({ dataUrl: dataURL });
        }
    }

    function sendResult(result) {
        if (window.parent !== window) {
            window.parent.postMessage({ action: "captureResult", result: result }, "*");
        }
    }

    window.addEventListener("message", function (event) {
        var data = event.data;
        if (!data) return;

        if (data.action === "capture") {
            readAndSend(data.uploadUrl || "", function (result) {
                sendResult(result);
            });
            return;
        }

        if (data.action === "startLive") {
            liveActive = true;
            liveUploadUrl = data.uploadUrl || "";
            var interval = data.intervalMs ? Math.max(200, parseInt(data.intervalMs, 10)) : 300;
            if (liveInterval) clearInterval(liveInterval);
            liveInterval = setInterval(function () {
                if (!liveActive) return;
                readAndSend(liveUploadUrl, function (result) {
                    if (!result.error) sendResult(result);
                });
            }, interval);
            return;
        }

        if (data.action === "stopLive") {
            liveActive = false;
            if (liveInterval) {
                clearInterval(liveInterval);
                liveInterval = null;
            }
        }
    });

    init();
})();
