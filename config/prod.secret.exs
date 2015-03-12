use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :media, Media.Endpoint,
  secret_key_base: "QN/Gh+weisA+h3eIRQos7XM4iuMvLfENUmAuLrEG6ddkovNA01zHzMmQgy7DTAHk"

# Configure your database
config :media, Media.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "media_prod"