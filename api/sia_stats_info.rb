# frozen_string_literal: true

require 'httparty'

# Globally Accessible Handler for SiaStats.info API
module SiaStatsInfo
  include HTTParty

  # HostAPI Endpoints
  @host_uri = 'https://siastats.info:3510/hosts-api'
  def self.active_hosts
    post("#{@host_uri}/allhosts", body: { network: 'sia', list: 'active' })

  end

  def self.all_hosts
    post("#{@host_uri}/allhosts", body: { network: 'sia', list: 'active' })
  end

  def self.get_host_id(pub_key)
    get("#{@host_uri}/get_id/#{pub_key}").parsed_response["id"]
  end

  def self.host_info(host_id)
    get("#{@host_uri}/host/#{host_id}")
  end
  # Navigator API endpoints
  @nav_uri = 'https://siastats.info:3500/navigator-api'

  def self.total_coin_supply
    get("#{@nav_uri}/totalcoins")
    # if i == 0 ; ERROR HANDLE
  end

  def self.most_recent_block
    get("#{@nav_uri}/status").first.fetch('consensusblock')
  end

  def self.recent_tx
    get("#{@nav_uri}/landing")
  end

  # Updated DBs API endpoints
  @dbs_uri = 'https://siastats.info/dbs'
  def self.network_difficulty
    get("#{@dbs_uri}/network_status.json").fetch('difficulty')
  end

  def self.network_block_time
    get("#{@dbs_uri}/miningdb.json").parsed_response.first['blocktime']
  end

  def self.number_online_hosts
    get("#{@dbs_uri}/network_status.json").fetch('online_hosts')
  end

  def self.network_bandwidth_prices
    prices = get("#{@dbs_uri}/bandwidthpricesdb.json").parsed_response.first
    { upload: prices['up'], download: prices['down'] }
  end

  def self.network_storage_price
    get("#{@dbs_uri}/storagepricesdb.json").parsed_response.first['price']
  end

  def self.total_burnt_coins
    get("#{@dbs_uri}/burn.json").parsed_response.first['burnt']
  end
end
