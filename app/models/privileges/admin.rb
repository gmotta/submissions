# encoding: utf-8
class Privileges::Admin < Privileges::Base
  def privileges
    can(:manage, :all)
    # Revoke these actions, to use the ones appropriate for each role, below
    cannot(:create, Session)
    cannot([:create, :update], ReviewDecision)
    cannot(:create, Review)
    cannot(:create, FinalReview)
    cannot(:create, EarlyReview)
    cannot(:manage, 'confirm_sessions')
    cannot(:manage, 'withdraw_sessions')
    cannot(:read, 'organizer_sessions')
    cannot(:read, 'organizer_reports')
    cannot(:read, 'accepted_sessions')
    cannot(:read, 'reviews_listing')
    cannot(:read, 'reviewer_sessions')
    cannot(:manage, Vote)
    cannot(:manage, ::Reviewer)
  end
end