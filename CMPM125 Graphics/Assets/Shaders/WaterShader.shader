Shader "Custom/WaterShader"
{
    Properties
    {
        _WaterColor        ("Water Color", Color) = (0.1, 0.4, 0.7, 0.85)
        _FoamColor         ("Foam / Crest Color", Color) = (0.85, 0.95, 1.0, 1.0)
        _WaveSpeed         ("Wave Speed", Float) = 1.0
        _WaveHeight        ("Wave Height", Float) = 0.3
        _WaveFrequency     ("Wave Frequency", Float) = 2.0
        _FresnelPower      ("Fresnel Power", Float) = 3.0
        _NormalMap         ("Normal Map", 2D) = "bump" {}
        _NormalScrollSpeed ("Normal Scroll Speed", Vector) = (0.05, 0.03, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 viewDirWS   : TEXCOORD2;
            };

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _WaterColor;
                float4 _FoamColor;
                float4 _NormalMap_ST;
                float4 _NormalScrollSpeed;
                float  _WaveSpeed;
                float  _WaveHeight;
                float  _WaveFrequency;
                float  _FresnelPower;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;

                // Two waves offset in frequency and phase
                float wave1 = sin(v.positionOS.x * _WaveFrequency + _Time.y * _WaveSpeed) * _WaveHeight;
                float wave2 = sin(v.positionOS.z * _WaveFrequency * 0.8 + _Time.y * _WaveSpeed * 1.3 + 1.5) * _WaveHeight * 0.6;
                v.positionOS.y += wave1 + wave2;

                // Transform to clip space
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                // UVs for normal map scrolling
                o.uv          = TRANSFORM_TEX(v.uv, _NormalMap);
                // Transform normal to world space for lighting calculations
                o.normalWS    = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS   = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(v.positionOS.xyz)));
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // Scroll two layers of normals in different directions for more dynamic waves
                float2 uv1 = i.uv + _Time.y * _NormalScrollSpeed.xy;
                float2 uv2 = i.uv + _Time.y * _NormalScrollSpeed.xy * float2(-0.7, 1.2) + float2(0.4, 0.2);

                // Sample and blend normals
                float3 n1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv1));
                float3 n2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv2));
                // Blend the two normal samples together
                float3 blendedNormal = normalize(n1 + n2);

                // Fresnel
                float fresnel = pow(1.0 - saturate(dot(blendedNormal, normalize(i.viewDirWS))), _FresnelPower);

                // Blend between water color and foam color based on Fresnel term
                half4 col = lerp(_WaterColor, _FoamColor, fresnel);
                // Make foam more opaque at glancing angles
                col.a = lerp(_WaterColor.a, 1.0, fresnel * 0.5);
                return col;
            }
            ENDHLSL
        }
    }
}