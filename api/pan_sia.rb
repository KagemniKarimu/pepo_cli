# frozen_string_literal: true

require 'httparty'

# Globally Accessible Handler for PanSia / Keops.cc API calls
module PanSia
  include HTTParty
  base_uri 'https://keops.cc/dbs/'
  def self.revenue_30_day
    get('/pansia_revenue.json').parsed_response.first.reject { |key| key == 'time' }
  end

  def self.all_networks_info
    get('/pansia_current.json').parsed_response
  end

  def self.total_network_storage
    store_sum = 0
    get('/pansia_current.json').parsed_response.each { |network| store_sum += network['usedstorage'] }
    store_sum
  end

  def self.total_network_difficulty
    diff_sum = 0
    get('/pansia_current.json').parsed_response.each { |network| diff_sum += network['difficulty'] }
    diff_sum
  end

  def self.total_network_hashrate
    hash_sum = 0
    get('/pansia_current.json').parsed_response.each { |network| hash_sum += network['hashrate'] }
    hash_sum
  end
end
