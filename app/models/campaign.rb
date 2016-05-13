class Campaign < ActiveRecord::Base
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  validates :name, presence: true
  validates :stamp_number, presence: true, inclusion: { in: [6,8,10,12] }


end
