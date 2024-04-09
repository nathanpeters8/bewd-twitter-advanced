class Tweet < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  after_create :notify_via_email

  validates :user, presence: true
  validates :message, presence: true, length: { maximum: 140 }

  private 

  def notify_via_email
    TweetMailer.notify(self).deliver!
  end
end
