// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
import "jquery"
import "jquery_ujs"

// Make jQuery available globally
window.$ = window.jQuery = jQuery;

// Import other JavaScript files as needed
// import "./custom" 