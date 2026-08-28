(function () {
    "use strict";
    if (typeof window.CfxTexture !== "undefined") return;
    var THREE = window.THREE;
    if (!THREE) return;

    var RGBFormat = THREE.RGBFormat !== undefined ? THREE.RGBFormat : 1022;
    var NearestFilter = THREE.NearestFilter !== undefined ? THREE.NearestFilter : 1003;
    var ClampToEdgeWrapping = THREE.ClampToEdgeWrapping !== undefined ? THREE.ClampToEdgeWrapping : 1001;
    var UnsignedByteType = THREE.UnsignedByteType !== undefined ? THREE.UnsignedByteType : 1009;

    function CfxTexture() {
        var data = new Uint8Array(3);
        this.image = { data: data, width: 1, height: 1 };
        this.needsUpdate = true;
        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;
        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
        this.format = RGBFormat;
        this.type = UnsignedByteType;
        this.wrapS = ClampToEdgeWrapping;
        this.wrapT = ClampToEdgeWrapping;
        this.offset = (THREE.Vector2 && new THREE.Vector2(0, 0)) || { x: 0, y: 0 };
        this.repeat = (THREE.Vector2 && new THREE.Vector2(1, 1)) || { x: 1, y: 1 };
        this.uuid = "cfx-" + Math.random().toString(36).slice(2);
    }
    CfxTexture.prototype.isDataTexture = true;
    CfxTexture.prototype.isCfxTexture = true;

    window.CfxTexture = CfxTexture;
})();
