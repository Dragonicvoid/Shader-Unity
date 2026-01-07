Shader "Unlit/SlimeDecal"
{
    Properties
    {
        _NormalMap ("Normal Map", 2D) = "white" {}
        _SlimeColor ("Slime Color", Color) = (1., 1., 1., 1.)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray: TEXCOORD1; 
                float4 screenUV : TEXCOORD2;
                half3 orientation: TEXCOORD3;
                half3 orientationX: TEXCOORD4;
                half3 orientationZ: TEXCOORD5;
                float3 wPos : TEXCOORD6;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.vertex.xz + 0.5;
                o.screenUV = ComputeScreenPos(o.vertex);
                o.ray = mul (UNITY_MATRIX_MV, v.vertex).xyz * float3(-1,-1, 1);
                o.orientation = mul (unity_ObjectToWorld, float4(0, 1, 0, 1));
                o.orientationX = mul (unity_ObjectToWorld, float4(1, 0, 0, 1));
                o.orientationZ = mul (unity_ObjectToWorld, float4(0, 0, 1, 1));
                return o;
            }

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float4 _SlimeColor;

            sampler2D _CameraDepthTexture;
			sampler2D _NormalsCopy;

            float4 slime(float2 uv, float2 posSeed) 
            {
                float dist = 1.;

                float2 uvNorm = float2(0.5, 0.5) - uv;
                float r = length(uvNorm) * 2.0;
                float a = atan2(uvNorm.y, uvNorm.x);

                dist = cos(a * 6.);

                clip(dist - 0.2);
                return float4(_SlimeColor.rgb, dist);
            }

            float rand(float2 st) {
                return frac(sin(dot(st.xy + 75.3, float2(2561, 6922))) * 7623);
            }

            void frag (v2f i, out half4 outDiffuse : SV_TARGET0, out half3 outNormal : SV_TARGET1)
            {
                i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
                float2 screenUV = i.screenUV.xy / i.screenUV.w;

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                depth = Linear01Depth(depth);
                float4 vpos = float4(i.ray * depth,1);
				float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
				float3 opos = mul (unity_WorldToObject, float4(wpos,1)).xyz;

                clip(float3(0.5,0.5,0.5) - abs(opos.xyz));

                half3 normal = tex2D(_NormalsCopy, screenUV).xyz;
                fixed3 wnormal = normal.xyz * 2.0 - 1.0;

                clip(dot(wnormal, i.orientation) - 0.1);

                i.uv = opos.xz + 0.5;
                outDiffuse = slime(i.uv, float2(0., 0.));

                float3 nor = UnpackNormal(tex2D(_NormalMap, float2(i.uv.x, frac(i.uv.y + _Time.x))));
				half3x3 norMat = half3x3(i.orientationX, i.orientationZ, i.orientation);
				outNormal = mul(nor, norMat);
            }
            ENDCG
        }
    }
}
