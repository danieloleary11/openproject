#-- encoding: UTF-8
$LOAD_PATH.unshift File.expand_path("../lib/", __FILE__)

require "acts_as_journalized"
ActiveRecord::Base.send(:include, Redmine::Acts::Journalized)

Rails.configuration.to_prepare do
  # Model
  require "journal"

  # this is for compatibility with current trunk
  # once the plugin is part of the core, this will not be needed
  # patches should then be ported onto the core
  # require File.dirname(__FILE__) + '/lib/acts_as_journalized/journal_patch'
  # require File.dirname(__FILE__) + '/lib/acts_as_journalized/journal_observer_patch'
  # require File.dirname(__FILE__) + '/lib/acts_as_journalized/activity_fetcher_patch'
end
