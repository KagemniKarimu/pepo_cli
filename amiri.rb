# frozen_string_literal: true

require './cli'
###########################################
#
## Here are the hooks for various Amri
module Amiri
  def self.configure
    @prompt = $command_instance.prompt
    @style = $command_instance.style
    @filebase_instances = $command_instance.filebase_instances
  end

  def filebase_login
    access_key = @prompt.ask('Please enter API access key.')
    secret_key = @prompt.mask('Please enter API secret key.')
    begin
      account = FilebaseHelper.new(access_key, secret_key)
      @prompt.say(@style.green.bold('Successful Login!'))
      @filebase_instances.append(account)
    rescue StandardError
      @prompt.error('Unable to login Filebase Account...')
      @filebase_instances.delete(account)
    end
  end

  def filebase_accounts_list
    @filebase_instances.each_with_index do |_acct, idx|
      if idx.zero?
        @prompt.say(@style.black.on_yellow('Active Account :: '))
        puts @filebase_instances[0].access_key
      else
        @prompt.say('Account :: ')
        puts @filebase_instances[idx].access_key
      end
    end
  end

  def filebase_menu
    # BRING IN ASCII ART LOGO To AID in DESIGN
    puts
    default_choices = ['Connect an Account']
    user_selection = @prompt.select('', default_choices, filter: true) do |fb|
      fb.choice('Accounts') unless @filebase_instances.empty?
      fb.choice('Buckets') unless @filebase_instances.empty?
      fb.choice('Return to Command-Line')
    end
    case user_selection
    when 'Connect an Account'
      filebase_login
      filebase_menu
    when 'Accounts'
      filebase_accounts_list
      filebase_menu
    when 'Buckets'
      default = @filebase_instances[0]
      default_dir = default.bucket_list.to_h { |dir| [dir, nil] }
      file_dir = TTY::Tree.new(default_dir)
      @prompt.say(file_dir.render)
      filebase_menu
    when 'Return to CommandLine'
      # Do nothing, returns to the Commandline by Default
    end
  end

  def total_coins
    @prompt.say("    #{SiaStatsInfo.total_coin_supply}")
  end

  # def get_host_info (host_name)
  #   hosts = SiaStatsInfo.all_hosts
  #   hosts_pubkey_list = hosts.map{|host| host['Pubkey']}
  #   hosts_id_list = hosts.map{|host| host['Id']}
  #   hosts_current_ip_list = hosts.map{|host| host['CurrentIp']}
  #   if hosts_pubkey_list.include?(host_name)
  #     host_info = SiaStatsInfo.host_info(SiaStatsInfo.get_host_id(host_name))
  #   elsif hosts_id_list.include?(host_name.to_i)
  #     host_info = SiaStatsInfo.host_info(host_name.to_i)
  #   elsif hosts_current_ip_list.include?(host_name)
  #     named_host = hosts.find{|host| host['CurrentIp'] == host_name}
  #     host_info = SiaStatsInfo.host_info(named_host['Id'])
  #   else
  #     @prompt.error 'Host not Found!'
  #     return
  #   end
  #   @prompt.say host_info
  #   #host_info = SiaStatsInfo.host_info(host_id)
  #   #@prompt.say(" #{SiaStatsInfo.host_info(host_id)}")
  # end

  def get_host_info(host_name,host_info='all')
    hosts = SiaStatsInfo.all_hosts
    found_host = hosts.detect do |host|
      host['CurrentIp'] == host_name || host['Pubkey'] == host_name || host['Id'] == host_name.to_i
    end
    if found_host
      host_info == 'all' ? give_all_host_info(found_host['Id']) : @prompt.say(found_host[host_info])
    else
      @prompt.error 'Host not Found!'
    end
  end


  def give_all_host_info (host_id)
    all_host_info = SiaStatsInfo.host_info(host_id)
    storage_cap = all_host_info['totalStorage']
    storage_amt = all_host_info['usedStorage']
    storage_percent = ((storage_amt / (storage_cap.nonzero? || 1) ) * 100).round(2)
    green = @style.on_bright_magenta(".")
    storage_bar = TTY::ProgressBar.new("storage [:bar]", bar_format: :block, total: 20, incomplete: green)
    @prompt.say @style.bright_green("Host #{host_id}"); @prompt.say "Pubkey #{all_host_info['pubkey']}"
    storage_bar.current = (storage_amt / (storage_cap.nonzero? || 1)) * 20 ; puts "~#{storage_percent}%"
    @prompt.say "IP Address: #{all_host_info['ip']}"

  end

  def get_host_number(data = nil)
    if data
      @prompt.say "    #{SiaStatsInfo.active_hosts.length-1}"
    else
      @prompt.say "    #{SiaStatsInfo.number_online_hosts}"
    end
  rescue SocketError => e
    $command_instance.error "unable to contact SiaStats.info"
  end

  def get_ip_address(host_name)
    host_ip = SiaStatsInfo.host_info(host_name)['ip']
    return error 'NO SUCH HOST' unless host_ip
    @prompt.say host_ip
  end

  def comment_toggle
    return if $command_instance.commenting
    $command_instance.commenting = true
    until @prompt.ask(@cmd_cursor+"#") == "END#"
      # do nothing
    end
  rescue Interrupt
    $command_instance.commenting = false
    $command_instance.success
  end

  def all_hosts(limit = -1, data = 'Id', order = '^')
    return unless order_correct?(order)

    hosts = SiaStatsInfo.all_hosts
    data_keys = []
    hosts[0].each_key { |field| data_keys << field }
    return unless valid_data_key?(data, data_keys)

    parse_hosts(hosts, limit, data, order)
  end

  def active_hosts(limit = -1, data = 'Id', order = '^')
    return unless order_correct?(order)

    hosts = SiaStatsInfo.active_hosts
    data_keys = []
    hosts[0].each_key { |field| data_keys << field }
    return unless valid_data_key?(data, data_keys)

    parse_hosts(hosts, limit, data, order)
  end

  def order_correct?(input)
    unless %w[^ v].include?(input)
      @prompt.error('select descending(v) or ascending(^) order')
      return false
    end
    true
  end

  def valid_data_key?(input, data_keys)
    unless data_keys.include?(input)
      @prompt.error("improper data field, #{input}")
      @prompt.say("valid data fields")
      @prompt.suggest(input, data_keys)
      return false
    end
    true
  end

  def parse_hosts(hosts, limit, data, order)
    standard_info = %w[Id CurrentIp UsedStorage TotalStorage Version]
    limit = limit.to_i
    hosts.sort_by! { |host| host[data] }
    hosts.reverse! unless order == 'v'
    hosts = hosts.take(limit) if limit.positive?
    hosts.each do |host|
      print "Host ID:#{host['Id']}  @  #{host['CurrentIp']}"
      print "    [#{host['UsedStorage']} / #{host['TotalStorage']}] TB Stored"
      print "    Ver #{host['Version']}"
      print "    #{data}: #{host[data]}" unless standard_info.include?(data)
      print "\n"
    end
  end


  # @param [String (frozen)] input
  # @return [nil]
  def help_cmd(input = 'default')
    amri = valid_commands.detect { |cmd| cmd.name_arr.include?(input) }
    # macro = macros.detect {|macro| macro.key == m}
    @prompt.say(amri.summary) if amri
    # get_macro(macro) if macro
    @prompt.say('please enter a valid command name') if input != 'default' && amri.nil?
    commands = @style.cyan.on_white('commands')
    help_example = @style.red.on_white('help [command-name]')
    idioms = @style.black.on_white('idioms')
    main = @style.black.on_white('main')
    quit = @style.bright_red.on_white('quit')
    help_txt = <<~HELP
      ************************************************************
      for a list of all commands type #{commands} into the command line
      for information on a specific command type #{help_example}
      for a list of Kiswahili idioms please type #{idioms}
      to return to main menu , type #{main} , type #{quit} to quit
      *************************************************************
    HELP
    @prompt.say help_txt if input == 'default'
  end

end
