Shader "Transparent/DepthCam"
{
    Properties
    {
        _Color ("Color when up", Color) = (1.0, 0., 0., 0.54)
        _ColorGround ("Color when hitting Object", Color) = (1.0, 0., 0., 1.)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
            };

            float4 _Color;
            float4 _ColorGround;

            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                // Sample the depth texture
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
                float linearDepth = Linear01Depth(rawDepth); // Convert to linear 0-1 range
                return fixed4(linearDepth, linearDepth, linearDepth, 1.0);
            
            }
            ENDCG
        }
    }
}
