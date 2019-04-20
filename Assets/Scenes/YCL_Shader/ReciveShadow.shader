Shader "Custom/ReciveShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Offset -1,-1
        Pass
        {
            Name "SHADOW_SELF"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowMapTex;
            float4x4 _shadowMapProjectionMatrix;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            //fixed flag;

            inline fixed3 projectionShadow(float4 worldPos)
            {
                float4 lightClipPos = mul(_shadowMapProjectionMatrix,worldPos);
                fixed4 depthRGBA = tex2Dproj(_ShadowMapTex, lightClipPos);
                lightClipPos.z = (lightClipPos.z +1) * 0.25;
                float depth = DecodeFloatRGBA(depthRGBA) - 0.001;
                fixed isShadow = 1;

                #ifdef UNITY_RTVERSED_Z
                isShadow = step(max(0.01,lightClipPos.z),depth);
                #else
                isShadow = step(depth,min(0.99,lightClipPos.z));
                #endif
                return isShadow;//1 - isShadow;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_ShadowMapTex, i.uv);
                //return fixed4(col.rgb, 1);
                col.rgb = projectionShadow(i.worldPos);
                return col;
            }
            ENDCG
        }
    }
}
