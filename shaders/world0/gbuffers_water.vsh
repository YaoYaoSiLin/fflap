#version 130

#define Enabled_TAA

attribute vec4 at_tangent;
attribute vec3 mc_Entity;

uniform mat4 gbufferModelViewInverse;

uniform vec3 sunPosition;
uniform vec3 upPosition;

out float id;

out vec2 texcoord;
out vec2 lmcoord;

out vec3 normal;
out vec3 binormal;
out vec3 tangent;
out vec3 vP;

out float fading;
out vec3 sunLightingColorRaw;
out vec3 skyLightingColorRaw;

out vec4 biomesColor;

#define Gen_Water_Color

#ifdef Enabled_TAA
  uniform int frameCounter;

  uniform float viewWidth;
  uniform float viewHeight;

  vec2 resolution = vec2(viewWidth, viewHeight);
  vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);

  #include "../libs/jittering.glsl"
#endif

#include "../libs/common.inc"
#include "../libs/biomes.glsl"
#include "../libs/atmospheric.glsl"

float CalculateSunLightFading(in vec3 wP, in vec3 sP){
  float h = playerEyeLevel + defaultHightLevel;
  return clamp01(dot(sP * defaultHightLevel, vec3(0.0, h, 0.0)) / (h * defaultHightLevel) * 10.0);
}

void main() {
  id = 0.0;

  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

  biomesColor = gl_Color;

  id += CalculateMaskIDVert(8.0, mc_Entity.x)
      + CalculateMaskIDVert(79.0, mc_Entity.x)
      + CalculateMaskIDVert(90.0, mc_Entity.x)
      + CalculateMaskIDVert(165.0, mc_Entity.x)
      + CalculateMaskIDVert2(20.0, 95.0, mc_Entity.x)
      + CalculateMaskIDVert2(106.0, 160.0, mc_Entity.x);

  if(id == 8.0) {
    //id = 8.0;
    biomesColor.a = 0.05;
    biomesColor = CalculateWaterColor(biomesColor);
  }

  //if(mc_Entity.x == 165.0){
  //  id = 7.0;
  //}

  //if(mc_Entity.x == 20 || mc_Entity.x == 95) id = 20.0;
  //if(mc_Entity.x == 79) id = 79.0;
  //if(mc_Entity.x == 90) id = 90.0;
  //if(mc_Entity.x == 106 || mc_Entity.x == 160) id = 106.0;

  normal  = normalize(gl_NormalMatrix * gl_Normal);
  tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
  binormal = cross(tangent, normal);

  vec3 sP = mat3(gbufferModelViewInverse) * normalize(sunPosition);

  vP = (gl_ModelViewMatrix * gl_Vertex).xyz;
  vec3 wP = mat3(gbufferModelViewInverse) * vP;

  fading = CalculateSunLightFading(normalize(wP.xyz), sP);

  sunLightingColorRaw = (CalculateSky(normalize(sunPosition), sP, 0.0, 0.7));
  skyLightingColorRaw = (CalculateSky(normalize(upPosition), sP, 0.0, 1.0));

  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
  #ifdef Enabled_TAA
  gl_Position.xy += jittering * gl_Position.w * pixel * 0.5;
  #endif
}
