#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

uniform int u_OCTAVE;
uniform float u_Frequency;
uniform float u_Lacunarity;
uniform float u_Amplitude;
uniform float u_Gain;
uniform int u_Layer;
uniform int u_Terrain;
uniform int u_CellSize;
uniform float u_Exponent;
uniform float u_Multiply;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out float fs_height;


// ================ Level 1 Noises =========================
float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec2 perlin_gradient(vec2 p, vec2 seed) {
  vec2 frac = random2(p, seed);       // range from [0, 1]
  return frac * 2.0 - 1.0;            // warp to range [-1, 1]
}
// ================ Level 1 Noises =========================


// ========= Interpolation & Helper Functions ==============
// LINEAR INTERPOLATION
float lerp(float a, float b, float t) {
  // t is from 0 to 1
  return a + (b - a) * t;
}

// COSINE INTERPOLATION
float cosinterp(float a, float b, float t) {
  float f = 1.1;
  float t_cos = (1.0 + cos(t * f * 3.1415926)) / 2.0;   // warp t in linear space into cosine space
  return lerp(a, b, t_cos);
}

// CUBIC INTERPOLATION
float cubinterp(float a, float b, float t) {
  float t_c = t * t * (3.0 - 2.0 * t);
  return lerp(a, b, t_c);
}

// SIGMOID FUNCTION
float sigmoid(float a, float h) {
  return h / (1.0 + pow(2.714, -a));
}
// ========= Interpolation & Helper Functions ==============


// =============== Level 2 NOISE FUNCTIONS =================
// ==== 1. Perlin noise
// ==== 2. Spatial noise
// ==== 3. Worley noise
// ======================================================
float perlin_noise(vec2 p) {
  // compute the integer part and fract part
  vec2 intg = floor(p);
  vec2 frac = p - intg;

  // compute the gradient at four conner points
  vec2 seed = vec2(122.46, 92.012);
  vec2 g0 = perlin_gradient(intg, seed);
  vec2 g1 = perlin_gradient(intg + vec2(0.0, 1.0), seed);
  vec2 g2 = perlin_gradient(intg + vec2(1.0, 1.0), seed);
  vec2 g3 = perlin_gradient(intg + vec2(1.0, 0.0), seed);

  // compute the value at four conner points
  float w0 = dot(g0, p - intg);
  float w1 = dot(g1, p - (intg + vec2(0.0, 1.0)));
  float w2 = dot(g2, p - (intg + vec2(1.0, 1.0)));
  float w3 = dot(g3, p - (intg + vec2(1.0, 0.0)));

  // calculate interpolation value
  // vec2 t = frac * frac * (3.0 - 2.0 * frac);
  vec2 t = frac;

  float x_interp_0 = lerp(w0, w3, t.x);
  float x_interp_1 = lerp(w1, w2, t.x);
  float interp = lerp(x_interp_0, x_interp_1, t.y);

  return (interp + 1.0) / 2.0;
}

float spatial_noise(vec2 p) {
  // compute the integer part and fract part
  vec2 intg = floor(p);
  vec2 frac = p - intg;

  // noise values at four conner points
  vec2 seed = vec2(123.456, 789.012);
  float a = random1(intg, seed);
  float b = random1(intg + vec2(0.0, 1.0), seed);
  float c = random1(intg + vec2(1.0, 1.0), seed);
  float d = random1(intg + vec2(1.0, 0.0), seed);

  // cubic interpolation
  // vec2 t = frac * frac * (3.0 - 2.0 * frac);
  vec2 t = frac;

  // caculate interpolation value
  float x_interp_0 = lerp(a, d, t.x);
  float x_interp_1 = lerp(b, c, t.x);
  float interp = lerp(x_interp_0, x_interp_1, t.y);

  return interp;
}

int floor_mod(float a, int m) {
  if (a > 0.0) {
    return (int(floor(a)) / m) * m;
  }
    return (int(floor(a)) / m - 1) * m;
}

float worley_noise(vec2 p) {
  int D = u_CellSize;

  int deltaX[3] = int[3](-D, 0, D);
  int deltaY[3] = int[3](-D, 0, D);

  float minDistance = 9999999.0;
  float distance = 123.0;
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      vec2 conner = vec2(float(floor_mod(p.x, D) + deltaX[i]),
                         float(floor_mod(p.y, D) + deltaY[j]));
      vec2 controlP = conner + random2(conner, vec2(0.0, 0.0)) * float(D);

      distance = sqrt(dot(controlP - p, controlP - p));
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
  }

  return minDistance / float(D);
}

