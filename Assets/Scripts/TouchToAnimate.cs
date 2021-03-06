﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.XR.iOS
{
    public class TouchToAnimate : MonoBehaviour
    {

        public float maxRayDistance = 30.0f;
        public LayerMask collisionLayer = 1 << 8;  //ARKitPlane layer
        public Material mat;
        public float wobbleUpSpeed;
        public float wobbleDownSpeed;
        private float wobbleAmount = 0.0f;
        private Coroutine currentCoroutine;

        void Enabled()
        {
            mat.shader = Shader.Find("WobbleSurface");
        }

        IEnumerator WobbleUp()
        {
            while (wobbleAmount < 1.0f)
            {
                wobbleAmount += wobbleUpSpeed;
                yield return null;
            }
        }

        IEnumerator WobbleDown()
        {
            while (wobbleAmount > 0.0f)
            {
                wobbleAmount -= wobbleDownSpeed;
                yield return null;
            }
        }

        // Update is called once per frame
        void Update()
        {
            mat.SetFloat("_NoiseAmount", wobbleAmount);
            #if UNITY_EDITOR   //we will only use this script on the editor side, though there is nothing that would prevent it from working on device
            if (Input.GetMouseButtonDown(0))
            {
                Debug.Log("Mouse button down");
                Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

                if (Physics.Raycast(ray))
                {
                    Debug.Log("Hit!");
                    if (currentCoroutine != null)
                        StopCoroutine(currentCoroutine);
                    currentCoroutine = StartCoroutine("WobbleUp");
                }
                else
                {
                    Debug.Log("Miss!");
                    if (currentCoroutine != null)
                        StopCoroutine(currentCoroutine);
                    currentCoroutine = StartCoroutine("WobbleDown");
                }
            }

            #else
            for (var i = 0; i < Input.touchCount; ++i) {
                if (Input.GetTouch(i).phase == TouchPhase.Began) {
                 
                    // Construct a ray from the current touch coordinates
                    Ray ray = Camera.main.ScreenPointToRay(Input.GetTouch(i).position);
                    // Create a particle if hit
                    if (Physics.Raycast(ray))
                    {
                        Debug.Log("Hit!");
                        if (currentCoroutine != null)
                            StopCoroutine(currentCoroutine);
                        currentCoroutine = StartCoroutine("WobbleUp");
                    }
                    else
                    {
                        Debug.Log("Miss!");
                        if (currentCoroutine != null)
                            StopCoroutine(currentCoroutine);
                        currentCoroutine = StartCoroutine("WobbleDown");
                    }               
                }
            }
            #endif

		}
	}
}
