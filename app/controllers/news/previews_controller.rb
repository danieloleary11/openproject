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

class News::PreviewsController < ApplicationController
  before_filter :find_model_object_and_project

  model_object News

  def create
    @text = news_params[:description]
    render :partial => 'common/preview'
  end

private

  def news_params
    params.fetch(:news, {})
  end
end
