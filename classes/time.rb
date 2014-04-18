class Time
  def local
    self + Time.zone_offset('EDT')
  end

  def ics
    self.utc.strftime '%Y%m%dT%H%M%SZ'
  end
end