// ========== Level 3 NOISE FUNCTIONS ===============
// ==== 1. Spatial -> Perlin
// ==== 2. Perlin -> Spatial
// ==== 3. Perlin -> Worley
// ==== 4. Worley -> Spatial
// ==== 5. Worley -> Worley
// ==================================================
float perlin_spatial(vec2 p) {
  vec2 spatial = vec2(spatial_noise(p + vec2(166.29, 44.87)), spatial_noise(p + vec2(333.2, 10.95)));
  float noise = perlin_noise(spatial + p);
  return noise;
}

float spatial_perlin(vec2 p) {
  vec2 perlin = vec2(perlin_noise(p + vec2(166.29, 44.87)), perlin_noise(p + vec2(333.2, 10.95)));
  float noise = spatial_noise(perlin + p);
  return noise;
}

float worley_perlin(vec2 p) {
  vec2 perlin = vec2(perlin_noise(p + vec2(166.29, 44.87)), perlin_noise(p + vec2(333.2, 10.95))) * 5.0;
  float noise = worley_noise(perlin + p);
  return noise;
}

float spatial_worley(vec2 p) {
  vec2 worley = vec2(worley_noise(p + vec2(166.29, 44.87)), worley_noise(p + vec2(333.2, 10.95)));
  float noise = spatial_noise(worley + p);
  return noise;
}

float worley_worley(vec2 p) {
  vec2 worley = vec2(worley_noise(p + vec2(166.29, 44.87)), worley_noise(p + vec2(333.2, 10.95)));
  float noise = worley_noise(worley + p);
  return noise;
}

// ================= Level 4 FBMs =====================
// ==== 1. Perlin noise only
// ==== 2. Spatial noise only
// ==== 3. Worley noise only
// ==== 4. Combination of Perlin & Spatial
// ==== 5. Worley & Perlin
// ====================================================

float fbm_perlin(vec2 p) {
  int OCTAVE = 6;
  float lacunarity = u_Lacunarity, frequency = u_Frequency;
  float gain = u_Gain, amplitude = u_Amplitude;

  float sum = 0.;
  for (int i = 0; i < OCTAVE; ++i) {
    sum += amplitude * perlin_noise(p * frequency);
    frequency *= lacunarity;
    amplitude *= gain;
  }
  return sum;
}

float fbm_spatial(vec2 p) {
  int OCTAVE = u_OCTAVE;
  float lacunarity = u_Lacunarity, frequency = u_Frequency;
  float gain = u_Gain, amplitude = u_Amplitude;

  float sum = 0.;
  for (int i = 0; i < OCTAVE; ++i) {
    sum += amplitude * spatial_noise(p * frequency);
    frequency *= lacunarity;
    amplitude *= gain;
  }
  return sum;
}

float fbm_worley(vec2 p) {
  int OCTAVE = 6;
  float lacunarity = 2.0, frequency = 0.7;
  float gain = 0.5, amplitude = 0.5;

  float sum = 0.;
  for (int i = 0; i < OCTAVE; ++i) {
    sum += amplitude * worley_noise(p * frequency);
    frequency *= lacunarity;
    amplitude *= gain;
  }
  return sum;
}

float fbm_ps(vec2 p) {
  int OCTAVE = 6;
  float lacunarity = u_Lacunarity, frequency = u_Frequency;
  float gain = u_Gain, amplitude = u_Amplitude;

  float sum = 0.;
  for (int i = 0; i < OCTAVE; ++i) {
    sum += amplitude * perlin_noise(p * frequency);
    sum += amplitude * spatial_noise(p * frequency);
    frequency *= lacunarity;
    amplitude *= gain;
  }
  return sum;
}

float fbm_worley_perlin(vec2 p) {
  int OCTAVE = u_OCTAVE;
  float lacunarity = u_Lacunarity, frequency = u_Frequency;
  float gain = u_Gain, amplitude = u_Amplitude;

  float sum = 0.;
  for (int i = 0; i < OCTAVE; ++i) {
    sum += amplitude * worley_perlin(p * frequency);
    frequency *= lacunarity;
    amplitude *= gain;
  }
  return sum;
}

// ============ Level 5 Recursive FBMs ================
// ==== 1. Use FBM that combines Perlin & Spatial
// ====================================================
float dream(vec2 p, int layers) {
  vec2 q = vec2(p);
  for (int i = 0; i < layers; ++i) {
    q = vec2(fbm_ps(q + vec2(1.2, 5.67)), fbm_ps(q + vec2(3.33, 6.66))) * 100.0;
  }

  return fbm_ps(q);
}

void main()
{
  fs_Pos = vs_Pos.xyz;
  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));

  vec2 p = vec2(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y);

  float h0 = fbm_worley_perlin(p);
  float h1 = dream(p, u_Layer);
  float h2 = fbm_spatial(p);

  float h = h2;

  vec4 modelposition = vec4(vs_Pos.x, pow(h, u_Exponent) * u_Multiply, vs_Pos.z, 1.0);

  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

  fs_height = h;
}
