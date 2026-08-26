import {
  OrthographicCamera,
  Scene,
  WebGLRenderTarget,
  LinearFilter,
  NearestFilter,
  RGBAFormat,
  UnsignedByteType,
  CfxTexture,
  ShaderMaterial,
  PlaneBufferGeometry,
  Mesh,
  WebGLRenderer,
} from "../src/module/Three.minimal.js";

var isAnimated = false;
var MainRender = null;
var liveInterval = null;
var outW = 426;
var outH = 240;
var payload = 58000;
var resourceNameCache = null;

function getResourceName() {
  if (resourceNameCache && resourceNameCache !== "") return resourceNameCache;
  try {
    if (typeof GetParentResourceName === "function") {
      resourceNameCache = GetParentResourceName();
    }
  } catch (e) {}

  if (!resourceNameCache || resourceNameCache === "") {
    var host = (window.location && window.location.host) ? String(window.location.host) : "";
    if (host.indexOf("cfx-nui-") === 0) {
      resourceNameCache = host.substring(8);
    }
  }

  if (!resourceNameCache || resourceNameCache === "") {
    resourceNameCache = "admin";
  }
  return resourceNameCache;
}

function sendToClient(dataUrl) {
  if (typeof dataUrl !== "string" || dataUrl === "") return;
  if (dataUrl.length <= payload) {
    fetch("https://" + getResourceName() + "/captureResult", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ dataUrl: dataUrl }),
    }).catch(function () {});
  }
}

function encodeCanvasForTransport(canvas) {
  var quality = 0.48;
  var encoded = canvas.toDataURL("image/jpeg", quality);
  var tries = 0;
  while (encoded.length > payload && tries < 4) {
    quality = quality - 0.08;
    if (quality < 0.18) break;
    encoded = canvas.toDataURL("image/jpeg", quality);
    tries++;
  }

  if (encoded.length > payload) {
    var scaled = document.createElement("canvas");
    scaled.width = Math.max(256, Math.floor(canvas.width * 0.8));
    scaled.height = Math.max(144, Math.floor(canvas.height * 0.8));
    var sctx = scaled.getContext("2d");
    sctx.drawImage(canvas, 0, 0, canvas.width, canvas.height, 0, 0, scaled.width, scaled.height);
    quality = 0.34;
    encoded = scaled.toDataURL("image/jpeg", quality);
    tries = 0;
    while (encoded.length > payload && tries < 4) {
      quality = quality - 0.06;
      if (quality < 0.15) break;
      encoded = scaled.toDataURL("image/jpeg", quality);
      tries++;
    }
  }

  return encoded;
}

class GameRender {
  constructor() {
    var w = Math.max(window.innerWidth || 640, 640);
    var h = Math.max(window.innerHeight || 360, 360);

    var cameraRTT = new OrthographicCamera(w / -2, w / 2, h / 2, h / -2, -10000, 10000);
    cameraRTT.position.z = 0;
    cameraRTT.setViewOffset(w, h, 0, 0, w, h);

    var sceneRTT = new Scene();
    var gameTexture = new CfxTexture();
    gameTexture.needsUpdate = true;

    var material = new ShaderMaterial({
      uniforms: { tDiffuse: { value: gameTexture } },
      vertexShader: [
        "varying vec2 vUv;",
        "void main() { vUv = vec2(uv.x, 1.0-uv.y); gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }",
      ].join("\n"),
      fragmentShader: [
        "varying vec2 vUv;",
        "uniform sampler2D tDiffuse;",
        "void main() { gl_FragColor = texture2D(tDiffuse, vUv); }",
      ].join("\n"),
    });

    var plane = new PlaneBufferGeometry(w, h);
    var quad = new Mesh(plane, material);
    quad.position.z = -100;
    sceneRTT.add(quad);

    var rtTexture = new WebGLRenderTarget(w, h, {
      minFilter: LinearFilter,
      magFilter: NearestFilter,
      format: RGBAFormat,
      type: UnsignedByteType,
    });

    var renderer = new WebGLRenderer({ alpha: true, preserveDrawingBuffer: true });
    renderer.setSize(w, h);
    renderer.setPixelRatio(1);
    renderer.autoClear = false;

    var container = document.createElement("div");
    container.id = "jc-live-capture-container";
    container.style.cssText = "position:fixed;left:0;top:0;width:1px;height:1px;opacity:0;pointer-events:none;overflow:hidden;";
    renderer.domElement.style.cssText = "width:1px;height:1px;";
    container.appendChild(renderer.domElement);
    document.body.appendChild(container);

    this.renderer = renderer;
    this.rtTexture = rtTexture;
    this.sceneRTT = sceneRTT;
    this.cameraRTT = cameraRTT;
    this.gameTexture = gameTexture;
    this.material = material;
  }

  renderOne() {
    if (!this.renderer || !this.sceneRTT || !this.cameraRTT || !this.rtTexture) return;
    this.gameTexture.needsUpdate = true;
    this.renderer.clear();
    this.renderer.render(this.sceneRTT, this.cameraRTT, this.rtTexture, true);
  }

  readAndSend() {
    if (!this.renderer || !this.rtTexture) return;
    var w = this.rtTexture.width;
    var h = this.rtTexture.height;
    var read = new Uint8Array(w * h * 4);
    this.renderer.readRenderTargetPixels(this.rtTexture, 0, 0, w, h, read);

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
    var dataURL = encodeCanvasForTransport(canvas);
    sendToClient(dataURL);
  }

  captureFrame() {
    this.renderOne();
    this.readAndSend();
  }
}

function start(opts) {
  opts = opts || {};
  if (!MainRender) MainRender = new GameRender();
  isAnimated = true;
  if (liveInterval) clearInterval(liveInterval);
  var intervalMs = (opts.intervalMs != null && opts.intervalMs !== "") ? Math.max(380, parseInt(opts.intervalMs, 10) || 420) : 420;
  liveInterval = setInterval(function () {
    if (MainRender && isAnimated) MainRender.captureFrame();
  }, intervalMs);
}

function stop() {
  isAnimated = false;
  if (liveInterval) {
    clearInterval(liveInterval);
    liveInterval = null;
  }
}

window.JcLiveCapture = { start: start, stop: stop };
