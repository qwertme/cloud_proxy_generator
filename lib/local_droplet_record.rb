# For storing local information on droplets
class LocalDropletRecord
  ATTRS = [
    :ip_address,
    :local_port,
    :name,
    :remote_id
  ]
  attr_accessor *ATTRS

  def initialize(options={})
    ATTRS.each do |a|
      v = options[a]
      instance_variable_set("@#{a.to_s}", v)
    end
  end
end