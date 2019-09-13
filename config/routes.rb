# frozen_string_literal: true

BrowseEverything::Engine.routes.draw do
  # Supporting other RESTful operations should be done for sessions
  resources :sessions, controller: 'browse_everything/sessions', only: [:create, :update] do
    # I'm not certain what :index would imply here - but it might be useful to
    # request all possible bytestreams or containers within the scope of a
    # session
    resources :bytestreams, controller: 'browse_everything/bytestreams', only: [:show]
    resources :containers, controller: 'browse_everything/containers', only: [:show, :index]

    # Supporting PUT and PATCH requests has me nervous, as Uploads should be
    # used to create a queue of BrowseEverything::UploadJobs
    #
    # :index would also be useful here
    resources :uploads, controller: 'browse_everything/sessions/uploads', only: [:create, :destroy]
  end
  resources :authorizations, controller: 'browse_everything/authorizations', only: [:create, :show]
  resources :providers, controller: 'browse_everything/providers', only: [:show, :index]

  # This is the route which will be needed for the OAuth callback URL
  # Rails defaults to accepting POST requests, so this might not work
  #   Within which the GET query parameters will instead be parsed
  #   This would probably violate the principles of RESTful architecture
  # This is a custom action for the OAuth callback
  get 'providers/:provider_id/authorize', to: 'browse_everything/providers#authorize', as: 'provider_authorize'
end
