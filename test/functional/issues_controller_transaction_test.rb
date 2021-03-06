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
require File.expand_path('../../test_helper', __FILE__)
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTransactionTest < ActionController::TestCase
  fixtures :all

  self.use_transactional_fixtures = false

  def setup
    super
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_put_update_stale_issue
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    assert_no_difference 'Journal.count' do
      assert_no_difference 'TimeEntry.count' do
        assert_no_difference 'Attachment.count' do
          put :update,
                :id => issue.id,
                :issue => {
                  :fixed_version_id => 4,
                  :lock_version => (issue.lock_version - 1)
                },
                :notes => '',
                :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}},
                :time_entry => { :hours => '2.5', :comments => '', :activity_id => TimeEntryActivity.first.id }
        end
      end
    end

    assert_response :success
    assert_template 'edit'
    assert_tag :tag => 'div', :attributes => { :id => 'errorExplanation' },
                              :content => /Information has been updated by at least one other user in the meantime./
  end

  def test_put_update_stale_issue_prints_users_that_were_changing_it
    issue = Issue.find(1)
    @request.session[:user_id] = 3

    put :update,
          :id => issue.id,
          :issue => {
            :fixed_version_id => 4,
            :lock_version => 0
          },
          :notes => '',
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}},
          :time_entry => { :hours => '2.5', :comments => '', :activity_id => TimeEntryActivity.first.id }

    assert_response :success
    assert_template 'edit'

    assert_tag :tag => 'div', :attributes => { :id => 'errorExplanation' },
                              :content => /redMine Admin \(#{Journal.find(1).created_at.strftime("%d %b 00:00")}\), John Smith \(#{Journal.find(2).created_at.strftime("%d %b 00:00")}\)/
    assert_tag :tag => 'div', :attributes => { :id => 'errorExplanation' },
                              :content => /Please reload the page/
  end

end



