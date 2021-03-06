﻿Shader "Custom/WobbleSurface" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
        _Ambient ("Ambient", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
        _NoiseScale ("Noise Scale", Range(0, 2)) = 1
        _NoiseAmount ("Noise Amount", Range(0, 5)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
        #define PI 3.14159265

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
        uniform fixed4 _Ambient;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END
        
            uniform float _NoiseScale;
            uniform float _NoiseAmount;

            float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
            float4 mod289(float4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
            float4 perm(float4 x){return mod289(((x * 34.0) + 1.0) * x);}

            float noise(float3 p){
                float3 a = floor(p);
                float3 d = p - a;
                d = d * d * (3.0 - 2.0 * d);

                float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
                float4 k1 = perm(b.xyxy);
                float4 k2 = perm(k1.xyxy + b.zzww);

                float4 c = k2 + a.zzzz;
                float4 k3 = perm(c);
                float4 k4 = perm(c + 1.0);

                float4 o1 = frac(k3 * (1.0 / 41.0));
                float4 o2 = frac(k4 * (1.0 / 41.0));

                float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
                float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

                return o4.y * d.y + o4.x * (1.0 - d.y);
            }

            float3 calculateFaceNormal(float3 a, float3 B, float3 C) {
                float3 EB, EC;
                EB = B - a;
                EC = C - a;
                return cross(EB, EC);
            }

            float3 getPoint(float r, float theta, float phi) {
                float r1 = r;//phi * m1;//sin(theta);//supershape(theta, m1, n11, n21, n31, a1, b1);
                float r2 = r;//cos(phi);//supershape(phi, m2, n12, n22, n32, a2, b2);
                float x = r1*cos(theta)*cos(phi);
                float y = r1*sin(theta)*cos(phi);
                float z = r2*sin(phi);

                return float3(x, y, z);
            }

            void vert (inout appdata_base v) {

                    float3 pos = v.vertex;
                    float r = length(pos);
                    float theta = atan2(pos.y, pos.x);
                    float phi = acos(pos.z / r);

                    theta -= PI;
                    phi -= PI/2;

                    float stepSize = 1.0;

                    float thetaPlus = theta + 1.0f/stepSize;
                    float phiPlus = phi + 1.0f/ stepSize;
                    float thetaMinus = theta - 1.0f/ stepSize;
                    float phiMinus = phi - 1.0f/ stepSize;

                    float3 p = getPoint(r, theta, phi);
                    float3 pointPlusTheta = getPoint(r, thetaPlus, phi);
                    float3 pointPlusPhi = getPoint(r, theta, phiPlus);

                    p *= noise(p * _NoiseScale + _Time.y) * _NoiseAmount + 1.0;
                    pointPlusTheta *= noise(pointPlusTheta * _NoiseScale + _Time.y) * _NoiseAmount + 1.0;
                    pointPlusPhi *= noise(pointPlusPhi * _NoiseScale + _Time.y) * _NoiseAmount + 1.0;

                    // float3 faceNorm = calculateFaceNormal(p, pointPlusTheta, pointPlusPhi);
                    // faceNorm = normalize(faceNorm);
                    // faceNorm *= -1;

                    v.vertex.xyz = p;
                    //v.normal = faceNorm;

            }

    		void surf (Input IN, inout SurfaceOutputStandard o) {
    			// Albedo comes from a texture tinted by color
    			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
    			o.Albedo = c.rgb;
                o.Emission = _Ambient;
                
    			// Metallic and smoothness come from slider variables
    			o.Metallic = _Metallic;
    			o.Smoothness = _Glossiness;
    			o.Alpha = c.a;
    		}
            
		ENDCG
	}
	FallBack "Diffuse"
}
