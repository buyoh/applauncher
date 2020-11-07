# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/executor'
require_relative 'al_task'

class ALTaskSetupBox
  include ALTask

  def initialize(directory_manager)
    @directory_manager = directory_manager
  end

  def validate_param(param, _local_storage)
    param = param.clone
    param.delete 'method'
  end

  def action(param, reporter, local_storage)
    validate_param param, local_storage if validation_enabled?
    user_id = local_storage[:user_id_str]

    @directory_manager.install_user(user_id) unless @directory_manager.user_exists?(user_id)
    boxkey = @directory_manager.new_box(user_id)

    reporter.report({ success: true, result: { box: boxkey } })
    nil
  end
end
