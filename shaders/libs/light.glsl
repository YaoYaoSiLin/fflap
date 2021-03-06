#define Simple 1
#define PCSS 2

#define Enabled_Soft_Shadow OFF               //[OFF Simple PCSS]

#define SHADOW_MAP_BIAS 0.9

const int   shadowMapResolution     = 2560;   //[512 768 1024 1536 2048 3072 4096]
const float shadowDistance		  		= 140.0;
const bool  generateShadowMipmap    = false;
const bool  shadowHardwareFiltering = false;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

float shadowPixel = 1.0 / float(shadowMapResolution);
vec2 shadowMapPixel = vec2(2048.0, 1.0 / 2048.0);

float CalculateSunLightFading(in vec3 wP, in vec3 sP){
  float h = playerEyeLevel + defaultHightLevel;
  return clamp01(dot(sP * defaultHightLevel, vec3(0.0, h, 0.0)) / (h * defaultHightLevel) * 10.0);
}

vec3 wP2sP(in vec4 wP, out float bias){
	vec4 sP = shadowModelView * wP;
       sP = shadowProjection * sP;
       sP /= sP.w;

  float distortion = length(sP.xy);

  bias = 1.0 / (mix(1.0, distortion, SHADOW_MAP_BIAS) / 0.95);
  //bias = 1.0 / mix(1.0, distortion, 0.7);

  sP.xy *= bias;
  //sP.z /= max(far / shadowDistance, 1.0);
  //sP.z *= 0.25;
  sP = sP * 0.5 + 0.5;
  sP.xy *= 0.8;
  sP.xy = min(sP.xy, 0.8);
  //sP.z = exp(sP.z * 128.0) / exp(128.0);
  //sP.z = exp(sP.z * 128.0);

	return sP.xyz;
}

vec3 wP2sP(in vec4 wP){
	vec4 sP = shadowModelView * wP;
       sP = shadowProjection * sP;
       sP /= sP.w;

  sP.xy /= mix(1.0, length(sP.xy), SHADOW_MAP_BIAS) / 0.95;

  sP = sP * 0.5 + 0.5;
  sP.xy *= 0.8;
  sP.xy = min(sP.xy, 0.8);

	return sP.xyz;
}

/*
vec3 CalculateFogLighting(in vec3 color, in float cameraHight, in float worldHight, in vec3 sunLightingColor, in vec3 skyLightingColor, in float fading){
	vec4 Wetness = vec4(0.0);
			 Wetness.rgb = (sunLightingColor * fading * 0.5 + skyLightingColor + 1.0) * 0.4;
			 Wetness.a = 0.504;
			 Wetness.a *= pow(clamp01(dot(sunLightingColor, vec3(0.333))), 5.0);
			 Wetness.a *= clamp01((-min(cameraHight, worldHight) + 120.0) / 48.0);
			 Wetness.a = clamp01(Wetness.a * 300.0) * 0.48;

	//color = mix(color, Wetness.rgb * 0.78, Wetness.a);
	//color *= pow(1.0 - Wetness.a, 2.0);

	return color;
}
*/
/*
float texture2DShadow(in sampler2D sampler, in vec3 coord){
  float pixel = shadowPixel * 0.25;
  coord.xy = round(coord.xy * shadowMapResolution) * shadowPixel;

  vec4 smoothShadow = vec4(step(coord.z, texture2D(sampler, coord.xy + vec2( pixel,  pixel)).x),
                           step(coord.z, texture2D(sampler, coord.xy + vec2( pixel, -pixel)).x),
                           step(coord.z, texture2D(sampler, coord.xy + vec2(-pixel,  pixel)).x),
                           step(coord.z, texture2D(sampler, coord.xy + vec2(-pixel, -pixel)).x));

  return dot(vec4(0.25), smoothShadow);
}
*/

