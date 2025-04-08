#version 300 es

// The actual raymarcher code
precision mediump float; 

in vec2 UV;
out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;

float noise(vec2 uv) {
   return 0.0;
   // return texture(iChannel0, uv).r;
}

float fbm(vec2 uv) {
    uv.x += iTime * .05;
    // uv *= -1.;
    float value = 0.0;
    float amplitude = .34;
    float frequency = .03;

    for (int i = 0; i < 50; i++) { // 5 octaves
        value += amplitude * noise(frequency * uv);
        frequency *= 1.5;
        amplitude *= 0.7;
    }

    return value;
}

float waveHeight(vec3 p, int iterations) {
    float height = 0.0;
    float Qi = 0.7;
    float A = 0.2;
    float F = 1.0;
    float t = iTime * 2.;
    float iter = 0.0;

   for(int i = 0; i < iterations; i++) {
       vec2 dir = vec2(sin(iter), cos(iter));
       
       float inner = dot(p.xz, dir) * F + t;
       height += A * exp(sin(inner) - 1.0);
       float dx = -(height * cos(inner));
       A *= 0.81;
       F *= 1.18;
       
       iter += 1232.399963;
   }
   
   return height;
}

vec2 combineDistance(vec3 p) {
    vec2 surface = vec2(0.0);
    
    float water = p.y - waveHeight(p, 40);
    return vec2(water, 0.0);
}

vec3 normal(vec3 p) {
    float eps = 0.001;
    return normalize(vec3(
        combineDistance(p + vec3(eps, 0.0, 0.0)).x - combineDistance(p - vec3(eps, 0.0, 0.0)).x,
        combineDistance(p + vec3(0.0, eps, 0.0)).x - combineDistance(p - vec3(0.0, eps, 0.0)).x,
        combineDistance(p + vec3(0.0, 0.0, eps)).x - combineDistance(p - vec3(0.0, 0.0, eps)).x
    ));
}

vec3 sky(vec2 uv) {
    vec3 sky = mix(vec3(0.5, 0.9, 1.0), vec3(0.0, 0.5, 1.0), uv.y);
    
    // Removed clouds for increased performance (minimal), may be re-added later
    float f = 0.0; 
    // fbm(uv * 3.0);
    /*
    f += fbm(uv * 2.0) * 0.5;
    f += fbm(uv) * 0.25;
    f = smoothstep(0.5, 1.2, f);
    */
    
    vec3 c = mix(sky, vec3(1.0), f);
    return mix(sky, c, uv.y - 0.3);
}

vec2 march(vec3 ro, vec3 rd) {
    float t = 0.0;
    float material = 0.0;
    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * t;
        vec2 surface = combineDistance(p);
        float d = surface.x;
        material = surface.y;
        t += d;
        
        if(t > 800.) break;
        if(d < 0.01) break;
    }
    
    return vec2(t, material);
}

vec3 shading(vec3 col, vec3 ro, vec3 rd, float t, vec2 uv) {
    vec3 N = normal(ro + (-rd) * t) * 0.9;
    vec3 sunDir = normalize(vec3(0.0, .7, 1.0));
    vec3 sunH = normalize(sunDir + rd);
    
    // Diffuse + Ambient
    col *= max(0.0, dot(N, sunDir));
    col += vec3(0., 0.5, 1.0);
    // 0.0, 0.5, 1.0
    // 0.0, 0.2, 0.4

    // Specular
    vec3 spec_col = vec3(1.0f);
    float spec_fact = pow(max(dot(sunH, N), 0.0), 16.);
	float spec_strength = .6;
	vec3 specular = spec_col * spec_fact * spec_strength;
    col += specular;
    
    // SSS
    float SSS_Distortion = .2;
    float SSS_Scale = 1.;
    float SSS_Power = 2.;
    float SSS_Strength = 1.5;
    float SSS_Dist = 10.;
    
    vec3 scatterColor = vec3(0.05, 0.8, 0.7);
	vec3 Hs = normalize(sunDir + N * SSS_Distortion);
    
    float scatter_fact = pow(max(dot(rd, -Hs), 0.0), SSS_Power) * SSS_Scale;
	float dist_fact = (SSS_Dist - clamp(t, 0.0, SSS_Dist))/SSS_Dist;
	vec3 scatter = SSS_Strength * dist_fact * scatterColor * scatter_fact;
    
    col += scatter;
    
    // Fresnel
	float F0 = .04;
	float base = 1.0 - max(dot(rd, N), 0.0);
	float exponential = pow(base, 5.);
	float fresnel = exponential + F0 * (1.0 - exponential);
    
    // Reflection
    vec3 R = reflect(rd, N);
    float rt = 1. - march(ro + rd * t, R).x;
    if (rt > 0.) {
        col = col + sky(R.xy) * fresnel;
    }
    
    return col;
}

// Great tonemapping function from : https://www.shadertoy.com/view/XsGfWV
vec3 aces_tonemap(vec3 color) {  
  mat3 m1 = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
  );
  mat3 m2 = mat3(
    1.60475, -0.10208, -0.00327,
    -0.53108,  1.10813, -0.07276,
    -0.07367, -0.00605,  1.07602
  );
  vec3 v = m1 * color;  
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));  
}

void main()
{
    vec2 uv = (gl_FragCoord.xy * 2. - iResolution.xy) / iResolution.y;

    float camHeight = 1.0;
    vec3 camDir = normalize(vec3(0., 0., 1.));
    // 0., 1., -5.
    
    vec3 ro = vec3(5., camHeight, -5.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    vec3 col = vec3(0.0);
    
    // Avoids unnecessary raymarching
    if(rd.y > 0.) {
        col = sky(gl_FragCoord.xy / iResolution.xy);
        fragColor = vec4(aces_tonemap(col), 1.0);
        return;
    }
    
    vec2 marchResult = march(ro, rd);
    float t = marchResult.x;
    int material = int(marchResult.y);
    
    // Simulates some kind of distant foam at the horizon, would look weird at higher cam positions
    col = mix(vec3(0.0, 0.0, 1.0), vec3(1.), t * 0.06);
    
    // -rd since we need the view direction to be from point to cam
    col = shading(col, ro, -rd, t, gl_FragCoord.xy / iResolution.xy);
    
    fragColor = vec4(aces_tonemap(col), 1.0);
    // fragColor = vec4(col, 1.0);
}