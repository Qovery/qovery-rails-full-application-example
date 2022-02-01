class Task < ApplicationRecord
  validates :label, presence: true

  enum status: [:created, :processing, :done], _default: :created

  after_create :process_task

  private

  def process_task
    ProcessTaskJob.perform_later(self.id)
  end
end
