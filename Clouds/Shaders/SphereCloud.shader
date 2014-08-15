Shader "Sphere/Cloud" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_MainTex ("Main (RGB)", 2D) = "white" {}
		_MainOffset ("Main Offset", Vector) = (0,0,0,0)
		_DetailTex ("Detail (RGB)", 2D) = "white" {}
		_FalloffPow ("Falloff Power", Range(0,3)) = 2
		_FalloffScale ("Falloff Scale", Range(0,20)) = 3
		_DetailScale ("Detail Scale", Range(0,1000)) = 100
		_DetailOffset ("Detail Offset", Vector) = (0,0,0,0)
		_DetailDist ("Detail Distance", Range(0,1)) = 0.00875
		_MinLight ("Minimum Light", Range(0,1)) = .5
		_FadeDist ("Fade Distance", Range(0,100)) = 10
		_FadeScale ("Fade Scale", Range(0,1)) = .002
		_RimDist ("Rim Distance", Range(0,1)) = 1
		_RimDistSub ("Rim Distance Sub", Range(0,2)) = 1.01
		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = .01
	}

Category {
	
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	Fog { Mode Global}
	AlphaTest Greater 0
	ColorMask RGB
	Cull Off Lighting On ZWrite Off
	
SubShader {
	Pass {

		Lighting On
		Tags { "LightMode"="ForwardBase"}
		
		CGPROGRAM
		
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma glsl
		#pragma vertex vert
		#pragma fragment frag
		#define MAG_ONE 1.4142135623730950488016887242097
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fwdadd_fullshadows
		#define PI 3.1415926535897932384626
		#define INV_PI (1.0/PI)
		#define TWOPI (2.0*PI) 
		#define INV_2PI (1.0/TWOPI)
	 
		sampler2D _MainTex;
		sampler2D _DetailTex;
		fixed4 _Color;
		fixed4 _MainOffset;
		fixed4 _DetailOffset;
		float _FalloffPow;
		float _FalloffScale;
		float _DetailScale;
		float _DetailDist;
		float _MinLight;
		float _FadeDist;
		float _FadeScale;
		float _RimDist;
		float _RimDistSub;
		uniform float4x4 _Rotation;
		
		float _InvFade;
		sampler2D _CameraDepthTexture;
			
		struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float3 normal : NORMAL;
			};

		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldVert : TEXCOORD0;
			float3 worldOrigin : TEXCOORD1;
			float  viewDist : TEXCOORD2;
			float3 worldNormal : TEXCOORD3;
			float3 objNormal : TEXCOORD4;
			float3 viewDir : TEXCOORD5;
			LIGHTING_COORDS(6,7)
			float4 projPos : TEXCOORD8;
		};	
		

		v2f vert (appdata_t v)
		{
			v2f o;
			
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
		   float3 vertexPos = mul(_Object2World, v.vertex).xyz;
		   float3 origin = mul(_Object2World, float4(0,0,0,1)).xyz;
	   	   o.worldVert = vertexPos;
	   	   o.worldOrigin = origin;
	   	   o.viewDist = distance(vertexPos,_WorldSpaceCameraPos);
	   	   o.worldNormal = normalize(vertexPos-origin);
	   	   float4 vertex = mul(_Rotation, v.vertex);
	   	   o.objNormal = -normalize( vertex);
	   	   o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
	   	   
	   	   o.projPos = ComputeScreenPos (o.pos);
			COMPUTE_EYEDEPTH(o.projPos.z);
			TRANSFER_VERTEX_TO_FRAGMENT(o);
	   	   return o;
	 	}
	 	
		float4 Derivatives( float lat, float lon, float3 pos)  
		{  
		    float2 latLong = float2( lat, lon );  
		    float latDdx = INV_2PI*length( ddx( pos.xz ) );  
		    float latDdy = INV_2PI*length( ddy( pos.xz ) );  
		    float longDdx = ddx( lon );  
		    float longDdy = ddy( lon );  
		 	
		    return float4( latDdx , longDdx , latDdy, longDdy );  
		} 
	 		
		fixed4 frag (v2f IN) : COLOR
			{
			half4 color;
			float3 objNrm = IN.objNormal;
		 	float2 uv;
		 	uv.x = .5 + (INV_2PI*atan2(objNrm.x, objNrm.z));
		 	uv.y = INV_PI*acos(objNrm.y);
		 	uv+=_MainOffset.xy;
		 	float4 uvdd = Derivatives(uv.x-.5, uv.y, objNrm);
		    half4 main = tex2D(_MainTex, uv, uvdd.xy, uvdd.zw)*_Color;
			half4 detailX = tex2D (_DetailTex, (objNrm.zy+ _DetailOffset.xy) *_DetailScale);
			half4 detailY = tex2D (_DetailTex, (objNrm.zx + _DetailOffset.xy) *_DetailScale);
			half4 detailZ = tex2D (_DetailTex, (objNrm.xy + _DetailOffset.xy) *_DetailScale);
			objNrm = abs(objNrm);
			half4 detail = lerp(detailZ, detailX, objNrm.x);
			detail = lerp(detail, detailY, objNrm.y);
			half detailLevel = saturate(2*_DetailDist*IN.viewDist);
			color = main.rgba * lerp(detail.rgba, 1, detailLevel);

			float rim = saturate(dot(IN.viewDir, IN.worldNormal));
			rim = saturate(pow(_FalloffScale*rim,_FalloffPow));
			float dist = distance(IN.worldVert,_WorldSpaceCameraPos);
			float distLerp = saturate(_RimDist*(distance(IN.worldOrigin,_WorldSpaceCameraPos)-_RimDistSub*distance(IN.worldVert,IN.worldOrigin)));
			float distFade = saturate((_FadeScale*dist)-_FadeDist);
	   	   	float distAlpha = lerp(distFade, rim, distLerp);

			color.a = lerp(0, color.a,  distAlpha);

          	//lighting
			half3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT;
			half3 lightDirection = normalize(_WorldSpaceLightPos0);
			half NdotL = saturate(dot (IN.worldNormal, lightDirection));
	        half diff = (NdotL - 0.01) / 0.99;
			half lightIntensity = saturate(_LightColor0.a * diff * 4);
			color.rgb *= saturate(ambientLighting + ((_MinLight + _LightColor0.rgb) * lightIntensity));

			float depth = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos)));
			depth = LinearEyeDepth (depth);
			float partZ = IN.projPos.z;
			float fade = saturate (_InvFade * (depth-partZ));
			color.a *= fade;

          	return color;
		}
		ENDCG
	
		}
		
	} 
	
}
}
