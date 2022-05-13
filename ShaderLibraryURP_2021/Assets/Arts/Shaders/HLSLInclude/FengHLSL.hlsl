#ifndef FENG_HLSL_INCLUDED
#define FENG_HLSL_INCLUDED

// 三颜色（顶，侧，底）插值环境光方法
float3 TriColAmbient (float3 n, float3 uCol, float3 sCol, float dCol) {
    float uMask = max(0.0, n.g);        // 获取朝上部分遮罩
    float dMask = max(0.0, -n.g);       // 获取朝下部分遮罩
    float sMask = 1.0 - uMask - dMask;  // 获取侧面部分遮罩
    float3 envCol = uCol * uMask +
                    sCol * sMask +
                    dCol * dMask;       // 混合环境色
    return envCol;
}

// 自定义亮度
float CustomLuminance(in float3 c)
{
    //根据人眼对颜色的敏感度，可以看见对绿色是最敏感的
    return 0.2125 * c.r + 0.7154 * c.g + 0.0721 * c.b;
}

///————————————————————————————————————————————————————————————————————————————————
/// UV
///————————————————————————————————————————————————————————————————————————————————

// Rotate
float2 Unity_Rotate_Radians(float2 UV, float2 Center, float Rotation)
{
    UV -= Center;
    float s = sin(Rotation);
    float c = cos(Rotation);
    float2x2 rMatrix = float2x2(c, -s, s, c);
    rMatrix *= 0.5;
    rMatrix += 0.5;
    rMatrix = rMatrix * 2 - 1;
    UV.xy = mul(UV.xy, rMatrix);
    UV += Center;
    return UV;
}

// 当有多个RenderTarget时，需要自己处理UV翻转问题
float2 CorrectUV(in float2 uv, in float4 texelSize)
{
    float2 result = uv;
	
    #if UNITY_UV_STARTS_AT_TOP      // DirectX之类的
    if(texelSize.y < 0.0)           // 开启了抗锯齿
        result.y = 1.0 - uv.y;      // 满足上面两个条件时uv会翻转，因此需要转回来
    #endif

    return result;
}


///————————————————————————————————————————————————————————————————————————————————
/// 形状
///————————————————————————————————————————————————————————————————————————————————
// border : (left, right, bottom, top), all should be [0, 1]
float Rect(float4 border, float2 uv)
{
    float v1 = step(border.x, uv.x);
    float v2 = step(border.y, 1 - uv.x);
    float v3 = step(border.z, uv.y);
    float v4 = step(border.w, 1 - uv.y);
    return v1 * v2 * v3 * v4;
}

float SmoothRect(float4 border, float2 uv)
{
    float v1 = smoothstep(0, border.x, uv.x);
    float v2 = smoothstep(0, border.y, 1 - uv.x);
    float v3 = smoothstep(0, border.z, uv.y);
    float v4 = smoothstep(0, border.w, 1 - uv.y);
    return v1 * v2 * v3 * v4;
}

float Circle(float2 center, float radius, float2 uv)
{
    return 1 - step(radius, distance(uv, center));
}

float SmoothCircle(float2 center, float radius, float smoothWidth, float2 uv)
{
    return 1 - smoothstep(radius - smoothWidth, radius, distance(uv, center));
}


///————————————————————————————————————————————————————————————————————————————————
/// 噪波
///————————————————————————————————————————————————————————————————————————————————

// SimpleNoise
float Unity_noise_randomValue (float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
}
float Unity_noise_interpolate (float a, float b, float t)
{
    return (1.0-t)*a + (t*b);
}
float Unity_valueNoise (float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);

    uv = abs(frac(uv) - 0.5);
    float2 c0 = i + float2(0.0, 0.0);
    float2 c1 = i + float2(1.0, 0.0);
    float2 c2 = i + float2(0.0, 1.0);
    float2 c3 = i + float2(1.0, 1.0);
    float r0 = Unity_noise_randomValue(c0);
    float r1 = Unity_noise_randomValue(c1);
    float r2 = Unity_noise_randomValue(c2);
    float r3 = Unity_noise_randomValue(c3);

    float bottomOfGrid = Unity_noise_interpolate(r0, r1, f.x);
    float topOfGrid = Unity_noise_interpolate(r2, r3, f.x);
    float t = Unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
    return t;
}
float Unity_SimpleNoise_float(float2 UV, float Scale)
{
    float t = 0.0;

    float freq = pow(2.0, float(0));
    float amp = pow(0.5, float(3-0));
    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(1));
    amp = pow(0.5, float(3-1));
    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(2));
    amp = pow(0.5, float(3-2));
    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
			    
    return t;
}

#endif