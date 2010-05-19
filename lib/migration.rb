class ActiveREcord::Migrator
  def initialize(direction, migrations_path, target_version = nil)
    Base.establish_connection if !Base.connection
    raise StandardError.new("This database does not yet support migrations") unless Base.connection.supports_migrations?
    Base.connection.initialize_schema_migrations_table
    @direction, @migrations_path, @target_version = direction, migrations_path, target_version
  end
end