/*
float CalculateRayMarchingShadow(in vec3 rayDirection, in vec3 viewVector){
  int steps = 8;
  float istep = 1.0 / steps;

  float sss = 0.0;

  float viewDistance = length(viewVector);
  float blockerDistance = length(rayDirection);

  float thickness = 0.125 - (viewDistance - blockerDistance) * 0.125;

  float dither = R2sq(texcoord * resolution - vec2(frameCounter) * 0.0039);

  rayDirection = normalize(rayDirection) * 0.03 * (blockerDistance * viewDistance) * istep;
  vec3 newVector = viewVector + rayDirection * dither - rayDirection * 0.5;

  for(int i = 0; i < steps; i++){
    newVector += rayDirection;

    vec3 testPoint = newVector;

    vec3 testCoord = nvec3(gbufferProjection * vec4(testPoint, 1.0)).xyz * 0.5 + 0.5;
    if(floor(testCoord.xy) != vec2(0.0)) break;

    vec3 samplePosition = nvec3(gbufferProjectionInverse * nvec4(vec3(testCoord.xy, texture(depthtex0, testCoord.xy).x) * 2.0 - 1.0));
         //samplePosition = mat3(gbufferModelViewInverse) * samplePosition;

    //if(length(newVector) - 0.05 > length(samplePosition)) sss = 1.0;

    //if((length(samplePosition) > length(testPoint) - thickness && length(samplePosition) < length(testPoint))) sss = 1.0;

    if((samplePosition.z < testPoint.z + thickness && samplePosition.z > testPoint.z)) sss = 1.0;
    //if(samplePosition.z > testPoint.z) sss = 1.0;
    //rayDirection *= 1.1;
    //if(samplePosition.z > testPoint.z) sss = 1.0;
  }

  return 1.0 - sss;
}
*/
#ifdef Enabled_ScreenSpace_Shadow
vec3 ScreenSpaceShadow(in vec3 lightDirection, in vec3 viewPosition){
  int steps = 8;
  float isteps = 1.0 / steps;

  float thickness = 0.2 / far;

  float t = 1.0;
  float hit = 1.0;

  //float dither = R2sq(texcoord * resolution - jittering);
  float dither = GetBlueNoise(depthtex2, texcoord, resolution.y, jitter);

  vec3 start = viewPosition;
  vec3 direction = lightDirection * isteps * 0.3533;

  float viewLength = length(viewPosition);
  float distanceFade = clamp01((-viewLength + shadowDistance - 16.0) / 32.0);

  //if(viewLength > shadowDistance - 16.0)
  if(bool(step(distanceFade, 0.99))){
    thickness *= 8.0;
    direction *= 8.0;
  }

  vec3 test = start + direction;
       test += dither * direction;

  float depth = (texture(depthtex0, texcoord).x);
  if(bool(step(depth, 0.7))) return vec3(1.0);

  //vec3 normal = normalDecode(texture2D(gnormal, texcoord).xy);

  for(int i = 0; i < steps; i++){
    vec3 coord = nvec3(gbufferProjection * vec4(test, 1.0)).xyz * 0.5 + 0.5;

    if(floor(coord.xyz) != vec3(0.0)) break;

    float h = texture(depthtex0, coord.xy).x;
    if(bool(step(h, 0.7))) continue;

    //vec3 samplePosition = nvec3(gbufferProjectionInverse * nvec4(vec3(coord.xy, h) * 2.0 - 1.0));

    float linearZ = linearizeDepth(coord.z);
    float linearD = linearizeDepth(h);
    float dist = linearZ - linearD;

    //direction *= 1.08;
    test += direction;
    if(dist < 1e-5) continue;

    if(dist < thickness) {
      return vec3(0.0);
    }
  }

  return vec3(1.0);
}
#endif

#define ESM_c 5.0

#if 1
float ShadowMapDepth(in sampler2D tex, in vec2 coord, in float scale){
  float c = exp2(ESM_c);
  //if(neg) c = -c;

  float depth = texture(tex, coord).x;
  float w0 = gaussianBlurWeights(0.001);

  float depthSum = 0.0;

  float radius = scale * shadowPixel;

  for(float i = -1.0; i <= 1.0; i += 1.0){
    for(float j = -1.0; j <= 1.0; j += 1.0){
     if(vec2(i, j) == vec2(0.0)) continue;
      vec2 offset = vec2(i, j);

      float weight = gaussianBlurWeights(offset + 0.0001);
      float di = texture(tex, coord.xy + offset * radius).x;
      depthSum += weight * exp(c * (di - depth));
    }
  }

  return exp(c * depth) * w0 * depthSum;
}

void TranslucentShadowMaps(out float translucentShadowMaps, out float irrdiance, in vec3 shadowCoord, in vec3 shadowNormal, in vec3 worldLightPosition){
  vec3 shadowViewPosition = nvec3(shadowProjectionInverse * nvec4(vec3(shadowCoord.xy, texture(shadowtex0, shadowCoord.xy).x) * 2.0 - 1.0));
  vec3 viewShadowPosition = nvec3(shadowProjectionInverse * nvec4(shadowCoord * 2.0 - 1.0));

  float distanceToLight = 1.0;
  float dist = length(viewShadowPosition - shadowViewPosition);

  float cost = max(0.0, dot(shadowNormal, worldLightPosition));

  float d = dist * cost;

  translucentShadowMaps = dist;
  irrdiance = cost;
}

float GetDepth(in sampler2D sampler, in vec2 coord, in float distort, in float dither){
  float result = 1.0;
  float totalWeight = 0.0;

  coord.xy = (coord.xy * float(shadowMapResolution));

  for(float x = -1.0; x <= 1.0; x += 1.0){
    for(float y = -1.0; y <= 1.0; y += 1.0){
      vec2 offset = vec2(x, y);
           offset = offset / max(1e-5, length(offset));// * sqrt(2.0);
           offset *= distort;
      //     offset = RotateDirection(offset, vec2(dither, 1.0 - dither));
      //     offset -= offset.yx * dither;

      offset = coord.xy + offset;
      //offset = round(coord.xy + offset) * shadowPixel;
      //result += texture(sampler, offset).x;
      //result = min(result, texture(sampler, offset).x);
      result = min(result, texelFetch(sampler, ivec2(0.5 + offset), 0).x);
    }
  }

  //result *= 0.04;

  return result;
}

float somethingelse(in vec2 uv, in float maxRadius, in float distort, in float dither){
  float sum = 0.0;
  float d0 = texture(shadowtex0, uv).x;

  int count = 0;

  int steps = 8;
  float invsteps = 1.0 / float(steps);
  float alpha = invsteps * 2.0 * Pi;

  sum = d0;

  float radius = maxRadius * distort * shadowPixel;

  for(int i = 0; i < steps; ++i){
    float r = (float(i) + float(steps) - dither * float(steps)) * alpha;

    vec2 offset = vec2(cos(r), sin(r));
         offset -= offset * (1.0 - dither);
         offset *= radius;

    //float depthSample = texture(shadowtex0, uv + offset).x;
    float depthSample = GetDepth(shadowtex0, uv + offset, distort, dither);

    if(depthSample < d0){
      count++;
      sum = depthSample;
    }
  }

  float nonresult = step(float(count), 0.5);

  //sum /= float(count);
  //sum += d0 * nonresult;

  return sum;
}

