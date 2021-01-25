# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/executor'
require_relative 'al_task'

ALTaskSetupBox = Struct.new('ALTaskSetupBox') do
  include ALTask

  def self.from_json(_param)
    new
  end

  def action(reporter, local_storage, directory_manager)
    user_id = local_storage[:user_id_str]

    directory_manager.install_user(user_id) unless directory_manager.user_exists?(user_id)
    boxkey = directory_manager.new_box(user_id)

    reporter.report({ success: true, result: { box: boxkey } })
    nil
  end
end
