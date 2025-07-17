class User < ApplicationRecord
  validates :username, presence: true

  validate :unique_username_with_bloom

  private

  def unique_username_with_bloom
    return if username.blank?

    if BLOOM_FILTER.include?(username.downcase)
      if User.where(username: username).exists?
        errors.add(:username, 'is already taken')
      end
    else
      BLOOM_FILTER.add(username.downcase)
    end
  end
end