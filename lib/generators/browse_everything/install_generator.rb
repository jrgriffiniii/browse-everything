# frozen_string_literal: true

require 'rails/generators'

class BrowseEverything::InstallGenerator < Rails::Generators::Base
  desc 'This generator installs the browse everything configuration into your application'

  source_root File.expand_path('templates', __dir__)

  def run_webpack
    return if ENV["RAILS_SPROCKETS"] == "true"

    rails_command "webpacker:install"
  end

  def inject_config
    generate 'browse_everything:config'
  end
end
