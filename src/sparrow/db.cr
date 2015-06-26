require "pg"

module Sparrow
  DB = PG.connect("postgres://postgres:password@127.0.0.1:5433/sparrow")
  DB.exec %{
    CREATE TABLE IF NOT EXISTS threads (
      id        VARCHAR(16),
      author    VARCHAR(16),
      author_ip VARCHAR(64),
      content   VARCHAR(512),
      parent    VARCHAR(16),
      time      BIGINT,
      modified  BIGINT
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

  DB.exec %{
    CREATE TABLE IF NOT EXISTS category (
      name  VARCHAR(16),
      admin VARCHAR(256)
    )
  }
  DB.exec %{COMMENT ON TABLE  category       IS '分类列表'}
  DB.exec %{COMMENT ON COLUMN category.name  IS '分类名称'}
  DB.exec %{COMMENT ON COLUMN category.admin IS '版主，空格分割'}

  DB.exec %{
    CREATE TABLE IF NOT EXISTS report (
      author VARCHAR(16),
      target VARCHAR(16),
      reason VARCHAR(512),
      time   BIGINT
    )
  }
  DB.exec %{COMMENT ON TABLE  report        IS '举报列表'}
  DB.exec %{COMMENT ON COLUMN report.author IS '举报者'}
  DB.exec %{COMMENT ON COLUMN report.target IS '举报帖子ID'}
  DB.exec %{COMMENT ON COLUMN report.reason IS '举报原因'}
  DB.exec %{COMMENT ON COLUMN report.time   IS '举报时间'}

  DB.exec %{
    CREATE TABLE IF NOT EXISTS log (
      handler   VARCHAR(16),
      target    VARCHAR(16),
      operation VARCHAR(16),
      reason    VARCHAR(512),
      time      BIGINT
    )
  }
  DB.exec %{COMMENT ON TABLE  log           IS '管理记录'}
  DB.exec %{COMMENT ON COLUMN log.handler   IS '处理者'}
  DB.exec %{COMMENT ON COLUMN log.target    IS '处理帖子ID'}
  DB.exec %{COMMENT ON COLUMN log.operation IS '处理方法'}
  DB.exec %{COMMENT ON COLUMN log.reason    IS '处理原因'}
  DB.exec %{COMMENT ON COLUMN log.time      IS '处理时间'}

  DB.exec %{
    CREATE TABLE IF NOT EXISTS users (
      id  VARCHAR(16),
      key CHAR(64)
    )
  }
  DB.exec %{COMMENT ON TABLE  users     IS '用户列表'}
  DB.exec %{COMMENT ON COLUMN users.id  IS '用户ID'}
  DB.exec %{COMMENT ON COLUMN users.key IS '用户识别key'}
end
