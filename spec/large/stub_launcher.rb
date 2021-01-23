# frozen_string_literal: true

require_root 'app_launcher/al_base.rb'
require_root 'app_launcher/al_task.rb'
require_root 'app_launcher/al_socket.rb'
require_root 'app_launcher/al_reciever.rb'
require_root 'app_launcher/directory_manager/directory_manager.rb'
require_root 'app_launcher/al_all_tasks.rb'

class StubLauncher
  include ALBase

  def initialize
    @iwr, @iww = IO.pipe
    @irr, @irw = IO.pipe
  end

  def writer
    @iww
  end

  def reader
    @irr
  end

  def main
    update_verbose(1)
    update_validate true
    # socket = ALSocket.new(STDIN, STDOUT)
    socket = ALSocket.new(@iwr, @irw)

    directory_manager = DirectoryManager.new
    reciever = ALReciever.new(socket)

    reciever.handle do |json_line, reporter, local_storage|
      # NOTE: ノンブロッキングで書く必要がある。TaskStoreがかなり怪しいが
      # ノンブロッキングで書くか、thread + chdir禁止か。forkはメモリを簡単に共有出来ないのでNG
      case json_line['method']
      when 'setupbox'
        task = ALTaskSetupBox.new directory_manager
        task.action(json_line, reporter, local_storage)
      when 'cleanupbox'
        task = ALTaskCleanupBox.new directory_manager
        task.action(json_line, reporter, local_storage)
      when 'store'
        task = ALTaskStore.new directory_manager
        task.action(json_line, reporter, local_storage)
      when 'exec'
        task = ALTaskExec.new directory_manager
        task.action(json_line, reporter, local_storage)
      when 'kill'
        task = ALTaskKill.new
        task.action(json_line, reporter, local_storage)
      else
        reporter.report({ success: false, error: 'unknown method' })
      end
    end
  end

  def close
    [@iwr, @iww, @irr, @irw].each(&:close)
  end
end