float GetShadow(in sampler2D shadowtex, in vec3 coord, in float diffthresh, in float distort, in float dither){
  float result = 0.0;
  float totalWeight = 0.0;

  coord.xy = (coord.xy * float(shadowMapResolution));

  for(float x = -1.0; x <= 1.0; x += 1.0){
    for(float y = -1.0; y <= 1.0; y += 1.0){
      vec2 offset = vec2(x, y);
           offset = offset / max(1e-5, length(offset));// * sqrt(2.0);
           offset *= distort;
      //     offset = RotateDirection(offset, vec2(dither, 1.0 - dither));
      //     offset -= offset.yx * dither;
      float z = coord.z - diffthresh;// * max(1.0, length(offset));

      //offset = round(coord.xy + offset) * shadowPixel;
      //result += step(z, texture(shadowtex1, offset).x);

      offset = coord.xy + offset;
      result += step(z, texelFetch(shadowtex1, ivec2(offset + 0.5), 0).x);
    }
  }

  result *= 1.0 / 9.0;

  return result;
}
/*
float PCF_Filter(in vec3 coord){
  float sum = 0.0;

  sum += textureGather()

  return sum;
}
*/

float shadowGather(in sampler2D sampler, in vec2 coord){
  coord = round(coord * shadowMapPixel.x) * shadowMapPixel.y;

  return (  texture(sampler, coord + vec2(shadowMapPixel.y, 0.0)).x
          + texture(sampler, coord - vec2(shadowMapPixel.y, 0.0)).x
          + texture(sampler, coord + vec2(0.0, shadowMapPixel.y)).x
          + texture(sampler, coord - vec2(0.0, shadowMapPixel.y)).x) * 0.25;
}

float GetShadow(in sampler2D sampler, in vec3 coord) {
  return step(coord.z, texture(sampler, coord.xy).x);
}

float shadowGather(in sampler2D sampler, in vec3 coord){
  vec2 texSize = vec2(float(shadowMapResolution), shadowPixel);

  coord.xy = round(coord.xy * texSize.x) * texSize.y;

  return (  GetShadow(sampler, coord + vec3(texSize.y, 0.0, 0.0))
          + GetShadow(sampler, coord - vec3(texSize.y, 0.0, 0.0))
          + GetShadow(sampler, coord + vec3(0.0, texSize.y, 0.0))
          + GetShadow(sampler, coord - vec3(0.0, texSize.y, 0.0))) * 0.25;
}

float shadowGatherOffset(in sampler2D sampler, in vec3 coord, in vec2 offset){
  vec2 texSize = vec2(float(shadowMapResolution), shadowPixel);

  return shadowGather(sampler, coord + vec3(offset * texSize.y, 0.0));
}

float shadowGatherOffset(in sampler2D sampler, in vec2 coord, in vec2 offset){
  return shadowGather(sampler, coord + offset * shadowMapPixel.y);
}

float FindBlocker(in vec3 shadowMapCoord, out int blockerCount){
  float blocker = 0.0;

  vec2 dither = vec2(GetBlueNoise(depthtex2, texcoord, resolution.y, jittering),
                     GetBlueNoise(depthtex2, 1.0 - texcoord, resolution.y, jittering));

  //int blockerCount = 0;

  for(int i = 0; i < 8; i++){
    float angle = (float(i) + 1.0) * 0.125 * 2.0 * Pi;
    vec2 direction = vec2(cos(angle), sin(angle));
         direction = RotateDirection(direction, dither);

    vec2 coord = shadowMapCoord.xy + direction * shadowMapPixel.y * 2.0;
         coord = coord * 2.0 - 1.0;
         coord /= mix(1.0, length(coord), SHADOW_MAP_BIAS) / 0.95;
         coord = coord * 0.5 + 0.5;
         coord.xy = coord.xy * 0.8;

    if(coord.x < shadowMapPixel.y || coord.y < shadowMapPixel.y || coord.x > 0.8 - shadowMapPixel.y || coord.y > 0.8 - shadowMapPixel.y) continue;

    float depth = texture(shadowtex0, coord).x;

    //float depth = (  shadowGather(shadowtex1, coord + vec2(shadowMapPixel.y, 0.0))
    //               + shadowGather(shadowtex1, coord - vec2(shadowMapPixel.y, 0.0))
    //               + shadowGather(shadowtex1, coord + vec2(0.0, shadowMapPixel.y))
    //               + shadowGather(shadowtex1, coord - vec2(0.0, shadowMapPixel.y))) * 0.25;

    if(bool(step(depth, shadowMapCoord.z))) {
      blocker += depth;
      blockerCount++;
    }
  }

  blocker /= max(float(blockerCount), 1.0);

  return blocker;
}

