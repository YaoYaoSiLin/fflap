float bayer2(vec2 a){
    a = floor(a);
    return fract( dot(a, vec2(.5f, a.y * .75f)) );
}

#define bayer4(a)   (bayer2( .5f*(a))*.25f+bayer2(a))
#define bayer8(a)   (bayer4( .5f*(a))*.25f+bayer2(a))
#define bayer16(a)   (bayer8( .5f*(a))*.25f+bayer2(a))
#define bayer32(a)   (bayer16( .5f*(a))*.25f+bayer2(a))
#define bayer64(a)   (bayer32( .5f*(a))*.25f+bayer2(a))

float bayer_4x4(in vec2 a, vec2 r){
  return bayer4(a * r);
}

float bayer_8x8(in vec2 a, vec2 r){
  return bayer8(a * r);
}

float bayer_16x16(in vec2 a, vec2 r){
  return bayer16(a * r);
}

float bayer_32x32(in vec2 a, vec2 r){
  return bayer32(a * r);
}

float bayer_64x64(in vec2 a, vec2 r){
  return bayer64(a * r);
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.2031);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}