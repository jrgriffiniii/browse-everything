# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
    initializer "browse_everything.assets.precompile" do |app|
      app.config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
      app.config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
      app.config.assets.precompile += %w[browse_everything.js browse_everything.css]
    end
  end
end
