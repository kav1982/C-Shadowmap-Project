using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CaptureDepth : MonoBehaviour
{
    public RenderTexture depthTexture;
    private Shader mSampleDepthShader;
    public Camera mCam;
    
    public Camera camera
    {
        get
        {
            if (mCam == null)
            {
                mCam =GetComponent<Camera>();
            }
            return mCam;
        }
    }
    
    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    void Update()
    {
        mCam = GetComponent<Camera>();
        
        if (mSampleDepthShader == null)
            mSampleDepthShader = Shader.Find("ShadowMap/DepthTextureShader");

        if (mCam != null)
        {
            mCam.backgroundColor = Color.black;
            mCam.clearFlags = CameraClearFlags.Color;
            mCam.targetTexture = depthTexture;
            mCam.enabled = false;

            Shader.SetGlobalTexture("_DepthTexture", depthTexture);
            Shader.SetGlobalFloat("_TexturePixelWidth", depthTexture.width);
            Shader.SetGlobalFloat("_TexturePixeHeight", depthTexture.height);

            mCam.RenderWithShader(mSampleDepthShader,"RenderType");
            //mCam.SetReplacementShader (mSampleDepthShader,"RenderType");
            //Debug.log("_SampleDepthShader");
        } 
    }
}
