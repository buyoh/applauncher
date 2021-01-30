# frozen_string_literal: true

require_relative '../../lib/executor'
require_relative 'al_task'

class ALTaskKill
  include ALTask

  def initialize(exec_task_id)
    @exec_task_id = exec_task_id
  end

  def self.from_json(param)
    exec_task_id = param['taskid']
    return nil if !exec_task_id.nil? && !exec_task_id.is_a?(String)

    new(exec_task_id)
  end

  def action(reporter, local_storage, _directory_manager)
    exec_tasks = local_storage[:exec_tasks]
    if !exec_tasks || !exec_tasks[@exec_task_id]
      vlog 'do_kill: no action'
      reporter.report({ success: true, continue: true, result: { accepted: false } })
      return nil
    end

    pid = exec_tasks[@exec_task_id]
    Executor.kill pid
    vlog "do_kill: kill pid=#{pid}"
    reporter.report({ success: true, continue: true, result: { accepted: true } })
  end
end
