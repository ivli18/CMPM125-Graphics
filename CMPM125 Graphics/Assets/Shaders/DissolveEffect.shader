Shader "Custom/DissolveEffect"
{
    Properties
    {
        _BaseMap        ("Base Texture", 2D)                = "white" {}
        _BaseColor      ("Tint Color", Color)               = (1, 1, 1, 1)
        _DissolveMap    ("Dissolve Noise Map", 2D)          = "white" {}
        _DissolveAmount ("Dissolve Amount", Range(0, 1))    = 0.0
        _DissolveSpeed  ("Auto Dissolve Speed", Range(0,2)) = 0.5
        _AutoDissolve   ("Auto Animate (0=off 1=on)", Range(0,1)) = 1
        _EdgeColor      ("Edge Glow Color", Color)          = (1, 0.4, 0, 1)
        _EdgeWidth      ("Edge Width", Range(0, 0.2))       = 0.05
        _EdgeIntensity  ("Edge Intensity", Range(1, 10))    = 3.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
        }

        Cull Off        // visible from both sides
        ZWrite On

        Pass
        {
            Name "DissolvePass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);      SAMPLER(sampler_BaseMap);
            TEXTURE2D(_DissolveMap);  SAMPLER(sampler_DissolveMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _DissolveMap_ST;
                float4 _BaseColor;
                float4 _EdgeColor;
                float  _DissolveAmount;
                float  _DissolveSpeed;
                float  _AutoDissolve;
                float  _EdgeWidth;
                float  _EdgeIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uvBase      : TEXCOORD0;
                float2 uvDissolve  : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvBase      = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uvDissolve  = TRANSFORM_TEX(IN.uv, _DissolveMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Sample textures
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uvBase) * _BaseColor;
                float noise     = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, IN.uvDissolve).r;

                // Compute threshold — loops 0→1 automatically, or use manual slider
                float autoThreshold = frac(_Time.y * _DissolveSpeed);
                float threshold     = lerp(_DissolveAmount, autoThreshold, _AutoDissolve);

                // Discard this pixel if noise is below threshold
                clip(noise - threshold);

                // Glow edge — pixels just above the threshold get colored
                float  edgeMask = 1.0 - smoothstep(0.0, _EdgeWidth, noise - threshold);
                float3 glow     = _EdgeColor.rgb * edgeMask * _EdgeIntensity;

                return half4(baseColor.rgb + glow, 1.0);
            }

            ENDHLSL
        }
    }
}
