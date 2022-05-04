using System.IO;
using UnityEditor;
using UnityEngine;

public class ScreenShotWindow : EditorWindow
{
    private Camera m_Camera;
    private string filePath;
    private bool m_IsEnableAlpha = false;
    private CameraClearFlags m_CameraClearFlags;

    [MenuItem("Tools/��Ļ��ͼ")]
    private static void Init()
    {
        ScreenShotWindow window = GetWindowWithRect<ScreenShotWindow>(new Rect(0, 0, 300, 150));
        window.titleContent = new GUIContent("��Ļ��ͼ");
        window.Show();
    }

    private void OnGUI()
    {
        EditorGUILayout.Space();
        m_Camera = EditorGUILayout.ObjectField("ѡ�������", m_Camera, typeof(Camera), true) as Camera;

        if (GUILayout.Button("ѡ�񱣴�λ��"))
        {
            filePath = EditorUtility.OpenFolderPanel("", "", "");
        }

        m_IsEnableAlpha = EditorGUILayout.Toggle("�Ƿ�ʹ�ô�ɫ����", m_IsEnableAlpha);  //�Ƿ���͸��ͨ��
        EditorGUILayout.Space();
        if (GUILayout.Button("���������ͼ"))
        {
            TakeShot();
        }
        if (GUILayout.Button("���ڽ�ͼ����UI��"))
        {
            string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
            ScreenCapture.CaptureScreenshot(fileName);
        }
        EditorGUILayout.Space();
        if (GUILayout.Button("�򿪵����ļ���"))
        {
            if (string.IsNullOrEmpty(filePath))
            {
                Debug.LogError("<color=red>" + "û��ѡ���ͼ����λ��" + "</color>");
                return;
            }
            Application.OpenURL("file://" + filePath);
        }
    }

    private void TakeShot()
    {
        if (m_Camera == null)
        {
            Debug.LogError("<color=red>" + "û��ѡ�������" + "</color>");
            return;
        }

        if (string.IsNullOrEmpty(filePath))
        {
            Debug.LogError("<color=red>" + "û��ѡ���ͼ����λ��" + "</color>");
            return;
        }

        m_CameraClearFlags = m_Camera.clearFlags;
        if (m_IsEnableAlpha)
        {
            m_Camera.clearFlags = CameraClearFlags.Depth;
        }

        int resolutionX = (int)Handles.GetMainGameViewSize().x;
        int resolutionY = (int)Handles.GetMainGameViewSize().y;
        RenderTexture rt = new RenderTexture(resolutionX, resolutionY, 24);
        m_Camera.targetTexture = rt;
        Texture2D screenShot = new Texture2D(resolutionX, resolutionY, TextureFormat.ARGB32, false);
        m_Camera.Render();
        RenderTexture.active = rt;
        screenShot.ReadPixels(new Rect(0, 0, resolutionX, resolutionY), 0, 0);
        m_Camera.targetTexture = null;
        RenderTexture.active = null;
        m_Camera.clearFlags = m_CameraClearFlags;
        //Destroy(rt);
        byte[] bytes = screenShot.EncodeToPNG();
        string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
        File.WriteAllBytes(fileName, bytes);
        Debug.Log("��ͼ�ɹ�");
    }
}