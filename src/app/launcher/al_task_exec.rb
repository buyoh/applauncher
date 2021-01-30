# frozen_string_literal: true

require 'tempfile'

require_relative '../../lib/executor'
require_relative 'al_task'

class ALTaskExec
  include ALTask

  def initialize(box, command, arguments, stdin, fileio, timeout) # rubocop:disable Metrics/ParameterLists
    @box = box
    @command = command
    @arguments = arguments
    @stdin = stdin
    @fileio = fileio
    @timeout = timeout
  end

  def self.from_json(param)
    box = param['box']
    cmd = param['cmd']
    args = param['args'] || []
    stdin = param['stdin'] || ''
    fileio = param['fileio'] || false
    timeout = param['timeout'] || 10
    return nil unless (box.is_a? String) && !box.empty?
    return nil unless (cmd.is_a? String) && !cmd.empty?
    return nil unless args.is_a? Array
    return nil unless stdin.is_a? String
    return nil unless (fileio.is_a? TrueClass) || (fileio.is_a? FalseClass)
    return nil unless timeout.is_a? Integer # TODO: assert range

    new(box, cmd, args, stdin, fileio, timeout)
  end

  def action(reporter, local_storage, directory_manager)
    if @box.nil? || !directory_manager.box_exists?(local_storage[:user_id_str], @box)
      report_failed reporter, 'uninitialized box'
      return nil
    end

    if @command.nil? || @command.empty?
      report_failed reporter, 'invalid arguments'
      return nil
    end

    exec_chdir = directory_manager.get_boxdir(local_storage[:user_id_str], @box)

    if @fileio
      in_file = Tempfile.open('in', exec_chdir, mode: File::Constants::RDWR)
      out_file = Tempfile.open('in', exec_chdir, mode: File::Constants::RDWR)
      err_file = Tempfile.open('in', exec_chdir, mode: File::Constants::RDWR)
      in_file.print @stdin
      in_file.close
      in_file.open
      exe = Executor.new(
        cmd: @command,
        args: @arguments,
        stdin: in_file, stdout: out_file, stderr: err_file,
        chdir: exec_chdir,
        timeout: @timeout
      )
    else
      in_r, in_w = IO.pipe
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      in_w.print @stdin
      in_w.close
      exe = Executor.new(
        cmd: @command,
        args: @arguments,
        stdin: in_r, stdout: out_w, stderr: err_w,
        chdir: exec_chdir,
        timeout: @timeout
      )
    end

    pid, = exe.execute(true) do |status, time|
      # finish
      # vlog "do_exec: finish pid=#{pid}"
      if @fileio
        in_file.close
        out_file.close
        err_file.close
        out_file.open
        output = out_file.read
        out_file.close
        err_file.open
        errlog = err_file.read
        err_file.close
        in_file.delete
        out_file.delete
        err_file.delete
      else
        output = out_r.read
        errlog = err_r.read
        out_r.close
        err_r.close
      end
      reporter.report(
        { success: true,
          result: { exited: true, exitstatus: status&.exitstatus, time: time,
                    out: output, err: errlog } }
      )
      local_storage.delete :pid
    end
    # vlog "do_exec: start pid=#{pid}"
    reporter.report(
      { success: true, continue: true, taskid: 1,
        result: { exited: false } }
    )
    local_storage[:pid] = pid
    nil
  end
end
