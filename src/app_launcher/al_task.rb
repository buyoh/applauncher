# frozen_string_literal: true

require_relative '../lib/executor'
require_relative 'al_base'

module ALTask
  include ALBase

  def report_failed(reporter, err)
    reporter.report({ success: false, error: err })
  end
end
