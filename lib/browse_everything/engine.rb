# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
=begin
rails aborted!
Don't know how to build task 'webpacker:install' (See the list of available tasks with `rails --tasks`)
=end
    if Rails.version < '6.0'
      config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
      config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
      config.assets.precompile += %w[browse_everything.js browse_everything.css]
    else

      # This is used for webpacker:install
      initializer "browse_everything.assets.precompile" do |app|
        app.config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
        app.config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
        app.config.assets.precompile += %w[browse_everything.js browse_everything.css]
      end
    end
  end
end
