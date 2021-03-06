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

class MessagesController < ApplicationController
  menu_item :boards
  default_search_scope :messages
  model_object Message, :scope => Board
  before_filter :find_object_and_scope
  before_filter :authorize, :except => [:preview, :edit, :update, :destroy]

  include AttachmentsHelper

  REPLIES_PER_PAGE = 25 unless const_defined?(:REPLIES_PER_PAGE)

  # Show a topic and its replies
  def show
    @topic = @message.root

    page = params[:page]
    # Find the page of the requested reply
    if params[:r] && page.nil?
      offset = @topic.children.count(:conditions => ["#{Message.table_name}.id < ?", params[:r].to_i])
      page = 1 + offset / REPLIES_PER_PAGE
    end

    @reply_count = @topic.children.count
    @reply_pages = Paginator.new self, @reply_count, REPLIES_PER_PAGE, page
    @replies =  @topic.children.find(:all, :include => [:author, :attachments, {:board => :project}],
                                           :order => "#{Message.table_name}.created_on ASC",
                                           :limit => @reply_pages.items_per_page,
                                           :offset => @reply_pages.current.offset)

    @reply = Message.new(:subject => "RE: #{@message.subject}")
    render :action => "show", :layout => false if request.xhr?
  end

  # new topic
  def new
    @message = Message.new.tap do |m|
      m.author = User.current
      m.board = @board
    end
  end

  # Create a new topic
  def create
    @message = Message.new.tap do |m|
      m.author = User.current
      m.board = @board
    end
    @message.safe_attributes = params[:message]
    if @message.save
      call_hook(:controller_messages_new_after_save, { :params => params, :message => @message})
      attachments = Attachment.attach_files(@message, params[:attachments])
      render_attachment_warning_if_needed(@message)
      redirect_to topic_path(@message)
    else
      render :action => 'new'
    end
  end

  # Reply to a topic
  def reply
    @topic = @message.root

    @reply = Message.new
    @reply.author = User.current
    @reply.board = @board
    @reply.safe_attributes = params[:reply]

    @topic.children << @reply
    if !@reply.new_record?
      call_hook(:controller_messages_reply_after_save, { :params => params, :message => @reply})
      attachments = Attachment.attach_files(@reply, params[:attachments])
      render_attachment_warning_if_needed(@reply)
    end
    redirect_to topic_path(@topic, :r => @reply)
  end

  # Edit a message
  def edit
    (render_403; return false) unless @message.editable_by?(User.current)
    @message.safe_attributes = params[:message]
  end

  # Edit a message
  def update
    (render_403; return false) unless @message.editable_by?(User.current)
    @message.safe_attributes = params[:message]
    if @message.save
      attachments = Attachment.attach_files(@message, params[:attachments])
      render_attachment_warning_if_needed(@message)
      flash[:notice] = l(:notice_successful_update)
      @message.reload
      redirect_to topic_path(@message.root, :r => (@message.parent_id && @message.id))
    else
      render :action => 'edit'
    end
  end

  # Delete a messages
  def destroy
    (render_403; return false) unless @message.destroyable_by?(User.current)
    @message.destroy
    redirect_to @message.parent.nil? ?
      { :controller => '/boards', :action => 'show', :project_id => @project, :id => @board } :
      { :action => 'show', :id => @message.parent, :r => @message }
  end

  def quote
    user = @message.author
    text = @message.content
    subject = @message.subject.gsub('"', '\"')
    subject = "RE: #{subject}" unless subject.starts_with?('RE:')
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\\n> "
    content << text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]').gsub('"', '\"').gsub(/(\r?\n|\r\n?)/, "\\n> ") + "\\n\\n"
    render(:update) { |page|
      page << "$('message_subject').value = \"#{subject}\";"
      page.<< "$('message_content').value = \"#{content}\";"
      page.show 'reply'
      page << "Form.Element.focus('message_content');"
      page << "Element.scrollTo('reply');"
      page << "$('message_content').scrollTop = $('message_content').scrollHeight - $('message_content').clientHeight;"
    }
  end

  def preview
    message = @board.messages.find_by_id(params[:id])
    @attachements = message.attachments if message
    @text = (params[:message] || params[:reply])[:content]
    render :partial => 'common/preview'
  end
end
