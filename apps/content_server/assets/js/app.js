import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

class InMemoryStorage {
  constructor() { this.storage = {} }
  getItem(keyName) { return this.storage[keyName] }
  removeItem(keyName) { delete this.storage[keyName] }
  setItem(keyName, keyValue) { this.storage[keyName] = keyValue }
}

const Hooks = {
  Render: {
    mounted() {
      render(this.el.id)
    },
    updated() {
      render(this.el.id)
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, localStorage: new InMemoryStorage(), sessionStorage: new InMemoryStorage(), params: {_csrf_token: csrfToken}})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

