# frozen_string_literal: true

class BrowserFactory
  class << self
    # Construct a Browser object with session information
    # @param [ActionDispatch::Session] session
    # @param [Hash] url_options the options for the URL generation in the provider
    # @return [Browser]
    def build(session: nil, url_options: {})
      new_browser = browser(url_options: url_options)
      return new_browser if session.nil?

      new_browser.providers.each_value do |provider_handler|
        # The authentication token must be set here
        provider_name = provider_handler.key
        provider_session = BrowseEverythingSession::ProviderSession.for(session: session, name: provider_name.to_sym)
        provider_handler.token = provider_session.token if provider_session.token
      end
      new_browser
    end

    # Retrieve an existing Provider by its name
    # @param [String] name the name of the provider
    # @param [ActionDispatch::Session] session
    # @param [Hash] url_options the options for the URL generation in the provider
    # @return [BrowseEverything::Driver::Base]
    #
    # @todo This should be renamed to #provider_for
    def for(name:, session: nil, url_options: {})
      current_browser = build(session: session, url_options: url_options)
      provider = current_browser.providers[name]
      provider || BrowseEverything::Driver::Base.new(url_options: url_options)
    end
  end

  def self.browser(url_options: {})
    BrowseEverything::Browser.new(url_options)
  end
  private_class_method :browser
end
