# Be sure to restart your server when you modify this file.

Trunk::Application.config.session_store :active_record_store, :key => '_trunk_session', :domain => '.littleredbrick.com'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Trunk::Application.config.session_store :active_record_store
