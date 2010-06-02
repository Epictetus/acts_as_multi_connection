class ActiveRecord::MultiConnection < ActiveRecord::Base
  self.abstract_class = true
  alias_method :_orig_connection, :connection
  
  def self.find_by_sql(sql)
    connection_by_sql(sql).select_all(sanitize_sql(sql), "#{name} Load").collect! { |record| instantiate(record) }
  end
  
  def self.connection_by_sql(sql)
    connection_hash = connection_hash_by_sql(sql)
    return connection if connection_hash.nil?
    (connection_handler.connection_pools[connection_hash.to_s] || establish_connection(connection_hash)).connection
  end
  
  def connection
    return _orig_connection if connection_hash.nil?
    (self.class.connection_handler.connection_pools[connection_hash.to_s] || establish_connection(connection_hash)).connection
  end
  
  def establish_connection(spec = nil, name = nil)
    case spec
    when nil
      raise AdapterNotSpecified unless defined? RAILS_ENV
      super.establish_connection
    when ConnectionSpecification
      self.class.connection_handler.establish_connection(name, spec)
    when Symbol, String
      name = spec.to_s
      if configuration = configurations[RAILS_ENV.to_s][:sub.to_s][spec.to_s]
        establish_connection(configuration, name)
      else
        raise AdapterNotSpecified, "#{spec} database is not configured"
      end
    else
      spec = spec.symbolize_keys
      unless spec.key?(:adapter) then raise AdapterNotSpecified, "database configuration does not specify adapter" end
      
      begin
        require 'rubygems'
        gem "activerecord-#{spec[:adapter]}-adapter"
        require "active_record/connection_adapters/#{spec[:adapter]}_adapter"
      rescue LoadError
        begin
          require "active_record/connection_adapters/#{spec[:adapter]}_adapter"
        rescue LoadError
          raise "Please install the #{spec[:adapter]} adapter: `gem install activerecord-#{spec[:adapter]}-adapter` (#{$!})"
        end
      end
      
      adapter_method = "#{spec[:adapter]}_connection"
      if !self.class.respond_to?(adapter_method)
        raise AdapterNotFound, "database configuration specifies nonexistent #{spec[:adapter]} adapter"
      end
      establish_connection(ConnectionSpecification.new(spec, adapter_method), name)
    end
  end
  
  def transaction(&block)
    connection.transaction(&block)
  end
end
  
