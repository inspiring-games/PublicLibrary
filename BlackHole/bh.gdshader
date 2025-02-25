shader_type canvas_item;

uniform vec4 black_color = vec4(0.0,0.0,0.0,1.0);
uniform int particle_count = 10;
uniform float particle_speed = 0.5;
uniform float particle_size = 0.003;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 uv = UV;
	float radius = 0.5;
	vec2 center = vec2(0.5, 0.5);
	vec2 to_center = uv - center;
	float angle = atan(to_center.y / to_center.x);
	vec2 direction = normalize(to_center);
	float distance = length(to_center);
	vec4 output_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (distance < radius)
	{
		float foo = (1.0 - (distance/radius)) / 4.0 + 0.45;
		float distortion_amount = foo - radius;
		float factor = (distance/radius) * distortion_amount;
		float distortion = distortion_amount - factor;
		vec2 sampling_uv = SCREEN_UV + direction * distortion;
		vec4 sample_color = texture(SCREEN_TEXTURE,sampling_uv);
		
		output_color = mix(black_color, sample_color,  ((distance - 0.1) / 0.8 / radius) ); //the Black of the black hole
		
		for (int i = 0; i < particle_count; i++){
			float angle = float(i) / float(particle_count) * PI * 2.0;
			float particle_speed_variation = particle_speed * (0.6 + 0.6 * fract(sin(float(i)) * 10000.0));
			float t = mod(TIME * particle_speed_variation, 1.0);
			vec2 particle_pos = center + vec2(cos(angle), sin(angle)) * radius * (1.0 - t);
			vec2 particle_start_pos = center + vec2(cos(angle), sin(angle)) * radius * 0.9;
			float brightness = length(particle_pos - center) / radius;
			float dist_to_particle = length(uv - particle_pos);
			if (dist_to_particle < particle_size) {
				sample_color = mix(texture(SCREEN_TEXTURE,particle_start_pos), vec4(1.0,1.0,1.0,1.0), 0.3 * brightness);
				output_color = mix(output_color, sample_color,  ((distance) / 0.5 / radius) );
			}
		}
		
		
		
	}

	COLOR = output_color;
}

