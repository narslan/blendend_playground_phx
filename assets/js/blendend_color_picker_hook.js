export const BlendendColorPicker = {
  mounted() {
    this.onClick = this.onClick.bind(this)
    this.el.addEventListener("click", this.onClick)

    this.onLoad = () => {
      this.imageWidth = this.el.naturalWidth || parseInt(this.el.dataset.imgWidth || "0", 10)
      this.imageHeight = this.el.naturalHeight || parseInt(this.el.dataset.imgHeight || "0", 10)
    }

    this.el.addEventListener("load", this.onLoad, {passive: true})
    this.onLoad()
  },

  updated() {
    this.onLoad()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("load", this.onLoad)
  },

  onClick(event) {
    const rect = this.el.getBoundingClientRect()
    const w = this.el.naturalWidth || this.imageWidth
    const h = this.el.naturalHeight || this.imageHeight

    if (!w || !h || rect.width <= 0 || rect.height <= 0) return

    const px = (event.clientX - rect.left) * (w / rect.width)
    const py = (event.clientY - rect.top) * (h / rect.height)

    const x = Math.max(0, Math.min(w - 1, Math.floor(px)))
    const y = Math.max(0, Math.min(h - 1, Math.floor(py)))

    const componentRoot = this.el.closest("[data-phx-component]")
    if (componentRoot) {
      this.pushEventTo(componentRoot, "pick-color", {x, y})
    } else {
      this.pushEvent("pick-color", {x, y})
    }
  },
}