vec4 CalculateShading(in sampler2D mainShadowTex, in sampler2D secShadowTex, in vec4 wP, in float preShadeShadow, in vec3 normal){
  float viewLength = length(wP.xyz);

  if(viewLength > shadowDistance) return vec4(0.0);

  float distanceFade = clamp01((-viewLength + shadowDistance - 16.0) / 32.0);

  vec3 sunDirectLighting = vec3(1.0);
  float shading = 0.0;

  float bias = 0.0;

  vec3 shadowPosition = wP2sP(wP, bias);
  bias *= 0.125;
  bias = 1.0;//

  const float bias_pix = 0.0003;
	vec2 bias_offcenter = abs(shadowPosition.xy * 2.0 - 1.0);

  float diffthresh = (1.0 + (1.0 - preShadeShadow) + viewLength * 0.0625);// + (1.0 - preShadeShadow) * (1.0 + viewLength * 0.0625);// + preShadeShadow * (1.0 + viewLength * 0.04);
        diffthresh = shadowPixel;

  float c = exp2(ESM_c);

  if(floor(shadowPosition.xyz) == vec3(0.0)){
    //float dither = R2sq(texcoord * resolution - jittering);
    float dither = GetBlueNoise(depthtex2, texcoord, resolution.y, jittering);
    mat2 rotate = mat2(cos(dither * 2.0 * Pi), -sin(dither * 2.0 * Pi), sin(dither * 2.0 * Pi), cos(dither * 2.0 * Pi));

    float subShadow = 0.0;

    vec3 shadowMapNormal = mat3(gbufferModelView) * (texture2D(shadowcolor1, shadowPosition.xy).xyz * 2.0 - 1.0);
    vec3 worldLightPosition = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    //TranslucentShadowMaps(translucentShadowMaps, shadowMapsIrrdiance, shadowPosition, shadowMapNormal, worldLightPosition);

    #if 1
      //shadowPosition.xy -= normal.xy * shadowPixel;

      //shadowPosition.xy = round(shadowPosition.xy * float(shadowMapResolution)) * shadowPixel;

      float d1 = texture(shadowtex1, shadowPosition.xy).x;
      float d0 = texture(shadowtex0, shadowPosition.xy).x;

      shadowPosition.z -= diffthresh * (1.0 + viewLength * 0.01);

      shading = step(shadowPosition.z, d1);

      vec4 p0 = shadowProjectionInverse * vec4(vec3(shadowPosition.xy, d0) * 2.0 - 1.0, 1.0);
      vec4 p1 = shadowProjectionInverse * vec4(vec3(shadowPosition.xy, d1) * 2.0 - 1.0, 1.0);

      float shadowDepth = length(p1.xyz - p0.xyz);
      
      //vec3 halfDirection = normalize(normalize(shadowLightPosition) - ref)
      vec3 f = F(vec3(0.02), normalize(shadowLightPosition), shadowMapNormal);

      float ldotln = dot(normalize(shadowLightPosition), shadowMapNormal);

      //sunDirectLighting = mix(texture(shadowcolor1, shadowPosition.xy).rgb, vec3(1.0), 1.0 - step(d0, d));

      //shading = max(0.0, shading - step(shadowPosition.z - diffthresh * 1.0, d0));

      float alpha = texture2D(shadowcolor0, shadowPosition.xy).a;
      shadowDepth = shadowDepth + alpha * alpha;
      shadowDepth = min(shadowDepth, texture2D(shadowcolor1, shadowPosition.xy).a * 16.0);
      //shadowDepth /= max(1e-5, ldotln);

      vec4 colored = vec4(0.0);
      colored.rgb = decodeGamma(texture2D(shadowcolor0, shadowPosition.xy).rgb);

      vec3 absorptioncoe =  (1.0 - colored.rgb) * pow5(alpha) * 10.47 / (length(colored.rgb + 0.005));//pow3(alpha) * (1.0 - colored.rgb) * Pi * 2.0;
      vec3 scatteringcoe = pow2(alpha) * vec3(Pi) * 2.0;

      colored.rgb = exp(-(scatteringcoe + absorptioncoe) * shadowDepth);
      colored.rgb *= 1.0 - f;

      colored.a = max(0.0, shading - step(shadowPosition.z - diffthresh * 1.0, d0));
      //colored.a = 1.0 - step(d1 - shadowMapPixel.y * 3.0, d0);

      //colored.a = sqrt(colored.a);
      //shading = sqrt(shading);

      sunDirectLighting = mix(vec3(1.0), colored.rgb, colored.a) * shading;
      //sunDirectLighting = colored.rgb;

      //shading = shadow2D(mainShadowTex, shadowPosition - vec3(0.0, 0.0, diffthresh)).x;
      //subShadow = shadow2D(secShadowTex, shadowPosition - vec3(0.0, 0.0, diffthresh)).x
    #else
      //vec3 shadowMapCoord = wP2sP(wP);
      //shading = step(shadowMapCoord.z, texture(shadowtex1, shadowMapCoord.xy).x + shadowMapPixel.y);

      //shading = 0.0;

      vec4 shadowMapCoord = shadowProjection * shadowModelView * (wP); shadowMapCoord /= shadowMapCoord.w;
           shadowMapCoord = shadowMapCoord * 0.5 + 0.5;

      float dither1 = GetBlueNoise(depthtex2, texcoord, resolution.y, jittering);
      float dither2 = GetBlueNoise(depthtex2, 1.0 - texcoord, resolution.y, jittering);

      float umbra = 0.0;

      float ndotl = dot(normalize(shadowLightPosition), normal);
      if(bool(step(ndotl, 1e-5))) return vec4(vec3(0.0), 1.0);
      
      float receiver = shadowMapCoord.z - shadowMapPixel.y;
            //receiver -= shadowMapPixel.y / ndotl * 0.04;
            receiver -= shadowMapPixel.y * max(0.05, length(shadowMapCoord.xy * 2.0 - 1.0)) * 32.0;

      const vec4 bitShL = vec4(16777216.0, 65536.0, 256.0, 1.0);
      const vec4 bitShR = vec4(1.0/16777216.0, 1.0/65536.0, 1.0/256.0, 1.0);
        /*
      for(int i = 0; i < 8; i++){
        float angle = float(i + 1.0) * 0.125 * 2.0 * Pi;
        vec2 direction = vec2(cos(angle), sin(angle));
        //     direction = RotateDirection(direction, vec2(dither1, dither2));

        vec2 coord = shadowMapCoord.xy + direction * shadowMapPixel.y * 2.0;
             coord = coord * 2.0 - 1.0;
             coord /= mix(1.0, length(coord), SHADOW_MAP_BIAS) / 0.95;
             coord = coord * 0.5 + 0.5;
             coord.xy = coord.xy * 0.8;

        if(coord.x < shadowMapPixel.y || coord.y < shadowMapPixel.y || coord.x > 0.8 - shadowMapPixel.y || coord.y > 0.8 - shadowMapPixel.y) continue;
        //coord.xy = round(coord.xy * shadowMapPixel.x * 0.25) * shadowMapPixel.y * 4.0;

        //float depth = dot(bitShR.zw, texture2D(gaux2, coord.xy).xy);
        float depth = texture(shadowtex0, coord).x;

        umbra += step(receiver - shadowMapPixel.y * length(direction * 2.0) * 1.414, depth);
      }

      umbra *= 0.125;
      umbra = step(umbra, 0.01);
        */
      vec3 red = vec3(1.0, 0.0, 0.0);
      vec3 green = vec3(0.0, 1.0, 0.0);
      vec3 blue = vec3(0.0, 0.0, 1.0);
      vec3 magenta = vec3(1.0, 0.0, 1.0);

      //if(bool(umbra)) return vec4(magenta, 1.0);

      //if(fullBlack) return vec4(red, 1.0);
      //if(fullWhite) return vec4(magenta, 1.0);

      //if(!fullBlack && !fullWhite) return vec4(magenta, 1.0);

      //if(bool(step(0.875, shading2))) return vec4(vec3(1.0), 1.0);
      //if(bool(step(shading2, 0.01))) return vec4(vec3(0.0), 1.0);

      //if(bool(step(0.9, shading2)) || bool(step(shading2, 0.1))) return vec4(vec3(shading2), 1.0);

      //if(bool(step(0.9, shading2))) return vec4(magenta, 1.0);

      //if(bool(step(shading2, 0.1))) return vec4(vec3(0.0), 1.0);
      //if(bool(step(0.8, earlyShading1))) return vec4(vec3(1.0), 1.0);

      float blocker = 0.0; int blockerCount = 0;
      //if(!fullBlack && !fullWhite)
      blocker = FindBlocker(vec3(shadowMapCoord.xy, receiver), blockerCount);

      if(blockerCount < 3) return vec4(vec3(1.0), 1.0);

      //receiver -= viewLength * shadowMapPixel.y * 0.08;
      //receiver -= shadowMapPixel.y / saturate(ndotl) * 0.08;

      float penumbra = (receiver - blocker) * 8.0 / blocker;
            penumbra = clamp(penumbra, 0.05, 2.0);

      for(int i = 0; i < 8; i++){
        float angle = (float(i) + 1.0) * 0.125 * 2.0 * Pi;
        vec2 direction = vec2(cos(angle), sin(angle));
             direction = RotateDirection(direction, vec2(dither1, dither2));
             direction *= penumbra;

        vec2 coord = shadowMapCoord.xy + direction * shadowMapPixel.y;
             coord = coord * 2.0 - 1.0; float distortion = mix(1.0, length(coord), SHADOW_MAP_BIAS) / 0.95;
             coord /= distortion;
             coord = coord * 0.5 + 0.5;
             coord.xy = coord.xy * 0.8;

        if(coord.x < shadowMapPixel.y || coord.y < shadowMapPixel.y || coord.x > 0.8 - shadowMapPixel.y || coord.y > 0.8 - shadowMapPixel.y) continue;

        //shading += (  shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2( 2.0,  0.0))
        //            + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2(-2.0,  0.0))
        //            + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2( 0.0,  2.0))
        //            + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2( 0.0, -2.0))) * 0.25;

        //if(bool(step(penumbra, 0.2) + step(0.5, penumbra)))
          shading += GetShadow(shadowtex1, vec3(coord, receiver));
        //else
        //  shading += (  shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2( 1.0,  1.0))
        //              + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2( 1.0, -1.0))
        //              + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2(-0.0, -1.0))
        //              + shadowGatherOffset(shadowtex1, vec3(coord, receiver), vec2(-1.0,  1.0))) * 0.25;

        //float depth = (  shadowGather(shadowtex1, coord + vec2(shadowMapPixel.y, 0.0))
        //               + shadowGather(shadowtex1, coord - vec2(shadowMapPixel.y, 0.0))
        //               + shadowGather(shadowtex1, coord + vec2(0.0, shadowMapPixel.y))
        //               + shadowGather(shadowtex1, coord - vec2(0.0, shadowMapPixel.y))) * 0.25;

        //shading += step(receiver, depth + shadowMapPixel.y);

        //shading += shadowGather(shadowtex1, vec3(coord, receiver));

        //shading += (  shadowGather(shadowtex1, vec3(coord + vec2(shadowMapPixel.y, 0.0) * 2.0, receiver))
        //            + shadowGather(shadowtex1, vec3(coord - vec2(shadowMapPixel.y, 0.0) * 2.0, receiver))
        //            + shadowGather(shadowtex1, vec3(coord + vec2(0.0, shadowMapPixel.y) * 2.0, receiver))
        //            + shadowGather(shadowtex1, vec3(coord - vec2(0.0, shadowMapPixel.y) * 2.0, receiver))) * 0.25;

        //shading += (  shadowGather(shadowtex1, vec3(coord + vec2(shadowMapPixel.y), receiver))
        //            + shadowGather(shadowtex1, vec3(coord - vec2(shadowMapPixel.y), receiver))
        //            + shadowGather(shadowtex1, vec3(coord + vec2(shadowMapPixel.y, -shadowMapPixel.y), receiver))
        //            + shadowGather(shadowtex1, vec3(coord - vec2(shadowMapPixel.y, -shadowMapPixel.y), receiver))) * 0.25;
      }

      shading *= 0.125;
      //shading = pow(shading, 2.2);

      sunDirectLighting = vec3(shading);
      /*
      vec2 coord = shadowMapCoord.xy;
           coord = coord * 2.0 - 1.0;
           coord /= mix(1.0, length(coord), SHADOW_MAP_BIAS) / 0.95;
           coord = coord * 0.5 + 0.5;
           //coord.xy = coord.xy * 0.8;

      const vec4 bitShL = vec4(16777216.0, 65536.0, 256.0, 1.0);
      const vec4 bitShR = vec4(1.0/16777216.0, 1.0/65536.0, 1.0/256.0, 1.0);

      float d = dot(bitShR.zw, texture2D(gaux2, coord.xy).xy);

      sunDirectLighting = vec3(step(receiver, d));
      */
    #endif

    /*
    float dsum = 0.0;
    float weights = 0.0;
    float w0 = gaussianBlurWeights(1e-5);

    float d = texture(shadowtex0, shadowPosition.xy).x;

    for(float i = -1.0; i <= 1.0; i += 1.0){
      for(float j = -1.0; j <= 1.0; j += 1.0){
        vec2 offset = vec2(i, j);
        float weight = gaussianBlurWeights(offset + 1e-5);

        if(vec2(i, j) == vec2(0.0)) continue;

        float di = texture(shadowtex0, shadowPosition.xy + offset * shadowPixel).x;

        dsum += weight * exp(c * (di - d));
        weights += weight;
      }
    }

    d = exp(c * d);
    d = w0 * d * dsum;

    sunDirectLighting = saturate(vec3(exp(-c * (shadowPosition.z - diffthresh)) * d * 127.0 - 40.0));
    */
    //d = exp(c * d);
    //d *= exp(c);
//shadowPosition.z = exp(c0 * shadowPosition.z) / exp(c0);
    #if 0
    shading = 0.0;
    vec4 colored;

    int steps = 8;
    float invsteps = 1.0 / float(steps);
    float alpha = 2.0 * Pi * invsteps;

    float radius = shadowPixel;
    float maxRadius = 12.0;

    float blocker = (shadowPosition.xy, maxRadius, bias, dither);
    float receiver = shadowPosition.z - diffthresh * maxRadius;

    float penumbra = (receiver - blocker) / blocker;
          penumbra = (1.0 - exp(-penumbra * 3.0)) * maxRadius;
          penumbra = clamp(penumbra, 1.0, maxRadius);
          //penumbra = maxRadius;

    radius *= penumbra;

    float expdiffthresh = exp(c * diffthresh * 0.5);
    //float z = exp(-c * shadowPosition.z) * expdiffthresh;
    float z = shadowPosition.z;

    float d0 = texture(shadowtex0, shadowPosition.xy).x;

    int count = 0;

    diffthresh = 1.0 + (viewLength * 0.0625);
    diffthresh = shadowPixel * (1.0 + viewLength * 0.019);

    normal = mat3(shadowModelView) * mat3(gbufferModelViewInverse) * normal;
    vec2 normalBias = normal.xy * shadowPixel;

    shadowPosition.xy += normal.xy * shadowPixel;
    shadowPosition.z -= diffthresh;

    //shadowPosition.xy += normal.xy * shadowPixel;

      for(int i = 0; i < steps; ++i){
        float r = (float(i) + float(steps) - dither * float(steps)) * alpha;

        vec2 offset = vec2(cos(r), sin(r));
             offset -= offset * (1.0 - dither);
             offset *= radius;

          vec3 coord = vec3(shadowPosition.xy + offset, shadowPosition.z);
               coord.xy += normal.xy * length(offset);
               coord.z -= diffthresh * length(offset);
               //coord.xy = round(coord.xy * float(shadowMapResolution)) * shadowPixel;
               //coord.z -= max(1.0, length(offset * float(shadowMapResolution))) * diffthresh;
               //coord.z -= diffthresh;
               //coord.xy += normalBias * sqrt(1.0 + length(offset));
               //coord.z -= shadowPixel * (1.0 + 0.5 * length(offset * float(shadowMapResolution)) * viewLength * 0.5 * (1.0 - preShadeShadow));

          //shading += step(coord.z, texture(shadowtex1, coord.xy).x);
          shading += GetShadow(shadowtex1, coord, 0.0, bias, dither);
          count++;

          //vec3 absorption =

          //float alphaSample = texture(shadowtex0, coord.xy).x;
          //vec4 coloredSample = texture2D(shadowcolor1, coord.xy);
          //     coloredSample.rgb = exp(-coloredSample.a * Pi * (1.0 - coloredSample.rgb));

          //colored += vec4(coloredSample.rgb, step(z, alphaSample));
    }

    //shading = 1.0 - min(1.0, 400.0 * shading);

    shading /= float(count);
    colored /= float(count);

    shading = sqrt(shading);
    colored = sqrt(colored);

    sunDirectLighting = shading * mix(vec3(1.0), colored.rgb, (shading - colored.a));
    sunDirectLighting = sunDirectLighting * sunDirectLighting;
    sunDirectLighting = vec3(shading * (shading));
    #endif
    //sunDirectLighting = vec3(step(linearizeDepth(shadowPosition.z), linearizeDepth(texture(shadowtex0, shadowPosition.xy).x) + 0.000002));

    //shading /= float(count) + step(float(count), 0.5);
    //blur /= float(blurcount);
    //shading = blur;
    //shading = blur;

    //dith
    /*
    for(int i = 0; i < shading_samples; i++){
        float r = (float(i) + dither) * inv_ssamples * 2.0 * Pi;
        vec2 offset = vec2(cos(r), sin(r));
             //offset += (offset.xy);
             offset *= radius;

        #if 0
        float d = GetShadowMap(shadowtex1, shadowPosition.xy + offset, bias, false);
        //float d = texture(shadowtex0, shadowPosition.xy + offset * bias).x;
        //d = exp(c * d);
        float translucentDepth = GetShadowMap(shadowtex0, shadowPosition.xy + offset, bias, false);

        colorShading.rgb += texture2D(shadowcolor1, shadowPosition.xy + offset).rgb;
        colorShading.a += clamp01(translucentDepth * z * 255.0 - 80.0);
        //shadowblockDepth += texture2D(shadowcolor1, shadowPosition.xy + offset).a * texture2D(shadowcolor0, shadowPosition.xy + offset).a;

        shading += clamp01(clamp01(d * z) * 255.0 - 80.0);
        #endif

        float d = texture(shadowtex0, shadowPosition.xy + offset * bias).x;
        float shadingSample = step(shadowPosition.z - shadowPixel * penumbra, d);

        if(shading0 < d){
          shading1 += shadingSample;
          weights += 1.0;
        }

        shading += shadingSample;

        //shading = max(shading, clamp01(d * z * 255.0 - 80.0));
        //shading2 = max(shading2, clamp01(d * z * 255.0 - 80.0));
    //  }
    }

    float nonresult = step(weights, 0.5);

    shading1 = shading1 / (weights + nonresult) + nonresult * step(shadowPosition.z - shadowPixel * penumbra, shading0);

    shading *= inv_ssamples;
    */
    //shading = clamp01(shading1 + (shading));

    //float viewLength =
    /*
    radius *= 1.0;

    float dl = clamp(viewLength * 0.1, 1.0, 3.0);
    float l = clamp(1.0 / penumbra * dl, 0.0416, 0.125);

    float r = 0.0;

    while(r <= 1.0){
      float ra = (r + dither * l) * 2.0 * Pi;
      vec2 offset = vec2(cos(ra), sin(ra));
           offset += (offset.yx * dither + offset * dither) * 0.5;
           offset *= radius * 0.5;

      float d = texture(shadowtex0, shadowPosition.xy + offset * bias).x;
      float shadingSample = step(shadowPosition.z - shadowPixel, d);

      shading += shadingSample;

      weights += 1.0;
      if(weights > 25.0) break;
      r += l;
    }

    shading *= l;
    */
    //shading = min(shading, 1.0);

    //if(weights > 8.5) shading = 0.0;

    //shading = pow(shading, 0.2);
    //colorShading *= inv_ssamples;
    //colorShading.rgb = rgb2L(colorShading.rgb);
    //shadowblockDepth /= 9.0;
    //vec3 blockAbsorption = 1.0 - min(1.0, exp(-shadowblockDepth * Pi * (1.0 - colorShading)));

    //colorShading.a = max(0.0, shading - colorShading.a);

    //colorShading.a = max(0.0, shading - colorShading.a);
    //shading = colorShading.a;

    //float d = GetShadowMap(shadowtex1, shadowPosition.xy, bias, false);
    //shading = clamp01(d * z * exp2(8.0) - exp2(6.3));

    //sunDirectLighting = L2Gamma(sunDirectLighting);

    //sunDirectLighting *= mix(colorShading.rgb * colorShading.rgb, vec3(1.0), colorShading.a);
    //sunDirectLighting = sqrt(sunDirectLighting);

    //shading = step(shadowPosition.z - diffthresh, texture(shadowtex0, shadowPosition.xy).x);
    //shading = clamp01((shading - 0.0625 * 5.0) * 8.6681 * 3.0);
    //shading = clamp01(exp(texture(shadowtex0, shadowPosition.xy).x * c) * exp(-c * z));

    /*
    float d0 = shadowPosition.z;
    float d = 0.0;

    float weight0 = gaussianBlurWeights(vec2(0.0001));
    float weights = 0.0;

    for(float i = 1.0; i <= 3.0; i += 1.0){
      //for(float j = -1.0; j <= 1.0; j += 1.0){
        float weight = gaussianBlurWeights(i - 1.0 + (0.0001));

        d += weight * exp(-c * d * (1.0 + i * 0.05));
        weights += weight;
        //d = weight0 * exp(c * d0) * weight * exp()
      //}
    }

    //d = exp(-c * d0);
    d /= weights;
    shading = clamp01(d * z);
    */

    //shading = clamp01(exp(c * -d) * z);
    //shading = clamp01(exp(-c * (d - z)));
    //shading = texcoord.x > 0.5 ? SampleTextureCatmullRom(shadowtex0, shadowPosition.xy, vec2(shadowMapResolution)).x : z;
    //shading = exp(c * d) * exp(c * d * 2.0);
    //shading = clamp01(exp(100.0 * -d) * exp(100.0 * shadowPosition.z));

    /*
      float weights = 0.0;

      for(float i = -1.0; i <= 1.0; i += 1.0){
        for(float j = -1.0; j <= 1.0; j += 1.0){
          vec2 offset = (vec2(i, j) - vec2(i, j) * dither * 0.05) * rotate * shadowPixel * bias;
          //shading += shadow2D(mainShadowTex, shadowPosition - vec3(offset, diffthresh)).x;
          //subShadow += shadow2D(secShadowTex, shadowPosition - vec3(offset, diffthresh)).x;

          float weight = gaussianBlurWeights(vec2(i, j) + 0.0001);
          weights += weight;

          float d = texture(shadowtex0, shadowPosition.xy + offset).x;
          shading += clamp01(exp(weight * 4096.0 * (d - shadowPosition.z + shadowPixel)));

        }
      }

      shading /= 9.0;
      subShadow /= 9.0;
*/
    #if 0
    float blocker = 0.0;
    float minShadowDepth = 1.0;
    float receiver = shadowPosition.z - diffthresh * 1.0;

    vec3 shadingColor = vec3(0.0);

    int blockerCount = 0;

    for(int i = 0; i < 4; i++){
      vec2 blockerSearch = shadowPosition.xy + shadowPixel * TRLB[i] * 4.0 * rotate;

      vec4 depthGather = textureGather(shadowcolor0, blockerSearch);
      float shadowMapDepth = dot(depthGather, vec4(0.25));

      minShadowDepth = min(minShadowDepth, shadowMapDepth);
      blocker += minShadowDepth;

      blockerCount++;
    }

    blocker /= blockerCount;

    float penumbra = (receiver - blocker) / blocker;
          penumbra = clamp(penumbra, 0.0625, 4.0) * 16.0;

    float alpha = bias * shadowPixel;

    for(float i = -1.0; i <= 1.0; i += 1.0){
      for(float j = -1.0; j <= 1.0; j += 1.0){
        vec2 offset = vec2(i, j);// + (offset - offset * dither * 0.05) * 1.052 * rotate * radius * penumbra
             //offset = offset - offset.yx * dither * 0.0156 * radius;
             offset = (offset - offset.xy * dither * 0.159) * alpha * penumbra * rotate;

        vec2 coord = shadowPosition.xy + offset;
        shading += shadow2D(mainShadowTex, vec3(coord, shadowPosition.z - diffthresh)).x;

        vec3 sampleColor = texture2D(shadowcolor1, coord).rgb * (1.0 - texture(shadowcolor0, coord).a);
        subShadow = shadow2D(secShadowTex, vec3(coord, shadowPosition.z - diffthresh)).x;
        shadingColor += mix(sampleColor, vec3(1.0), subShadow);
      }
    }

    shading /= 9.0;
    shadingColor /= 9.0;

    sunDirectLighting = shading * shadingColor;
    #endif


    //float blocker = texture(shadowcolor0, shadowPosition.xy).x;
    //float receiver = shadowPosition.z - diffthresh;
    //float penumbra = (receiver - blocker) / blocker;

    //float c = 2048.0;

    //if(d > z) shading = vec3(0.0);
    //else shading = vec3(1.0);
    //shading = (float(blocker > receiver));
    //shading = vec3(clamp01(exp(step(z, d) - 16.0 * z)));
    //shading = vec3( clamp01( exp(2048.0 * (d - z)) ) );
    //shading = vec3(shadow2D(shadowtex1, shadowPosition - vec3(0.0, 0.0, diffthresh)).x);
    //shading = (1.0 - clamp01( exp(-2048.0 * (blocker - receiver)) ) );
    //shading = (shading) - vec3(step(receiver, blocker));
    //shading = step(receiver, blocker) + shading * min(1.0, penumbra * 2.0);

    //shading = shading.rrr;


    #if 0
    Enabled_Soft_Shadow != PCSS
    sunDirectLighting = vec3(shading);

    float shadingAlpha = texture2D(shadowcolor0, shadowPosition.xy).a;
    vec4 shadingColor = texture2D(shadowcolor1, shadowPosition.xy);
         shadingColor.rgb *= 1.0 - shadingAlpha;
         shadingColor.rgb = rgb2L(shadingColor.rgb);

    //vec3 colorShading = mix(shadingColor.rgb, vec3(1.0, 0.0, 0.0), subShadow);
    sunDirectLighting *= mix(shadingColor.rgb, vec3(1.0), subShadow);
    #endif
  }
  //sunDirectLighting = vec3(shading);

  return vec4(sunDirectLighting, distanceFade);
}
#else
vec4 CalculateShading(in sampler2DShadow mainShadowTex, in sampler2DShadow secShadowTex, in vec4 wP, in float preShadeShadow){
  float bias = 0.0;

  vec3 shading = vec3(1.0);

  vec3 shadowPosition = wP2sP(wP, bias);
  bias *= 0.125;

  float diffthresh = 1.0 / float(shadowMapResolution);

  shading = vec3(shadow2D(mainShadowTex, shadowPosition - vec3(0.0, 0.0, diffthresh)).x);

  float subShadow = shadow2D(secShadowTex, shadowPosition - vec3(0.0, 0.0, diffthresh)).x;

  vec3 colorShading = texture2D(shadowcolor1, shadowPosition.xy).rgb;
  shading = mix(colorShading, vec3(1.0), subShadow) * shading;

  return vec4(shading, 1.0);
}
#endif
