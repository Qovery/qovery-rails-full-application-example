class ProcessTaskJob < ApplicationJob
  queue_as :default
  
  def perform(task_id)
    task = Task.find(task_id)
    puts "Starting processing task"
    task.update_attribute(:status, :processing)
    sleep rand(5..20)
    task.update_attribute(:status, :done)
    puts "Task processed"
  end
end
