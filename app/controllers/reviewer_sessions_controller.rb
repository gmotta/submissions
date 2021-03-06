# encoding: UTF-8
class ReviewerSessionsController < ApplicationController
  def index
    @tracks = @conference.tracks
    @audience_levels = @conference.audience_levels
    @session_types = @conference.session_types

    @session_filter = SessionFilter.new(filter_params)
    @sessions = @session_filter.apply(scope_based_on_conference_phase)
  end

  protected

  def scope_based_on_conference_phase
    scope = Session.includes([:track, :session_type, :audience_level])
      .for_reviewer(current_user, @conference).page(params[:page])
    if @conference.in_early_review_phase?
      scope.order('sessions.early_reviews_count ASC')
    elsif @conference.in_final_review_phase?
      scope.order('sessions.final_reviews_count ASC')
    else
      scope.none
    end
  end

  def filter_params
    params.permit(session_filter: [
      :track_id, :session_type_id, :audience_level_id
    ])[:session_filter]
  end
end
