// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Transparent/Barrier"
{
    Properties
    {
        _Color ("Color when up", Color) = (1.0, 0., 0., 0.54)
        _ColorGround ("Color when hitting Object", Color) = (1.0, 0., 0., 1.)
        _Threshold("Depth threshold to become grounded", float) = 0.2
        _Freshnel("how long is freshnel", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 worldPos: POSITION3;
                float3 normal: NORMAL;
                float depth01 : TEXCOORD2;
            };

            float4 _Color;
            float4 _ColorGround;

            sampler2D _CameraDepthTexture;
            float4 _CameraPos;

            float _Freshnel;
            float _Threshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.normal = v.normal;
                o.uv = v.uv;
                o.depth01 = COMPUTE_DEPTH_01;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
                float linearDepth = Linear01Depth(rawDepth); // Convert to linear 0-1 range
                float depth = i.depth01;

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 worldNormal = UnityObjectToWorldNormal(i.normal.xyz);
                float fresnel = 1.0 - saturate(dot(i.normal, viewDir));

                float offset = (sin(_Time.z) + 1.) / 2;
                float dist = smoothstep(_Threshold * offset, (_Threshold + _Threshold) * offset, linearDepth - depth);
                float4 color = lerp(_ColorGround, _Color, saturate(dist));
                color.a *= fresnel;

                return color;
            }
            ENDCG
        }
    }
}
