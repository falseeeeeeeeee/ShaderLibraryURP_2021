Shader "URP/Toon/Ink01"
{
    Properties 
    {
        [Foldout(1,1,0,1)] _foldout_Diffuse ("基本颜色_Foldout", Float) = 1
        [HideInInspector] _BaseColor ("Base Color", Color) = (1, 1, 1)
        [Tex(_BaseColor)] _BaseMap ("Base Map", 2D) = "white" {}

        [Foldout(1,1,0,1)] _foldout_ToonShadow ("卡通颜色_Foldout", Float) = 1
        [Enum_Switch(Double,CustomNum,RampMap,Ink)] _RampSytle ("Ramp Sytle", Float) = 3
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0)
        [Switch(Double)] _ShadowOffset ("Shadow Offset", Range(0.0, 1.0)) = 0.5
        [Switch(CustomNum)] _ShadowNum ("Shadow Number", Range(3.0, 16.0)) = 3.0
        [Switch(RampMap,Ink)][NoScaleOffset] _RampMap ("Ramp Map", 2D) = "white" {}

		[Switch(Ink)][NoScaleOffset] _StrokeMap ("Stroke Map", 2D) = "white" {}
		[Switch(Ink)] _InteriorNoiseMap ("Interior Noise Map", 2D) = "white" {}
		[Switch(Ink)] _InteriorNoiseLevel ("Interior Noise Level", Range(0, 1)) = 0.15
		[Switch(Ink)] _GguassianRadius ("Guassian Blur Radius", Range(0,60)) = 30
        [Switch(Ink)] _GuassianResolution ("Guassian Resolution", Float) = 800  
        [Switch(Ink)] _GuassianHStep ("Guassian Horizontal Step", Range(0,1)) = 0.5
        [Switch(Ink)] _GuassianVStep ("Guassian Vertical Step", Range(0,1)) = 0.5  

        [Foldout(1,1,0,1)] _foldout_Outline ("描边_Foldout", Float) = 1
        [Toggle] _OutlineAutoSize ("Outline Auto Size?", Float) = 0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0)
        _OutlineWidth ("Outline Width", Range(0.0, 64.0)) = 0.5
        [Tex(_OutlineNoiseScale)] [NoScaleOffset] _OutlineNoiseMap ("Outline Noise Map", 2D) = "white" {}
        _OutlineNoiseWidth ("Outline Noise Width", Range(0.0, 2.0)) = 1.0
		[HideInInspector] _OutlineNoiseScale ("Outline Noise Scale", Range(0.0, 32.0)) = 1.0
        _InlinePower ("Inline Power", Range(0.1, 10.0)) = 2.0
        _InlineThred ("Inline Thred", Range(0.0, 1.0)) = 0.5

        [Foldout(1,1,0,0)] _foldout_Other ("其它_Foldout", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    	[Toggle] _ReceiveShadows ("Receive Shadows", Float) = 1

    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
		uniform half4 _BaseColor;
		uniform float4 _BaseMap_ST;
        
        uniform half4 _ShadowColor;
        uniform half _ShadowOffset;
        uniform half _ShadowNum;
        
        uniform float4 _InteriorNoiseMap_ST;
        uniform half _InteriorNoiseLevel;
        uniform float _GguassianRadius;
        uniform float _GuassianResolution;
        uniform float _GuassianHStep;
        uniform float _GuassianVStep;
        
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;
        uniform float _OutlineNoiseWidth;
        uniform float _OutlineNoiseScale;
        uniform float _InlinePower;
        uniform float _InlineThred;
        CBUFFER_END
        
        ENDHLSL
        

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 

            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma shader_feature _RAMPSYTLE_DOUBLE _RAMPSYTLE_CUSTOMNUM _RAMPSYTLE_RAMPMAP _RAMPSYTLE_INK
            #pragma shader_feature _RECEIVESHADOWS_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile_instancing
			#pragma multi_compile_fog

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			TEXTURE2D(_BaseMap);	        SAMPLER(sampler_BaseMap);
			TEXTURE2D(_RampMap);	        SAMPLER(sampler_RampMap);
			TEXTURE2D(_StrokeMap);	        SAMPLER(sampler_StrokeMap);
			TEXTURE2D(_InteriorNoiseMap);	SAMPLER(sampler_InteriorNoiseMap);
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            	#if _RAMPSYTLE_INK
					float2 uvNoise : TEXCOORD3;
            	#endif
                half fogFactor: TEXCOORD4; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
            	
            	#if _RAMPSYTLE_INK
                output.uvNoise = TRANSFORM_TEX(input.texcoord, _InteriorNoiseMap);
            	#endif
            	
                output.fogFactor = ComputeFogFactor(input.positionOS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

			    // Vector
			    float3 normalWS = normalize(input.normalWS);
			    float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                //Light
				float3 Ambient = SampleSH(normalWS);

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
                float3 mainlightDir = normalize(mainLight.direction);
				#if _RECEIVESHADOWS_ON
					float mainlighShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
				#else
					float mainlighShadow = 1.0;
				#endif

			    // LightMode
			    half lambert = dot(normalWS, mainlightDir);
			    half halfLambert = lambert * 0.5 + 0.5;
			    half fresnel = pow(saturate(dot(normalWS, viewDirWS)), _InlinePower);
			    fresnel = (fresnel > _InlineThred) ? 1 : fresnel * fresnel; 

                // Ramp
                half3 rampColor;
                #if _RAMPSYTLE_DOUBLE 
                    rampColor = step(_ShadowOffset, halfLambert).rrr;
                #elif _RAMPSYTLE_CUSTOMNUM
                    rampColor = (floor(halfLambert * _ShadowNum) / _ShadowNum).rrr;
                #elif _RAMPSYTLE_RAMPMAP
                    rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(halfLambert, 1.0)).rgb;
				#elif _RAMPSYTLE_INK
					// Noise
				    float2 var_InteriorNoiseMap = SAMPLE_TEXTURE2D(_InteriorNoiseMap, sampler_InteriorNoiseMap, input.uvNoise).xy;                         
				    float2 var_StrokeMap = SAMPLE_TEXTURE2D(_StrokeMap, sampler_StrokeMap, input.uv).xy;
				    float2 noiseUV = float2(halfLambert, halfLambert) + var_StrokeMap * var_InteriorNoiseMap * _InteriorNoiseLevel;
					if (noiseUV.x > 0.95)
					{
						noiseUV.x = 0.95;
						noiseUV.y = 1;
					}
					if (noiseUV.y >  0.95)
					{
						noiseUV.x = 0.95;
						noiseUV.y = 1;
					}
					noiseUV = clamp(noiseUV, 0, 1);
					// Guassian Blur
					float4 sum = float4(0.0, 0.0, 0.0, 0.0);
	                float2 tc = noiseUV;
	                float hstep = _GuassianHStep;
	                float vstep = _GuassianVStep;
	                // blur radius in pixels
	                float blur = _GguassianRadius/_GuassianResolution/4;     
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 3.0*blur*hstep, tc.y - 3.0*blur*vstep)) * 0.0540540541;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 2.0*blur*hstep, tc.y - 2.0*blur*vstep)) * 0.1216216216;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 1.0*blur*hstep, tc.y - 1.0*blur*vstep)) * 0.1945945946;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x, tc.y)) * 0.2270270270;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 1.0*blur*hstep, tc.y + 1.0*blur*vstep)) * 0.1945945946;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 2.0*blur*hstep, tc.y + 2.0*blur*vstep)) * 0.1216216216;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 3.0*blur*hstep, tc.y + 3.0*blur*vstep)) * 0.0540540541;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 4.0*blur*hstep, tc.y + 4.0*blur*vstep)) * 0.0162162162;
					rampColor = sum.rgb;
                #endif
                half3 shadowColor = lerp(_ShadowColor.rgb, half3(1.0, 1.0, 1.0), rampColor);
			    
                // Color
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
				
				// Gray
				float texGrey = (var_BaseMap.r + var_BaseMap.g + var_BaseMap.b)*0.33;
				texGrey = pow(texGrey, 0.4);
				texGrey *= 1 - cos(texGrey * 3.14);

				// Blend Color
                half3 color = texGrey.rrr * _BaseColor.rgb * shadowColor * mainlighShadow
			                + texGrey.rrr * _BaseColor.rgb * Ambient
			                ;
			    color = lerp(_OutlineColor.rgb, color, lerp(1.0, fresnel, _OutlineColor.a *0));
			    
                half alpha = 1;

			    // Fog
                real fogFactor = ComputeFogFactor(input.positionCS.z * input.positionCS.w);
                color = MixFog(color, fogFactor);
                
                return half4(color, alpha);
            } 
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
        	
        	Cull Off
            
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
            	
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }
        /*
        Pass
        {
        	Name "Outline"
            Tags{"LightMode" = "SRPDefaultUnlit"}

            Cull Front
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_OutlineNoiseMap);	SAMPLER(sampler_OutlineNoiseMap);


            #pragma multi_compile_instancing

            #pragma shader_feature _OUTLINEAUTOSIZE_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;                
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float burn = SAMPLE_TEXTURE2D_LOD(_OutlineNoiseMap, sampler_OutlineNoiseMap, input.positionOS.xy * _OutlineNoiseScale, 0).x * _OutlineNoiseWidth;
                
                float4 scaledScreenParams = GetScaledScreenParams();
                float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);    //求得X因屏幕比例缩放的倍数

                //float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 normalCS = TransformWorldToHClipDir(normalWS);

                float2 extendis = normalize(normalCS.xy) * (_OutlineWidth * 0.01);  //根据法线和线宽计算偏移量
                       extendis.x /= scaleX;   //修正屏幕比例x

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                #if _OUTLINEAUTOSIZE_ON
                    //屏幕下描边宽度会变
                    output.positionCS.xy += extendis * burn;
                #else
                    //屏幕下描边宽度不变，则需要顶点偏移的距离在NDC坐标下为固定值
                    //因为后续会转换成NDC坐标，会除w进行缩放，所以先乘一个w，那么该偏移的距离就不会在NDC下有变换
                    output.positionCS.xy += extendis * burn * output.positionCS.w;
                #endif

                return output;
            }
            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return float4(_OutlineColor.rgb, 1);
            }
            ENDHLSL
        }
    	*/
    	UsePass "Universal Render Pipeline/Lit/DepthOnly"

    }
    CustomEditor "Scarecrow.SimpleShaderGUI"
}
