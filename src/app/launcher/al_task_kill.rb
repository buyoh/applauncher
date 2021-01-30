# frozen_string_literal: true

require_relative '../../lib/executor'
require_relative 'al_task'

class ALTaskKill
  include ALTask

  def self.from_json(_param)
    new
  end

  def action(reporter, local_storage, _directory_manager)
    if !local_storage.key?(:pid) || local_storage[:pid].nil?
      vlog 'do_kill: no action'
      reporter.report({ success: true, continue: true, result: { accepted: false } })
      return nil
    end
    pid = local_storage[:pid]
    Executor.kill pid
    vlog "do_kill: kill pid=#{pid}"
    reporter.report({ success: true, continue: true, result: { accepted: true } })
  end
end
