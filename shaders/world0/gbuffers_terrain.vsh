#version 130

//#ifdef winter_mode

attribute vec4 at_tangent;
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform sampler2D noisetex;

uniform float frameTimeCounter;

uniform int blockEntityId;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

out float id;
out float spruce_leaves;
out float isBlockEntity;

out vec2 texcoord;
out vec2 lmcoord;

out vec3 normal;
out vec3 tangent;
out vec3 binormal;

out vec3 vP;
out vec3 viewVector;

out vec4 color;

#define Enabled_TAA

uniform vec2 jitter;

vec3 nvec3(in vec4 x){
  return x.xyz / x.w;
}

#define GetBlockID(x, id) bool(step(id - 0.5, x) * step(x, id + 0.5) * id)

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

  color = gl_Color;

  vec4 position = gl_Vertex;

  vP = (gl_ModelViewMatrix * position).xyz;
  vec3 wP = mat3(gbufferModelViewInverse) * vP;

  normal = normalize(gl_NormalMatrix * gl_Normal);
  vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;

  viewVector = wP;

  float blockID = float(mc_Entity.x);

  bool leaves = mc_Entity.x == 18 || (mc_Entity.x > 1799 && mc_Entity.x < 1806);

  bool plant = mc_Entity.x == 31;
  bool lily_pad = GetBlockID(111.0, blockID);

  bool double_plant_upper = mc_Entity.x == 175;
  bool double_plant_lower = mc_Entity.x == 176;
  bool double_plant = double_plant_upper || double_plant_lower;

  bool unWaveingFarm = mc_Entity.x == 83;

  bool end_portal = GetBlockID(119.0, blockID);

  //if((mc_Entity.x == 64 && worldNormal.z > 0.05) || (mc_Entity.x == 65 && -worldNormal.z > 0.05)
  //|| (mc_Entity.x == 66 && worldNormal.x > 0.05) || (mc_Entity.x == 67 && -worldNormal.x > 0.05))
  //if(mc_Entity.x == 64)

  if(worldNormal.x > 0.5){
    if(mc_Entity.x == 66) viewVector.y = -viewVector.y;
    if(mc_Entity.x == 92) viewVector.xz = -viewVector.xz;
  }

  if(worldNormal.x < -0.5){
    if(mc_Entity.x == 67) viewVector.y = -viewVector.y;
    if(mc_Entity.x == 92) viewVector.xz = -viewVector.xz;
  }

  if(worldNormal.y > 0.5){
    if(mc_Entity.x == 93) viewVector.xy = -viewVector.xy;
    if(mc_Entity.x == 94) viewVector.x = -viewVector.x;
    if(lily_pad) viewVector.xy = -viewVector.xy;
  }

  if(worldNormal.z > 0.5){
    if(mc_Entity.x == 64) viewVector.y = -viewVector.y;
    if(mc_Entity.x == 91) viewVector.xz = -viewVector.xz;
  }

  if(worldNormal.z < -0.5){
    if(mc_Entity.x == 65) viewVector.y = -viewVector.y;
    if(mc_Entity.x == 91) viewVector.xz = -viewVector.xz;
  }

  //if(mc_Entity.x == 119) position.xyz += 1000.0;

  //viewVector.y = -viewVector.y;

  //viewVector.xyz = -viewVector.xyz;
  //if((mc_Entity.x == 64 && worldNormal.z > 0.5) || (mc_Entity.x == 65 && -worldNormal.z > 0.5) || (mc_Entity.x == 66 && -worldNormal.x > 0.5) || (mc_Entity.x == 67 && worldNormal.x > 0.5)) viewVector.y = -viewVector.y;

  //if(mc_Entity.x == 10) position.xyz += 10.0;

  viewVector = mat3(gbufferModelView) * viewVector;

  //viewVector = mat3(gbufferModelView) * (wP * vec3(1.0, -1.0, 1.0));

  //if(mc_Entity.x == 94 && worldNormal.y * worldNormal.y < 0.001) viewVector = mat3(gbufferModelView) * (wP * vec3(1.0, -1.0, 1.0));
  //if(mc_Entity.x == 93 && worldNormal.y > 0.01) viewVector = mat3(gbufferModelView) * (wP * vec3(-1.0, -1.0, 1.0));
  //if(mc_Entity.x == 92 && worldNormal.y > 0.01) viewVector = mat3(gbufferModelView) * (wP * vec3(-1.0, 1.0, 1.0));

  wP += cameraPosition;

  tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
  binormal = cross(tangent, normal);

  id = 0.0;

  //if(mc_Entity.x == 11 || mc_Entity.x == 10) id = 10;
  //if(mc_Entity.x == 1) position.x += 1000;

  //leaves_type = -1.0;
  //if(mc_Entity.x > 1799 && mc_Entity.x < 1805) leaves_type = float(mc_Entity.x) - 1800.0;

  //if(mc_Entity.x == 1800) leaves_type = 0.0;
  //if(mc_Entity.x == 1803)

  //lukewarm_plants = 0.0;
  //if(mc_Entity.x == 1800 || mc_Entity.x == 1802 || mc_Entity.x == 1803 || mc_Entity.x == 1804 || plant || double_plant || unWaveingFarm) lukewarm_plants = 1.0;

  //bool glazed_terracotta = mc_Entity.x == 235;

  //bool farm = mc_Entity.x == 59 || mc_Entity.x == 141 || mc_Entity.x == 142 || mc_Entity.x == 207;

  if(double_plant || plant) {
    //if(length(vP.xyz) < 1.0)
    //position.xz += position.xz * clamp(1.0 - length(vP), 0.0, 1.0) * 0.1;
    //position.xz += (wP.xz - cameraPosition.xz) * 2.0 * (1.0 - length(vP.xyz)) * mix((1.0 + (mc_midTexCoord.y - gl_MultiTexCoord0.y)) * 0.632, float(mc_midTexCoord.y > gl_MultiTexCoord0.y), float(double_plant_lower || plant));

    vec2 noise = texture2D(noisetex, (position.xz) / 64.0).xz * 80.0;
    float time = frameTimeCounter * 0.74;
    float time2 = sin(frameTimeCounter * 0.48) * 1.21;
    vec2 noise2 = vec2(sin(time2 + noise.x * 1.3), sin(time2 + noise.y * 1.3));

    vec2 wave = vec2(sin((time + noise.x) * 3.14159 * 0.5 + noise2.y + time2), sin((time + noise.y) * 3.14159 * 0.5 + noise2.x + time2)) * 0.016;

    if(double_plant_lower || plant) {
      wave *= float(mc_midTexCoord.y > gl_MultiTexCoord0.y);
    }else{
      wave *= 1.0 + (mc_midTexCoord.y - gl_MultiTexCoord0.y);
    }

    if(double_plant) wave *= 0.632;

    position.xz += wave * lmcoord.y;
    id = 31.0;
    //cutoutBlock = 1.0;
  }

  if(leaves) {
    float time2 = sin(frameTimeCounter * 1.07);
    float time = frameTimeCounter * 1.14;

    vec3 noise  = texture2D(noisetex, (position.xz + vec2(time2, time * 0.45) * 0.019) / 8.0).xyz * 4.0;
         noise += texture2D(noisetex, (position.xz - vec2(time * 0.45, time2) * 0.019) / 4.0).xyz * 2.0;
         noise *= 0.74;

    //vec3 noise2 = vec3(sin(noise.x * time2), sin(noise.y * time2), sin(noise.z * time2)) * 0.1;

    vec3 wave = vec3(sin(time + noise.x), sin(time + noise.y), sin(time + noise.z));

    position.xyz += wave * 0.021 * lmcoord.y;
    id = 18.0;
    //cutoutBlock = 1.0;
  }

  //if(mc_Entity.x == 0.0 && blockEntityId != 63) position.x += 10.0;

  isBlockEntity = 0.0;
  if(mc_Entity.x == 0.0) {
    isBlockEntity = 1.0;
  }

  if(mc_Entity.x == 35) id = 35.0;
  if(unWaveingFarm) id = 83.0;

  #ifdef winter_mode
  spruce_leaves = 0.0;
  if(mc_Entity.x == 1801) spruce_leaves = 1.0;

  if(unWaveingFarm || leaves || plant || double_plant || mc_Entity.x == 2){
    if(color.r + color.g + color.b < 2.9 && spruce_leaves < 0.5) {
      vec3 gold = vec3(1.0, 0.782, 0.344);
      color.rgb = mix(color.rgb, gold, 0.782);
    }
  }
  #endif

  //if(mc_Entity.x == 1800) id = 119.0;

  //if(mc_Entity.x == 35)  id = 35.0;
  //if(mc_Entity.x == 235) id = 235.0;

  //position.xyz -= cameraPosition;
  //position = gbufferModelView * position;

  //if(mc_Entity.x == 91) position.y += 1.0;

  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * position;
  /*
  vec3 vpos = (gl_ProjectionMatrix * gl_ModelViewMatrix * position).xyz;

  float magnitude = length(vpos.xyz);
  vec3 normalizedVertPos = vpos.xyz / magnitude;

  vpos.xy = normalizedVertPos.xy / (1.0 + normalizedVertPos.z);
  //vpos.y = -vpos.y;

  gl_Position.xy = vpos.xy;
  */

  #ifdef Enabled_TAA
    gl_Position.xy += jitter * 2.0 * gl_Position.w;
  #endif
}
