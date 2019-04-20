Shader "ShadowMap/DepthTextureShader"
{
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct  vsInput
            {
                float4 vertex : POSITION;//顶点局部坐标
            };

            struct vsOutput
            {
                float4 vertex : SV_POSITION;//顶点视图坐标
                float2 depth : TEXCOORD0;//深度图转化成的纹理贴图
            };

            vsOutput vert (vsInput v)
            {
                vsOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);//MVP
                o.depth = o.vertex.zw;//保存深度值
                return o;
            }

            fixed4 frag (vsOutput i) : SV_Target
            {
                //Z深度从视图坐标转换为齐次坐标
                float depth = i.depth.x / i.depth.y;
                //EncodeFloatRGBA把float类型的深度信息转换为RGBA
                fixed4 col = EncodeFloatRGBA(depth);
                return col;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
