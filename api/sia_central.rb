require 'httparty'


module SiaCentral

  def hosts (parameters)
    possibilities = %[minuptime minuploadspeed mindownloadspeed maxstorageprice maxuploadprice maxdownloadprice online]
    specs = []
    parameters.each do |parameter|
      given_arg = parameter.partition('=')
      possibilities.include?(given_arg[0]) ? specs << parameter : raise ArgumentError
    end
    specs = parameters.join('&')
    get "https://api.siacentral.com/v2/hosts/list?#{specs}"
    # curl "https://api.siacentral.com/v2/hosts/list?minuptime=75&maxstorageprice=115740740740"
  end
end