Shader "Shadow/ShadowMapNormal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bias("Bias",Range(-0.0005,0.0005)) = 0.0005
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4x4 _LightSpaceMatrix;//把世界坐标变换到光源所在的空间
            sampler2D _DepthTexture;//深度贴图
            half _Bias;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
               float4 pos : SV_POSITION;
               float4 worldPos : TEXCOORD0;
               float2 uv : TEXCOORD1;
            };

            float GetShadowBias(float3 lightDir , float3 normal , float maxBias , float baseBias)
            {
                float cos_val = saturate(dot(lightDir, normal));
                float sin_val = sqrt(1 - cos_val*cos_val); // sin(acos(L·N))
                float tan_val = sin_val / cos_val;    // tan(acos(L·N))
                float bias = baseBias + clamp(tan_val,0 , maxBias) ;
                return bias ;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); //MVP从局部坐标系变换到视图坐标系
                float4 worldPos = mul(UNITY_MATRIX_M,v.vertex);//从局部坐标转换到世界坐标
                //这种赋值无法理解????
                o.worldPos.xyz = worldPos.xyz;
                o.worldPos.w = 1;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);//保存变换后的纹理坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 采样纹理坐标的颜色值
                fixed4 col = tex2D(_MainTex, i.uv);\
                //将顶点从世界坐标空间转换到光线空间
                fixed4 lightSpacePos = mul(_LightSpaceMatrix,i.worldPos);
                //光线空间的片元位置转换为NDC
                lightSpacePos.xyz = lightSpacePos.xyz / lightSpacePos.w;
                //将NDC变换为0-1的范围
                float3 pos = lightSpacePos.xyz; //* 0.5 + 0.5;

                //阴影值 1在0不在
                float shadow = 0.0;
                //获取深度图的颜色
                fixed4 depthRGBA = tex2D(_DepthTexture,pos.xy);
                //return depthRGBA;
                //获取深度贴图的深度
                float depth = DecodeFloatRGBA(depthRGBA);
                //获取当前像素的深度值
                float currentDepth = lightSpacePos.z;
                //如果贴图的深度值小于实际深度,就说明结果为1,在阴影中.如果相等就为0,不在阴影中
                //shadow = currentDepth < depth ? 1.0 : 0.0;
                shadow = currentDepth + _Bias < depth ? 1.0 : 0.0;
                //颠倒黑白
                return (1 - shadow) * col;
                //return shadow * col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
