# encoding: UTF-8
require 'spec_helper'

describe Reviewer, type: :model do
  before(:each) do
    EmailNotifications.stubs(:reviewer_invitation).returns(stub(deliver_now: true))
    # TODO: Improve outcome and conference usage
    @conference = FactoryGirl.create(:conference)
    Conference.stubs(:current).returns(@conference)
    @track = FactoryGirl.create(:track, conference: @conference)
    @audience_level = FactoryGirl.create(:audience_level, conference: @conference)
  end

  it_should_trim_attributes Reviewer, :user_username

  context "validations" do
    it { should validate_presence_of :conference_id }

    context "uniqueness" do
      before { FactoryGirl.create(:reviewer, conference: @conference) }
      it { should validate_uniqueness_of(:user_id).scoped_to(:conference_id) }
    end

    should_validate_existence_of :conference, :user

    it "should validate that at least 1 preference was accepted" do
      reviewer = FactoryGirl.create(:reviewer, conference: @conference)
      reviewer.preferences.build(accepted: false)
      expect(reviewer.accept).to be false
      expect(reviewer.errors[:base]).to include(I18n.t("activerecord.errors.models.reviewer.preferences"))
    end

    it "should validate that reviewer agreement was accepted" do
      reviewer = FactoryGirl.create(:reviewer, reviewer_agreement: false, conference: @conference)
      reviewer.preferences.build(accepted: true, track_id: 1, audience_level_id: 1)
      expect(reviewer.accept).to be false
      expect(reviewer.errors[:reviewer_agreement]).to include(I18n.t("errors.messages.accepted"))
    end

    it "should copy user errors to user_username" do
      reviewer = FactoryGirl.create(:reviewer, conference: @conference)
      new_reviewer = FactoryGirl.build(:reviewer, user: reviewer.user, conference: reviewer.conference)
      expect(new_reviewer).to_not be_valid
      expect(new_reviewer.errors[:user_username]).to include(I18n.t("activerecord.errors.messages.taken"))
    end

    context "user" do
      before(:each) do
        @reviewer = FactoryGirl.create(:reviewer, conference: @conference)
      end

      it "should be a valid user" do
        @reviewer.user_username = 'invalid_username'
        expect(@reviewer).to_not be_valid
        expect(@reviewer.errors[:user_username]).to include(I18n.t("activerecord.errors.messages.existence"))
      end
    end
  end

  context "associations" do
    it { should belong_to :user }
    it { should belong_to :conference }
    it { should have_many(:preferences).dependent(:destroy) }
    it { should have_many(:accepted_preferences).class_name('Preference') }

    it { should accept_nested_attributes_for :preferences }

    context "reviewer username" do
      subject { FactoryGirl.build(:reviewer, conference: @conference) }
      it_should_behave_like "virtual username attribute", :user
    end

    context 'inferred' do
      before(:each) do
        @reviewer = FactoryGirl.build(:reviewer, conference: @conference)
      end
      it 'should find early reviews for this reviewer' do
        @reviewer.user.expects(:early_reviews).returns(Review)
        Review.expects(:for_conference).with(@conference).returns(:result)

        expect(@reviewer.early_reviews).to eq(:result)
      end
      it 'should find final reviews for this reviewer' do
        @reviewer.user.expects(:final_reviews).returns(Review)
        Review.expects(:for_conference).with(@conference).returns(:result)

        expect(@reviewer.final_reviews).to eq(:result)
      end
      it 'should find all reviews for this reviewer' do
        @reviewer.user.expects(:reviews).returns(Review)
        Review.expects(:for_conference).with(@conference).returns(:result)

        expect(@reviewer.reviews).to eq(:result)
      end
    end
  end

  context "state machine" do
    before(:each) do
      @reviewer = FactoryGirl.build(:reviewer, conference: @conference)
    end

    context "State: created" do
      it "should be the initial state" do
        expect(@reviewer).to be_created
      end

      it "should allow invite" do
        expect(@reviewer.invite).to be true
        expect(@reviewer).to_not be_created
        expect(@reviewer).to be_invited
      end

      it "should not allow accept" do
        expect(@reviewer.accept).to be false
      end

      it "should not allow reject" do
        expect(@reviewer.reject).to be false
      end
    end

    context "Event: invite" do
      it "should send invitation email" do
        EmailNotifications.expects(:reviewer_invitation).with(@reviewer).returns(mock(deliver_now: true))
        @reviewer.invite
      end
    end

    context "State: invited" do
      before(:each) do
        @reviewer.invite
        expect(@reviewer).to be_invited
      end

      it "should allow inviting again" do
        expect(@reviewer.invite).to be true
        expect(@reviewer).to be_invited
      end

      it "should allow accepting" do
        # TODO: review this
        @reviewer.preferences.build(accepted: true, track_id: @track.id, audience_level_id: @audience_level.id)
        expect(@reviewer.accept).to be true
        expect(@reviewer).to_not be_invited
        expect(@reviewer).to be_accepted
      end

      it "should allow rejecting" do
        expect(@reviewer.reject).to be true
        expect(@reviewer).to_not be_invited
        expect(@reviewer).to be_rejected
      end
    end

    context "State: accepted" do
      before(:each) do
        @reviewer.invite
        # TODO: review this
        @reviewer.preferences.build(accepted: true, track_id: @track.id, audience_level_id: @audience_level.id)
        @reviewer.accept
        expect(@reviewer).to be_accepted
      end

      it "should not allow invite" do
        expect(@reviewer.invite).to be false
      end

      it "should not allow accepting" do
        expect(@reviewer.accept).to be false
      end

      it "should not allow rejecting" do
        expect(@reviewer.reject).to be false
      end
    end

    context "State: rejected" do
      before(:each) do
        @reviewer.invite
        @reviewer.reject
        expect(@reviewer).to be_rejected
      end

      it "should not allow invite" do
        expect(@reviewer.invite).to be false
      end

      it "should not allow accepting" do
        expect(@reviewer.accept).to be false
      end

      it "should not allow rejecting" do
        expect(@reviewer.reject).to be false
      end
    end
  end

  context "callbacks" do
    it "should invite after created" do
      reviewer = FactoryGirl.build(:reviewer)
      reviewer.save
      expect(reviewer).to be_invited
    end

    it "should not invite if validation failed" do
      reviewer = FactoryGirl.build(:reviewer, user_id: nil)
      reviewer.save
      expect(reviewer).to_not be_invited
    end
  end

  shared_examples_for "reviewer role" do
    it "should make given user reviewer role after invitation accepted" do
      reviewer = FactoryGirl.create(:reviewer, user: subject, conference: @conference)
      reviewer.invite
      expect(subject).to_not be_reviewer
    end

    it "should not remove organizer role if more reviewers for user are available" do
      old_conference = FactoryGirl.create(:conference, year: 1)
      old_track = FactoryGirl.create(:track, conference: old_conference)
      old_audience_level = FactoryGirl.create(:audience_level, conference: old_conference)
      accepted_reviewer_for(subject, old_conference, old_track, old_audience_level)

      reviewer = accepted_reviewer_for(subject, @conference, @track, @audience_level)
      expect(subject).to be_reviewer
      reviewer.destroy
      expect(subject).to_not be_reviewer
      # TODO: Remove current_conference from reviewer check.
      # Stupid user class redefines the roles to user current conference
      expect(subject).to be_reviewer_without_conference
      expect(subject.reload).to_not be_reviewer
      expect(subject.reload).to be_reviewer_without_conference
    end

    it "should remove organizer role after last reviewer for user is destroyed" do
      reviewer = accepted_reviewer_for(subject, @conference, @track, @audience_level)

      expect(subject).to be_reviewer
      reviewer.destroy
      expect(subject).to_not be_reviewer
      expect(subject.reload).to_not be_reviewer
    end
  end

  context "managing reviewer role for complete user" do
    subject { FactoryGirl.create(:user) }
    it_should_behave_like "reviewer role"
  end

  context "managing reviewer role for simple user" do
    subject { FactoryGirl.create(:simple_user) }
    it_should_behave_like "reviewer role"
  end

  context "checking if able to review a track" do
    before(:each) do
      @conference = FactoryGirl.create(:conference)
      @track = FactoryGirl.create(:track, conference: @conference)
      @organizer = FactoryGirl.create(:organizer, track: @track, conference: @conference)
      @reviewer = FactoryGirl.create(:reviewer, user: @organizer.user, conference: @conference)
    end

    it "can review track when not organizer" do
      expect(@reviewer).to be_can_review(FactoryGirl.create(:track, conference: @conference))
    end

    it "can not review track when organizer on the same conference" do
      expect(@reviewer).to_not be_can_review(@organizer.track)
    end

    it "can review track when organizer for different conference" do
      other_conference = FactoryGirl.create(:conference)
      reviewer = FactoryGirl.create(:reviewer, user: @organizer.user, conference: other_conference)
      expect(reviewer).to be_can_review(@organizer.track)
    end
  end

  context 'display name rules' do
    before :each do
      @user = FactoryGirl.build(:user, first_name: 'Raphael', last_name: 'Molesim', default_locale: 'en')
    end
    context 'for signing reviewer' do
      subject { FactoryGirl.build(:reviewer, user: @user, sign_reviews: true) }
      it 'should display reviewer name' do
        expect(subject.display_name).to eq('Raphael Molesim')
      end
    end
    context 'for non signing reviewer' do
      subject { FactoryGirl.build(:reviewer, user: @user, sign_reviews: false) }
      it 'should display generic reviewer title' do
        expect(subject.display_name).to eq(I18n.t('formtastic.labels.reviewer.user_id'))
      end
      it 'should display generic reviewer title with index if passed' do
        expect(subject.display_name(1)).to eq("#{I18n.t('formtastic.labels.reviewer.user_id')} 1")
      end
    end
  end

  def accepted_reviewer_for(user, conference, track, audience_level)
    FactoryGirl.create(:reviewer, user: user, conference: conference).
        tap {|r| r.invite}.
        tap {|r| r.preferences.build(accepted: true, track_id: track.id, audience_level_id: audience_level.id)}.
        tap {|r| r.accept}
  end
end
