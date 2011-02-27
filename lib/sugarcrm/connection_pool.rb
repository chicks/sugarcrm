require 'monitor'

module SugarCRM; class ConnectionPool
  def initialize(session, config={})
    @session = session
    
    # The cache of reserved connections mapped to threads
    @reserved_connections = {}
    
    # The mutex used to synchronize pool access
    @connection_mutex = Monitor.new
    @queue = @connection_mutex.new_cond
    @timeout = config[:wait_timeout] || 5
    
    # default max pool size to 5
    @size = (config[:pool] && config[:pool].to_i) || 5
    
    @connections = []
    @checked_out = []
  end
  
  # If a connection already exists yield it to the block. If no connection
  # exists checkout a connection, yield it to the block, and checkin the
  # connection when finished.
  def with_connection
    connection_id = current_connection_id
    fresh_connection = true unless @reserved_connections[connection_id]
    yield connection
  ensure
    release_connection(connection_id) if fresh_connection
  end
  
  # Retrieve the connection associated with the current thread, or call
  # #checkout to obtain one if necessary.
  #
  # #connection can be called any number of times; the connection is
  # held in a hash keyed by the thread id.
  def connection
    @reserved_connections[current_connection_id] ||= checkout
  end
  
  # Check-out a sugarcrm connection from the pool, indicating that you want
  # to use it. You should call #checkin when you no longer need this.
  #
  # This is done by either returning an existing connection, or by creating
  # a new connection. If the maximum number of connections for this pool has
  # already been reached, but the pool is empty (i.e. they're all being used),
  # then this method will wait until a thread has checked in a connection.
  # The wait time is bounded however: if no connection can be checked out
  # within the timeout specified for this pool, then a ConnectionTimeoutError
  # exception will be raised.
  def checkout
    # Checkout an available connection
    @connection_mutex.synchronize do
      loop do
        conn = if @checked_out.size < @connections.size
                  checkout_existing_connection
                elsif @connections.size < @size
                  checkout_new_connection
                end
        return conn if conn

        @queue.wait(@timeout)

        if(@checked_out.size < @connections.size)
          next
        else
          clear_stale_cached_connections!
          if @size == @checked_out.size
            raise SugarCRM::ConnectionTimeoutError, "could not obtain a sugarcrm connection#{" within #{@timeout} seconds" if @timeout}. The max pool size is currently #{@size}; consider increasing it."
          end
        end

      end
    end
  end
  
  # Check-in a sugarcrm connection back into the pool, indicating that you
  # no longer need this connection.
  def checkin(conn)
    @connection_mutex.synchronize do
      @checked_out.delete conn
      @queue.signal
    end
  end
  
  # Return any checked-out connections back to the pool by threads that
  # are no longer alive.
  def clear_stale_cached_connections!
    keys = @reserved_connections.keys - Thread.list.find_all { |t|
      t.alive?
    }.map { |thread| thread.object_id }
    keys.each do |key|
      checkin @reserved_connections[key]
      @reserved_connections.delete(key)
    end
  end
  
  private
  def new_connection
    Connection.new(@session.config[:base_url], @session.config[:username], @session.config[:password])
  end
  
  def checkout_new_connection
    c = new_connection
    @connections << c
    checkout_connection(c)
  end

  def checkout_existing_connection
    c = (@connections - @checked_out).first
    checkout_connection(c)
  end
  
  def checkout_connection(c)
    @checked_out << c
    c
  end
  
  def current_connection_id #:nodoc:
    Thread.current.object_id
  end
end; end