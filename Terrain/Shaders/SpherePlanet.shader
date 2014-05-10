﻿Shader "Sphere/Planet" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_SpecColor ("Specular tint", Color) = (1,1,1,1)
		_Shininess ("Shininess", Float) = 10
		_MainTex ("Main (RGB)", 2D) = "white" {}
		_DetailTex ("Detail (RGB)", 2D) = "white" {}
		_DetailVertTex ("Detail for Vertical Surfaces (RGB)", 2D) = "white" {}
		_DetailScale ("Detail Scale", Range(0,1000)) = 200
		_DetailVertScale ("Detail Scale", Range(0,1000)) = 200
		_DetailDist ("Detail Distance", Range(0,1)) = 0.00875
		_MinLight ("Minimum Light", Range(0,1)) = .5
		_CityOverlayTex ("Overlay (RGB)", 2D) = "white" {}
		_CityOverlayDetailScale ("Overlay Detail Scale", Range(0,1000)) = 80
		_CityDarkOverlayDetailTex ("Overlay Detail (RGB) (A)", 2D) = "white" {}
		_CityLightOverlayDetailTex ("Overlay Detail (RGB) (A)", 2D) = "white" {}
	}
	
SubShader {

Tags { "Queue"="Geometry" "RenderType"="Opaque" }
	Fog { Mode Global}
	ColorMask RGB
	Cull Back Lighting On ZWrite On
	
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
		#pragma multi_compile CITYOVERLAY_OFF CITYOVERLAY_ON
		#pragma multi_compile DETAIL_MAP_OFF DETAIL_MAP_ON
		#define PI 3.1415926535897932384626
		#define INV_PI (1.0/PI)
		#define TWOPI (2.0*PI) 
		#define INV_2PI (1.0/TWOPI)
	 
		fixed4 _Color;
		float _Shininess;
		sampler2D _MainTex;
		sampler2D _DetailTex;
		sampler2D _DetailVertTex;
		float _DetailScale;
		float _DetailVertScale;
		float _DetailDist;
		float _MinLight;
		
		#ifdef CITYOVERLAY_ON
		sampler2D _CityOverlayTex;
		float _CityOverlayDetailScale;
		sampler2D _CityDarkOverlayDetailTex;
		sampler2D _CityLightOverlayDetailTex;
		#endif
		
		struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

		struct v2f {
			float4 pos : SV_POSITION;
			float  viewDist : TEXCOORD0;
			float3 viewDir : TEXCOORD1;
			float3 normal : TEXCOORD2;
			LIGHTING_COORDS(3,4)
			float3 worldNormal : TEXCOORD5;
			float3 sphereNormal : TEXCOORD6;
		};	
		

		v2f vert (appdata_t v)
		{
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
		   float3 vertexPos = mul(_Object2World, v.vertex).xyz;
	   	   o.viewDist = distance(vertexPos,_WorldSpaceCameraPos);
	   	   
	   	   half3 nrm = normalize(v.normal);

		   float3 origin = mul(_Object2World, float4(0,0,0,1)).xyz;
	   	   o.worldNormal = normalize(vertexPos-origin);
	   	   o.sphereNormal = -normalize(v.vertex);
		   o.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(_Object2World, v.vertex).xyz);
		   o.normal = nrm;
    
    	   TRANSFER_VERTEX_TO_FRAGMENT(o);
    
	   	   return o;
	 	}
	 	
		float4 Derivatives( float3 pos )  
		{  
		    float lat = INV_2PI*atan2( pos.y, pos.x );  
		    float lon = INV_PI*acos( pos.z );  
		    float2 latLong = float2( lat, lon );  
		    float latDdx = INV_2PI*length( ddx( pos.xy ) );  
		    float latDdy = INV_2PI*length( ddy( pos.xy ) );  
		    float longDdx = ddx( lon );  
		    float longDdy = ddy( lon );  
		 	
		    return float4( latDdx , longDdx , latDdy, longDdy );  
		} 
	 		
		fixed4 frag (v2f IN) : COLOR
		{
			half4 color;
			float3 sphereNrm = IN.sphereNormal;
		 	float2 uv;
		 	uv.x = .5 + (INV_2PI*atan2(sphereNrm.x, sphereNrm.z));
		 	uv.y = INV_PI*acos(sphereNrm.y);
		 	float4 uvdd = Derivatives(sphereNrm);
		    half4 main = tex2D(_MainTex, uv, uvdd.xy, uvdd.zw);
		    half2 detailnrmzy = sphereNrm.zy*_DetailScale;
		    half2 detailnrmzx = sphereNrm.zx*_DetailScale;
		    half2 detailnrmxy = sphereNrm.xy*_DetailScale;
		    half2 detailvertnrmzy = sphereNrm.zy*_DetailVertScale;
		    half2 detailvertnrmzx = sphereNrm.zx*_DetailVertScale;
		    half2 detailvertnrmxy = sphereNrm.xy*_DetailVertScale;
		    half vertLerp = saturate((32*(saturate(dot(IN.normal, -IN.sphereNormal))-.95))+.5);
			half4 detailX = lerp(tex2D (_DetailVertTex, detailvertnrmzy), tex2D (_DetailTex, detailnrmzy), vertLerp);
			half4 detailY = lerp(tex2D (_DetailVertTex, detailvertnrmzx), tex2D (_DetailTex, detailnrmzx), vertLerp);
			half4 detailZ = lerp(tex2D (_DetailVertTex, detailvertnrmxy), tex2D (_DetailTex, detailnrmxy), vertLerp);
			
			#ifdef CITYOVERLAY_ON
			half4 cityoverlay = tex2D(_CityOverlayTex, uv, uvdd.xy, uvdd.zw);
			half4 citydarkoverlaydetailX = tex2D (_CityDarkOverlayDetailTex, sphereNrm.zy*_CityOverlayDetailScale);
			half4 citydarkoverlaydetailY = tex2D (_CityDarkOverlayDetailTex, sphereNrm.zx*_CityOverlayDetailScale);
			half4 citydarkoverlaydetailZ = tex2D (_CityDarkOverlayDetailTex, sphereNrm.xy*_CityOverlayDetailScale);
			half4 citylightoverlaydetailX = tex2D (_CityLightOverlayDetailTex, sphereNrm.zy*_CityOverlayDetailScale);
			half4 citylightoverlaydetailY = tex2D (_CityLightOverlayDetailTex, sphereNrm.zx*_CityOverlayDetailScale);
			half4 citylightoverlaydetailZ = tex2D (_CityLightOverlayDetailTex, sphereNrm.xy*_CityOverlayDetailScale);
			#endif
			
			sphereNrm = abs(sphereNrm);
			half4 detail = lerp(detailZ, detailX, sphereNrm.x);
			detail = lerp(detail, detailY, sphereNrm.y);
			half detailLevel = saturate(2*_DetailDist*IN.viewDist);
			color = main.rgba * lerp(detail.rgba, 1, detailLevel);
			#ifdef CITYOVERLAY_ON
			detail = lerp(citydarkoverlaydetailZ, citydarkoverlaydetailX, sphereNrm.x);
			detail = lerp(detail, citydarkoverlaydetailY, sphereNrm.y);
			half4 citydarkoverlay = cityoverlay*detail;
			detail = lerp(citylightoverlaydetailZ, citylightoverlaydetailX, sphereNrm.x);
			detail = lerp(detail, citylightoverlaydetailY, sphereNrm.y);
			half4 citylightoverlay = cityoverlay*detail;
			color = lerp(color, citylightoverlay, citylightoverlay.a);
			#endif
			
            color *= _Color;
            
          	//lighting
            half3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT;
			half3 lightDirection = normalize(_WorldSpaceLightPos0);
			half3 normalDir = IN.worldNormal;
			half NdotL = saturate(dot (normalDir, lightDirection));
	        half diff = (NdotL - 0.01) / 0.99;
	        fixed atten = LIGHT_ATTENUATION(IN); 
			half lightIntensity = saturate(_LightColor0.a * diff * 4 * atten);
			half3 light = saturate(ambientLighting + ((_MinLight + _LightColor0.rgb) * lightIntensity));
			
            float3 specularReflection = saturate(floor(1+NdotL));
            
            specularReflection *= atten * float3(_LightColor0) 
                  * float3(_SpecColor) * pow(saturate( dot(
                  reflect(-lightDirection, normalDir), 
                  IN.viewDir)), _Shininess);
 
            light += main.a*specularReflection;
			
			color.rgb *= light;
			
			#ifdef CITYOVERLAY_ON
			citydarkoverlay.a *= 1-saturate(lightIntensity*1.5);
			color = lerp(color, citydarkoverlay, citydarkoverlay.a);
			#endif
			color.a = 1;
			
          	return color;
		}
		ENDCG
	
		}
		
	} 
	
	FallBack "VertexLit"
}