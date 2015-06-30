require "pg"

module Sparrow
  begin
    @@uri = ENV["SP_URI"]
  rescue
    puts "请设置环境变量 SP_URI 为 PostgreSQL 数据库 URI"
    exit(2)
  end

  DB = PG.connect(@@uri)

  def self.init_db()
    DB.exec %{
      CREATE TABLE IF NOT EXISTS threads (
        id        VARCHAR(16),
        author    VARCHAR(16),
        author_ip VARCHAR(64),
        content   VARCHAR(512),
        parent    VARCHAR(16),
        time      BIGINT,
        modified  BIGINT,
        sage      BOOLEAN
      )
    }
    DB.exec %{COMMENT ON TABLE  threads           IS '帖子列表'}
    DB.exec %{COMMENT ON COLUMN threads.id        IS '自身ID'}
    DB.exec %{COMMENT ON COLUMN threads.author    IS '作者ID'}
    DB.exec %{COMMENT ON COLUMN threads.author_ip IS '作者IP'}
    DB.exec %{COMMENT ON COLUMN threads.content   IS '内容'}
    DB.exec %{COMMENT ON COLUMN threads.parent    IS '分类or串ID'}
    DB.exec %{COMMENT ON COLUMN threads.time      IS '创建时间'}
    DB.exec %{COMMENT ON COLUMN threads.modified  IS '最后修改时间'}
    DB.exec %{COMMENT ON COLUMN threads.sage      IS '是否下沉'}

    DB.exec %{
      CREATE TABLE IF NOT EXISTS categories (
        id    VARCHAR(16),
        name  VARCHAR(32),
        admin VARCHAR(256),
        rule  VARCHAR(1024)
      )
    }
    DB.exec %{COMMENT ON TABLE  categories       IS '分类列表'}
    DB.exec %{COMMENT ON COLUMN categories.id    IS '分类ID'}
    DB.exec %{COMMENT ON COLUMN categories.name  IS '分类名称'}
    DB.exec %{COMMENT ON COLUMN categories.admin IS '版主，空格分割'}
    DB.exec %{COMMENT ON COLUMN categories.rule  IS '版规'}

    DB.exec %{
      CREATE TABLE IF NOT EXISTS report (
        author   VARCHAR(16),
        target   VARCHAR(16),
        category VARCHAR(16),
        reason   VARCHAR(512),
        close    BOOLEAN,
        time     BIGINT
      )
    }
    DB.exec %{COMMENT ON TABLE  report          IS '举报列表'}
    DB.exec %{COMMENT ON COLUMN report.author   IS '举报者'}
    DB.exec %{COMMENT ON COLUMN report.target   IS '帖子ID'}
    DB.exec %{COMMENT ON COLUMN report.category IS '帖子所属分类'}
    DB.exec %{COMMENT ON COLUMN report.reason   IS '举报原因'}
    DB.exec %{COMMENT ON COLUMN report.close    IS '是否已处理'}
    DB.exec %{COMMENT ON COLUMN report.time     IS '举报时间'}

    DB.exec %{
      CREATE TABLE IF NOT EXISTS log (
        handler   VARCHAR(16),
        target    VARCHAR(16),
        category  VARCHAR(16),
        operation VARCHAR(16),
        reason    VARCHAR(512),
        time      BIGINT
      )
    }
    DB.exec %{COMMENT ON TABLE  log           IS '管理记录'}
    DB.exec %{COMMENT ON COLUMN log.handler   IS '处理者'}
    DB.exec %{COMMENT ON COLUMN log.target    IS '帖子ID'}
    DB.exec %{COMMENT ON COLUMN log.category  IS '帖子所属分类'}
    DB.exec %{COMMENT ON COLUMN log.operation IS '处理方法'}
    DB.exec %{COMMENT ON COLUMN log.reason    IS '处理原因'}
    DB.exec %{COMMENT ON COLUMN log.time      IS '处理时间'}

    DB.exec %{
      CREATE TABLE IF NOT EXISTS users (
        id  VARCHAR(16),
        key CHAR(128)
      )
    }
    DB.exec %{COMMENT ON TABLE  users     IS '用户列表'}
    DB.exec %{COMMENT ON COLUMN users.id  IS '用户ID'}
    DB.exec %{COMMENT ON COLUMN users.key IS '用户识别key'}

    DB.exec %{
      CREATE TABLE IF NOT EXISTS last_id (
        name VARCHAR(16),
        id   VARCHAR(16)
      )
    }
    DB.exec %{COMMENT ON TABLE  last_id      IS '记录最后一个ID'}
    DB.exec %{COMMENT ON COLUMN last_id.name IS '名称'}
    DB.exec %{COMMENT ON COLUMN last_id.id   IS 'ID'}
    result = DB.exec({String}, "SELECT id FROM last_id WHERE name='user'")
    if result.rows.length == 0
      DB.exec %{INSERT INTO last_id VALUES ('user', '0')}
    end
    result = DB.exec({String}, "SELECT id FROM last_id WHERE name='threads'")
    if result.rows.length == 0
      DB.exec %{INSERT INTO last_id VALUES ('threads', '0')}
    end
  end
end
