require "pg"

module Sparrow
  DB = PG.connect("postgres://postgres:password@127.0.0.1:5433/sparrow")
  DB.exec %{
    CREATE TABLE IF NOT EXISTS threads (
      id        VARCHAR(16),
      author    VARCHAR(16),
      author_ip VARCHAR(64),
      content   VARCHAR(512),
      parent    VARCHAR(16)
    )
  }
  DB.exec %{
    CREATE TABLE IF NOT EXISTS category (
      name  VARCHAR(16),
      admin VARCHAR(256)
    )
  }
  DB.exec %{
    CREATE TABLE IF NOT EXISTS users (
      id  VARCHAR(16),
      key CHAR(64)
    )
  }
end
