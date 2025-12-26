export const PlaygroundEditor = {
  mounted() {
    this.indent = parseInt(this.el.dataset.indent || "2", 10)

    this.cursorEl = this.el.dataset.cursorId
      ? document.getElementById(this.el.dataset.cursorId)
      : null
    this.gutterInner = document.getElementById(`${this.el.id}-gutter-inner`)
    this.lineCount = null

    this.onKeyDown = this.onKeyDown.bind(this)
    this.onInput = this.onInput.bind(this)
    this.onScroll = this.onScroll.bind(this)
    this.onSelectionUpdate = this.onSelectionUpdate.bind(this)

    this.el.addEventListener("keydown", this.onKeyDown)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("scroll", this.onScroll, {passive: true})
    this.el.addEventListener("click", this.onSelectionUpdate)
    this.el.addEventListener("keyup", this.onSelectionUpdate)
    this.el.addEventListener("select", this.onSelectionUpdate)

    this.updateGutter()
    this.updateCursor()
    this.syncGutterScroll()
  },

  updated() {
    this.updateGutter()
    this.updateCursor()
    this.syncGutterScroll()
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKeyDown)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("scroll", this.onScroll)
    this.el.removeEventListener("click", this.onSelectionUpdate)
    this.el.removeEventListener("keyup", this.onSelectionUpdate)
    this.el.removeEventListener("select", this.onSelectionUpdate)
  },

  onInput() {
    this.updateGutter()
    this.updateCursor()
  },

  onScroll() {
    this.syncGutterScroll()
  },

  onSelectionUpdate() {
    this.updateCursor()
  },

  updateGutter() {
    if (!this.gutterInner) return

    const nextCount = (this.el.value.match(/\n/g) || []).length + 1
    if (this.lineCount === nextCount) return

    let html = ""
    for (let i = 1; i <= nextCount; i++) {
      html += `<div class="h-6 leading-6 text-right">${i}</div>`
    }

    this.gutterInner.innerHTML = html
    this.lineCount = nextCount
  },

  syncGutterScroll() {
    if (!this.gutterInner) return
    this.gutterInner.style.transform = `translateY(${-this.el.scrollTop}px)`
  },

  updateCursor() {
    if (!this.cursorEl) return

    const pos = this.el.selectionStart ?? 0
    const value = this.el.value
    let line = 1
    let lastNewline = -1

    for (let i = 0; i < pos; i++) {
      if (value[i] === "\n") {
        line++
        lastNewline = i
      }
    }

    const col = pos - lastNewline
    this.cursorEl.textContent = `Ln ${line}, Col ${col}`
  },

  onKeyDown(event) {
    const isModKey = event.metaKey || event.ctrlKey

    if (isModKey && (event.key === "s" || event.key === "S")) {
      event.preventDefault()
      document.getElementById("playground-update")?.click()
      return
    }

    if (isModKey && event.shiftKey && event.key === "Enter") {
      event.preventDefault()
      document.getElementById("playground-format")?.click()
      return
    }

    if (event.key !== "Tab") return

    event.preventDefault()

    const textarea = this.el
    const value = textarea.value
    const selectionStart = textarea.selectionStart
    const selectionEnd = textarea.selectionEnd
    const indentText = " ".repeat(Math.max(0, this.indent))

    const startLineStart = value.lastIndexOf("\n", selectionStart - 1) + 1
    const endLineEnd = (() => {
      const newlineIndex = value.indexOf("\n", selectionEnd)
      return newlineIndex === -1 ? value.length : newlineIndex
    })()

    const before = value.slice(0, startLineStart)
    const selectedBlock = value.slice(startLineStart, endLineEnd)
    const after = value.slice(endLineEnd)

    const lines = selectedBlock.split("\n")

    if (!event.shiftKey) {
      const newLines = lines.map(line => indentText + line)
      const newBlock = newLines.join("\n")
      textarea.value = before + newBlock + after

      const lineCount = lines.length
      const selectionDelta = indentText.length * lineCount
      textarea.selectionStart = selectionStart + indentText.length
      textarea.selectionEnd = selectionEnd + selectionDelta
    } else {
      const newLines = lines.map(line => {
        if (line.startsWith(indentText)) return line.slice(indentText.length)
        if (line.startsWith("\t")) return line.slice(1)
        if (line.startsWith(" ")) return line.replace(/^ {1,2}/, "")
        return line
      })

      const removedPerLine = lines.map((line, index) => lines[index].length - newLines[index].length)

      const removedFirstLine = removedPerLine[0] || 0
      const removedTotal = removedPerLine.reduce((sum, amount) => sum + amount, 0)

      const newBlock = newLines.join("\n")
      textarea.value = before + newBlock + after

      textarea.selectionStart = Math.max(startLineStart, selectionStart - removedFirstLine)
      textarea.selectionEnd = Math.max(textarea.selectionStart, selectionEnd - removedTotal)
    }

    textarea.dispatchEvent(new Event("input", {bubbles: true}))
  },
}
