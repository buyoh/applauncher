# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/executor'
require_relative 'al_task'

class ALTaskCleanupBox
  include ALTask

  def initialize(directory_manager)
    @directory_manager = directory_manager
  end

  def validate_param(param, _local_storage)
    param = param.clone
    param.delete 'method'
    abort 'ALTaskCleanupBox: validation failed: box' if param['box'].nil?
    param.delete 'box'
    abort 'ALTaskExec: validation failed: extra values' unless param.empty?
  end

  def action(param, reporter, local_storage)
    validate_param param, local_storage if validation_enabled?
    user_id = local_storage[:user_id_str]
    box = param['box']
    if box.nil?
      report_failed reporter, 'param invalid'
      return nil
    end

    if @directory_manager.user_exists?(user_id) && @directory_manager.box_exists?(user_id, box)
      @directory_manager.delete_box(user_id, box)
    end

    reporter.report({ success: true })
    nil
  end
end
