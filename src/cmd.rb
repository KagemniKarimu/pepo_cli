# frozen_string_literal: true

require_relative 'cli'

# Amri is Kiswahili for 'Instruction/Order/Commmand' - each recognized command in Pepo has an Amri instance
# those Amri instances live in the valid_commands array of $command_instance

class Amri
  attr_reader :action, :description, :summary, :example, :idiom, :standard_name, :args
  attr_accessor :name_arr

  def initialize(**configs)
    @name_arr = configs[:names]
    @description = configs[:descr]
    @example = configs[:example]
    @action = configs[:action]
    @standard_name = @name_arr.first
    @idiom = @name_arr.last
    @summary = "#{@standard_name} // #{@idiom}
 syntax: #{@example}
 aliases: #{@name_arr}
#{@description}"
    @args = @action.arity
    $command_instance.valid_commands << self
  end

  def execute(*args)
    @action.call(*args)
  rescue ArgumentError => e
    $command_instance.error(e.message)
  end


end

# This rb file contains a customizable/programmable list of all the Commands for PepoCLI
# adding a command is as simple as defining four parameters (names, descr, example, & action)
# removing a command is as simple as deleting its corresponding 'Amri' instance

puts 'initializing commands...'

########################
## TERMINAL COMMANDS ##

# SOUND // sauti
puts Amri.new(
  names: %w[sound sounds volume sauti],
  descr: 'turn ON/OFF sound for pepo cli',
  example: 'sound',
  action: $command_instance.method(:adjust_sound)
)

# MATH // hesabu
puts Amri.new(
  names: %w[math ~ hesabu],
  descr: 'calculate a given expression',
  example: 'math 200 + 200',
  action: $command_instance.method(:calculate)
)

# STORE // hifadhi
puts Amri.new(
  names: %w[store keep hifadhi],
  descr: 'save a variable',
  example: 'store [name] [value]',
  action:$command_instance.method(:store)
)

# PAUSE // pumziko
puts Amri.new(
  names: %w[pause delay sleep pumziko],
  descr: 'suspends all pepo activity for specified time interval',
  example: 'pause [SECONDS]',
  action: proc { |sec|
            sec = sec.to_f
            if sec.is_a?(Float) && sec.positive?
              sleep(sec)
            else
              $command_instance.error 'Please enter a number of seconds > 0'
            end
          },
)

# SET-IP // anwani!
puts Amri.new(
  names: %w[set-ip refresh-ip anwani!],
  descr: 'retrieves an accurate external IP address from ipify API',
  example: 'set-ip',
  action: $command_instance.method(:set_ip_address)
)

# GET-IP // anwani?
puts Amri.new(
  names: %w[get-ip what-ip anwani?],
  descr: 'returns a list of valid IP addresses from the Socket layer',
  example: 'get-ip',
  action: $command_instance.method(:print_ip_addresses)
)

# MENU // orodha
puts Amri.new(
  names: %w[menu main main_menu orodha],
  descr: 'escapes cli and pulls up the main menu',
  example: 'menu',
  action: proc {
            $command_instance.clear_screen
            $command_instance.main_menu
          }
)

# CLEAR // safisha
puts Amri.new(
  names: %w[clear cls clear_screen safisha],
  descr: 'updates the interface header, clears screen of all text',
  example: 'clear',
  action: $command_instance.method(:clear_screen)
)

# IDIOMS // misemo
puts Amri.new(
  names: %w[idioms misemo],
  descr: 'returns a list of all commands as their respective idioms',
  example: 'idioms',
  action: proc {
            $command_instance.valid_commands.each do
              print _1.standard_name
              print ' = '
              puts _1.idiom
            end
          }
)

# COMMANDS // amri
puts Amri.new(
  names: %w[commands list-commands command-list amri],
  descr: 'lists all valid commands',
  example: 'commands',
  action: proc {
    puts $command_instance.valid_commands.map { "#{_1.standard_name} ||  #{_1.description}" }.sort
  }
)

# QUIT // acha
puts Amri.new(
  names: %w[quit exit stop acha],
  descr: 'immediately stops all processes and exits the program',
  example: 'quit',
  action: $command_instance.method(:program_close)
)

# SUGGESTIONS // madokezo
puts Amri.new(
  names: %w[suggestions hints do-you-mean madokezo],
  descr: 'adjust the suggestion sensitivity to receive more or less hints per invalid command',
  example: 'suggestions',
  action: $command_instance.method(:adjust_sensitivity),
)

# HELP // habari
puts Amri.new(
  names: %w[help info habari],
  descr: 'gives information on a given command',
  example: 'help `amri`',
  action: $command_instance.method(:help_cmd)
)

