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

float sdSphere( vec3 p, vec3 q, float s )
{
  return length(p - q)-s;
}

float sdVerticalCapsule( vec3 p, float h, float r, vec3 op )
{
  p.y -= clamp( p.y - op.y, 0.0, h );
  return length( p - op ) - r;
}

float sdCappedCylinder( vec3 p, float h, float r, vec3 q )
{
  vec2 d = abs(vec2(length(p.xz - q.xz),p.y - q.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float smin( float a, float b, float k )
{
    k *= 16.0/3.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - h*h*h*(4.0-h)*k*(1.0/16.0);
}

vec2 sdLighthouse(vec3 p) {
    // float cyl = sdVerticalCapsule(p, 3., 1., vec3(-5., 0., 0.));
    float cyl = sdCappedCylinder(p, 4., .75, vec3(5., 0., 0.)); 
    // float mid = sdOctahedron(p, 2., vec3(-5., -3.8, 0.));
    // float mid = sdSphere(p, vec3(5., 3.8, 0.), 1.);
    float mid = sdVerticalCapsule(p, 1., .5, vec3(5., 4., 0.));
    float island = sdSphere(p, vec3(5., -3., 0.), 3.8);
    
    vec2 lighthouse = vec2(0.0);
    lighthouse.x = min(cyl, mid);
    lighthouse.x = min(lighthouse.x, island);
    if(lighthouse.x == cyl) {
        lighthouse.y = 1.;
    }
    else if (lighthouse.x == mid) {
        lighthouse.y = 2.;
    }
    else {
        lighthouse.y = 3.;
    }
    
    return lighthouse;
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
    vec2 lighthouse = sdLighthouse(p);
    // return lighthouse;
    surface.x = min(water, lighthouse.x);
    if(lighthouse.x < water) {
        surface.y = lighthouse.y;
    }
    
    return surface;
}

vec3 normal(vec3 p) {
    float eps = 0.001;
    return normalize(vec3(
        combineDistance(p + vec3(eps, 0.0, 0.0)).x - combineDistance(p - vec3(eps, 0.0, 0.0)).x,
        combineDistance(p + vec3(0.0, eps, 0.0)).x - combineDistance(p - vec3(0.0, eps, 0.0)).x,
        combineDistance(p + vec3(0.0, 0.0, eps)).x - combineDistance(p - vec3(0.0, 0.0, eps)).x
    ));
}

vec3 sampleTriplanar(sampler2D tex, vec3 p, vec3 N) {
    vec3 absN = abs(N);
    absN /= (absN.x + absN.y + absN.z);

    vec3 XY = texture(tex, p.xy).rgb;
    vec3 XZ = texture(tex, p.xz).rgb;
    vec3 YZ = texture(tex, p.yz).rgb;

    return XY * absN.z + XZ * absN.y + YZ * absN.x;
}

vec3 sky(vec2 uv) {
    vec3 sky = mix(vec3(0.5, 0.9, 1.0), vec3(0.0, 0.5, 1.0), uv.y);
    
    vec3 clouds = vec3(noise(uv));
    
    float f = fbm(uv * 3.0);
    f += fbm(uv * 2.0) * 0.5;
    f += fbm(uv) * 0.25;
    f = smoothstep(0.5, 1.2, f); // Threshold clouds
    
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

vec3 shading(vec3 col, vec3 ro, vec3 rd, float t, vec2 uv, vec3 vDir) {
    vec3 N = normal(ro + rd * t) * 0.9;
    vec3 sunDir = normalize(vec3(0.0, .7, 1.0));
    vec3 sunH = normalize(sunDir + vDir);
    
    // Diffuse + Ambient
    col *= max(0.0, dot(N, sunDir));
    col += vec3(0., 0.5, 1.0);
    // 0.0, 0.5, 1.0
    // 0.0, 0.2, 0.4

    // Specular
    vec3 spec_col = vec3(1.0f);
    float spec_fact = pow(max(dot(sunH, N), 0.0), 8.);
	float spec_strength = 8.;
	vec3 specular = spec_col * spec_fact * spec_strength;
    col += specular;
    
    // SSS
    float SSS_Distortion = 0.2;
    float SSS_Scale = .4;
    float SSS_Power = 8.;
    float SSS_Strength = .5;
    float SSS_Dist = 50.;
    
    vec3 scatterColor = vec3(0.05, 0.8, 0.7);
	vec3 Hs = normalize(sunDir + N * SSS_Distortion);
	// float scatter_fact = pow(max(dot(rd, -Hs), 0.0), SSS_Power) * SSS_Scale;
    float scatter_fact = pow(max(dot(vDir, -Hs), 0.0), SSS_Power) * SSS_Scale;
	float dist_fact = (SSS_Dist - clamp(t, 0.0, SSS_Dist))/SSS_Dist;
	vec3 scatter = SSS_Strength * dist_fact * scatterColor * scatter_fact;
    
    col += scatter;
    
    // Fresnel
	float F0 = .04;
	float base = 1.0 - max(dot(vDir, sunH), 0.0);
	float exponential = pow(base, 5.);
	float fresnel = exponential + F0 * (1.0 - exponential);
    
    // Reflection
    vec3 R = reflect(vDir, N);
    // No fresnel initially due to the viewing angle
    float rt = 1. - march(ro + rd * t, R).x;
    if (rt > 0.) {
        col = mix(col, sky(R.xy / R.z * 0.5 + 0.5), fresnel);
    }
    // col = vec3(fresnel);
    
    // Refraction
    vec3 Rf = normalize(refract(vDir, N, 1.333));
    vec3 pos = ro + rd * t;
    vec3 npos = pos + Rf * 0.5;
    // March from there and color it
    vec2 march = march(npos, Rf);
    if(int(march.y) != 0) {
        col = mix(col, vec3(.9, .9, 0.), 0.2);
    }
    // col = vec3(max(dot(vDir, -Hs), 0.0));
    // col = sunDir;
    
    return col;
}

vec3 shadeLighthouse(vec3 col, vec3 p, vec3 rd, int mat) {
    vec3 N = normal(p);
    vec3 sunDir = normalize(vec3(0.0, 1.0, 1.0));
    vec3 sunH = normalize(sunDir + rd);
    
    // Diffuse + Ambient
    vec3 tex = vec3(.7, .1, .0);
    if(mat == 2) {
        tex = vec3(0.1, 0.4, 0.8);
    }
    else if (mat == 1) {
        float h = mod(p.y * 6.5, 2.);
        h = step(1., h);
        tex = 1.0 - vec3(h) + vec3(0.7, 0.0, 0.0);
    }
    else {
        tex = vec3(0.9, 0.9, 0.0);
    }
    col *= max(0.0, dot(N, sunDir)) * tex;
    col += tex * 0.5;
    
    // Specular
    vec3 spec_col = vec3(1.0f);
    float spec_fact = pow(max(dot(sunH, N), 0.0), 8.);
	float spec_strength = 16.;
	vec3 specular = spec_col * spec_fact * spec_strength;
    col += specular;
    
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
    vec3 camDir = vec3(0., 0., 1.);
    // camHeight = sin(iTime) + 1.;
    // 0., 1., -5.
    vec3 ro = vec3(.0, camHeight, -5.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    
    vec2 marchResult = march(ro, rd);
    float t = marchResult.x;
    int material = int(marchResult.y);
    
    vec3 col = vec3(1.0) - vec3(t * 0.06);
    col *= vec3(0.0, 0.0, 1.0);
    col = mix( vec3(0.0, 0.0, 1.0), vec3(1.), t * 0.06);
    
    if(t > 25.) {
        col = sky(gl_FragCoord.xy / iResolution.xy);
    }
    else {
        if(material == 0) {
            col = shading(col, ro, rd, t, gl_FragCoord.xy / iResolution.xy, camDir);
        }
        else {
            col = shadeLighthouse(col, ro + rd * t, rd, material);
        }
    }
    
    fragColor = vec4(aces_tonemap(col), 1.0);
    // fragColor = vec4(uv, 0., 1.);
    // fragColor = vec4(0.0);
}