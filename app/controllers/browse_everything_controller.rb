# frozen_string_literal: true

require File.expand_path('../helpers/browse_everything_helper', __dir__)

class BrowseEverythingController < ActionController::Base
  layout 'browse_everything'
  helper BrowseEverythingHelper
  include BrowseEverything::Parameters

  protect_from_forgery with: :exception

  after_action do
    provider_session.token = provider.token unless provider.nil? || provider.token.blank?
  end

  def validate_provider_supported
    raise BrowseEverything::NotImplementedError, 'No provider supported' if provider.nil?
  end

  def validate_provider_authorized
    raise BrowseEverything::NotAuthorizedError, 'Not authorized' unless provider.authorized?
  end

  # This requires that the API for the provider service be queried
  def provider_contents
    validate_provider_supported && validate_provider_authorized

    provider.contents(browse_path, provider_contents_current_page)
  end

  # This requires that the number of pages be known
  def provider_contents_pages
    validate_provider_supported && validate_provider_authorized

    provider.contents_pages
  end

  # This may be obtained by strictly parsing the request parameters
  def provider_contents_current_page
    provider.contents_current_page(self)
  end

  # This may be obtained by strictly parsing the request parameters
  def provider_contents_next_page
    provider.contents_next_page(self)
  end

  # This requires that the number of pages be known
  def provider_contents_last_page?
    validate_provider_supported && validate_provider_authorized

    provider.contents_last_page?(self)
  end

  def index
    render layout: !request.xhr?
  end

  # Either render the link to authorization or render the files
  # provider#show method is invoked here
  def show
    render partial: 'files', layout: !request.xhr?
  rescue StandardError => error
    reset_provider_session!

    # Should an error be raised, log the error and redirect the use to reauthenticate
    logger.warn "Failed to retrieve the hosted files: #{error}"
    render partial: 'auth', layout: !request.xhr?
  end

  # Action for the OAuth2 callback
  # Authenticate against the API and store the token in the session
  def auth
    # params contains the access code with with the key :code
    provider_session.token = provider.connect(params, provider_session.data, connector_response_url_options)
  end

  def resolve
    # This needs to just pass URLs
    selected_files = browse_everything_params || selected_params || []
    selected_links = []
    selected_directories = []
    payload = {}
    last_provider_key = nil

    selected_files.each do |file|
      binding.pry
      location = file[:location]
      provider_key_value, id = location.split(/:/)
      provider_key = provider_key_value.to_sym

      values = browser.providers[provider_key].link_for(id, file[:name], file[:size])
      values.each do |value|
        (url, extra) = value
        result = { url: url }
        result.merge!(extra) unless extra.nil?
        selected_links << result unless result.fetch(:directory, false)
        selected_directories << result if result.fetch(:directory, false) && !selected_directories.include?(result)
      end

      last_provider_key = provider_key
    end

    payload = selected_links

    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: payload }
    end
  end

  private

    # Constructs or accesses an existing session manager Object
    # @return [BrowseEverythingSession::ProviderSession] the session manager
    def provider_session
      BrowseEverythingSession::ProviderSession.new(session: session, name: provider_name)
    end

    # Clears all authentication tokens, codes, and other data from the Rails session
    def reset_provider_session!
      return unless @provider_session
      @provider_session.token = nil
      @provider_session.code = nil
      @provider_session.data = nil
      @provider_session = nil
    end

    def connector_response_url_options
      { protocol: request.protocol, host: request.host, port: request.port }
    end

    # Generates the authentication link for a given provider service
    # @return [String] the authentication link
    def auth_link
      @auth_link ||= if provider.present?
                       link, data = provider.auth_link(connector_response_url_options)
                       provider_session.data = data
                       link = "#{link}&state=#{provider.key}" unless link.to_s.include?('state')
                       link
                     end
    end

    # Accesses the relative path for browsing from the Rails session
    # @return [String]
    def browse_path
      params.fetch(:path, '')
    end

    # Generate the provider name from the Rails session state value
    # @return [String]
    def provider_name_from_state
      state_value = params[:state]
      state_components = state_value.to_s.split(/\|/)
      state_components.last
    end

    # Generates the name of the provider using Rails session values
    # @return [String]
    def provider_name
      value = params[:provider] || provider_name_from_state || browser.providers.each_key.to_a.first
      session[:provider] = value
    end

    # Constructs a browser manager Object
    # Browser state cannot persist between requests to the Controller
    # Hence, a Browser must be reinstantiated for each request using the state provided in the Rails session
    # @return [BrowseEverything::Browser]
    def browser
      BrowserFactory.build(session: session, url_options: url_options)
    end

    # Retrieves a cached provider, or, defaults to the first configured provider
    # @return [BrowseEverything::Driver::Base]
    def build_provider
      provider_key = provider_name.to_sym
      return browser.providers[provider_key] if browser.providers.key?(provider_key)

      browser.first_provider
    end

    # Retrieve the Driver for each request
    # @return [BrowseEverything::Driver::Base]
    def provider
      @provider ||= build_provider
    end

    helper_method :auth_link
    helper_method :browser
    helper_method :browse_path
    helper_method :provider
    helper_method :provider_name
    helper_method :provider_contents
    helper_method :provider_contents_pages
    helper_method :provider_contents_current_page
    helper_method :provider_contents_next_page
    helper_method :provider_contents_last_page?
end
