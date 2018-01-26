Shader "Custom/Wobble"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Range(0.0, 20.0) ) = 1
        _LightPosition("Light Position", Vector) = (0.0, 0.0, 0.0)
        _NoiseScale("Noise Scale", Range(0, 5.0)) = 1.0
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			#define PI 3.14159265

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				//float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
            uniform float _Scale;
            uniform float3 _LightPosition;
            uniform float _NoiseScale;

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

			
			v2f vert (appdata_base v)
			{
				float3 pos = v.vertex;
                float r = length(pos);
                float theta = atan2(pos.y, pos.x);
                float phi = acos(pos.z / r);

                theta -= PI;
                phi -= PI/2;

                float stepSize = 1000;

                float thetaPlus = theta + 1.0f/stepSize;
                float phiPlus = phi + 1.0f/ stepSize;
                float thetaMinus = theta - 1.0f/ stepSize;
                float phiMinus = phi - 1.0f/ stepSize;

                float3 p = getPoint(r, theta, phi);
                float3 pointPlusTheta = getPoint(r, thetaPlus, phi);
                float3 pointPlusPhi = getPoint(r, theta, phiPlus);


                p *= noise(p * _NoiseScale + _Time.y);
                pointPlusTheta *= noise(pointPlusTheta * _NoiseScale + _Time.y);
                pointPlusPhi *= noise(pointPlusPhi * _NoiseScale + _Time.y);


                float3 faceNorm = calculateFaceNormal(p, pointPlusTheta, pointPlusPhi);
                faceNorm = normalize(faceNorm);

                faceNorm *= -1;

                p *= _Scale;

				v2f o;
				o.vertex = UnityObjectToClipPos(p);
				//o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(faceNorm);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

                float3 position = i.vertex.xyz;
                float3 normal = i.worldNormal;
				// sample the texture
                // float3 n = i.worldNormal;
				//fixed4 col = fixed4(normal.x, normal.y, normal.z, 1.0);
                // float dist = distance(position, _WorldSpaceLightPos0.xyz);
                float attenuation = 1.0 / 6.0f;//(1.0 + 0.001*dist + 0.01*dist*dist);// ;
                float3 lightPos = _LightPosition;
                float3 surf2light;
                surf2light = normalize(position - lightPos);

                float3 norm = normalize(normal);
                float dcont = max(0.0, dot(norm, surf2light));
                float3 diffuse = dcont * float3(1.0, 0.0, 0.0) * float3(1.0, 0.0, 0.0);

                //fixed3 col1 = float3(position.x / 200.0, 0.0, 0.0);

                fixed4 col = fixed4(diffuse, 1.0);

                //float3 ambient = m_ambient*l_ambient;
                // apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
