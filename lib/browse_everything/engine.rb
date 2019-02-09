# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
    config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
    config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
  end
end
