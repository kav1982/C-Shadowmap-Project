Shader "Hidden/ShadowReplace"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZWrite Off
        

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"

            struct shadowAppdata
            {
                float4 vertex : POSITION;
            };

            struct shadowV2F
            {
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD0;
            };

            float4x4 _shadowMapProjectionMatrix;

            shadowV2F shadowVert (shadowAppdata v)
            {
                shadowV2F o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float sdfBox (float2 coord, float2 center, float width, float height) 
            {
               float2 d = abs(coord - center) - float2(width,height);
               return length(max(d,0.0));
            }

            fixed4 shadowFrag(shadowV2F i) : SV_Target
            {
                //return float4(1,0,0,1);
                fixed4 lightClipPos = mul(_shadowMapProjectionMatrix,i.worldPos);
                float depth = lightClipPos.z;
                depth = (depth + 1) * 0.25;
                #ifdef UNITY_REVERSED_Z
                depth *= 1- smoothstep(0,0.1,sdfBox(lightClipPos.xy,float2(0.5,0.5),0.4,0.4));
                #else
                depth += smoothstep(0,0.1,sdfBox(lightClipPos.xy,float2(0.5,0.5),0.4,0.4));
                #endif
                return EncodeFloatRGBA(depth);
            }

            #pragma vertex shadowVert
            #pragma fragment shadowFrag
            ENDCG
        }
    }
}