# REFRESH // upya
puts Amri.new(
  names: %w[refresh renew erase upya],
  descr: 'refreshes the instance of PepoCLI - logs out of everything, resets connections',
  example: 'refresh',
  action: $command_instance.method(:reinitialize)
)

# SET-MACRO // mkato
puts Amri.new(
  names: %w[set-macro macro mkato!],
  descr: 'program a macro',
  example: 'macro [name-of-phrase]',
  action: $command_instance.method(:set_macro),
)

# LIST-MACROS // mikato
puts Amri.new(
  names: %w[macros list-macros ls-macro macro-list mikato],
  descr: 'list all valid macros',
  example: 'macros',
  action: $command_instance.method(:list_macros)
)

# LOAD-MACRO //
puts Amri.new(
  names: %w[load-macro pep-to-macro import import-macro pep2mkato],
  descr: 'loads a macro from a .pep file',
  example: 'macro [/absolute/path/to/file/]',
  action: $command_instance.method(:import_macro)
)

# GET-MACRO //
puts Amri.new(
  names: %w[get-macro mkato?],
  descr: 'prints the series of commands a macro will execute',
  example: 'get-macro [macro_name]',
  action: $command_instance.method(:get_macro)
)

# EXPORT-MACRO
puts Amri.new(
  names: %w[export-macro macro-to-pep export mkato2pep],
  descr: 'export any/all macros',
  example: 'export-macro [macro_name]',
  action: $command_instance.method(:export_macro)
)

# DELETE-MACRO //
puts Amri.new(
  names: %w[delete-macro macro-delete del-mac mkatokufa],
  descr: 'removes a macro from memory',
  example: 'delete-macro ',
  action: $command_instance.method(:delete_macro)

)

# PING // gota
puts Amri.new(
  names: %w[ping gota],
  descr: 'ping a specified address',
  example: 'ping [address]',
  action: $command_instance.method(:ping),
)

# DIRECTORY // folda
puts Amri.new(
  names: %w[directory dir ls folda],
  descr: 'lists contents of a directory at the location specified',
  example: 'directory [/absolute/path]',
  action: $command_instance.method(:dir),
)
###########################
## FILEBASE API COMMANDS ##
# FILEBASE // faili
puts Amri.new(
  names: %w[filebase filebase-menu open-filebase faili],
  descr: 'opens filebase menu',
  example: 'filebase',
  action: $command_instance.method(:filebase_menu)
)

###########################
## SIASTATS API COMMANDS ##

# TOTAL-COINS // siacoins
puts Amri.new(
  names: %w[total-coins total-coin-supply siacoins],
  descr: 'gives total current supply of Siacoins',
  example: 'total-coin-supply',
  action: $command_instance.method(:total_coins)
)

# HOSTS // seva
puts Amri.new(
  names: %w[hosts all-hosts seva],
  descr: 'gives a complete list of hosts on the Sia network, alive or dead',
  example: 'hosts',
  action: $command_instance.method(:all_hosts),
)

# ACTIVE-HOSTS // seva-hai
puts Amri.new(
  names: %w[active-hosts hosts-alive seva-hai],
  descr: 'gives a list of active hosts on the Sia network',
  example: 'active-hosts',
  action: $command_instance.method(:active_hosts),
)

# HOST-INFO // SEVA
puts Amri.new(
  names: %w[host-info query-host seva?],
  descr: 'gives detailed information on a specific host, given a host-id,pubkey, or ip address',
  example: 'host-info [host-id/pubkey/ip-address] [data]',
  action: $command_instance.method(:get_host_info),
)

# TOTAL-HOSTS // namba-seva
puts Amri.new(
  names: %w[total-hosts host-num host-number host-sum namba-seva],
  descr: 'lists the number of hosts in the ecosystem',
  example: 'host-num [active/all]',
  action: $command_instance.method(:get_host_number),
)

### TEST COMMANDS ###
puts Amri.new(
  names: %w[comment-enable comment-mode comments fasiri],
  descr: 'allows user to make continuous comments',
  example: 'comment-enable',
  action: $command_instance.method(:comment_toggle)
)

puts 'all commands initalized...'
puts 'configuring command controller...'
Amiri.configure
puts 'loading test macro'
# p Dir['C:\Users\Admin\RubymineProjects\pepo_cli\test_macros']
# sleep 3
$command_instance.import_macro'C:\Users\Admin\RubymineProjects\pepo_cli\test_macros\sifa.pep'
puts 'starting program...'
$command_instance.program_start
