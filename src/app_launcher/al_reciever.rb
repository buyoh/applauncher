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

      # ビルド→実行→KILL等のワークフローで共通となる識別子
      # local_storageはワークフロー単位で分離されるので、このワークフローが異なると、ボックスにアクセス出来ない
      # つまり、実質ユーザ・ボックスだね　要らないね
      job_id = id['jid'] # (client)ビルド→実行のワークフローで共通　KILLも共通

      # ユーザID。1人のユーザが複数のボックスにアクセスできるようにする・別のユーザがアクセス出来ないようにするためだったが消す予定
      socket_id = id['sid'] # (server)ページ単位で共通

      # クエリに対してレスポンスを関連付けるための識別子 todo: rename 'requestid'
      # 各クエリについてユニークな値を指定するべき
      # launcher の実装としては使わないが、必要である。
      _lcm_id = id['lcmid'] # (server)ユーザのアクション単位で共通　KILLは別のアクションなのでlcmidは異なる(launcher callback id)
      json_line.delete 'id'

      # note: job_idは純粋な連番なので、複数ページを同時に開くだけで衝突する TODO: このworkaroundはlauncherの役目じゃない
      # socket_idを結合してこれを回避する
      job_id_str = (JSON.generate(job_id) + '_' + JSON.generate(socket_id)).hash.to_s(36)
      user_id_str = JSON.generate(socket_id).hash.to_s(36)
      # TODO: 削除しないと貯まる まじで
      ls = @local_storage_manager[job_id_str]
      ls[:user_id_str] = user_id_str
      callback.call(json_line, Reporter.new(@socket, id), ls)
    end
  end
end
