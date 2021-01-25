# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/executor'
require_relative 'al_task'

ALTaskStore = Struct.new('ALTaskStore', :box, :files) do
  include ALTask

  FileData = Struct.new('FileData', :path, :data) do # rubocop:disable Lint/ConstantDefinitionInBlock:
    def self.check_valid_filequery(path)
      !path.nil? && !path.start_with?('/') && !path.include?('..')
    end

    def self.from_json(param)
      path = param['path']
      data = param['data']
      return nil unless (path.is_a? String) && !path.empty?
      return nil unless data.is_a? String
      return nil unless check_valid_filequery(path)

      new(path, data)
    end
  end

  def self.from_json(param)
    box = param['box']
    files = param['files']
    return nil unless box.is_a? String
    return nil unless files.is_a? Array

    files = files.map { |f| FileData.from_json(f) }
    return nil unless files.all?

    new(box, files)
  end

  def action(reporter, local_storage, directory_manager)
    unless directory_manager.box_exists?(local_storage[:user_id_str], box)
      report_failed reporter, 'uninitialized box'
      return nil
    end

    ls_chdir = directory_manager.get_boxdir(local_storage[:user_id_str], box)

    # work
    files.each do |file|
      IO.write(ls_chdir + file.path, file.data)
    end
    reporter.report({ success: true })
    nil
  end
end
