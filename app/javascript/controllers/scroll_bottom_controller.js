import { Controller } from "@hotwired/stimulus"

// Keeps a scrollable container (e.g. a conversation) pinned to its newest content.
export default class extends Controller {
  connect() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
