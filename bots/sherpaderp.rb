# Sherpaderp : A spiralling bot
#
# Does not get dizzy

class Sherpaderp < RTanque::Bot::Brain
  NAME = 'Sherpaderp'
  include RTanque::Bot::BrainHelper

  TURRET_FIRE_RANGE = RTanque::Heading::ONE_DEGREE * 5.0

  def tick!
    @clockwise ||= true
    if (derp = self.get_derp)
      self.beast_mode(derp)
    else
      self.find_derp
    end

    self.rotate_spiral
    self.hodor
  end

  def health_factor
    1 - (self.health * 0.01)
  end

  # kill derp-to-kill like a savage
  # Notes:
  # DFD = Distance From Derp
  def beast_mode(derp)
    @derp_last_seen = derp.position

    largest_radius = [self.arena.width, self.arena.height].min / 2
    desired_dfd = largest_radius * self.health_factor
    dfd_delta = (desired_dfd - derp.distance).abs

    command.turret_heading = derp.heading
    command.radar_heading = derp.heading

    if (derp.heading.delta(sensors.turret_heading)).abs < TURRET_FIRE_RANGE
      command.fire(dtd > 200 ? MAX_FIRE_POWER : MIN_FIRE_POWER)
    end

    if dfd_delta <= 20 # we are at desired distance away
      command.heading = self.angle_to_next_dot_on_spiral(derp.position, dfd_delta)
      command.speed = MAX_BOT_SPEED * (1 - (derp.distance / largest_radius))
    else
      command.heading = desired_dfd > derp.distance ? self.angle_from_derp(derp) : self.angle_from_derp(derp) + 180
      command.speed = MAX_BOT_SPEED
    end

  end

  # fetch derp-to-kill
  def get_derp
    @derp_name ||= nil
    derp = if @derp_name
      sensors.radar.find { |next_derp| next_derp.name == @derp_name } || sensors.radar.first
    else
      sensors.radar.first
    end
    @derp_name = derp.name if derp
    derp
  end

  # track derp-to-kill
  def find_derp
    if sensors.position.on_wall?
      @facing = sensors.heading + RTanque::Heading::HALF_ANGLE
    end
    command.radar_heading = sensors.radar_heading + MAX_RADAR_ROTATION
    command.speed = 1
    if @facing
      command.heading = @facing
      command.turret_heading = @facing
    end
  end

  # get angle from derp
  def angle_from_derp(derp)
    Math.atan2(self.position.y - derp.position.y, self.position.x - derp.position.x) * 180 / Math::PI
  end

  # get next position on spiral
  def angle_to_next_dot_on_spiral(center, radius)
    
  end

  # rotate spiral
  def rotate_spiral
    at_tick_interval(5000) do
      @clockwise = !@clockwise
    end
  end

  # hodor reports not necessarily redundant things
  def hodor
    at_tick_interval(100) do
      puts "Tick ##{sensors.ticks}!"
      puts " Gun Energy: #{sensors.gun_energy}"
      puts " Health: #{sensors.health}"
      puts " Position: (#{sensors.position.x}, #{sensors.position.y})"
      puts sensors.position.on_wall? ? " On Wall" : " Not on wall"
      puts " Speed: #{sensors.speed}"
      puts " Heading: #{sensors.heading.inspect}"
      puts " Turret Heading: #{sensors.turret_heading.inspect}"
      puts " Radar Heading: #{sensors.radar_heading.inspect}"
      puts " Radar Reflections (#{sensors.radar.count}):"
      sensors.radar.each do |reflection|
        puts "  #{reflection.name} #{reflection.heading.inspect} #{reflection.distance}"
      end
    end
  end
end
