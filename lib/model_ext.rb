# Extensions to radiotag models to be used only on the web frontend
require 'time'

class User
  def admin?
    AdminUsers.include? self.name
  end

  def has_authorized_devices?
    devices.each do |device|
      return true if device.authorized?
    end
    false
  end

  def tags_by_day
    sorted_tags = self.tags.map {|t| Time.at(t.time)}.group_by {|t| t.strftime('%F')}.sort
    labels = []
    counts = []
    sorted_tags.each do |group|
      labels << Time.parse(group[0]).strftime('%b%e')
      counts << group[1].size
    end
    [labels, counts]
  end

  def tag_chart
    labels, counts = self.tags_by_day
    labels = labels.join('|')
    counts = counts.join(',')

    "http://chart.apis.google.com/chart" +
      "?chxl=1:|#{labels}" +
      "&chxr=0,0,20" +
      "&chxt=y,x" +
      "&chbh=a" +
      "&chs=600x400" +
      "&cht=bvg" +
      "&chco=A2C180" +
      "&chd=t:#{counts}"
  end
end

class Device
  def authorized?
    response = AuthService["/auth"].get({:params => { :token => self.token }}) { |response, request, reply| response }
    case response.code

    when 200..299
      true
    else
      false
    end
  end

  def deauthorize!
    response = AuthService["/assoc"].post({:token => self.token, :_method => 'DELETE'}) { |response, request, reply| response }

    case response.code
    when 200..299
      true
    else
      false
    end
  end
end
