using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Profiling;
//[ExecuteInEditMode]

public class ProjectionShadowMap : MonoBehaviour
{
    public RenderTexture renderTexture;
    Camera m_shadowMapCamera;
    public Shader replaceShader;
    int m_matrixshaderID;
    Matrix4x4 m_matrixPosToUV;

    void Start()
    {
        m_matrixshaderID = Shader.PropertyToID("_shadowMapProjectionMatrix");
        m_shadowMapCamera = gameObject.GetComponent<Camera>();
        if(m_shadowMapCamera == null)
            m_shadowMapCamera = gameObject.AddComponent<Camera>();
        m_shadowMapCamera.clearFlags = CameraClearFlags.SolidColor;
        if(SystemInfo.usesReversedZBuffer)
        {
            m_shadowMapCamera.backgroundColor = Color.black;
        }
        else
        {
            m_shadowMapCamera.backgroundColor =Color.white;
        }

        m_shadowMapCamera.orthographic              =true;
        m_shadowMapCamera.nearClipPlane             =1;
        m_shadowMapCamera.farClipPlane              =20;
        m_shadowMapCamera.cullingMask               = LayerMask.GetMask(new string[] {"UI"});
        m_shadowMapCamera.SetReplacementShader(replaceShader,"RenderType");
        //摄像机最早渲染
        m_shadowMapCamera.depth                     =-1;
        m_shadowMapCamera.orthographicSize          =8;
        m_shadowMapCamera.allowHDR                  =false;
        m_shadowMapCamera.allowMSAA                 =false;
        //m_shadowMapCamera.enabled                   =false;
        renderTexture = new RenderTexture(1024,1024,32,RenderTextureFormat.ARGB32);
        renderTexture.name = "SceneShadowMap";
        renderTexture.filterMode = FilterMode.Bilinear;
        m_shadowMapCamera.targetTexture = renderTexture;
        Shader.SetGlobalTexture("_ShadowMapTex",renderTexture);
        //阴影后处理
        //UV重映射
        m_matrixPosToUV = new Matrix4x4();
        m_matrixPosToUV.SetRow(0, new Vector4(0.5f,0,0,0.5f));
        m_matrixPosToUV.SetRow(1, new Vector4(0,0.5f,0,0.5f));
        m_matrixPosToUV.SetRow(2, new Vector4(0,0,1,0));
        m_matrixPosToUV.SetRow(3, new Vector4(0,0,0,1));

    }

    // Update is called once per frame
    void Update()
    {
        Matrix4x4 worldToView = m_shadowMapCamera.worldToCameraMatrix;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(m_shadowMapCamera.projectionMatrix,false);
        Shader.SetGlobalMatrix("_shadowMapProjectionMatrix",m_matrixPosToUV * projection * worldToView);
    }
}
