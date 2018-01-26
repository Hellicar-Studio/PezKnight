using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.XR.iOS
{
    public class TouchToAnimate : MonoBehaviour
    {

        public float maxRayDistance = 30.0f;
        public LayerMask collisionLayer = 1 << 8;  //ARKitPlane layer
        public Material mat;
        public float upAmount;
        public float upSpeed;
        public float downSpeed;
        public float wobbleUpTarget;
        public float wobbleDownTarget;
        public float panelsDownScale;
        public float panelsUpScale;
        private Coroutine currentCoroutine;
        private bool goingUp = false;
        public Transform PanelsTransform;

        float map(float value, float low1, float high1, float low2, float high2) {
            return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
        }

        void Enabled()
        {
            mat.shader = Shader.Find("WobbleSurface");
        }

        IEnumerator WobbleUp()
        {
            goingUp = true;
            while (upAmount < 1.0f)
            {
                upAmount += upSpeed;
                yield return null;
            }
            upAmount = 1.0f;
        }

        IEnumerator WobbleDown()
        {
            goingUp = false;
            while (upAmount > 0.0f)
            {
                upAmount -= downSpeed;
                yield return null;
            }
            upAmount = 0.0f;
        }

        // Update is called once per frame
        void Update()
        {
            mat.SetFloat("_NoiseAmount", map(upAmount, 0.0f, 1.0f, wobbleDownTarget, wobbleUpTarget));
            float panelsScale = map(upAmount, 0.0f, 1.0f, panelsDownScale, panelsUpScale);
            PanelsTransform.localScale = new Vector3(panelsScale, panelsScale, panelsScale);
#if UNITY_EDITOR   //we will only use this script on the editor side, though there is nothing that would prevent it from working on device
            if (Input.GetMouseButtonDown(0))
            {
                Debug.Log("Mouse button down");
                RaycastHit rayHit;
                Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

                if (Physics.Raycast(ray, out rayHit, 100, collisionLayer))
                {
                    Debug.Log("Hit!");
                    if (currentCoroutine != null)
                        StopCoroutine(currentCoroutine);
                    if (!goingUp)
                        currentCoroutine = StartCoroutine("WobbleUp");
                    else
                        currentCoroutine = StartCoroutine("WobbleDown");
                }
            }

#else
            for (var i = 0; i < Input.touchCount; ++i) {
                if (Input.GetTouch(i).phase == TouchPhase.Began) {
                 
                    // Construct a ray from the current touch coordinates
                    Ray ray = Camera.main.ScreenPointToRay(Input.GetTouch(i).position);
                    RaycastHit rayHit;
                    // Create a particle if hit
                    if (Physics.Raycast(ray, out rayHit, 100, collisionLayer))
                    {
                        Debug.Log("Hit!");
                        if (currentCoroutine != null)
                            StopCoroutine(currentCoroutine);
                        if (!goingUp)
                            currentCoroutine = StartCoroutine("WobbleUp");
                        else
                            currentCoroutine = StartCoroutine("WobbleDown");
                    }
                }
            }
#endif

        }
	}
}
