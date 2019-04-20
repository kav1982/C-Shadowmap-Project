Shader "QianDao/QD_MatCaprealistic_Shadow"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_MetalRef ("MetalRef", Range(0, 1)) = 0
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" { }
		_MatCap ("MatCap (RGB)", 2D) = "white" { }
		_MatCapValue ("MatcapValue", Range(0, 3)) = 1
		_MatCapSpec ("MatCapSpec(RGB)", 2D) = "black" { }
		_SpecValue ("SpecValue", Range(0, 3)) = 0
		//_RoughnessTex("Roughness texture",2D) = "grey"{}
        _Roughness("Roughness",float) = 0
		_DarkfaceColor("Darkface Color",Color) = (0,0,0,1)
        _DarkfaceMin("Darkface Range",Range(0,1)) = 0
        _DarkfaceRange("Soft Darkface",Range(0.001,0.999)) = 0.2
        _Darkface("Darkface Value",Range(0,1)) = 1

        _RotDiff("Rot Diff",Range(0,6.28)) = 0
        _RotSpec("Rot Spec",Range(0,6.28)) = 0
        _RotDarkface("Darkface Rot",Range(0,6.28)) = 0
		
		_CampMap ("Camp (RGB)", 2D) = "white" { }
		//_Strong ("Strong", Range(0, 10)) = 2.0
		_CampColor ("CampColor", Color) = (1, 1, 1, 1)
		
		_Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
		_ShadowFalloff ("ShadowFalloff", Range(0, 1)) = 0.5
		_LightDir ("灯光相对模型位置", Vector) = (0, 100, 0, 1)  
		_ShadowColor ("ShadowColor", Color) = (0.03529, 0.02745, 0.05098, 1)
		_ShadowAlpha ("阴影整体透明度", Range(0, 1)) = 0.9
		_ShadowZ ("阴影Z轴偏移", Range(0, 1)) = 0
		_ShadowY ("阴影Y轴偏移", Range(-10, 10)) = 0
		_Alpha ("半透效果", Range(0, 1)) = 1
		_AdditiveEffect ("Add效果", Color) = (0, 0, 0, 0)
		_ShowShadow ("显示阴影", float) = 1
	}
	
	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		Fog
		{
			Color [_AddFog]
		}
		
		Pass
		{
			Name "AlphaDepth"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite On
			ColorMask 0
		}
		//Tags { "Queue"="AlphaTest" "RenderType"="Opaque" }
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Opaque" "MyReplaceTag" = "Other" }
		Pass
		{
			Name "Normal"
			Tags { "LightMode" = "Always" }
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			
			struct v2f
			{
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD0;
				
				float3 c0: TEXCOORD1;
				float3 c1: TEXCOORD2;
                float3 visual : TEXCOORD3;
                float4 normal : TEXCOORD4;
			};
			
			uniform float4 _MainTex_ST;
			uniform float4 _BumpMap_ST;
			
			v2f vert(appdata_tan v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				TANGENT_SPACE_ROTATION;
				//o.c0 = mul(rotation, UNITY_MATRIX_IT_MV[0].xyz);
				//o.c1 = mul(rotation, UNITY_MATRIX_IT_MV[1].xyz);
                o.c0 = normalize(mul(rotation,UNITY_MATRIX_IT_MV[0].xyz));
                o.c1 = normalize(mul(rotation,UNITY_MATRIX_IT_MV[1].xyz));
                o.visual = normalize(mul(rotation, -ObjSpaceLightDir(v.vertex)));
				return o;
			}
			
			uniform fixed4 _Color,_DarkfaceColor;
            uniform sampler2D _MatCap;
            uniform sampler2D _MainTex;
            uniform sampler2D _MatCapSpec;
            uniform fixed _SpecValue;
            //uniform sampler2D _RoughnessTex;
            uniform fixed _Roughness;
            uniform fixed _MatCapValue;
            uniform float _DarkfaceRange,_Darkface;
            uniform fixed _DarkfaceMin,_RotDarkface,_RotDiff,_RotSpec,_MetalRef;
			uniform sampler2D _CampMap;
			//fixed _Strong;
			float4 _CampColor;
			float _Cutoff;
			fixed _Alpha;
			float4 _AdditiveEffect;

			float3 lum(fixed3 c)
            {
                return c.r * 0.2 + c.g * 0.7 + c.b * 0.1;
            }
			
			fixed4 frag(v2f i) : SV_TARGET
			{
				
				fixed4 c = tex2D(_MainTex,i.uv.xy);
				clip(c.a - _Cutoff);
				fixed3 normal = fixed3(0, 0, 1);
				float3 correctiveNormal = normalize(reflect(i.visual,normal));
                normal = lerp(normal,correctiveNormal,_MetalRef);

				half2 vn;
                vn.x = dot(i.c0,normal);
                vn.y = dot(i.c1,normal);

                fixed2x2 rotDiff =
                {
                    cos(_RotDiff),-sin(_RotDiff),
                    sin(_RotDiff), cos(_RotDiff)
                };
                half2 vnd = mul(rotDiff,vn);

                fixed4 matcapLookup = saturate(tex2D(_MatCap,vnd * 0.495+0.505)*_Color*_MatCapValue);
                matcapLookup.a =1;

                
				fixed2 capCoord = fixed2(dot(i.c0, normal), dot(i.c1, normal));
				fixed4 mc = tex2D(_MatCap, capCoord * 0.5 + 0.5) ;
				
				fixed4 camp = tex2D(_CampMap, i.uv);
				fixed CampTex = camp.r;
				fixed4 cc = (1 - CampTex) + CampTex * _CampColor;
				fixed LightMask = (1-camp.g) * normal;
				//fixed LightMask = camp.g * normal;
				float roughness = camp.b;
				//float roughness = tex2D(_CampMap,i.uv.xy).b;
				fixed4 nc = mc * LightMask * _SpecValue * roughness + (1 - LightMask);
				fixed4 selfLight = _AdditiveEffect * camp.a;

                fixed2x2 rotSpec =
                {
                    cos(_RotSpec),-sin(_RotSpec),
                    sin(_RotSpec),cos(_RotSpec)
                };

				half2 vnsp = mul(rotSpec,vn);
                fixed4 matcapSpec = tex2D(_MatCapSpec,vnsp*0.5 + 0.5);
				matcapSpec = lerp(matcapSpec,0,lerp(0,roughness,_Roughness)) * c;
				//matcapSpec = lerp(matcapSpec,0,roughness) * LightMask;
				//matcapSpec = lerp(matcapSpec,0,roughness) * matcapSpec;
				//matcapSpec = matcapSpec * roughness * LightMask;
                matcapSpec.a = 1;

                fixed2x2 rot =
                {
                    -cos(_RotDarkface),sin(_RotDarkface),
                    -sin(_RotDarkface),-cos(_RotDarkface)
                };

                half2 vns = mul(rot,vn);
                fixed4 shadow = tex2D(_MatCap,vns*0.5 + 0.5);
                shadow.rgb = saturate((1-lum(shadow.rgb)-_DarkfaceMin)/_DarkfaceRange);
                shadow.rgb = lerp(1,_DarkfaceColor.rgb,1-shadow.rgb);


				fixed4 diff = c*matcapLookup;
                fixed4 finalColor = clamp(diff + matcapSpec * _SpecValue,0,1);
                
                finalColor = finalColor*lerp(1,shadow,_Darkface);
                //finalColor.a = 1.0;
                //return finalColor;
				fixed4 fn = finalColor * cc * nc;
				fn.a = _Alpha ;
				return fn + fixed4(selfLight.r, selfLight.g, selfLight.b, 0);
			}
			ENDCG
			
		}


		//UsePass "QianDao/PlanarShadow/PSCASTER"
		//UsePass "Custom/ReciveShadow/SHADOW_SELF"
	}
	
	Fallback "VertexLit"
}