/*
    XorDev's Procedural Texture Upscaler:

    DO NOT redistribute this source code.
    If you use this shader in a video, credit is greatly appreciated but not required.
*/
#version 130
#define Scale1 4.     //Texture1 scale [2. 4. 8. 16. 32. 64.]
#define Scale2 16.    //Texture2 scale [4. 8. 16. 32. 64. 128.]
#define Intensity1 2. //Scale1's intensity [.0 .2 .5 .8 1. 1.5 2. 3.5 5.]
#define Intensity2 1. //Scale2's intensity [.0 .2 .5 .8 1. 1.5 2. 3.5 5.]
#define Light 1.      //Light blending amount [.2 .5 .8 1. 1.5 2. 3.5 5.]
#define Color 1.      //Color blending amount [.2 .5 .8 1. 1.5 2. 3.5 5.]
#define Tolerance .04 //Total blending tolerance [.02 .04 .08 .16]

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform vec4 entityColor;
uniform float blindness;
uniform int isEyeInWater;
uniform ivec2 atlasSize;

varying vec4 color;
varying vec3 world;
varying vec2 coord0;
varying vec2 coord1;

float hash(vec3 p)
{
    return fract(cos(p.x*74.1+p.y*97.5-p.z*62.0)*762.5);
}
vec2 hash2(vec3 p)
{
    return fract(cos(p.xy*74.1+p.yz*97.5-p.zx*62.0)*762.5);
}

void main()
{
    vec3 light = (1.-blindness) * texture2D(lightmap,coord1).rgb;
    vec4 tex = texture2D(texture,coord0);

    //if (gl_FragCoord.x>420.)
    {
        vec2 s = max(vec2(atlasSize/16),6.);
        vec2 p = coord0*s;
        vec2 f = floor(p);

        vec2 gx = dFdx(coord0);
        vec2 gy = dFdy(coord0);

        vec2 h1 = floor(hash2(floor(world*Scale1))*4.)/4.;
        vec2 h2 = floor(hash2(floor(world*Scale2))*8.)/8.;
        vec4 t1 = textureGrad(texture,(f+fract((p-f)*Scale1+h1))/s,gx*Scale1,gy*Scale1);
        vec4 t2 = textureGrad(texture,(f+fract((p-f)*Scale2+h2))/s,gx*Scale2,gy*Scale2);

        vec4 r1 = (t1-tex);
        vec4 r2 = (t2-tex);
        float g1 = dot(r1*r1,vec4(.299,.578,.114,0))/Light+dot(abs(r1*r1-dot(r1*r1,vec4(1,1,1,0)/3.)),vec4(1,1,1,0))/Color;
        float g2 = dot(r2*r2,vec4(.299,.578,.114,0))/Light+dot(abs(r2*r2-dot(r2*r2,vec4(1,1,1,0)/3.)),vec4(1,1,1,0))/Color;

        float depth = gl_FragCoord.z/gl_FragCoord.w;
        tex.rgb += Intensity1*r1.rgb*smoothstep(Tolerance,.01,g1)/exp(.2*depth);
        tex.rgb += Intensity2*r2.rgb*smoothstep(Tolerance,.01,g2)/exp(.4*depth);
    }

    vec4 col = color * vec4(light,1) * tex;
    col.rgb = mix(col.rgb,entityColor.rgb,entityColor.a);

    float fog = (isEyeInWater>0) ? 1.-exp(-gl_FogFragCoord * gl_Fog.density):
    clamp((gl_FogFragCoord-gl_Fog.start) * gl_Fog.scale, 0., 1.);

    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);

    gl_FragData[0] = col;
}
