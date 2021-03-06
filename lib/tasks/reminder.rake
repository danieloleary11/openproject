#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

desc <<-END_DESC
Send reminders about issues due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user ids who should be reminded

Example:
  rake redmine:send_reminders days=7 users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :send_reminders => :environment do
    reminder = DueIssuesReminder.new(ENV['days'], ENV['project'], ENV['tracker'], ENV['users'].to_s.split(',').map(&:to_i))
    reminder.remind_users
  end
end
