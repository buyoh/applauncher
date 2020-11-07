# frozen_string_literal: true

require_relative 'al_base'
require_relative 'al_local_storage_manager'

class ALReciever
  include ALBase

  def initialize(launcher_socket)
    super()
    @socket = launcher_socket
    @local_storage_manager = ALLocalStorageManager.new
  end

  class Reporter
    include ALBase
    def initialize(socket, id)
      @socket = socket
      @id = id
    end

    def report(result)
      @socket.responce result.merge({ id: @id })
    end
  end

  def handle(&callback)
    while (raw_line = @socket.gets)
      # note: dont forget "\n"
      # note: block each line
      raw_line = raw_line.chomp
      json_line = nil
      begin
        json_line = JSON.parse(raw_line)
      rescue JSON::JSONError => e
        vlog e
        responce({ success: false, error: 'json parse error' })
      end
      next if json_line.nil?

      # json.idを失わないようにALRecieverで管理する
      # ALRecieverの重要な役割のひとつ
      id = json_line['id'] # task-unique

      # クエリに対してレスポンスを関連付けるための識別子 todo: rename 'request_id'
      # 各クエリについてユニークな値を指定するべき
      # launcher の実装としては使わないが、必要である。
      _req_id = id['request_id']
      # none
      # _user_id = id['user_id']
      json_line.delete 'id'

      # user_id による分類は未使用
      user_id_str = 'singleton_user'

      ls = @local_storage_manager[user_id_str]
      ls[:user_id_str] = user_id_str
      callback.call(json_line, Reporter.new(@socket, id), ls)
    end
  end
end
